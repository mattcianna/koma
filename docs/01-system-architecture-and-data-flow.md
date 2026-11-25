# Koma — System Architecture and Data Flow

This document specifies the end-to-end system architecture, service topology, data models, caching tiers, and interaction flows for **Koma** (`com.ciannavei.koma`), an offline-first manga reading tracker built with Flutter, Firebase, Drift SQLite, and the MangaDex API v5.

---

## 1. Architectural Principles and System Tenets

Koma is intentionally architected as a **pure tracker** rather than an image reader. It delivers high-fidelity reading tracking, metadata discovery, chapter/volume progress synchronization, and notification triggers without hosting or scraping manga image scans. The architecture conforms to five non-negotiable tenets:

1. **Strict Upstream Etiquette & Zero Scraping**:
   All communication with MangaDex (`api.mangadex.org` and `uploads.mangadex.org`) is strictly rate-limited: while MangaDex enforces an upstream ceiling of 5 requests per second per IP, Koma's client-side token bucket conservatively caps outgoing traffic at 4 requests per second (250ms interval) to provide a safety margin against 429 rate limit triggers. Requests identify themselves with the immutable User-Agent:
   ```http
   User-Agent: Koma/0.1.0 (https://github.com/mattcianna/koma)
   ```
   No web-scraping or non-API endpoints are used.

2. **Unidirectional Layered Monorepo Architecture**:
   The Flutter client strictly follows the Very Good Ventures (VGV) 4-Layer monorepo specification:
   `Presentation -> Business Logic (Bloc/Cubit) -> Repository -> Data`
   - Data and Repository layers reside in standalone packages in `packages/`.
   - Data packages contain zero Flutter dependencies and zero domain business rules.
   - Repositories never import other repositories and expose pure domain models extending `Equatable`.
   - The Presentation layer interacts solely through BLoC events and states.

3. **Multi-Tier Offline-First Reliability**:
   The app provides an instant, offline-available user experience through two complementary storage tiers:
   - **Cloud Firestore Native Offline Persistence**: Provides local LRU caching and an offline write mutation queue for user libraries, reading status, and history.
   - **Local Drift (SQLite) Cache**: Stores MangaDex catalog metadata, search indices, and structural chapter/volume hierarchies (`/aggregate` responses) to minimize upstream bandwidth and eliminate redundant network hops.

4. **Atomic Progress & Event Immutability**:
   Reading progress mutations (marking individual chapters, entire volumes, or bulk "Mark Previous as Read") are executed as atomic operations (`WriteBatch`) across the user's library document and an immutable, append-only reading history subcollection (`reading_history`).

5. **Cloud-Orchestrated Notifications**:
   A daily serverless Cloud Function v2 (`onSchedule`, Node.js 22, executing at 06:00 UTC) scans library subscriptions, queries MangaDex feeds for new chapter drops, updates user catalog pointers, and broadcasts localized push notifications through Firebase Cloud Messaging (FCM).

---

## 2. High-Level C4 Context Architecture

The C4 Context diagram illustrates how Koma integrates within its external environment, interacting with the user, MangaDex infrastructure, and Google Cloud/Firebase services.

```mermaid
flowchart TD
    User["Manga Reader / User (Mobile Device)"]

    subgraph ClientDevice["Client Boundary (iOS / Android)"]
        KomaApp["Koma Mobile App (Flutter Engine / Dart 3.13.7) com.ciannavei.koma"]
    end

    subgraph MangaDexPlatform["MangaDex Upstream Services"]
        MD_API["MangaDex REST API v5 (api.mangadex.org)"]
        MD_CDN["MangaDex Cover CDN (uploads.mangadex.org)"]
    end

    subgraph FirebaseGCP["Firebase & Google Cloud Platform"]
        FB_Auth["Firebase Authentication (OAuth & Email/Password)"]
        Cloud_Firestore["Cloud Firestore (User Collections & Persistence)"]
        Cloud_Functions["Cloud Functions v2 (Daily Node.js 22 Engine)"]
        Cloud_Scheduler["Cloud Scheduler (Daily 06:00 UTC Cron)"]
        FCM["Firebase Cloud Messaging (Push Gateway)"]
    end

    User -->|"Interacts with UI, updates progress, tracks manga"| KomaApp
    KomaApp -->|"Queries metadata, aggregate trees (Client Bucket: 4 req/s)"| MD_API
    KomaApp -->|"Streams cover art thumbnails"| MD_CDN
    KomaApp -->|"Authenticates via Google & Email tokens"| FB_Auth
    KomaApp -->|"Syncs library status & reading history"| Cloud_Firestore
    KomaApp -->|"Registers device tokens for notifications"| FCM
    Cloud_Scheduler -->|"Triggers scheduled chapter check"| Cloud_Functions
    Cloud_Functions -->|"Queries followed manga releases"| MD_API
    Cloud_Functions -->|"Reads user tracking records"| Cloud_Firestore
    Cloud_Functions -->|"Dispatches new chapter push alerts"| FCM
    FCM -->|"Delivers push notification to device"| KomaApp
```

