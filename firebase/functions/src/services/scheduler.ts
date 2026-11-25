import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';
import { MangaDexClient } from './mangadex';
import { NotificationService } from './notification';
import { LibraryDocument, UserDocument, DeviceDocument } from '../types/firestore';
import { CONFIG } from '../config';

interface Subscriber {
  uid: string;
  libraryRef: admin.firestore.DocumentReference;
  title: string;
  preferredLanguages: Set<string>;
  readChapters: Set<string>;
  lastReadChapter?: string | null;
  latestKnownChapterId?: string | null;
  latestKnownChapterNumber?: string | null;
}

interface CandidateRelease {
  chapterId: string;
  chapterNumber: string;
  translatedLanguage: string | null;
  source: 'mangadex' | 'official';
}

function compareChapterNumbers(a: string, b: string): number {
  const normA = a.trim().toLowerCase();
  const normB = b.trim().toLowerCase();
  if (normA === normB) return 0;
  if (normA === 'none' || normA === '') return -1;
  if (normB === 'none' || normB === '') return 1;

  const parseNum = (val: string): number | null => {
    const m = val.match(/^(\d+(?:\.\d+)?)/);
    if (!m) return null;
    const parsed = Number.parseFloat(m[1]);
    return Number.isNaN(parsed) ? null : parsed;
  };

  const numA = parseNum(normA);
  const numB = parseNum(normB);
  if (numA !== null && numB !== null) {
    if (numA !== numB) return numA - numB;
    return normA.localeCompare(normB);
  }
  if (numA !== null) return -1;
  if (numB !== null) return 1;
  return normA.localeCompare(normB);
}

interface SubscriberGroup {
  mangaId: string;
  languages: Set<string>;
  subscribers: Subscriber[];
}

interface NotificationBatchGroup {
  chapterId: string;
  chapterNumber: string;
  mangaId: string;
  mangaTitle: string;
  uiLocale: 'en' | 'it';
  userTokens: Array<{ uid: string; token: string; deviceId: string }>;
}

export interface SchedulerExecutionResult {
  titlesChecked: number;
  chaptersFound: number;
  notificationsSent: number;
  emulatorSimulated: number;
}

export class NotificationScheduler {
  private db: admin.firestore.Firestore;
  private mangadex: MangaDexClient;
  private notifications: NotificationService;

  constructor(
    db: admin.firestore.Firestore,
    mangadex: MangaDexClient,
    notifications: NotificationService,
  ) {
    this.db = db;
    this.mangadex = mangadex;
    this.notifications = notifications;
  }

