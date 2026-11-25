import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onRequest } from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';

import { CONFIG } from './config';
import { MangaDexClient } from './services/mangadex';
import { NotificationService } from './services/notification';
import { NotificationScheduler } from './services/scheduler';

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const mangadexClient = new MangaDexClient();
const notificationService = new NotificationService(messaging, db);
const scheduler = new NotificationScheduler(db, mangadexClient, notificationService);

/**
 * Scheduled Cloud Function v2: Runs every 24 hours at 06:00 UTC.
 * Scans for new chapters across all reading manga and sends FCM notifications.
 */
export const checkDailyMangaReleases = onSchedule(
  {
    region: CONFIG.scheduler.region,
    schedule: CONFIG.scheduler.defaultCronSchedule,
    timeZone: CONFIG.scheduler.timeZone,
    timeoutSeconds: CONFIG.scheduler.timeoutSeconds,
    memory: CONFIG.scheduler.memory,
  },
  async (event) => {
    logger.info('Scheduled release check execution triggered.', {
      scheduleTime: event.scheduleTime,
    });

    try {
      const stats = await scheduler.executeDailyCheck({ lookbackHours: 24, dryRun: false });
      logger.info('checkDailyMangaReleases completed successfully:', stats);
    } catch (error) {
      logger.error('Fatal error during checkDailyMangaReleases execution:', error);
      throw error;
    }
  },
);

/**
 * Manual HTTP Trigger for Local Emulator & Integration Testing.
 * Allows triggering the daily release check on demand with custom parameters.
 *
 * Query parameters:
 *  - lookbackHours: number (default: 24)
 *  - dryRun: boolean (default: false)
 */
export const triggerDailyCheckManual =
  process.env.FUNCTIONS_EMULATOR === 'true'
    ? onRequest(
        {
          timeoutSeconds: 300,
          memory: '512MiB',
        },
        async (req, res) => {
          logger.info('triggerDailyCheckManual invoked via HTTP.', { query: req.query });

          try {
            const lookbackHours = req.query.lookbackHours
              ? parseInt(req.query.lookbackHours as string, 10)
              : 24;
            const dryRun = req.query.dryRun === 'true';

            const stats = await scheduler.executeDailyCheck({ lookbackHours, dryRun });

            res.status(200).json({
              status: 'ok',
              titlesChecked: stats.titlesChecked,
              chaptersFound: stats.chaptersFound,
              notificationsSent: stats.notificationsSent,
              emulatorSimulated: stats.emulatorSimulated,
              timestamp: new Date().toISOString(),
              lookbackHours,
              dryRun,
            });
          } catch (error: any) {
            logger.error('Manual trigger failed:', error);
            res.status(500).json({
              status: 'error',
              message: error.message || 'Internal Server Error',
            });
          }
        },
      )
    : undefined;