---

## 3. C4 Container Architecture

The C4 Container diagram details the internal software systems, client packages, storage tiers, and external protocol boundaries.

```mermaid
flowchart TD
    subgraph MobileAppContainer["Koma Client Application (Flutter 3.47.9 / Dart 3.13.7)"]
        subgraph PresentationLayer["Presentation Layer (lib/features/)"]
            UI["Flutter Widgets & Screen Views (packages/koma_ui)"]
        end

        subgraph BLoCLayer["Business Logic Layer (lib/features/*/bloc/)"]
            AuthBloc["AuthBloc"]
            SearchBloc["SearchBloc"]
            LibraryBloc["LibraryBloc"]
            ReaderProgressBloc["ReaderProgressBloc"]
            HistoryBloc["HistoryBloc"]
        end

        subgraph RepositoryLayer["Repository Layer (packages/*_repository)"]
            AuthRepo["AuthRepository"]
            MangaRepo["MangaRepository"]
            LibraryRepo["LibraryRepository"]
            NotifRepo["NotificationsRepository"]
        end

        subgraph DataLayer["Data Layer (packages/*_client)"]
            FirebaseAuthClient["FirebaseAuthClient"]
            MDClient["MangadexApiClient (Dio + Token Bucket: 4 req/s)"]
            DriftClient["KomaCacheClient (Drift SQLite Engine)"]
            FirestoreClient["FirestoreLibraryClient (Cloud Firestore SDK)"]
        end

        subgraph LocalStorageTiers["Local Persistence"]
            DriftDB[("Local Drift SQLite Database (MangaDex Catalog & Aggregate Cache)")]
            FirestoreOfflineCache[("Firestore Local Cache (IndexedDB / SQLite Engine)")]
        end
    end

    subgraph ExternalBackend["Backend & Upstream Services"]
        Ext_MD_API["api.mangadex.org"]
        Ext_MD_CDN["uploads.mangadex.org"]
        Ext_FB_Auth["Firebase Auth Service"]
        Ext_Firestore["Cloud Firestore Database"]
        Ext_FCM["FCM Push Notification Service"]
        Ext_Scheduler["Cloud Scheduler (06:00 UTC)"]
        Ext_Function["Cloud Functions v2 (Node.js 22)"]
    end

    UI -->|"Dispatches User Events"| BLoCLayer
    BLoCLayer -->|"Emits Equatable State"| UI
    AuthBloc -->|"Manages credentials"| AuthRepo
    SearchBloc -->|"Searches titles"| MangaRepo
    LibraryBloc -->|"Reads/writes library"| LibraryRepo
    ReaderProgressBloc -->|"Updates progress"| LibraryRepo
    HistoryBloc -->|"Loads timeline"| LibraryRepo

    AuthRepo -->|"Delegates auth calls"| FirebaseAuthClient
    MangaRepo -->|"Fetches remote metadata"| MDClient
    MangaRepo -->|"Reads/writes local aggregate"| DriftClient
    LibraryRepo -->|"Syncs library & history"| FirestoreClient
    NotifRepo -->|"Registers APNS/FCM tokens"| FirestoreClient

    FirebaseAuthClient -->|"HTTPS / REST"| Ext_FB_Auth
    MDClient -->|"HTTPS / REST (User-Agent: Koma/0.1.0)"| Ext_MD_API
    UI -->|"HTTP Cache Stream"| Ext_MD_CDN
    FirestoreClient -->|"gRPC / Firestore SDK"| Ext_Firestore
    FirestoreClient <-->|"Reads/Writes"| FirestoreOfflineCache
    DriftClient <-->|"SQL Queries / Migrations"| DriftDB

    Ext_Scheduler -->|"HTTP POST Trigger"| Ext_Function
    Ext_Function -->|"Reads active tracking"| Ext_Firestore
    Ext_Function -->|"Polls latest chapters"| Ext_MD_API
    Ext_Function -->|"Sends push notifications"| Ext_FCM
    Ext_FCM -->|"APNS / FCM Delivery"| MobileAppContainer
```

