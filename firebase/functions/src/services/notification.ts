import * as admin from 'firebase-admin';
import * as logger from 'firebase-functions/logger';
import { CONFIG } from '../config';

export interface NotificationPayload {
  mangaId: string;
  mangaTitle: string;
  chapterNumber: string;
  chapterId: string;
  uiLocale: 'en' | 'it';
}

export interface MulticastResult {
  successCount: number;
  failureCount: number;
  emulatorSimulated: number;
  prunedTokens: Array<{ uid: string; deviceId: string }>;
}

export class NotificationService {
  private messaging: admin.messaging.Messaging;
  private db: admin.firestore.Firestore;

  constructor(messaging: admin.messaging.Messaging, db: admin.firestore.Firestore) {
    this.messaging = messaging;
    this.db = db;
  }

  /**
   * Generates localized notification title and body based on recipient UI locale.
   */
  public static formatMessage(payload: NotificationPayload): { title: string; body: string } {
    const isUnnumbered = !payload.chapterNumber || payload.chapterNumber === 'none';
    if (payload.uiLocale === 'it') {
      const chapterLabel = isUnnumbered ? 'Nuovo Capitolo' : `Capitolo ${payload.chapterNumber}`;
      return {
        title: `${payload.mangaTitle} — Nuovo Rilascio!`,
        body: `È disponibile il ${chapterLabel}. Tocca per aggiornare i tuoi progressi in Koma.`,
      };
    }

    const chapterLabel = isUnnumbered ? 'New Chapter' : `Chapter ${payload.chapterNumber}`;
    return {
      title: `${payload.mangaTitle} — New Release!`,
      body: `${chapterLabel} is now available. Tap to track your reading progress in Koma.`,
    };
  }

  /**
   * Dispatches FCM multicast notification to devices and cleans up invalid tokens.
   * Returns counts and the list of pruned token references so calling caches can be updated.
   */
  public async sendMulticastNotification(
    userTokens: Array<{ uid: string; token: string; deviceId: string }>,
    payload: NotificationPayload,
  ): Promise<MulticastResult> {
    if (userTokens.length === 0) {
      return { successCount: 0, failureCount: 0, emulatorSimulated: 0, prunedTokens: [] };
    }

    const { title, body } = NotificationService.formatMessage(payload);
    const deepLinkRoute = `/library/manga/${payload.mangaId}`;

    const tokens = userTokens.map((t) => t.token);
    let totalSuccess = 0;
    let totalFailure = 0;
    let totalSimulated = 0;
    const tokensToDelete: Array<{ uid: string; deviceId: string }> = [];

    // Chunk tokens into batches of <= 500 for FCM sendEachForMulticast
    for (let i = 0; i < tokens.length; i += CONFIG.fcm.maxMulticastBatchSize) {
      const chunkTokens = tokens.slice(i, i + CONFIG.fcm.maxMulticastBatchSize);
      const chunkRefs = userTokens.slice(i, i + CONFIG.fcm.maxMulticastBatchSize);

      const message: admin.messaging.MulticastMessage = {
        tokens: chunkTokens,
        notification: {
          title,
          body,
        },
        data: {
          mangaId: payload.mangaId,
          chapterId: payload.chapterId,
          chapterNumber: payload.chapterNumber,
          route: deepLinkRoute,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'koma_manga_releases',
            icon: 'ic_notification',
            color: '#E11D48', // Koma Vermilion
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: { title, body },
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      try {
        const response = await this.messaging.sendEachForMulticast(message);
        totalSuccess += response.successCount;
        totalFailure += response.failureCount;

        response.responses.forEach((resp, index) => {
          if (!resp.success) {
            const error = resp.error;
            const ref = chunkRefs[index];
            logger.warn(
              `FCM delivery failure for user ${ref.uid}, device ${ref.deviceId}: ${error?.code}`,
            );

            // Check for invalid or unregistered registration tokens
            if (
              error?.code === 'messaging/registration-token-not-registered' ||
              error?.code === 'messaging/invalid-registration-token' ||
              error?.code === 'messaging/invalid-argument'
            ) {
              tokensToDelete.push({ uid: ref.uid, deviceId: ref.deviceId });
            }
          }
        });
      } catch (err: any) {
        const isEmulator = process.env.FUNCTIONS_EMULATOR === 'true';
        const isInvalidArgument =
          err?.code === 'messaging/invalid-argument' ||
          err?.code === 'messaging/invalid-registration-token';

        if (isEmulator && !isInvalidArgument) {
          logger.info(
            `[EMULATOR SIMULATION] FCM send simulated for ${chunkTokens.length} device tokens (offline demo project / missing GCP credentials). Payload:`,
            {
              title,
              body,
              data: message.data,
              tokens: chunkTokens,
            },
          );
          totalSimulated += chunkTokens.length;
          totalSuccess += chunkTokens.length;
        } else {
          logger.error('Failed to send multicast batch:', err);
          totalFailure += chunkTokens.length;
        }
      }
    }

    // Prune stale / unregistered device tokens from Firestore
    if (tokensToDelete.length > 0) {
      logger.info(`Pruning ${tokensToDelete.length} unregistered device tokens from Firestore.`);
      await this.pruneInvalidTokens(tokensToDelete);
    }

    return {
      successCount: totalSuccess,
      failureCount: totalFailure,
      emulatorSimulated: totalSimulated,
      prunedTokens: tokensToDelete,
    };
  }

  /**
   * Batch deletes invalid tokens from users/{uid}/devices/{deviceId}.
   */
  private async pruneInvalidTokens(
    tokens: Array<{ uid: string; deviceId: string }>,
  ): Promise<void> {
    const batches: admin.firestore.WriteBatch[] = [];
    let currentBatch = this.db.batch();
    let count = 0;

    for (const item of tokens) {
      const deviceRef = this.db.doc(`users/${item.uid}/devices/${item.deviceId}`);
      currentBatch.delete(deviceRef);
      count++;

      if (count === CONFIG.firestore.maxBatchWriteSize) {
        batches.push(currentBatch);
        currentBatch = this.db.batch();
        count = 0;
      }
    }

    if (count > 0) {
      batches.push(currentBatch);
    }

    await Promise.all(batches.map((b) => b.commit()));
  }
}
