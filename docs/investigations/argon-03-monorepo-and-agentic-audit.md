# Argon Investigation 03 — Flutter 3.47.9 Monorepo, Pixel 9 AVD & Cross-Document Audit

**Auditor:** `argon-monorepo-qa` (`gemini-4-argon-high`)  
**Target SDK:** Flutter `3.47.9` (stable) / Dart `3.13.7` (`sdk: ^3.13.0`, DevTools `2.60.0`)  
**Scope:** `docs/01-system-architecture-and-data-flow.md` through `docs/08-design-system-and-starting-graphics.md`  
**Status:** Complete — Actionable Remediations Logged

---

## 1. Executive Summary

This investigation audits the eight baseline specification documents (`docs/01`–`docs/08`) for **Koma** (`com.ciannavei.koma`) across three engineering dimensions:

1. **Flutter `3.47.9` / Dart `3.13.7` Package & Codegen Compatibility**: Empirical verification of the local Flutter `3.47.9` SDK (`packages/flutter/pubspec.yaml`, `packages/flutter_test/pubspec.yaml`, `packages/flutter_localizations/pubspec.yaml`) and live dependency constraint resolution against `pub.dev`.
2. **Android API 35/36 & Google Pixel 9 AVD Operational Traps**: Deep-dive analysis of Android 15/16 network security policies, FCM notification channels, Google Sign-In Credential Manager behavior on `google_apis` vs `google_apis_playstore` system images, and Flutter Impeller accessibility semantics dumping via `uiautomator`.
3. **Cross-Document Consistency & Guardrail Verification (`docs/01`–`docs/08`)**: Line-by-line verification of package names, Firestore schemas, cache tables, rate-limit parameters, Dart/TypeScript snippets, Mermaid syntax, and Markdown/KaTeX escaping.

| Audit Pillar | Status | Critical Findings | Major Findings | Minor / Formatting Findings |
| :--- | :--- | :---: | :---: | :---: |
| **1. Flutter 3.47.9 / Dart 3.13.7 Compatibility** | **REQUIRES PATCH** | 2 | 3 | 1 |
| **2. Android API 35/36 Pixel 9 AVD Readiness** | **REQUIRES PATCH** | 1 | 3 | 0 |
| **3. Cross-Doc Consistency (`docs/01`–`docs/08`)** | **REQUIRES PATCH** | 2 | 5 | 3 |

---

## 2. Flutter `3.47.9` / Dart `3.13.7` Compatibility Audit

### 2.1 Host SDK Baseline (Verified Empirically)

Inspection of the local Flutter `3.47.9` installation (`$FLUTTER_ROOT`) confirms the following internal SDK pins that govern version solving across all workspace packages:

* **Flutter Framework**: `3.47.9` (channel `stable`, revision `c197ca5199`)
* **Dart SDK**: `3.13.7` (`macos_arm64`)
* **Flutter Internal Package Pins**:
  * `meta: ^1.18.3`
  * `collection: ^1.19.1`
  * `characters: ^1.4.1`
  * `material_color_utilities: 0.13.0` (strictly pinned by `flutter`)
  * `vector_math: ^2.4.0`
  * `intl: ^0.20.3` (required by `flutter_localizations`)
  * `test_api: 0.7.12` and `matcher: 0.12.20` (strictly pinned by `flutter_test`)
  * `leak_tracker_flutter_testing: ^3.0.10`

### 2.2 Package Compatibility Matrix (`docs/02` vs `pub.dev` Live Constraints)