### Container Responsibility Matrix

| Container / Package | Runtime | Responsibility | Storage / Protocol |
|---|---|---|---|
| `koma` (Root App) | Flutter 3.47.9 / Dart 3.13.7 | App bootstrap, DI container, `go_router` navigation, feature orchestration | In-memory Flutter state |
| `packages/koma_ui` | Flutter SDK | Reusable widgets, Material 3 theming, typography, color system | Visual rendering |
| `packages/mangadex_api_client` | Pure Dart (No Flutter) | Dio client, Retrofit API endpoints, Token Bucket rate-limiter, User-Agent interceptor | HTTPS REST with JSON serialization |
| `packages/koma_cache_client` | Pure Dart (No Flutter) | Drift SQLite table definitions, queries, migrations, aggregate serialization | SQLite file (`koma_cache.db`) |
| `packages/firebase_auth_client` | Pure Dart (No Flutter) | Wraps Google Sign-In and Firebase Auth SDK, auth status streams | OAuth2 / Secure Token Storage |
| `packages/firestore_library_client` | Pure Dart (No Flutter) | Firestore SDK bridge, atomic `WriteBatch`, document serialization | Native gRPC + local offline queue |
| `packages/auth_repository` | Pure Dart (No Flutter) | Domain models (`User`), auth state mapping, exception sanitization | Stream-based domain state |
| `packages/manga_repository` | Pure Dart (No Flutter) | Manga search, detail retrieval, SWR caching combining Drift and MangaDex | Domain models (`Manga`, `ChapterAggregate`) |
| `packages/library_repository` | Pure Dart (No Flutter) | Library status management, progress updates, reading history streams | Domain models (`LibraryEntry`, `HistoryEvent`) |
| `packages/notifications_repository` | Pure Dart (No Flutter) | Device FCM token syncing, push permission orchestration | Native APNS/FCM channels |
| `Cloud Functions v2` | Node.js 22 / TypeScript | Daily scheduled chapter check (06:00 UTC), delta calculation, FCM multicast | Cloud Scheduler HTTP trigger |

---

## 4. Canonical Data Models and Storage Specifications

### 4.1 Cloud Firestore Document Schemas

All Firestore paths adhere to an immutable user scoping hierarchy: `users/{uid}/...`. Security rules strictly enforce `request.auth.uid == uid`.

```mermaid
flowchart TD
    UsersCol["users (Collection)"]
    UserDoc["users/{uid} (Document): Profile, preferences & settings"]
    DevicesSubCol["devices (Subcollection)"]
    DeviceDoc["users/{uid}/devices/{deviceId}: FCM tokens & platform metadata"]
    LibrarySubCol["library (Subcollection)"]
    LibraryDoc["users/{uid}/library/{mangaId}: Status, read chapters & volumes"]
    HistorySubCol["reading_history (Subcollection)"]
    HistoryDoc["users/{uid}/reading_history/{eventId}: Immutable timeline audit log"]

    UsersCol --> UserDoc
    UserDoc --> DevicesSubCol --> DeviceDoc
    UserDoc --> LibrarySubCol --> LibraryDoc
    UserDoc --> HistorySubCol --> HistoryDoc
```

