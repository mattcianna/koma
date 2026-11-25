# 06 — Test Account, Emulator Suite, and Pixel 9 Setup

This document specifies the local development, test account fixtures, Firebase Emulator Suite configuration, and automated Pixel 9 Android Virtual Device (AVD) testing procedures for Koma.

---

## 1. Local Testing Philosophy & Architecture

To achieve rapid iteration cycles, zero cloud operational expenses during development, and zero risk of MangaDex IP rate bans, Koma employs a **hermetic local testing architecture**:

1. **Local Emulation**: Firebase Authentication, Cloud Firestore, and Cloud Functions run entirely on the host machine using the Firebase Emulator Suite.
2. **Predictable Test Fixture**: A standardized QA test account (`test@mangatracker.local`) is seeded automatically with deterministic reading statuses, chapter progress, and reading history events.
3. **Loopback Bridging**: Android emulators communicate with the host's emulator ports via the specialized loopback interface `10.0.2.2`.
4. **Bypass Interactive OAuth**: In development flavor builds (`koma-dev`), an automated 1-tap "Sign in as QA Agent" button allows instant authentication without opening Google Sign-In or Apple ID browser sheets.
5. **Physical / AVD Spec Alignment**: Testing targets the Google Pixel 9 profile (6.3" display, 1080 x 2424 resolution, 422 dpi, gesture navigation, and Material 3 ink aesthetics).

---

## 2. Firebase Emulator Configuration (`firebase/firebase.json`)

The emulator configuration binds all services to `0.0.0.0` (all network interfaces). This ensures accessibility from both host browsers (`localhost` / `127.0.0.1`) and the Android emulator loopback bridge (`10.0.2.2`).

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log"
      ]
    }
  ],
  "emulators": {
    "auth": {
      "port": 9099,
      "host": "0.0.0.0"
    },
    "firestore": {
      "port": 8080,
      "host": "0.0.0.0"
    },
    "functions": {
      "port": 5001,
      "host": "0.0.0.0"
    },
    "ui": {
      "enabled": true,
      "port": 4000,
      "host": "0.0.0.0"
    },
    "singleProjectMode": true
  }
}
```

### Port Allocation Summary

| Service | Host Port | Android AVD Access Point | iOS Simulator / Host URL |
| :--- | :--- | :--- | :--- |
| **Firebase Auth** | `9099` | `http://10.0.2.2:9099` | `http://127.0.0.1:9099` |
| **Cloud Firestore** | `8080` | `http://10.0.2.2:8080` | `http://127.0.0.1:8080` |
| **Cloud Functions** | `5001` | `http://10.0.2.2:5001` | `http://127.0.0.1:5001` |
| **Emulator UI** | `4000` | N/A (Web UI) | `http://127.0.0.1:4000` |

---

## 3. Environment Variables & App Configuration

### 3.1 `.env.example`
Place this configuration in the repository root as `.env.example` and copy to `.env.development`:

```bash
# ==============================================================================
# KOMA MANGA TRACKER - LOCAL DEVELOPMENT ENVIRONMENT CONFIGURATION
# ==============================================================================

# QA Test Account Credentials
KOMA_TEST_EMAIL=test@mangatracker.local
KOMA_TEST_PASSWORD=KomaTest!2026#Dev
KOMA_TEST_UID=koma-test-uid-001

# Firebase Emulator Integration
USE_FIREBASE_EMULATOR=true
FIREBASE_EMULATOR_HOST_ANDROID=10.0.2.2
FIREBASE_EMULATOR_HOST_IOS=127.0.0.1
FIREBASE_AUTH_EMULATOR_PORT=9099
FIREBASE_FIRESTORE_EMULATOR_PORT=8080
FIREBASE_FUNCTIONS_EMULATOR_PORT=5001

# MangaDex API Configuration
MANGADEX_BASE_URL=https://api.mangadex.org
MANGADEX_UPLOADS_URL=https://uploads.mangadex.org
MANGADEX_USER_AGENT=Koma/0.1.0 (https://github.com/mattcianna/koma)

# Application Flavor
FLAVOR=development
```

### 3.2 Flutter Emulator Initialization & Dev Bootstrap (`lib/main_development.dart`)

The development entrypoint aligns with `docs/02` Section 7.2's `bootstrap(...)` architecture. It initializes all local emulator bridges, initializes the 4-layer dependencies, injects them into `KomaApp`, and calls `SemanticsBinding.instance.ensureSemantics()` so Android AVD accessibility trees (`uiautomator dump`) are fully populated during automated test runs.

```dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:koma/app/view/app.dart';
import 'package:koma/bootstrap.dart';

import 'package:auth_repository/auth_repository.dart';
import 'package:firebase_auth_client/firebase_auth_client.dart';
import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:koma_cache_client/koma_cache_client.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:notifications_repository/notifications_repository.dart';

void main() {
  bootstrap(() async {
    await Firebase.initializeApp();

    // Determine host loopback IP based on runtime target
    final emulatorHost = !kIsWeb && Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';

    // Connect to Firebase Local Emulators
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080, sslEnabled: false);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    FirebaseFunctions.instance.useFunctionsEmulator(emulatorHost, 5001);

    // Ensure semantics tree is active in debug mode for Pixel 9 uiautomator testing
    if (kDebugMode) {
      SemanticsBinding.instance.ensureSemantics();
      debugPrint('🔥 Firebase Emulators connected to host: $emulatorHost');
    }

    // Initialize Pure Dart Data Clients
    final firebaseAuthClient = FirebaseAuthClient(
      firebaseAuth: FirebaseAuth.instance,
    );
    final firestoreLibraryClient = FirestoreLibraryClient(
      firestore: FirebaseFirestore.instance,
    );
    final mangadexApiClient = MangadexApiClient(
      userAgent: 'Koma/0.1.0 (https://github.com/mattcianna/koma)',
    );
    final komaCacheClient = KomaCacheClient();

    // Initialize Domain Repositories
    final authRepository = AuthRepository(authClient: firebaseAuthClient);
    final mangaRepository = MangaRepository(
      apiClient: mangadexApiClient,
      cacheClient: komaCacheClient,
    );
    final libraryRepository = LibraryRepository(
      firestoreClient: firestoreLibraryClient,
    );
    final notificationsRepository = NotificationsRepository(
      firestoreClient: firestoreLibraryClient,
    );

    return KomaApp(
      authRepository: authRepository,
      mangaRepository: mangaRepository,
      libraryRepository: libraryRepository,
      notificationsRepository: notificationsRepository,
      isDevelopmentMode: true,
    );
  });
}
```

---

## 4. Full Emulator Seed Script (`firebase/scripts/seed_emulator.ts`)

The seed script creates the test user in Firebase Auth Emulator, sets up user profile data in `users/{uid}`, creates sample manga titles spanning various reading statuses in `users/{uid}/library/{mangaId}`, registers a mock Pixel 9 FCM device token, and inserts reading history events.

### 4.1 Script Source Code