| Package | Version in `docs/02` | Latest on `pub.dev` | Dart `3.13.7` Status of `docs/02` Pin | Recommended Constraint for `sdk: ^3.13.0` |
| :--- | :--- | :--- | :--- | :--- |
| `flutter_bloc` | `^9.1.0` | `9.1.1` | Compatible | `^9.1.1` |
| `equatable` | `^2.0.7` | `3.0.0` | Compatible (`^2.0.7` works; `3.0.0` available) | `^2.0.7` |
| `go_router` | `^14.8.1` | `18.1.4` | **Upgrade Required** (paired with `go_router_builder`) | `^18.1.4` |
| `go_router_builder` | `^2.7.3` | `4.5.3` | **FAILS (`analyzer <8.0.0` rejects Dart 3.13)** | `^4.5.3` (targets `sdk: ^3.13.0`, `flutter: >=3.47.0`) |
| `build_runner` | `^2.4.15` | `2.17.1` | **FAILS (`analyzer <8.0.0` rejects Dart 3.13)** | `^2.17.1` (`analyzer: >=14.3.0 <15.0.0`) |
| `dio` | `^5.8.0+1` | `5.11.1` | Compatible (resolves to `5.11.1`) | `^5.11.1` |
| `retrofit` | `^4.4.2` | `4.10.0` | **Upgrade Required** (for `retrofit_generator` v10) | `^4.10.0` |
| `retrofit_generator` | `^9.1.9` | `10.3.3` | **FAILS (`analyzer <8.0.0` rejects Dart 3.13)** | `^10.3.3` (`analyzer: >=8.4.1 <15.0.0`) |
| `json_annotation` | `^4.9.0` | `4.12.0` | **Upgrade Required** (for `json_serializable` `6.15.2`) | `^4.12.0` |
| `json_serializable` | `^6.9.4` | `6.15.2` | **FAILS (`analyzer <8.0.0` rejects Dart 3.13)** | `^6.15.2` (`analyzer: >=10.0.0 <15.0.0`) |
| `drift` | `^2.26.0` | `2.35.4` | **Upgrade Required** (for `drift_dev` & `drift_flutter`) | `^2.35.4` |
| `drift_dev` | `^2.26.0` | `2.35.3` | **FAILS (`analyzer <8.0.0` rejects Dart 3.13)** | `^2.35.3` (`analyzer: >=13.0.0 <15.0.0`) |
| `drift_flutter` | *(Omitted in `docs/02`)* | `0.3.1` | **MISSING from root `pubspec.yaml` in `docs/02`** | `^0.3.1` (requires `drift: ^2.30.0`, `sqlite3: ^3.0.0`) |
| `sqlite3` | `^2.5.0` | `3.9.1` | **INCOMPATIBLE with `drift_flutter: ^0.3.1` (`^3.0.0`)** | `^3.9.1` (uses Dart 3.13 Native Assets hooks) |
| `firebase_core` | `^3.12.1` | `5.1.0` | Compatible (`^3.12.1` or `^5.1.0` lockstep) | `^5.1.0` (or keep BoM lockstep with v3/v5) |
| `firebase_auth` | `^5.5.1` | `7.0.1` | Compatible (must match `firebase_core` generation) | `^7.0.1` |
| `cloud_firestore` | `^5.6.5` | `7.1.0` | Compatible (must match `firebase_core` generation) | `^7.1.0` |
| `firebase_messaging` | `^15.2.4` | `17.0.1` | Compatible (must match `firebase_core` generation) | `^17.0.1` |
| `google_sign_in` | `^6.2.2` | `7.2.0` | Compatible (`^6.2.2` legacy vs `^7.2.0` Credential Mgr) | `^6.2.2` or `^7.2.0` (see Section 2.5 API diff) |
| `cached_network_image`| `^3.4.1` | `4.0.7` | Compatible (`^3.4.1` or `^4.0.7`) | `^4.0.7` |
| `very_good_analysis` | `^7.0.0` | `11.0.0` | **OUTDATED (`7.0.0` targets Dart 3.5; `11.0.0` targets 3.13)**| `^11.0.0` |
| `bloc_test` | `^10.0.0` | `10.0.0` | Compatible | `^10.0.0` |
| `mocktail` | `^1.0.4` | `1.0.5` | Compatible | `^1.0.5` |
| `intl` | `^0.20.2` | `0.20.3` | Compatible (resolves to `0.20.3` via `flutter_localizations`) | `^0.20.3` |

---

### 2.3 Trap 1 (CRITICAL BLOCKER): The `analyzer <8.0.0` vs Dart `3.13.7` Codegen Deadlock

> [!CAUTION]
> **Immediate Build Failure if Unpatched**: In `docs/02-flutter-monorepo-structure-and-packages.md` (Section 4), every `pubspec.yaml` declares `environment: sdk: ^3.13.0`, which opts the package into **Dart language version `3.13`** (including Dart 3.7+ tall-style formatting in `dart_style ^3.1.0` and Dart 3.10–3.13 AST structures). However, `docs/02` pins 2024/early-2025 `dev_dependencies`:
> * `build_runner: ^2.4.15` (constrains `analyzer: >=4.4.0 <8.0.0`)
> * `go_router_builder: ^2.7.3` (constrains `analyzer: >=6.9.0 <8.0.0`, `source_gen: <3.0.0`)
> * `retrofit_generator: ^9.1.9` (constrains `analyzer: >=6.9.0 <8.0.0`, `source_gen: <3.0.0`)
> * `json_serializable: ^6.9.4` (constrains `analyzer: >=6.5.0 <8.0.0`, `source_gen: ^2.0.0`)
> * `drift_dev: ^2.26.0` (constrains `analyzer: >=6.11.0 <8.0.0`, `source_gen: <3.0.0`)