#### 1. User Profile Document: `users/{uid}`
- `uid`: `String` *(Immutable)* — Firebase Auth UID.
- `email`: `String` — User's email address.
- `displayName`: `String?` — User's display name or nickname.
- `photoUrl`: `String?` — Profile avatar URI.
- `uiLocale`: `String` — Selected UI language (`'en'` or `'it'`).
- `preferredLanguages`: `List<String>` — Content languages for chapter releases (e.g., `['en', 'it']`).
- `contentRatings`: `List<String>` — Allowed MangaDex content ratings (e.g., `['safe', 'suggestive']`).
- `notificationsEnabled`: `bool` — Global notification master toggle.
- `createdAt`: `Timestamp` *(Immutable)* — Server timestamp on creation.
- `updatedAt`: `Timestamp` — Server timestamp on last mutation.

#### 2. Device Registration Document: `users/{uid}/devices/{deviceId}`
- `token`: `String` — Firebase Cloud Messaging (FCM) registration token.
- `platform`: `String` — Client platform identifier (`'android'` or `'ios'`).
- `updatedAt`: `Timestamp` — Last token refresh timestamp.

#### 3. Library Entry Document: `users/{uid}/library/{mangaId}`
- `mangaId`: `String` *(Immutable)* — MangaDex UUID for the series.
- `uid`: `String` *(Immutable)* — Owner user UID.
- `title`: `String` — Primary localized or romanized title.
- `coverFileName`: `String` — File name of the cover image for CDN URL generation.
- `status`: `String` — Serialized reading status (`'Reading'`, `'Plan to Read'`, `'Completed'`, `'On Hold'`, `'Dropped'`).
- `preferredLanguages`: `List<String>` — Specific languages tracked for this manga.
- `readChapters`: `List<String>` — Array of completed chapter identifiers/numbers (e.g., `['1', '2', '2.5', '3']`).
- `readVolumes`: `List<String>` — Array of completed volume identifiers/numbers (e.g., `['1', '2']`).
- `lastReadChapter`: `String?` — Human-readable number of the most recently read chapter (e.g., `'104'`).
- `lastReadChapterId`: `String?` — MangaDex UUID of the most recently read chapter.
- `latestKnownChapterId`: `String?` — MangaDex UUID of the newest available release discovered by background polling.
- `latestKnownChapterNumber`: `String?` — Chapter number string of newest release.
- `addedAt`: `Timestamp` *(Immutable)* — Initial library entry creation timestamp.
- `updatedAt`: `Timestamp` — Last mutation timestamp.

#### 4. Reading History Document: `users/{uid}/reading_history/{eventId}`
- `eventId`: `String` *(Immutable)* — Unique event UUID.
- `uid`: `String` *(Immutable)* — Owner user UID.
- `mangaId`: `String` *(Immutable)* — MangaDex UUID of the manga series.
- `mangaTitle`: `String` *(Immutable)* — Snapshot of manga title at event creation.
- `coverFileName`: `String` *(Immutable)* — Snapshot of cover image filename.
- `actionType`: `String` *(Immutable)* — Enum token: `'chapter_read'`, `'volume_read'`, or `'bulk_previous_read'`.
- `chapterNumbers`: `List<String>` *(Immutable)* — List of chapter numbers affected by this action.
- `volumeNumber`: `String?` *(Immutable)* — Volume number affected, if applicable.
- `chaptersCount`: `int` *(Immutable)* — Total count of chapters marked in this transaction.
- `timestamp`: `Timestamp` *(Immutable)* — Server timestamp recording the event.

---

### 4.2 Local Drift (SQLite) Schema

Drift stores metadata locally to enable sub-millisecond search query filtering and zero-latency loading of chapter aggregation trees without hitting MangaDex endpoints repeatedly. In accordance with `docs/04` Section 6.2, local storage is partitioned into two specialized cache tables with distinct time-to-live (TTL) policies:

1. **`MangaMetadataCache` (24-Hour TTL)**: Caches search and catalog metadata payloads for 24 hours.
2. **`MangaAggregateCache` (30-Minute TTL)**: Caches structural chapter/volume hierarchies from `/manga/{id}/aggregate` partitioned by composite primary key `(manga_id, languages_key)` with a 30-minute TTL, ensuring new chapter releases are surfaced promptly while preventing redundant upstream queries.

