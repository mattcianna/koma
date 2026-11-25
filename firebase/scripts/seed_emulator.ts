import admin from 'firebase-admin';

// Configure environment to point strictly to local emulators
process.env.FIREBASE_AUTH_EMULATOR_HOST =
  process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';

const TEST_UID = 'koma-test-uid-001';
const TEST_EMAIL = 'test@mangatracker.local';
const TEST_PASSWORD = 'KomaTest!2026#Dev';
const TEST_DISPLAY_NAME = 'QA Test Agent';
const PROJECT_ID = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT || 'demo-koma';
const DEVICE_ID = 'pixel9_emulator_device_001';

admin.initializeApp({
  projectId: PROJECT_ID,
});

const auth = admin.auth();
const db = admin.firestore();

async function seedAuthUser(): Promise<void> {
  console.log(`\n[1/5] Seeding Firebase Auth user: ${TEST_EMAIL}...`);

  try {
    const existingUser = await auth.getUser(TEST_UID);
    console.log(`User already exists with UID: ${existingUser.uid}. Updating password...`);
    await auth.updateUser(TEST_UID, {
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
      displayName: TEST_DISPLAY_NAME,
      emailVerified: true,
    });
  } catch (err: any) {
    if (err.code === 'auth/user-not-found') {
      console.log(`Creating fresh user ${TEST_EMAIL} with UID: ${TEST_UID}...`);
      await auth.createUser({
        uid: TEST_UID,
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        displayName: TEST_DISPLAY_NAME,
        emailVerified: true,
      });
    } else {
      throw err;
    }
  }
  console.log('✅ Auth user ready.');
}