#### Root Cause
The highest version of `analyzer` matching `<8.0.0` is `analyzer 7.4.5` (published May 2025 for Dart 3.5–3.8). When `dart run build_runner build` executes under Dart `3.13.7` on a package declaring `sdk: ^3.13.0`, `analyzer 7.4.5` aborts immediately because language version `3.13` exceeds its maximum supported language version (`3.8`).

#### Required Remediation
1. **Upgrade all codegen packages in lockstep** to the `analyzer ^13.0.0 / ^14.3.0`, `build ^5.0.0`, and `source_gen ^4.0.0` ecosystem:
   * `build_runner: ^2.17.1`
   * `go_router: ^18.1.4` + `go_router_builder: ^4.5.3`
   * `retrofit: ^4.10.0` + `retrofit_generator: ^10.3.3`
   * `json_annotation: ^4.12.0` + `json_serializable: ^6.15.2`
   * `drift: ^2.35.4` + `drift_dev: ^2.35.3` + `drift_flutter: ^0.3.1` + `sqlite3: ^3.9.1`
2. **Add Mandatory Route Mixins for `go_router_builder` v3/v4 (`docs/02` Section 5.1)**:
   Starting in `go_router_builder 3.0.0+` (and required in `4.5.3`), every `GoRouteData` subclass must include the generated `with $<ClassName>` mixin, or `build_runner` emits an analyzer error:
   ```dart
   @TypedGoRoute<AuthRouteData>(path: '/auth', name: 'auth')
   class AuthRouteData extends GoRouteData with $AuthRouteData {
     const AuthRouteData();

     @override
     Widget build(BuildContext context, GoRouterState state) => const LoginPage();
   }
   ```
   *(In `docs/02` lines 513–616, `AuthRouteData`, `LibraryRouteData`, `MangaDetailRouteData`, `DiscoverRouteData`, `HistoryRouteData`, and `SettingsRouteData` omit `with $...RouteData`.)*

---

### 2.4 Trap 2 (CRITICAL ARCHITECTURE): "Pure Dart" Packages vs Flutter Platform Plugins (`firebase_*`, `google_sign_in`, `drift_flutter`)

> [!WARNING]
> **The Transitive Flutter SDK Trap in VGV Monorepos**:
> `docs/01` (Section 3) and `docs/02` (Sections 1–4) classify all four data packages (`mangadex_api_client`, `koma_cache_client`, `firebase_auth_client`, `firestore_library_client`) and all four repository packages (`auth_repository`, `manga_repository`, `library_repository`, `notifications_repository`) as **"Pure Dart (Zero Flutter SDK)"** executed via `dart test`.
>
> However, `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`, and `google_sign_in` are **Flutter platform plugins** whose `pubspec.yaml` files explicitly require:
> ```yaml
> dependencies:
>   flutter:
>     sdk: flutter
> ```

#### What Happens During Build & Test
1. **`mangadex_api_client`, `koma_cache_client`, and `manga_repository` ARE Truly 100% Pure Dart**:
   * `koma_cache_client` depends only on `drift: ^2.35.4` and `sqlite3: ^3.9.1` (which uses Dart 3.13 Native Assets hooks and has zero Flutter dependency).
   * `KomaCacheClient` accepts a `QueryExecutor` in its constructor. In unit tests (`dart test`), it uses `NativeDatabase.memory()` from `package:drift/native.dart`. In the root app (`main_*.dart`), the app passes `driftDatabase(name: 'koma_cache')` from `package:drift_flutter/drift_flutter.dart`.
   * **Discrepancy in `docs/02`**: The root `pubspec.yaml` in `docs/02` (lines 292–328) forgot to include `drift: ^2.35.4` and `drift_flutter: ^0.3.1`, and `lib/main_*.dart` calls `KomaCacheClient()` without passing the `driftDatabase(name: 'koma_cache')` executor!