```sql
-- Cached MangaDex Catalog Entry (MangaMetadataCache - 24-Hour TTL)
CREATE TABLE manga_metadata_cache (
    manga_id TEXT NOT NULL PRIMARY KEY,
    json_payload TEXT NOT NULL,
    cached_at INTEGER NOT NULL, -- Epoch milliseconds
    expires_at INTEGER NOT NULL -- Epoch milliseconds (cached_at + 24 hours)
);

-- Cached Chapter Aggregate Hierarchy (MangaAggregateCache - 30-Minute TTL)
CREATE TABLE manga_aggregate_cache (
    manga_id TEXT NOT NULL,
    languages_key TEXT NOT NULL, -- e.g. "en,it"
    json_payload TEXT NOT NULL,  -- Serialized MangaDex /aggregate JSON
    cached_at INTEGER NOT NULL,  -- Epoch milliseconds
    expires_at INTEGER NOT NULL, -- Epoch milliseconds (cached_at + 30 minutes)
    PRIMARY KEY (manga_id, languages_key),
    FOREIGN KEY (manga_id) REFERENCES manga_metadata_cache(manga_id) ON DELETE CASCADE
);

-- Index for instant aggregate retrieval by manga and language filter
CREATE INDEX idx_aggregate_manga_lang ON manga_aggregate_cache(manga_id, languages_key);
```

#### Drift Table Definitions (`packages/koma_cache_client`)

```dart
import 'package:drift/drift.dart';

class MangaMetadataCache extends Table {
  TextColumn get mangaId => text()();
  TextColumn get jsonPayload => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {mangaId};
}

class MangaAggregateCache extends Table {
  TextColumn get mangaId => text()();
  TextColumn get languagesKey => text()(); // e.g. "en,it"
  TextColumn get jsonPayload => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {mangaId, languagesKey};
}
```

---

## 5. End-to-End Sequence Diagrams & Data Flows

### 5.1 Flow A: Authentication & User Provisioning

Koma supports three distinct authentication pathways:
1. **Google Sign-In**: Native Google OAuth credential exchange.
2. **Email & Password**: Standard Firebase Auth credential validation.
3. **Development QA Bypass**: Automated test harness authentication using:
   - Email: `test@mangatracker.local`
   - Password: `KomaTest!2026#Dev`
   - Configured against the Firebase Auth Emulator on port `9099`.

```mermaid
sequenceDiagram
    autonumber
    actor User as User / QA Engineer
    participant UI as LoginPage (koma_ui)
    participant Bloc as AuthBloc
    participant Repo as AuthRepository
    participant Client as FirebaseAuthClient
    participant AuthEngine as Firebase Auth (or Emulator:9099)
    participant FirestoreClient as FirestoreLibraryClient
    participant FS as Cloud Firestore (or Emulator:8080)

    alt Standard Google / Email Sign-In
        User->>UI: Selects "Sign in with Google" or submits Email/Password
        UI->>Bloc: AuthSignInRequested(credentials)
        Bloc->>Repo: signInWithCredentials(...)
        Repo->>Client: authenticate(credentials)
        Client->>AuthEngine: signInWithCredential(...)
        AuthEngine-->>Client: UserCredential (uid, email, displayName)
    else Dev Flavor QA Bypass
        User->>UI: Taps "QA Quick Login" (Dev flavor only)
        UI->>Bloc: AuthQABypassRequested()
        Bloc->>Repo: signInWithQABypass(email: "test@mangatracker.local", pass: "KomaTest!2026#Dev")
        Repo->>Client: signInWithEmailAndPassword("test@mangatracker.local", "KomaTest!2026#Dev")
        Client->>AuthEngine: signIn(credentials on 10.0.2.2 / 127.0.0.1:9099)
        AuthEngine-->>Client: UserCredential (mockUid)
    end

    Client-->>Repo: AuthUserData(uid, email, displayName)
    Repo->>FirestoreClient: ensureUserProfileExists(uid, email, displayName)
    FirestoreClient->>FS: getDoc("users/{uid}")
    
    alt User profile does not exist
        FS-->>FirestoreClient: null (not found)
        FirestoreClient->>FS: setDoc("users/{uid}", {uid, email, uiLocale: 'en', preferredLanguages: ['en', 'it'], notificationsEnabled: true, createdAt: serverTimestamp()})
        FS-->>FirestoreClient: WriteSuccess
    else Profile already exists
        FS-->>FirestoreClient: UserProfileData
    end

    FirestoreClient-->>Repo: ProfileConfirmed
    Repo-->>Bloc: Emit UserAuthenticated(User)
    Bloc-->>UI: Navigate to Library (/library) via GoRouter
```