```typescript
import * as admin from 'firebase-admin';

// Configure environment to point strictly to local emulators
process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';

const TEST_UID = 'koma-test-uid-001';
const TEST_EMAIL = 'test@mangatracker.local';
const TEST_PASSWORD = 'KomaTest!2026#Dev';
const TEST_DISPLAY_NAME = 'QA Test Agent';
const PROJECT_ID = 'koma-dev';

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
  console.log(`\n[3/5] Seeding test FCM device token for Pixel 9...`);

  const deviceRef = db.doc(`users/${TEST_UID}/devices/pixel9-avd-emulator`);
  await deviceRef.set({
    token: 'fcm-fake-test-token-pixel-9-avd-emulator-hash-1234567890',
    platform: 'android',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('✅ Device registration seeded.');
}

async function seedLibraryDocuments(): Promise<void> {
  console.log(`\n[4/5] Seeding realistic MangaDex library entries...`);

  // Canonical UUIDs aligned with docs/03, docs/04, and argon-01 investigations
  const sampleLibrary = [
    {
      mangaId: 'a1c7c817-4e59-42b5-bd41-522e96416fbb', // Chainsaw Man (canonical docs/03 UUID)
      title: 'Chainsaw Man',
      coverFileName: 'd198f121-a20d-45db-b97c-9f6974fb442b.jpg',
      status: 'Reading',
      preferredLanguages: ['en', 'it'],
      readChapters: Array.from({ length: 150 }, (_, i) => (i + 1).toString()),
      readVolumes: Array.from({ length: 16 }, (_, i) => (i + 1).toString()),
      lastReadChapter: '150',
      lastReadChapterId: 'fake-ch-uuid-150',
      latestKnownChapterId: 'fake-ch-uuid-155',
      latestKnownChapterNumber: '155',
    },
    {
      mangaId: 'b0b721ff-c388-4486-aa0f-c2b0bb321512', // Sousou no Frieren (canonical argon-01 UUID)
      title: "Frieren: Beyond Journey's End",
      coverFileName: 'e86b0336-bcba-4f27-9c97-6a5bbca7d2d3.jpg',
      status: 'Reading',
      preferredLanguages: ['en', 'it'],
      readChapters: Array.from({ length: 120 }, (_, i) => (i + 1).toString()),
      readVolumes: Array.from({ length: 11 }, (_, i) => (i + 1).toString()),
      lastReadChapter: '120',
      lastReadChapterId: 'fake-ch-uuid-120',
      latestKnownChapterId: 'fake-ch-uuid-128',
      latestKnownChapterNumber: '128',
    },
    {
      mangaId: 'd90ea6cb-7bc3-4d80-8af0-28557e6c4e17', // Dungeon Meshi (canonical argon-01 UUID)
      title: 'Dungeon Meshi',
      coverFileName: 'a123f111-b44c-4123-8899-771122334455.jpg',
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
      mangaId: '801513ba-a712-498b-8f57-4155a32924f3', // Berserk
      title: 'Berserk',
      coverFileName: '44556677-8899-0011-2233-445566778899.jpg',
      status: 'Plan to Read',
      preferredLanguages: ['en'],
      readChapters: [],
      readVolumes: [],
      lastReadChapter: null,
      lastReadChapterId: null,
      latestKnownChapterId: 'fake-ch-uuid-berserk-376',
      latestKnownChapterNumber: '376',
    },
    {
      mangaId: '206f35cd-2090-4303-8486-2ec40237f0b8', // Oshi no Ko
      title: '【OSHI NO KO】',
      coverFileName: '33221100-ffeedd-ccbbaa-998877665544.jpg',
      status: 'On Hold',
      preferredLanguages: ['en'],
      readChapters: Array.from({ length: 80 }, (_, i) => (i + 1).toString()),
      readVolumes: Array.from({ length: 8 }, (_, i) => (i + 1).toString()),
      lastReadChapter: '80',
      lastReadChapterId: 'fake-ch-uuid-onk-80',
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
      mangaId: 'a1c7c817-4e59-42b5-bd41-522e96416fbb',
      mangaTitle: 'Chainsaw Man',
      coverFileName: 'd198f121-a20d-45db-b97c-9f6974fb442b.jpg',
      actionType: 'chapter_read',
      chapterNumbers: ['150'],
      volumeNumber: '16',
      chaptersCount: 1,
      timestamp: admin.firestore.Timestamp.fromMillis(now - 2 * oneHour),
    },
    {
      eventId: 'evt-csm-vol16-complete',
      uid: TEST_UID,
      mangaId: 'a1c7c817-4e59-42b5-bd41-522e96416fbb',
      mangaTitle: 'Chainsaw Man',
      coverFileName: 'd198f121-a20d-45db-b97c-9f6974fb442b.jpg',
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
      coverFileName: 'e86b0336-bcba-4f27-9c97-6a5bbca7d2d3.jpg',
      actionType: 'bulk_previous_read',
      chapterNumbers: ['110', '111', '112', '113', '114', '115', '116', '117', '118', '119', '120'],
      volumeNumber: '11',
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
  console.log(`Target: Auth (${process.env.FIREBASE_AUTH_EMULATOR_HOST}), Firestore (${process.env.FIRESTORE_EMULATOR_HOST})`);
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
```

### 4.2 Executing the Seed Script

Add the helper command to `firebase/package.json`:

```bash
# Ensure emulators are running in another terminal
firebase emulators:start --only auth,firestore,functions

# In a new terminal window, execute the seed runner
cd firebase
npx tsx scripts/seed_emulator.ts
```

---

## 5. Android Pixel 9 AVD Setup Guide

The Google Pixel 9 represents the baseline tier for Android testing in Koma.

### 5.1 Device Profile Specifications

| Property | Pixel 9 Specification |
| :--- | :--- |
| **Physical Display** | 6.3-inch Actua OLED |
| **Resolution** | 1080 x 2424 pixels |
| **Aspect Ratio** | 20.2:9 |
| **Pixel Density** | 422 dpi (`xxhdpi`) |
| **System Bar Insets** | Status Bar ~48dp, Gesture Bar ~24dp |
| **Target Architecture** | `arm64-v8a` (Apple Silicon host) or `x86_64` (Intel host) |
| **Target Android API** | Android 15 (API Level 35) or Android 14 (API Level 34) |

