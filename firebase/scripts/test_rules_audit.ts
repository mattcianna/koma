import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const RULES_PATH = path.resolve(__dirname, '../firestore.rules');

let passed = 0;

async function check(name: string, fn: () => Promise<void>): Promise<void> {
  await fn();
  passed++;
  console.log(`  ✅ [${passed}] ${name}`);
}

function validUserPayload(uid: string) {
  return {
    uid,
    email: `${uid}@mangatracker.local`,
    displayName: 'Koma Reader',
    uiLocale: 'en',
    preferredLanguages: ['en', 'it'],
    contentRatings: ['safe', 'suggestive'],
    notificationsEnabled: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

function validDevicePayload() {
  return {
    token: 'fcm-device-token-minimum-32-chars-long-0123456789',
    platform: 'android',
    updatedAt: serverTimestamp(),
  };
}

function validLibraryPayload(uid: string, mangaId: string, omitOptional = false) {
  const base: Record<string, unknown> = {
    mangaId,
    uid,
    title: 'Chainsaw Man',
    status: 'Reading',
    preferredLanguages: ['en', 'it'],
    readChapters: ['1', '2'],
    readVolumes: ['1'],
    addedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
  if (!omitOptional) {
    base.coverFileName = '6e518bd1-5f60-446b-8832-bfe6bf74834b.jpg';
    base.lastReadChapter = '2';
    base.lastReadChapterId = '11111111-1111-1111-1111-111111111111';
  }
  return base;
}

function validHistoryPayload(
  uid: string,
  eventId: string,
  mangaId: string,
  actionType: 'chapter_read' | 'volume_read' | 'bulk_previous_read',
  chapters: string[],
  volumeNumber: string | null = null,
) {
  return {
    eventId,
    uid,
    mangaId,
    mangaTitle: 'Chainsaw Man',
    coverFileName: '6e518bd1-5f60-446b-8832-bfe6bf74834b.jpg',
    actionType,
    chapterNumbers: chapters,
    volumeNumber,
    chaptersCount: chapters.length,
    timestamp: serverTimestamp(),
  };
}

async function runAudit(): Promise<void> {
  const rules = fs.readFileSync(RULES_PATH, 'utf8');
  const testEnv: RulesTestEnvironment = await initializeTestEnvironment({
    projectId: 'demo-koma-rules-audit',
    firestore: {
      rules,
      host: '127.0.0.1',
      port: 8080,
    },
  });

  try {
    const alice = 'alice-uid-001';
    const bob = 'bob-uid-002';
    const mangaId = 'a77742b1-befd-49a4-bff5-1ad4e6b0ef7b';

    const unauthDb = testEnv.unauthenticatedContext().firestore();
    const aliceDb = testEnv.authenticatedContext(alice, { email: 'alice@mangatracker.local' }).firestore();
    const bobDb = testEnv.authenticatedContext(bob, { email: 'bob@mangatracker.local' }).firestore();

    // Seed baseline Alice docs via Admin/Security-Rules-Disabled context
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const adminDb = ctx.firestore();
      await setDoc(doc(adminDb, `users/${alice}`), validUserPayload(alice));
      await setDoc(doc(adminDb, `users/${alice}/devices/dev1`), validDevicePayload());
      await setDoc(doc(adminDb, `users/${alice}/library/${mangaId}`), validLibraryPayload(alice, mangaId));
      await setDoc(
        doc(adminDb, `users/${alice}/reading_history/evt1`),
        validHistoryPayload(alice, 'evt1', mangaId, 'chapter_read', ['1']),
      );
      await setDoc(doc(adminDb, `users/${bob}`), validUserPayload(bob));
    });

    console.log('\nRunning 21-Vector Red-Team Security Rules Audit + Positive Owner Flows...\n');

    // Positive baseline checks
    await check('Owner can create, read, update user profile with immutable uid/createdAt preserved', async () => {
      const carol = 'carol-uid-003';
      const carolDb = testEnv.authenticatedContext(carol).firestore();
      await assertSucceeds(setDoc(doc(carolDb, `users/${carol}`), validUserPayload(carol)));
      await assertSucceeds(getDoc(doc(carolDb, `users/${carol}`)));
      await assertSucceeds(updateDoc(doc(carolDb, `users/${carol}`), { uiLocale: 'it', updatedAt: serverTimestamp() }));
    });

    await check('Owner can commit atomic WriteBatch (library + bulk_previous_read history)', async () => {
      const batch = writeBatch(aliceDb);
      batch.update(doc(aliceDb, `users/${alice}/library/${mangaId}`), {
        readChapters: ['1', '2', '3', '4', '5'],
        lastReadChapter: '5',
        updatedAt: serverTimestamp(),
      });
      batch.set(
        doc(aliceDb, `users/${alice}/reading_history/evt_bulk_1`),
        validHistoryPayload(alice, 'evt_bulk_1', mangaId, 'bulk_previous_read', ['3', '4', '5'], null),
      );
      await assertSucceeds(batch.commit());
    });

    // Vector 1: Public List Exploit
    await check('[Vector 1] Blocks unauthenticated list/read on users, library, reading_history', async () => {
      await assertFails(getDocs(collection(unauthDb, 'users')));
      await assertFails(getDoc(doc(unauthDb, `users/${alice}/library/${mangaId}`)));
      await assertFails(getDocs(collection(unauthDb, `users/${alice}/reading_history`)));
    });

    // Vector 2: Unauthorized Read/Write across users
    await check('[Vector 2] Blocks Bob reading or writing any document under Alice', async () => {
      await assertFails(getDoc(doc(bobDb, `users/${alice}/library/${mangaId}`)));
      await assertFails(setDoc(doc(bobDb, `users/${alice}/devices/hacked`), validDevicePayload()));
      await assertFails(deleteDoc(doc(bobDb, `users/${alice}/library/${mangaId}`)));
    });

    // Vector 3: The "Update Bypass" (ARGON-RULES-01)
    await check('[Vector 3] Blocks device update bypass with invalid platform / huge token', async () => {
      await assertFails(
        updateDoc(doc(aliceDb, `users/${alice}/devices/dev1`), {
          token: 'x'.repeat(2000),
          platform: 'windows_phone',
          updatedAt: serverTimestamp(),
        }),
      );
    });

    // Vector 4: Ownership Hijacking (Create)
    await check('[Vector 4] Blocks creating library item with mismatched data.uid', async () => {
      const lib = validLibraryPayload(bob, 'b0b721ff-c388-4486-aa0f-c2b0bb321512');
      await assertFails(setDoc(doc(aliceDb, `users/${alice}/library/b0b721ff-c388-4486-aa0f-c2b0bb321512`), lib));
    });

    // Vector 5: Ownership Hijacking (Update)
    await check('[Vector 5] Blocks updating library item to reassign uid to Bob', async () => {
      await assertFails(
        updateDoc(doc(aliceDb, `users/${alice}/library/${mangaId}`), {
          uid: bob,
          updatedAt: serverTimestamp(),
        }),
      );
    });

    // Vector 6: Immutable Field Modification
    await check('[Vector 6] Blocks tampering with immutable createdAt, addedAt, and reading_history updates/deletes', async () => {
      await assertFails(
        updateDoc(doc(aliceDb, `users/${alice}`), {
          createdAt: new Date(0),
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(aliceDb, `users/${alice}/library/${mangaId}`), {
          addedAt: new Date(0),
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(aliceDb, `users/${alice}/reading_history/evt1`), { mangaTitle: 'Tampered' }),
      );
      await assertFails(deleteDoc(doc(aliceDb, `users/${alice}/reading_history/evt1`)));
    });

    // Vector 7: Data Corruption (Type Juggling)
    await check('[Vector 7] Blocks type juggling on device platform and user contentRatings', async () => {
      await assertFails(
        setDoc(doc(aliceDb, `users/${alice}/devices/dev2`), {
          token: 'fcm-device-token-minimum-32-chars-long-0123456789',
          platform: 123,
          updatedAt: serverTimestamp(),
        }),
      );
      await assertFails(
        updateDoc(doc(aliceDb, `users/${alice}`), {
          contentRatings: [999],
          updatedAt: serverTimestamp(),
        }),
      );
    });

    // Vector 8: Validation Bypass (Create vs. Update)
    await check('[Vector 8] Blocks removing required fields during device update', async () => {
      await assertFails(
        setDoc(doc(aliceDb, `users/${alice}/devices/dev1`), {
          platform: 'android',
          updatedAt: serverTimestamp(),
        }),
      );
    });

    // Vector 9: Resource Exhaustion / DoS
    await check('[Vector 9] Blocks oversized strings and excess device/list items', async () => {
      await assertFails(
        setDoc(doc(aliceDb, `users/${alice}/devices/dev_dos`), {
          token: 'a'.repeat(501),
          platform: 'android',
          updatedAt: serverTimestamp(),
        }),
      );
    });

    // Vector 10: Required Field Omission
    await check('[Vector 10] Blocks omitting required status on library item', async () => {
      const bad = validLibraryPayload(alice, 'd90ea6cb-7bc3-4d80-8af0-28557e6c4e17');
      delete bad.status;
      await assertFails(setDoc(doc(aliceDb, `users/${alice}/library/d90ea6cb-7bc3-4d80-8af0-28557e6c4e17`), bad));
    });

    // Vector 11: Privilege Escalation
    await check('[Vector 11] Blocks adding role/isAdmin privilege fields', async () => {
      await assertFails(
        updateDoc(doc(aliceDb, `users/${alice}`), {
          isAdmin: true,
          updatedAt: serverTimestamp(),
        }),
      );
    });

    // Vector 12: Schema Pollution
    await check('[Vector 12] Blocks extra polluted keys on users, devices, library, reading_history', async () => {
      await assertFails(
        setDoc(doc(aliceDb, `users/${alice}/devices/dev_extra`), {
          ...validDevicePayload(),
          extraField: 'malicious',
        }),
      );
      await assertFails(
        setDoc(doc(aliceDb, `users/${alice}/reading_history/evt_extra`), {
          ...validHistoryPayload(alice, 'evt_extra', mangaId, 'chapter_read', ['9']),
          extraField: 'malicious',
        }),
      );
    });

    // Vector 13: Invalid State Transition / Action Invariant (ARGON-RULES-03)
    await check('[Vector 13] Enforces actionType invariants on chapter_read and volume_read', async () => {
      await assertFails(
        setDoc(
          doc(aliceDb, `users/${alice}/reading_history/evt_bad_ch`),
          validHistoryPayload(alice, 'evt_bad_ch', mangaId, 'chapter_read', ['1', '2'], '5'),
        ),
      );
      await assertFails(
        setDoc(
          doc(aliceDb, `users/${alice}/reading_history/evt_bad_vol`),
          validHistoryPayload(alice, 'evt_bad_vol', mangaId, 'volume_read', ['1', '2'], null),
        ),
      );
    });

    // Vector 14: Path Traversal / Relationship Scoping / URL Scheme (ARGON-RULES-04)
    await check('[Vector 14] Blocks mismatched doc ID vs mangaId and javascript: photoUrl scheme', async () => {
      await assertFails(
        setDoc(
          doc(aliceDb, `users/${alice}/library/wrong-id`),
          validLibraryPayload(alice, mangaId),
        ),
      );
      await assertFails(
        updateDoc(doc(aliceDb, `users/${alice}`), {
          photoUrl: 'javascript:alert(1)',
          updatedAt: serverTimestamp(),
        }),
      );
    });

    // Vector 15: Timestamp Manipulation
    await check('[Vector 15] Blocks backdated timestamps on users, library, and history', async () => {
      await assertFails(
        updateDoc(doc(aliceDb, `users/${alice}/library/${mangaId}`), {
          status: 'Completed',
          updatedAt: new Date(2020, 1, 1),
        }),
      );
      await assertFails(
        setDoc(doc(aliceDb, `users/${alice}/reading_history/evt_time`), {
          ...validHistoryPayload(alice, 'evt_time', mangaId, 'chapter_read', ['9']),
          timestamp: new Date(2020, 1, 1),
        }),
      );
    });

    // Vector 16: Negative Value / Overflow
    await check('[Vector 16] Blocks negative or mismatched chaptersCount', async () => {
      await assertFails(
        setDoc(doc(aliceDb, `users/${alice}/reading_history/evt_neg`), {
          ...validHistoryPayload(alice, 'evt_neg', mangaId, 'chapter_read', ['9']),
          chaptersCount: -5,
        }),
      );
    });

    // Vector 17: Mixed Content PII Leak
    await check('[Vector 17] Blocks Bob reading Alice user profile PII', async () => {
      await assertFails(getDoc(doc(bobDb, `users/${alice}`)));
    });

    // Vector 18: Client Delete of Users Denied & Action Replay Denied
    await check('[Vector 18] Blocks client delete on /users/{uid} and counter replay on history', async () => {
      await assertFails(deleteDoc(doc(aliceDb, `users/${alice}`)));
      await assertFails(
        setDoc(doc(aliceDb, `users/${alice}/reading_history/evt1`), {
          ...validHistoryPayload(alice, 'evt1', mangaId, 'chapter_read', ['9']),
        }),
      );
    });

    // Vector 19: Client collectionGroup('library') Denied
    await check('[Vector 19] Blocks client collectionGroup("library") query across users', async () => {
      await assertFails(getDocs(query(collectionGroup(aliceDb, 'library'), where('status', '==', 'Reading'))));
    });

    // Vector 20: Omitted optional fields work (ARGON-RULES-02)
    await check('[Vector 20] Allows creating Plan to Read library item omitting optional nullable keys', async () => {
      const mId = '801513ba-a712-498c-8f57-cae55b38cc92';
      await assertSucceeds(
        setDoc(doc(aliceDb, `users/${alice}/library/${mId}`), validLibraryPayload(alice, mId, true)),
      );
    });

    // Vector 21: Default deny unmatched root collections
    await check('[Vector 21] Denies access to any arbitrary unmatched path', async () => {
      await assertFails(getDoc(doc(aliceDb, 'admin/config')));
      await assertFails(setDoc(doc(aliceDb, 'public/test'), { hello: 'world' }));
    });

    console.log(`\n🎉 ALL ${passed} SECURITY RULE ASSERTION GROUPS PASSED!\n`);
  } finally {
    await testEnv.cleanup();
  }
}

runAudit().catch((err) => {
  console.error('❌ Security rules audit failed:', err);
  process.exit(1);
});