---

### 5.2 Flow B: Manga Search, Rate-Limited Dio Token Bucket & Cover Art Resolution

MangaDex enforces a strict limit of 5 requests per second per IP address. Exceeding this triggers an HTTP 429 response. Koma implements a proactive client-side token bucket interceptor inside `MangadexApiClient` to throttle outgoing traffic before it leaves the device.

```mermaid
sequenceDiagram
    autonumber
    actor User as User
    participant SearchUI as SearchView (koma_ui)
    participant SearchBloc as SearchBloc
    participant MangaRepo as MangaRepository
    participant MDClient as MangadexApiClient (Dio)
    participant Bucket as Dio TokenBucketInterceptor
    participant Drift as KomaCacheClient (Drift SQLite)
    participant MD_API as api.mangadex.org
    participant CoverCDN as uploads.mangadex.org

    User->>SearchUI: Types "Frieren" (debounced 300ms)
    SearchUI->>SearchBloc: SearchQueryChanged(query: "Frieren")
    SearchBloc->>MangaRepo: searchManga(title: "Frieren", limit: 20)
    MangaRepo->>MDClient: getMangaSearch(title: "Frieren", includes: ["cover_art"])
    
    MDClient->>Bucket: acquireToken()
    Note over Bucket: Token Bucket: Capacity=4, Refill=1 token / 250ms (Upstream ceiling: 5 req/s). If empty, await next refill tick.
    Bucket-->>MDClient: Token granted
    
    MDClient->>MD_API: GET /manga?title=Frieren&includes[]=cover_art (Header: User-Agent: Koma/0.1.0)
    MD_API-->>MDClient: 200 OK (MangaDexSearchResponse JSON)
    
    MDClient-->>MangaRepo: List<MangaDexData>
    MangaRepo->>Drift: upsertMangaCache(List<CachedMangaData>)
    Drift-->>MangaRepo: Cache updated
    MangaRepo-->>SearchBloc: List<Manga> (Domain models)
    SearchBloc-->>SearchUI: SearchStateSuccess(results)
    
    SearchUI->>CoverCDN: Request image: https://uploads.mangadex.org/covers/{mangaId}/{coverFileName}.512.jpg (Header: User-Agent: Koma/0.1.0)
    CoverCDN-->>SearchUI: 200 OK (JPEG Image stream cached by cached_network_image)
```

---

### 5.3 Flow C: Offline-First Library & Manga Detail `/aggregate` Cache Flow

When a user opens a manga detail screen, the application employs a Stale-While-Revalidate (SWR) strategy. The structural tree of chapters and volumes is loaded instantly from local SQLite storage, while a background sync verifies if upstream updates occurred on MangaDex.

