export const CONFIG = {
  mangadex: {
    baseUrl: 'https://api.mangadex.org',
    userAgent: 'Koma/0.1.0 (https://github.com/mattcianna/koma)',
    maxRequestsPerSecond: 3.84,
    minTimeBetweenRequestsMs: 260,
    feedPageLimit: 100,
  },
  fcm: {
    maxMulticastBatchSize: 500,
  },
  firestore: {
    maxBatchWriteSize: 490, // Margin below Firestore 500-op ceiling
  },
  scheduler: {
    region: 'europe-west1' as const,
    timeZone: 'UTC',
    defaultCronSchedule: '0 */2 * * *', // Every 2 hours UTC
    timeoutSeconds: 540,
    memory: '512MiB' as const,
  },
};