### 5.2 Creation via CLI

Run the following commands using the Android SDK CLI utilities (`sdkmanager`, `avdmanager`):

```bash
# 1. Download system image (ARM64 for macOS Apple Silicon)
sdkmanager "system-images;android-35;google_apis;arm64-v8a"

# 2. Create the Pixel 9 AVD
avdmanager create avd \
  --name "Pixel_9_API_35" \
  --package "system-images;android-35;google_apis;arm64-v8a" \
  --device "pixel_8" \
  --force

# 3. Fine-tune hardware profile in ~/.android/avd/Pixel_9_API_35.avd/config.ini
cat << 'EOF' >> ~/.android/avd/Pixel_9_API_35.avd/config.ini
hw.lcd.width = 1080
hw.lcd.height = 2424
hw.lcd.density = 422
hw.ramSize = 4096
vm.heapSize = 512
hw.gpu.enabled = yes
hw.gpu.mode = host
EOF

# 4. Launch the AVD with zero snapshot latency
emulator -avd Pixel_9_API_35 -no-snapshot-load -netdelay none -netspeed full &
```

---

## 6. Network Security Configuration for `10.0.2.2`

Android 9 (API 28) and higher prohibits unencrypted cleartext HTTP traffic by default. Because local Firebase emulators operate over standard HTTP on ports `8080`, `9099`, and `5001`, attempting to connect from the emulator fails with `CLEARTEXT_NOT_PERMITTED` unless explicitly permitted.

To maintain strict production security while allowing emulator connectivity, Koma introduces a **debug-only network security override**.

### 6.1 `android/app/src/debug/res/xml/network_security_config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Allow cleartext HTTP solely to host loopback addresses in development -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">10.0.2.2</domain>
        <domain includeSubdomains="false">127.0.0.1</domain>
        <domain includeSubdomains="false">localhost</domain>
    </domain-config>

    <!-- Base config enforces HTTPS for all other domains (e.g. api.mangadex.org) -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

### 6.2 Debug Manifest Registration (`android/app/src/debug/AndroidManifest.xml`)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:networkSecurityConfig="@xml/network_security_config" />
</manifest>
```

> [!IMPORTANT]
> The `network_security_config.xml` file is located exclusively under `src/debug/`. The release build manifest under `src/main/` does **not** declare this file, guaranteeing that production release APKs strictly prohibit cleartext HTTP.

---

## 7. Dev-Flavor 1-Tap QA Login Button

To bypass interactive third-party web sheets during automated testing or manual verification, the development login screen exposes a quick-login widget.

### 7.1 Component Source (`lib/features/auth/widgets/dev_quick_login_button.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koma/features/auth/bloc/auth_bloc.dart';

class DevQuickLoginButton extends StatelessWidget {
  const DevQuickLoginButton({super.key});

  static const String testEmail = 'test@mangatracker.local';
  static const String testPassword = 'KomaTest!2026#Dev';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, size: 18, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text(
                'DEV / QA SHORTCUT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            key: const Key('dev_quick_login_button'),
            icon: const Icon(Icons.login),
            label: const Text('Sign In as QA Agent ($testEmail)'),
            onPressed: () {
              context.read<AuthBloc>().add(
                    const AuthSignInWithEmailRequested(
                      email: testEmail,
                      password: testPassword,
                    ),
                  );
            },
          ),
        ],
      ),
    );
  }
}
```

---

## 8. Automated UI Inspection & Verification Tools

When verifying the app on a running Pixel 9 AVD, automated inspection can be performed via the terminal:

### 8.1 Layout Tree Dumping (`adb uiautomator`)
To inspect the current hierarchy, find accessibility labels, or confirm widget keys:

```bash
# Dump the UI hierarchy to XML on host
adb exec-out uiautomator dump /dev/tty
```

### 8.2 Screen Capture & Verification
Capture the current screen to inspect visual fidelity, ink styling, and contrast:

```bash
adb exec-out screencap -p > /tmp/koma_pixel9_screen.png
open /tmp/koma_pixel9_screen.png
```

### 8.3 Flutter Integration Test Execution
Run the end-to-end integration test suite targeting the Pixel 9 AVD:

```bash
flutter test integration_test/library_flow_test.dart \
  --flavor development \
  --dart-define=USE_FIREBASE_EMULATOR=true \
  -d Pixel_9_API_35
```