2. **`firebase_auth_client`, `firestore_library_client`, `auth_repository`, `library_repository`, and `notifications_repository` Transitively Require `flutter: sdk: flutter`**:
   * Because `firebase_auth_client` imports `package:firebase_auth/firebase_auth.dart` and `package:google_sign_in/google_sign_in.dart`, and `firestore_library_client` imports `package:cloud_firestore/cloud_firestore.dart` (`docs/03` line 378), any package that depends on them inherits `flutter: sdk: flutter` in its dependency graph.
   * Running `dart test` (the standalone Dart VM test runner) on a package whose dependency graph includes `flutter: sdk: flutter` fails immediately with:
     ```text
     Package cloud_firestore_platform_interface requires the Flutter SDK, which is not available on the dart test runner. Use "flutter test" instead.
     ```
   * **Solution**:
     1. Include `flutter: sdk: flutter` (and `flutter_test: sdk: flutter` in `dev_dependencies`) in `firebase_auth_client`, `firestore_library_client`, `auth_repository`, `library_repository`, and `notifications_repository`.
     2. Run unit tests in those 5 packages with `flutter test` (or `mcp__very-good-cli__test` omitting `dart: true` so the runner auto-detects the Flutter dependency).
     3. Enforce **architectural purity** (zero UI widget coupling in data/repository layers) by banning `package:flutter/material.dart`, `package:flutter/cupertino.dart`, and `package:flutter/widgets.dart` in `packages/*_client` and `packages/*_repository`.

---

### 2.5 Trap 3: `google_sign_in` v6 (`^6.2.2`) vs v7 (`^7.2.0`) API & Credential Manager Trap

`docs/02` pins `google_sign_in: ^6.2.2`, while the latest stable release on `pub.dev` is `google_sign_in: ^7.2.0`. Builders must not mix v6 and v7 APIs:

| Aspect | `google_sign_in: ^6.2.2` (Legacy API in `docs/02`) | `google_sign_in: ^7.2.0` (Modern Credential Manager API) |
| :--- | :--- | :--- |
| **Instantiation** | `final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);` | Singleton: `GoogleSignIn.instance` initialized via `await GoogleSignIn.instance.initialize(serverClientId: ...)` |
| **Interactive Sign-In** | `final account = await _googleSignIn.signIn();` (returns `null` on cancel) | `final account = await GoogleSignIn.instance.authenticate();` (throws `GoogleSignInException` on cancel) |
| **Firebase Credential** | `final auth = await account.authentication;` supplies both `idToken` and `accessToken` | `account.authentication` supplies **only `idToken`** (`GoogleAuthProvider.credential(idToken: auth.idToken)` is valid for Firebase Auth) |
| **Android Backend** | Legacy `play-services-auth` intent dialog | Android 14+ `androidx.credentials` (**Credential Manager**) bottom sheet |

> [!TIP]
> **Recommendation for Phase 2 (`flash-data-firebase`)**: If pinning `google_sign_in: ^6.2.2` as written in `docs/02`, constructor-inject `GoogleSignIn` into `FirebaseAuthClient` for `mocktail` unit testing. If upgrading to `google_sign_in: ^7.2.0`, wrap `GoogleSignIn.instance` behind a thin injectable `GoogleSignInGateway` interface because `GoogleSignIn.instance` is a singleton with a private constructor.

---

### 2.6 Trap 4: `drift_dev` + `build_runner` in a Pub Workspace / Melos Monorepo

On Dart `3.13.7` / Flutter `3.47.9`, multi-package repositories use **Dart Pub Workspaces** (`workspace:` in the root `pubspec.yaml` and `resolution: workspace` in each sub-package `pubspec.yaml`), which shares a single root `pubspec.lock` and `.dart_tool/package_config.json`.

To prevent `drift_dev`, `retrofit_generator`, and `go_router_builder` from colliding or scanning the entire workspace unnecessarily:
1. **Scope `build_runner` only to packages with builders**:
   * `packages/mangadex_api_client` (`retrofit_generator` + `json_serializable`)
   * `packages/koma_cache_client` (`drift_dev` + `json_serializable`)
   * Root `koma` (`go_router_builder`)
2. **Add `packages/koma_cache_client/build.yaml`** to silence Drift analyzer warnings and optimize SQL generation:
   ```yaml
   targets:
     $default:
       builders:
         drift_dev:
           options:
             store_date_time_values_as_text: false
             named_parameters: true
             scoped_dart_components: true
   ```
3. **Exclude generated files in `analysis_options.yaml`**:
   `very_good_analysis: ^11.0.0` enforces `public_member_api_docs`, `lines_longer_than_80_chars`, and `cascade_invocations`. Generated `*.g.dart` and `*.drift.dart` files will fail `dart analyze` unless every package's `analysis_options.yaml` includes:
   ```yaml
   include: package:very_good_analysis/analysis_options.yaml

   analyzer:
     exclude:
       - "**/*.g.dart"
       - "**/*.freezed.dart"
       - "**/*.drift.dart"
       - "lib/l10n/gen/**"
   ```