  /**
   * Primary entry point to execute the 24-hour manga release check.
   */
  public async executeDailyCheck(options?: {
    lookbackHours?: number;
    dryRun?: boolean;
  }): Promise<SchedulerExecutionResult> {
    const lookbackHours = options?.lookbackHours ?? 24;
    const dryRun = options?.dryRun ?? false;
    const sinceDate = new Date(Date.now() - lookbackHours * 60 * 60 * 1000);

    logger.info(
      `Starting Daily Manga Release Check. Lookback: ${lookbackHours}h (since ${sinceDate.toISOString()}), dryRun: ${dryRun}`,
    );

    // 1. Query all library items where status == 'Reading' using collectionGroup
    const librarySnapshot = await this.db
      .collectionGroup('library')
      .where('status', '==', 'Reading')
      .get();

    logger.info(`Found ${librarySnapshot.size} total active 'Reading' library entries.`);

    if (librarySnapshot.empty) {
      return { titlesChecked: 0, chaptersFound: 0, notificationsSent: 0, emulatorSimulated: 0 };
    }

    // 2. Aggregate subscribers by mangaId
    const mangaGroups = new Map<string, SubscriberGroup>();

    for (const doc of librarySnapshot.docs) {
      const data = doc.data() as LibraryDocument;
      const mangaId = data.mangaId;
      const languages =
        data.preferredLanguages && data.preferredLanguages.length > 0
          ? data.preferredLanguages
          : ['en'];

      let group = mangaGroups.get(mangaId);
      if (!group) {
        group = {
          mangaId,
          languages: new Set<string>(),
          subscribers: [],
        };
        mangaGroups.set(mangaId, group);
      }

      for (const lang of languages) {
        group.languages.add(lang);
      }

      group.subscribers.push({
        uid: data.uid,
        libraryRef: doc.ref,
        title: data.title,
        preferredLanguages: new Set(languages),
        readChapters: new Set(data.readChapters ?? []),
        lastReadChapter: data.lastReadChapter,
        latestKnownChapterId: data.latestKnownChapterId,
        latestKnownChapterNumber: data.latestKnownChapterNumber,
      });
    }

    logger.info(
      `Deduplicated ${librarySnapshot.size} reading items into ${mangaGroups.size} unique manga titles.`,
    );

    let totalChaptersDiscovered = 0;
    let totalNotificationsSent = 0;
    let totalEmulatorSimulated = 0;

    // Cache user profiles (for uiLocale) and devices
    const userProfiles = new Map<string, UserDocument>();
    const userDevices = new Map<string, Array<{ deviceId: string; token: string }>>();

    // Structure for batching Firestore library document updates
    const pendingLibraryUpdates: Array<{
      ref: admin.firestore.DocumentReference;
      chapterId: string;
      chapterNumber: string;
    }> = [];

    // Structure for grouping notifications across all subscribers per release
    const notificationGroups = new Map<string, NotificationBatchGroup>();

    // 3. Process each unique manga title sequentially with rate limiting
    for (const [mangaId, group] of mangaGroups.entries()) {
      try {
        const languagesArray = Array.from(group.languages);
        const candidates: CandidateRelease[] = [];

        const mdChapters = await this.mangadex.getMangaFeed(
          mangaId,
          languagesArray,
          sinceDate,
        );
        for (const ch of mdChapters) {
          candidates.push({
            chapterId: ch.id,
            chapterNumber: ch.attributes.chapter ?? 'none',
            translatedLanguage: ch.attributes.translatedLanguage,
            source: 'mangadex',
          });
        }

        // Fallback to all-language MangaDex feed if no matching-language chapters found
        if (mdChapters.length === 0 && languagesArray.length > 0) {
          const fallbackMd = await this.mangadex.getMangaFeed(
            mangaId,
            [],
            sinceDate,
          );
          for (const ch of fallbackMd) {
            candidates.push({
              chapterId: ch.id,
              chapterNumber: ch.attributes.chapter ?? 'none',
              translatedLanguage: ch.attributes.translatedLanguage,
              source: 'mangadex',
            });
          }
        }

        // Also check official publisher RSS/Atom feed via attributes.links.raw
        const rawUrl = await this.mangadex.getMangaRawUrl(mangaId);
        if (rawUrl) {
          const officialChapters = await this.mangadex.getOfficialFeedChapters(rawUrl);
          for (const off of officialChapters) {
            if (!off.publishedAt || off.publishedAt >= sinceDate) {
              candidates.push({
                chapterId: off.id,
                chapterNumber: off.chapterNumber,
                translatedLanguage: null,
                source: 'official',
              });
            }
          }
        }

        if (candidates.length === 0) {
          continue;
        }

        // Order highest chapter number first
        candidates.sort((a, b) =>
          compareChapterNumbers(b.chapterNumber, a.chapterNumber),
        );

        totalChaptersDiscovered += candidates.length;

        // 4. Evaluate newly published chapters against each subscriber
        for (const sub of group.subscribers) {
          // Match preferred-language MangaDex chapters, official publisher releases,
          // or any all-language MangaDex fallback when none matched locally.
          const matchingChapter =
            candidates.find(
              (c) =>
                c.source === 'official' ||
                (c.translatedLanguage !== null &&
                  sub.preferredLanguages.has(c.translatedLanguage)),
            ) ?? candidates[0];

          if (!matchingChapter) {
            continue;
          }

          const chapterNumber = matchingChapter.chapterNumber;
          const chapterId = matchingChapter.chapterId;

          // Guard against duplicates or older chapters
          if (sub.latestKnownChapterId === chapterId) {
            continue;
          }
          if (
            sub.latestKnownChapterNumber &&
            chapterNumber !== 'none' &&
            compareChapterNumbers(chapterNumber, sub.latestKnownChapterNumber) <= 0
          ) {
            continue;
          }
          if (sub.readChapters.has(chapterNumber)) {
            continue;
          }
          if (
            sub.lastReadChapter &&
            chapterNumber !== 'none' &&
            compareChapterNumbers(chapterNumber, sub.lastReadChapter) <= 0
          ) {
            continue;
          }

          // Fetch user profile if not in cache
          let profile = userProfiles.get(sub.uid);
          if (!profile) {
            const userSnap = await this.db.doc(`users/${sub.uid}`).get();
            if (userSnap.exists) {
              profile = userSnap.data() as UserDocument;
              userProfiles.set(sub.uid, profile);
            }
          }

          const notificationsEnabled = profile?.notificationsEnabled ?? true;
          const uiLocale = profile?.uiLocale ?? 'en';

          if (notificationsEnabled && !dryRun) {
            // Fetch devices if not in cache
            let devices = userDevices.get(sub.uid);
            if (!devices) {
              const devicesSnap = await this.db.collection(`users/${sub.uid}/devices`).get();
              devices = devicesSnap.docs.map((d) => ({
                deviceId: d.id,
                token: (d.data() as DeviceDocument).token,
              }));
              userDevices.set(sub.uid, devices);
            }

            if (devices.length > 0) {
              // Group notifications by (chapterId, uiLocale, title) for batching
              const groupKey = `${chapterId}_${uiLocale}_${sub.title}`;
              let notifGroup = notificationGroups.get(groupKey);
              if (!notifGroup) {
                notifGroup = {
                  chapterId,
                  chapterNumber,
                  mangaId,
                  mangaTitle: sub.title,
                  uiLocale,
                  userTokens: [],
                };
                notificationGroups.set(groupKey, notifGroup);
              }

              for (const device of devices) {
                notifGroup.userTokens.push({
                  uid: sub.uid,
                  token: device.token,
                  deviceId: device.deviceId,
                });
              }
            }
          }

          // Queue library document update for batched commit
          if (!dryRun) {
            pendingLibraryUpdates.push({
              ref: sub.libraryRef,
              chapterId,
              chapterNumber,
            });
          }
        }
      } catch (mangaErr) {
        logger.error(`Error processing manga feed for ${mangaId}:`, mangaErr);
      }
    }

    // 5. Dispatch batched multicast notifications
    if (!dryRun && notificationGroups.size > 0) {
      logger.info(`Dispatching ${notificationGroups.size} aggregated notification groups via FCM.`);

      for (const group of notificationGroups.values()) {
        const result = await this.notifications.sendMulticastNotification(group.userTokens, {
          mangaId: group.mangaId,
          mangaTitle: group.mangaTitle,
          chapterNumber: group.chapterNumber,
          chapterId: group.chapterId,
          uiLocale: group.uiLocale,
        });

        totalNotificationsSent += result.successCount;
        totalEmulatorSimulated += result.emulatorSimulated;

        // Evict pruned tokens from userDevices cache
        if (result.prunedTokens.length > 0) {
          for (const pruned of result.prunedTokens) {
            const cached = userDevices.get(pruned.uid);
            if (cached) {
              userDevices.set(
                pruned.uid,
                cached.filter((d) => d.deviceId !== pruned.deviceId),
              );
            }
          }
        }
      }
    }

    // 6. Batch commit library updates (<= 490 ops per WriteBatch)
    if (!dryRun && pendingLibraryUpdates.length > 0) {
      logger.info(
        `Committing ${pendingLibraryUpdates.length} library progress updates in WriteBatch chunks.`,
      );

      for (let i = 0; i < pendingLibraryUpdates.length; i += CONFIG.firestore.maxBatchWriteSize) {
        const chunk = pendingLibraryUpdates.slice(i, i + CONFIG.firestore.maxBatchWriteSize);
        const batch = this.db.batch();

        for (const update of chunk) {
          batch.update(update.ref, {
            latestKnownChapterId: update.chapterId,
            latestKnownChapterNumber: update.chapterNumber,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }
    }

    logger.info(
      `Daily check finished. Titles checked: ${mangaGroups.size}, Chapters found: ${totalChaptersDiscovered}, Notifications sent: ${totalNotificationsSent}, Simulated in emulator: ${totalEmulatorSimulated}`,
    );

    return {
      titlesChecked: mangaGroups.size,
      chaptersFound: totalChaptersDiscovered,
      notificationsSent: totalNotificationsSent,
      emulatorSimulated: totalEmulatorSimulated,
    };
  }
}