```mermaid
sequenceDiagram
    autonumber
    actor User as User
    participant DetailUI as MangaDetailPage
    participant ProgressBloc as ReaderProgressBloc
    participant MangaRepo as MangaRepository
    participant LibraryRepo as LibraryRepository
    participant Drift as KomaCacheClient (Drift SQLite)
    participant MDClient as MangadexApiClient
    participant FS as Cloud Firestore Native Cache

    User->>DetailUI: Opens Manga Detail (mangaId: "uuid-123")
    DetailUI->>ProgressBloc: LoadMangaDetailRequested(mangaId: "uuid-123")
    
    par Load User Library Record (Offline Firestore)
        ProgressBloc->>LibraryRepo: watchLibraryEntry(mangaId: "uuid-123")
        LibraryRepo->>FS: listenToDocument("users/{uid}/library/uuid-123")
        FS-->>LibraryRepo: Local Cached Snapshot (readChapters: ["1", "2"])
        LibraryRepo-->>ProgressBloc: LibraryEntry(status: reading, readChapters: ["1", "2"])
    and Load Structural Chapter Hierarchy (Drift Cache)
        ProgressBloc->>MangaRepo: getChapterAggregate(mangaId: "uuid-123")
        MangaRepo->>Drift: queryAggregate(mangaId: "uuid-123")
        Drift-->>MangaRepo: CachedAggregateData (Volumes 1..3, Chapters 1..25)
        MangaRepo-->>ProgressBloc: ChapterAggregate(cached: true)
    end

    ProgressBloc-->>DetailUI: Render UI with cached chapters & read status
    
    opt Revalidate with MangaDex if Cache Stale (> 30 minutes or forced)
        MangaRepo->>MDClient: getAggregate(mangaId: "uuid-123")
        MDClient->>MDClient: Token Bucket throttle (4 req/s)
        MDClient->>MDClient: GET api.mangadex.org/manga/uuid-123/aggregate
        MDClient-->>MangaRepo: 200 OK (Fresh Aggregate JSON)
        MangaRepo->>Drift: replaceAggregate(mangaId, freshData)
        Drift-->>MangaRepo: Stored
        MangaRepo-->>ProgressBloc: Fresh ChapterAggregate
        ProgressBloc-->>DetailUI: Re-render UI with newly published chapters
    end
```

---

### 5.4 Flow D: Granular Progress & Atomic "Mark Previous as Read" Transaction

When a user finishes chapter 45 and taps "Mark Previous as Read", Koma must execute an all-or-nothing mutation. It updates the tracking state of all chapters up to chapter 45 and registers a single history event audit record. A Firestore `WriteBatch` guarantees that if any part fails or loses connectivity, the entire transaction is preserved locally in the offline queue and committed atomically to the server once reconnected.

```mermaid
sequenceDiagram
    autonumber
    actor User as User
    participant UI as ReaderProgressView (koma_ui)
    participant Sheet as KomaBulkReadSheet (Modal)
    participant Bloc as ReaderProgressBloc
    participant Repo as LibraryRepository
    participant Client as FirestoreLibraryClient
    participant FS as Cloud Firestore (WriteBatch Engine)

    User->>UI: Long presses Chapter 45 -> Selects "Mark Previous as Read"
    UI->>Sheet: Opens Confirmation Sheet ("Mark chapters 1 to 45 as read?")
    User->>Sheet: Confirms action
    Sheet->>Bloc: BulkMarkPreviousRequested(mangaId, targetChapter: "45", allPreviousChapters: ["1".."45"])
    
    Bloc->>Repo: markPreviousAsRead(mangaId, chaptersToMark: ["1".."45"], targetChapter: "45")
    Repo->>Client: executeAtomicBulkRead(uid, mangaId, chaptersToMark, targetChapter)
    
    Note over Client,FS: Initialize Firestore WriteBatch
    Client->>FS: batch = firestore.batch()
    
    Note over Client,FS: 1. Update Library Document
    Client->>FS: batch.update("users/{uid}/library/{mangaId}", { readChapters: FieldValue.arrayUnion(["1".."45"]), lastReadChapter: "45", lastReadChapterId: "chapter-uuid-45", updatedAt: FieldValue.serverTimestamp() })
    
    Note over Client,FS: 2. Create Immutable Reading History Audit Event
    Client->>FS: eventRef = "users/{uid}/reading_history/{newEventId}"
    Client->>FS: batch.set(eventRef, { eventId: "newEventId", uid: uid, mangaId: mangaId, mangaTitle: "Frieren: Beyond Journey's End", coverFileName: "frieren.jpg", actionType: "bulk_previous_read", chapterNumbers: ["1".."45"], chaptersCount: 45, timestamp: FieldValue.serverTimestamp() })
    
    Client->>FS: await batch.commit()
    
    alt Device is Online
        FS-->>Client: Batch committed successfully to cloud
    else Device is Offline
        FS-->>Client: Mutation queued in local Firestore cache (Offline Write)
    end

    Client-->>Repo: Success
    Repo-->>Bloc: ProgressUpdated(readChapters: ["1".."45"])
    Bloc-->>UI: Refresh chapter list with read checkmarks & show SnackBar
```

---

### 5.5 Flow E: Daily Chapter Notification Engine & Deep Linking