---

## 3. Android API 35/36 & Pixel 9 AVD Traps

### 3.1 Trap 1: `10.0.2.2` Cleartext HTTP, Flavor Manifest Merging & Firestore Emulator Ordering

1. **Flavor Source-Set Manifest Trap (`src/debug/` vs `src/development/`)**:
   `docs/06` (Section 6) places `network_security_config.xml` inside `android/app/src/debug/res/xml/network_security_config.xml`. While this works for `flutter run --debug --flavor development`, running an integration test or performance check in `--profile --flavor development` ignores `src/debug/`!
   * **Fix**: Place `network_security_config.xml` and the `<application android:networkSecurityConfig="@xml/network_security_config" />` overlay in `android/app/src/development/` (the flavor source set) in addition to `src/debug/`, while leaving `src/staging/` and `src/production/` untouched so production APKs strictly block cleartext HTTP.
2. **Firestore Emulator Initialization Order**:
   `FirebaseFirestore.instance.useFirestoreEmulator(host, 8080)` **must** be invoked immediately after `Firebase.initializeApp()` and **before** any stream listener or document access. Calling `useFirestoreEmulator` after `FirebaseFirestore.instance` has already opened a gRPC channel throws a `StateError`.

### 3.2 Trap 2 (CRITICAL RUNTIME): Android 13–16 (API 33–36) `POST_NOTIFICATIONS` & Missing FCM Channel Creation

In `docs/05` (line 459), the Cloud Function dispatches Android FCM payloads targeting:
```typescript
android: {
  priority: 'high',
  notification: {
    channelId: 'koma_manga_releases',
    icon: 'ic_notification',
    color: '#E11D48',
  },
}
```
On a **Pixel 9 running Android 15/16 (API 35/36)**, three failure modes will cause push notifications to be silently dropped if not configured in the Flutter client (`packages/notifications_repository` and `android/app/src/main/AndroidManifest.xml`):

1. **Missing `POST_NOTIFICATIONS` Manifest Declaration & Runtime Prompt**:
   Android 13+ (API 33+) blocks all notifications until the user grants `android.permission.POST_NOTIFICATIONS`. The manifest must declare:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   ```
   And `NotificationsRepository.initialize()` must call:
   ```dart
   final settings = await FirebaseMessaging.instance.requestPermission(
     alert: true,
     badge: true,
     sound: true,
   );
   ```
2. **Missing Client-Side `NotificationChannel` Creation (`koma_manga_releases`)**:
   Firebase Cloud Messaging **does not automatically create custom notification channels** on Android 8.0+ (API 26+). If the Cloud Function sends `channelId: 'koma_manga_releases'` and the Flutter app has not registered that exact channel ID with `NotificationManager` at `IMPORTANCE_HIGH`, Android drops the notification with logcat warning:
   `W/FirebaseMessaging: Notification Channel set in AndroidManifest.xml has not been created by the app.`
   * **Fix**: Register the channel on Android startup (via `flutter_local_notifications` or `MainActivity.kt` in `onCreate`) with ID `'koma_manga_releases'`, name `'Manga Chapter Releases'`, and `NotificationManager.IMPORTANCE_HIGH`, and declare the default channel metadata in `AndroidManifest.xml`:
     ```xml
     <meta-data
         android:name="com.google.firebase.messaging.default_notification_channel_id"
         android:value="koma_manga_releases" />
     ```
3. **Missing Small Notification Icon (`ic_notification`)**:
   `docs/05` line 460 specifies `icon: 'ic_notification'`. If `android/app/src/main/res/drawable/ic_notification.xml` (a monochrome white vector drawable with transparent background) does not exist, Android 15/16 either falls back to a blank square or drops the notification.

### 3.3 Trap 3: Google Sign-In SHA-1 & Credential Manager on Pixel 9 AVD (`google_apis` vs `google_apis_playstore`)

`docs/06` (Section 5.2, line 444) provisions the Pixel 9 AVD using:
`system-images;android-35;google_apis;arm64-v8a`

* On a fresh `google_apis` (or `google_apis_playstore`) emulator without an interactive Google Account signed into the OS Settings, invoking interactive Google Sign-In fails with:
  * `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10:)` (`DEVELOPER_ERROR`) if the host machine's `~/.android/debug.keystore` SHA-1 fingerprint is not registered in the live Firebase project.
  * `NoCredentialException` (in `google_sign_in` v7 Credential Manager) when no Google account is provisioned on the AVD.
* **Why Koma's Dual-Path Auth Design Solves This**:
  1. **Path 1 (`DevQuickLoginButton` -> `signInWithEmailAndPassword` on Auth Emulator `:9099`)**: Authenticates `test@mangatracker.local` deterministically with zero dependency on Google Play Services, SHA-1 certificates, or interactive OS sheets.
  2. **Path 2 (Simulated Google Sign-In on Auth Emulator)**: The Firebase Auth Emulator (`10.0.2.2:9099`) accepts unsigned mock OIDC tokens via `FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(idToken: '{"sub": "koma-google-test-uid", "email": "test@mangatracker.local", "email_verified": true}'))`, allowing automated E2E tests to verify the Google Sign-In code path in `FirebaseAuthClient` without needing a live Google account on the Pixel 9 AVD!

### 3.4 Trap 4: Pixel 9 AVD Inspection Quirks (`android layout` / `uiautomator dump` vs Flutter Impeller Semantics)

> [!IMPORTANT]
> **Flutter Semantics Tree Laziness on Android AVDs**:
> `docs/06` (Section 8.1) and `docs/07` (Section 8.3) instruct agents to inspect the live Pixel 9 UI hierarchy via `adb exec-out uiautomator dump /dev/tty` (or the `android layout` CLI).
>
> By default, Flutter's Impeller engine **does not build or expose the Android `AccessibilityNodeInfo` bridge** unless an active accessibility service (such as TalkBack) is enabled on the device. Consequently, the very first `uiautomator dump` on a cold-booted Flutter app frequently returns a single opaque `<node class="android.view.View" />` with zero child nodes!

#### Mandatory Fix for `lib/main_development.dart`
In `lib/main_development.dart` (or `lib/bootstrap.dart` when `kDebugMode` is true), explicitly retain a `SemanticsHandle` immediately after `WidgetsFlutterBinding.ensureInitialized()`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

SemanticsHandle? _debugSemanticsHandle;

void enableDebugSemanticsForAutomation() {
  if (kDebugMode) {
    // Forces Flutter to keep the Android AccessibilityNodeInfo tree warm
    // so `adb exec-out uiautomator dump` and `android layout` work instantly.
    _debugSemanticsHandle = SemanticsBinding.instance.ensureSemantics();
  }
}
```