async function seedUserProfile(): Promise<void> {
  console.log(`\n[2/5] Seeding Firestore document: users/${TEST_UID}...`);

  const userRef = db.doc(`users/${TEST_UID}`);
  await userRef.set({
    uid: TEST_UID,
    email: TEST_EMAIL,
    displayName: TEST_DISPLAY_NAME,
    photoUrl: null,
    uiLocale: 'en',
    preferredLanguages: ['en', 'it'],
    contentRatings: ['safe', 'suggestive'],
    notificationsEnabled: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('✅ User profile seeded.');
}

async function seedDeviceTokens(): Promise<void> {
  console.log(`\n[3/5] Seeding test FCM device token for ${DEVICE_ID}...`);

  const deviceRef = db.doc(`users/${TEST_UID}/devices/${DEVICE_ID}`);
  await deviceRef.set({
    token: 'fcm-fake-test-token-pixel-9-avd-emulator-hash-1234567890',
    platform: 'android',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('✅ Device registration seeded.');
}

async function seedLibraryDocuments(): Promise<void> {
  console.log(`\n[4/5] Seeding realistic MangaDex library entries...`);

  // Canonical live-verified MangaDex tuples
  const sampleLibrary = [
    {
      mangaId: 'a77742b1-befd-49a4-bff5-1ad4e6b0ef7b', // Chainsaw Man
      title: 'Chainsaw Man',
      coverFileName: '6e518bd1-5f60-446b-8832-bfe6bf74834b.jpg',
      status: 'Reading',
      preferredLanguages: ['en', 'it'],
      readChapters: Array.from({ length: 150 }, (_, i) => (i + 1).toString()),
      readVolumes: Array.from({ length: 16 }, (_, i) => (i + 1).toString()),
      lastReadChapter: '150',
      lastReadChapterId: 'fake-ch-uuid-csm-150',
      latestKnownChapterId: 'fake-ch-uuid-csm-155',
      latestKnownChapterNumber: '155',
    },
    {
      mangaId: 'b0b721ff-c388-4486-aa0f-c2b0bb321512', // Sousou no Frieren
      title: "Frieren: Beyond Journey's End",
      coverFileName: 'b9a049b0-186b-4714-a83e-bb965458914a.jpg',
      status: 'Reading',
      preferredLanguages: ['en', 'it'],
      readChapters: Array.from({ length: 120 }, (_, i) => (i + 1).toString()),
      readVolumes: Array.from({ length: 11 }, (_, i) => (i + 1).toString()),
      lastReadChapter: '120',
      lastReadChapterId: 'fake-ch-uuid-fri-120',
      latestKnownChapterId: 'fake-ch-uuid-fri-128',
      latestKnownChapterNumber: '128',
    },
    {
      mangaId: 'd90ea6cb-7bc3-4d80-8af0-28557e6c4e17', // Dungeon Meshi
      title: 'Dungeon Meshi',
      coverFileName: 'd3430039-ea47-48c3-9b8b-cf80200d7f0b.jpg',
      status: 'Completed',
      preferredLanguages: ['en'],
      readChapters: Array.from({ length: 97 }, (_, i) => (i + 1).toString()),
      readVolumes: Array.from({ length: 14 }, (_, i) => (i + 1).toString()),
      lastReadChapter: '97',
      lastReadChapterId: 'fake-ch-uuid-dm-97',
      latestKnownChapterId: 'fake-ch-uuid-dm-97',
      latestKnownChapterNumber: '97',
    },
    {
      mangaId: '801513ba-a712-498c-8f57-cae55b38cc92', // Berserk
      title: 'Berserk',
      coverFileName: '81e1c82d-6672-400c-8c58-4ff9bfb89031.jpg',
      status: 'On Hold',
      preferredLanguages: ['en'],
      readChapters: Array.from({ length: 300 }, (_, i) => (i + 1).toString()),
      readVolumes: Array.from({ length: 35 }, (_, i) => (i + 1).toString()),
      lastReadChapter: '300',
      lastReadChapterId: 'fake-ch-uuid-ber-300',
      latestKnownChapterId: 'fake-ch-uuid-ber-376',
      latestKnownChapterNumber: '376',
    },
    {
      mangaId: '296cbc31-af1a-4b5b-a34b-fee2b4cad542', // Oshi no Ko
      title: '【OSHI NO KO】',
      coverFileName: 'd803d885-e371-4018-b332-4cbc5935177f.jpg',
      status: 'Plan to Read',
      preferredLanguages: ['en'],
      readChapters: [],
      readVolumes: [],
      lastReadChapter: null,
      lastReadChapterId: null,
      latestKnownChapterId: 'fake-ch-uuid-onk-150',
      latestKnownChapterNumber: '150',
    },
  ];

  const batch = db.batch();
  for (const manga of sampleLibrary) {
    const docRef = db.doc(`users/${TEST_UID}/library/${manga.mangaId}`);
    batch.set(docRef, {
      ...manga,
      uid: TEST_UID,
      addedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
  console.log(`✅ Seeded ${sampleLibrary.length} manga titles in users/${TEST_UID}/library.`);
}

async function seedReadingHistory(): Promise<void> {
  console.log(`\n[5/5] Seeding reading history timeline events...`);

  const now = Date.now();
  const oneHour = 60 * 60 * 1000;
  const oneDay = 24 * oneHour;

  const events = [
    {
      eventId: 'evt-csm-150-single',
      uid: TEST_UID,
      mangaId: 'a77742b1-befd-49a4-bff5-1ad4e6b0ef7b',
      mangaTitle: 'Chainsaw Man',
      coverFileName: '6e518bd1-5f60-446b-8832-bfe6bf74834b.jpg',
      actionType: 'chapter_read',
      chapterNumbers: ['150'],
      volumeNumber: null,
      chaptersCount: 1,
      timestamp: admin.firestore.Timestamp.fromMillis(now - 2 * oneHour),
    },
    {
      eventId: 'evt-csm-vol16-complete',
      uid: TEST_UID,
      mangaId: 'a77742b1-befd-49a4-bff5-1ad4e6b0ef7b',
      mangaTitle: 'Chainsaw Man',
      coverFileName: '6e518bd1-5f60-446b-8832-bfe6bf74834b.jpg',
      actionType: 'volume_read',
      chapterNumbers: ['144', '145', '146', '147', '148', '149', '150'],
      volumeNumber: '16',
      chaptersCount: 7,
      timestamp: admin.firestore.Timestamp.fromMillis(now - 1 * oneDay),
    },
    {
      eventId: 'evt-frieren-bulk-catchup',
      uid: TEST_UID,
      mangaId: 'b0b721ff-c388-4486-aa0f-c2b0bb321512',
      mangaTitle: "Frieren: Beyond Journey's End",
      coverFileName: 'b9a049b0-186b-4714-a83e-bb965458914a.jpg',
      actionType: 'bulk_previous_read',
      chapterNumbers: ['110', '111', '112', '113', '114', '115', '116', '117', '118', '119', '120'],
      volumeNumber: null,
      chaptersCount: 11,
      timestamp: admin.firestore.Timestamp.fromMillis(now - 3 * oneDay),
    },
  ];

  const batch = db.batch();
  for (const event of events) {
    const docRef = db.doc(`users/${TEST_UID}/reading_history/${event.eventId}`);
    batch.set(docRef, event);
  }

  await batch.commit();
  console.log(`✅ Seeded ${events.length} reading history events.`);
}

async function main() {
  console.log('===============================================================');
  console.log('🚀 SEEDING FIREBASE EMULATOR WITH KOMA TEST FIXTURES');
  console.log(
    `Target: Auth (${process.env.FIREBASE_AUTH_EMULATOR_HOST}), Firestore (${process.env.FIRESTORE_EMULATOR_HOST})`,
  );
  console.log(`Project: ${PROJECT_ID}, User: ${TEST_EMAIL} (${TEST_UID})`);
  console.log('===============================================================');

  try {
    await seedAuthUser();
    await seedUserProfile();
    await seedDeviceTokens();
    await seedLibraryDocuments();
    await seedReadingHistory();
    console.log('\n🎉 ALL FIXTURES SUCCESSFULLY SEEDED! READY FOR QA.\n');
  } catch (error) {
    console.error('\n❌ SEEDING FAILED WITH ERROR:', error);
    process.exit(1);
  }
}

main();