Koma monitors releases for all manga in a user's library. At 06:00 UTC, a Cloud Functions v2 instance wakes up, scans subscriptions, compares with MangaDex chapter feeds, updates the catalog tracking pointers, and dispatches FCM notifications. Clicking the notification deep links directly into the manga details, where the user can tap an external link to read the chapter on MangaDex.

```mermaid
sequenceDiagram
    autonumber
    participant Cron as Cloud Scheduler (06:00 UTC)
    participant CF as Cloud Function v2 (onSchedule - Node.js 22)
    participant FS as Cloud Firestore
    participant MD_API as MangaDex API (/chapter feed)
    participant FCM as Firebase Cloud Messaging
    participant DeviceOS as Mobile OS (APNS / FCM Service)
    participant KomaApp as Koma Client (go_router)
    participant Browser as External Browser / MangaDex Web

    Cron->>CF: HTTP Trigger (Daily Chapter Scan)
    CF->>FS: Query users where notificationsEnabled == true
    FS-->>CF: List of active users & their library manga IDs
    
    loop For each unique Manga ID in active libraries
        CF->>MD_API: GET /manga/{id}/feed?translatedLanguage[]=en&translatedLanguage[]=it&limit=5&order[publishAt]=desc
        MD_API-->>CF: 200 OK (Latest chapters feed)
        
        opt New chapter discovered > latestKnownChapterId
            CF->>FS: Update library entry latestKnownChapterId & latestKnownChapterNumber
            CF->>FCM: sendMulticast({ tokens, notification: { title: "New Chapter Out!", body: "Ch. 132 of Frieren is now available." }, data: { mangaId: "uuid-123", chapterId: "ch-uuid-132", chapterNumber: "132" } })
            FCM-->>CF: Notification dispatched
        end
    end

    FCM->>DeviceOS: Push notification delivery
    DeviceOS->>DeviceOS: Displays system notification banner
    
    User->>DeviceOS: Taps notification banner
    DeviceOS->>KomaApp: Launch app with payload: {mangaId: "uuid-123", chapterId: "ch-uuid-132"}
    
    Note over KomaApp: GoRouter parses deep link: /library/manga/uuid-123?highlightChapter=132
    KomaApp->>KomaApp: Navigates to MangaDetailPage(mangaId: "uuid-123")
    KomaApp->>User: Displays detail screen with Chapter 132 highlighted
    
    User->>KomaApp: Taps "Read on MangaDex" external action button
    KomaApp->>Browser: url_launcher opens "https://mangadex.org/chapter/ch-uuid-132"
```

---

## 6. Resilience, Error Handling & Upstream Constraints

### 6.1 MangaDex Rate Limit Handling (HTTP 429)

MangaDex limits API consumers to 5 requests per second per IP. If burst traffic causes an HTTP 429, the client responds gracefully:

1. **Header Inspection**: `MangadexApiClient` inspects the `Retry-After` or `X-RateLimit-Retry-After` header.
2. **Exponential Backoff with Jitter**: If no header is present, the client pauses for an initial backoff of 1000ms, doubling on consecutive failures with a randomized +/- 200ms jitter:
   ```text
   T_wait = 2^attempt * 1000ms + Uniform(-200, 200)ms
   ```
3. **Queue Pause**: The internal token bucket suspends dispatching queued requests until the retry duration expires.

### 6.2 Cloud Firestore Offline Resilience

- Cloud Firestore's native persistent disk cache ensures the application remains fully interactive in airplane mode.
- Reads are satisfied immediately from local cache (`Source.cache`).
- Write operations (`WriteBatch`) resolve locally and are appended to the pending mutation queue.
- When connectivity resumes, the Firestore SDK seamlessly synchronizes offline mutations to the cloud, resolving conflicts via server timestamps.

### 6.3 Drift SQLite Cache Versioning & Maintenance

- The Drift cache uses schema versioning with incremental migration strategies (`MigrationStrategy`).
- In accordance with `docs/04` TTL policies, `MangaMetadataCache` expires after 24 hours while `MangaAggregateCache` expires after 30 minutes.
- An LRU garbage collection routine executes during background startup, removing cached aggregate entries older than 7 days for manga not currently present in the user's library (`Reading` or `Plan to Read`).