Additionally, `uiautomator dump` waits for the Android UI thread to remain idle for 500ms (aborting after 10 seconds with `ERROR: could not get idle state` if an infinite animation is running). All loading spinners (`CircularProgressIndicator`) and shimmer placeholders must either complete deterministically against the local emulator or respect `MediaQuery.disableAnimationsOf(context)`.

---

## 4. Cross-Document Consistency Audit (`docs/01`–`docs/08`)

### 4.1 Canonical Shared Contract Verification Table

| Contract Item | Canonical Value | Verified Across `docs/01`–`docs/08`? | Notes |
| :--- | :--- | :---: | :--- |
| **Root Package & Bundle ID** | `koma` / `com.ciannavei.koma` | **YES** | Consistent across all 8 documents. |
| **MangaDex `User-Agent`** | `Koma/0.1.0 (https://github.com/mattcianna/koma)` | **PARTIAL** | Missing from `CachedNetworkImage` in `docs/08` line 756 (see D-07). |
| **4 Data Packages** | `mangadex_api_client`, `koma_cache_client`, `firebase_auth_client`, `firestore_library_client` | **YES** | Names match in `docs/01`, `02`, `03`, `04`, `07`. |
| **4 Repository Packages** | `auth_repository`, `manga_repository`, `library_repository`, `notifications_repository` | **YES** | Names match in `docs/01`, `02`, `03`, `04`, `07`. |
| **UI Package** | `packages/koma_ui` | **PARTIAL** | Widget filenames in `docs/02` lack `koma_` prefix used in `docs/07` & `08` (see D-05). |
| **ReadingStatus Values** | `'Reading'`, `'Plan to Read'`, `'Completed'`, `'On Hold'`, `'Dropped'` | **YES** | Matches Dart `enum ReadingStatus` and `firestore.rules`. |
| **Firestore Collections** | `users/{uid}`, `devices/{deviceId}`, `library/{mangaId}`, `reading_history/{eventId}` | **YES** | All field names and immutability rules match across `docs/01`, `03`, `05`, `06`. |
| **Emulator Ports** | Auth `9099`, Firestore `8080`, Functions `5001`, UI `4000` | **YES** | Consistent across `docs/01`, `02`, `05`, `06`. |
| **QA Test Account** | `test@mangatracker.local` / `KomaTest!2026#Dev` | **YES** | Consistent across `docs/01`, `02`, `06`, `07`. |
| **7 Starting Asset Links** | `./assets/branding/*`, `./assets/illustrations/*`, `./assets/mockups/*` | **YES** | All 7 PNGs exist on disk under `docs/assets/` and resolve cleanly in `docs/08`. |

---

### 4.2 Exact Discrepancy Register (`docs/01`–`docs/08`)

Below is the complete register of cross-document discrepancies, code bugs, and formatting violations identified across `docs/01`–`docs/08`:

| ID | Severity | Affected File(s) & Lines | Discrepancy Description | Exact Remediation |
| :--- | :--- | :--- | :--- | :--- |
| **D-01** | **CRITICAL** | `docs/02` (lines 335–336, 365–367, 395–396, 513–616) | **Codegen `analyzer <8.0.0` incompatibility with `sdk: ^3.13.0` + missing `GoRouteData` mixins**: `build_runner: ^2.4.15`, `go_router_builder: ^2.7.3`, `retrofit_generator: ^9.1.9`, `json_serializable: ^6.9.4`, `drift_dev: ^2.26.0`, and `very_good_analysis: ^7.0.0` target Dart 3.5–3.8 and fail on Dart `3.13.7`. Route data classes in Section 5.1 also omit `with $...RouteData` mixins. Additionally, root `pubspec.yaml` omits `drift_flutter` and `cloud_functions`. | Bump `build_runner: ^2.17.1`, `go_router: ^18.1.4`, `go_router_builder: ^4.5.3`, `retrofit: ^4.10.0`, `retrofit_generator: ^10.3.3`, `json_annotation: ^4.12.0`, `json_serializable: ^6.15.2`, `drift: ^2.35.4`, `drift_dev: ^2.35.3`, `drift_flutter: ^0.3.1`, `sqlite3: ^3.9.1`, `very_good_analysis: ^11.0.0`, and add `with $...RouteData` mixins to Section 5.1. |
| **D-02** | **CRITICAL** | `docs/04` (lines 450, 462) | **Bug in `MangaDexRateLimitInterceptor.onError` retry logic**: (1) Line 450 computes `parsed - DateTime.now().millisecondsSinceEpoch` when `x-ratelimit-retry-after` is a Unix epoch in **seconds** (`> 1000`), subtracting milliseconds from seconds and yielding a large negative number clamped to `1000ms` (must multiply `parsed * 1000` before subtracting `millisecondsSinceEpoch`). (2) Line 462 instantiates a bare `final dio = Dio();` on retry, losing base options and bypassing interceptors. | Multiply 10-digit epoch seconds by `1000` (`parsed * 1000 - DateTime.now().millisecondsSinceEpoch`) and retry using the injected `Dio` instance rather than `Dio()`. |
| **D-03** | **MAJOR** | `docs/01` (lines 248–276, 413) vs `docs/04` (lines 483–514) & `docs/07` (line 128) | **Conflicting Drift SQLite Schema & Aggregate Cache TTL**: `docs/01` Section 4.2 defines normalized SQL tables `cached_manga` and `cached_aggregate_chapters` (without a language key column) and states a `> 24 hours` TTL for `/aggregate` (line 413). `docs/04` Section 6.2 defines `MangaMetadataCache` (24h TTL) and `MangaAggregateCache` keyed by `(mangaId, languagesKey)` with a **30-minute TTL**. | Align `docs/01` Section 4.2 and line 413 with `docs/04`'s language-keyed `MangaAggregateCache` (30-minute TTL for `/aggregate`, 24-hour TTL for metadata). |
| **D-04** | **MAJOR** | `docs/01` (lines 60, 125, 170, 475, 482) vs `docs/05` (lines 3, 29, 96, 193, 778) | **Cloud Functions Node.js Version & Cron Schedule Mismatch**: `docs/01` states `Node.js 20` and `00:00 UTC` schedule, whereas `docs/05` specifies `Node.js 22` (`"node": "22"`) and `06:00 UTC` (`'0 6 * * *'`). | Update `docs/01` to specify `Node.js 22` and `06:00 UTC` (matching `docs/05`). |
| **D-05** | **MAJOR** | `docs/02` (lines 110, 135–143) vs `docs/07` (lines 201–224) & `docs/08` (Sections 2–4) | **`packages/koma_ui` File Tree & Widget Naming Mismatch**: `docs/02` lists widget files without the `koma_` prefix (`manga_card.dart`, `status_chip.dart`, etc.), puts `bulk_read_sheet.dart` inside `lib/features/reader_progress/view/widgets/`, and omits `koma_empty_state.dart`. `docs/07` and `docs/08` place all 7 widgets under `packages/koma_ui/lib/src/widgets/koma_*.dart` and all theme files under `packages/koma_ui/lib/src/theme/koma_*.dart`. | Update the directory tree in `docs/02` (lines 109–144) to match `docs/07` and `docs/08`'s canonical `koma_*.dart` filenames in `packages/koma_ui`. |
| **D-06** | **MAJOR** | `docs/06` (lines 112–150, 541) vs `docs/02` (lines 848–896) & `docs/01` (line 313) | **`lib/main_development.dart` Signature & `DevQuickLoginButton` Typo in `docs/06`**: (1) `docs/06` line 541 contains a Dart compile error: `crossAxisAlignment: CrossAxisReset.stretch` (should be `CrossAxisAlignment.stretch`). (2) `docs/06` lines 140–150 call `runApp(const KomaApp())` with no repositories injected, contradicting `docs/02`'s DI bootstrap `KomaApp(authRepository: ..., ...)`. | Fix `CrossAxisReset.stretch` -> `CrossAxisAlignment.stretch` in `docs/06` line 541 and align `docs/06` Section 3.2 with `docs/02` Section 7.2's `bootstrap(...)` DI pattern. |
| **D-07** | **MAJOR** | `docs/08` (lines 756, 896, 1153, 1188) | **Missing `User-Agent` Header in `KomaMangaCard` & Deprecated `.withOpacity()` Calls**: (1) `KomaMangaCard` in `docs/08` line 756 calls `CachedNetworkImage(imageUrl: imageUrl, ...)` without passing `httpHeaders: const {'User-Agent': 'Koma/0.1.0 (https://github.com/mattcianna/koma)'}`. (2) Lines 896, 1153, and 1188 call `.withOpacity(...)`, which is deprecated in Flutter `3.27+` / `3.47.9` and flagged by `very_good_analysis` (use `.withValues(alpha: ...)`). | Add `httpHeaders` to `KomaMangaCard`'s `CachedNetworkImage` and replace `.withOpacity(x)` with `.withValues(alpha: x)` in `docs/08`. |
| **D-08** | **MAJOR** | `docs/01` (lines 12, 107, 341, 362) vs `docs/04` (lines 60, 381–393) & `docs/05` (lines 158, 184–185) | **Rate-Limiter Parameter Discrepancy**: `docs/01` describes the client token bucket as `Capacity=5, Refill=1 token / 200ms` (5 req/s), whereas `docs/04` and `docs/07` cap the client bucket at `4 req/s` (`250ms` interval) for safety headroom, and `docs/05` uses `minTime: 260ms` in prose (line 158) vs `270ms` in `src/config.ts` (line 185). | Clarify in `docs/01` that while MangaDex's upstream ceiling is 5 req/s, Koma's client token bucket is conservatively capped at 4 req/s (250ms refill). |
| **D-09** | **MINOR** | `docs/03` (line 501) vs `docs/05` (line 529, 909) & `docs/07` (line 188) | **WriteBatch Chunk Size Constant**: `docs/03` chunks `markPreviousChaptersRead` at `450` items (`const maxPerChunk = 450`), whereas `docs/05` and `docs/07` reference `490` operations per batch. Also, `docs/03` line 521 passes the unchunked `previousChapterNumbersToMark` list to `FieldValue.arrayUnion`, which is fine up to 5,000 chapters per `firestore.rules` line 783, while `reading_history` chunks must stay `<= 500` items (`firestore.rules` line 809). | Standardize chunk size documentation (`450` for history array chunks, `490` for document write batches) across `docs/03` and `docs/07`. |
| **D-10** | **MINOR** | `docs/01`, `docs/02`, `docs/03`, `docs/05`, `docs/06`, `docs/07` | **Mermaid & Markdown Formatting Guardrails**: (1) Unescaped LaTeX `$` math spans appear outside code blocks in `docs/05` (lines 14, 158), `docs/06` (lines 15, 431, 434), and `docs/07` (lines 119, 187, 188, 226, 321, 322). (2) HTML `<br/>` tags appear inside Mermaid labels/notes in `docs/01`, `docs/02`, and `docs/05`, and unquoted cylinder labels `DriftDB[(...)]` appear in `docs/01` lines 113–114. | Replace `$math$` with plain Unicode (`<= 4 req/s`, `1080 x 2424`, `>= 90%`, `>= 48 x 48dp`), remove `<br/>` from Mermaid labels, and quote cylinder labels `DriftDB[("...")]`. |
