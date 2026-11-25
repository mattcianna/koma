# Argon-01 Investigation: MangaDex v5 Live API & CDN Edge Cases

**Author:** `argon-mangadex`  
**Date:** 2026-11-13  
**Target Documents Audited:**
- [04-mangadex-api-integration-guide.md](../04-mangadex-api-integration-guide.md)
- [05-cloud-functions-notification-scheduler.md](../05-cloud-functions-notification-scheduler.md)

**Audit Methodology:**  
Read-only live HTTP/2 requests executed against `https://api.mangadex.org` and `https://uploads.mangadex.org` using the audit identification header `User-Agent: KomaDocsAudit/0.1` and the canonical production header `User-Agent: Koma/0.1.0 (https://github.com/mattcianna/koma)`, spaced at $\ge 400\text{ ms}$ intervals ($\le 2.5\text{ req/s}$).

---

## Executive Summary of Empirical Findings

| # | Area | Empirical Live Behaviour | Impact on `docs/04` & `docs/05` |
| :--- | :--- | :--- | :--- |
| **1** | **`GET /manga` Locale Maps & Relationships** | Flagship titles (*One Piece*, *Frieren*, *Dungeon Meshi*, *Solo Leveling*) frequently omit `"en"` and `"it"` from `attributes.title`, using only `{"ja-ro": "..."}` or `{"ko-ro": "..."}` while placing `"en"` and `"it"` inside `attributes.altTitles` (`List<Map<String, String>>`). Furthermore, `relationships` includes unexpanded entries (`artist`, `manga`) without an `attributes` object alongside expanded `cover_art` and `author` entries, and `cover_art.attributes.fileName` may be `.png` (requiring `.png.512.jpg` on CDN). | `docs/04` needs a **Canonical Title & Description Locale Resolver** (`it` $\rightarrow$ `en` across `title` then `altTitles`, falling back to `ja-ro`/`ko-ro`/first value) and null-safe `relationships` extraction. Also replace synthetic Dungeon Meshi UUID `d8f93318-...` with real UUID `d90ea6cb-7bc3-4d80-8af0-28557e6c4e17` (or *One Piece* `a1c7c817-4e59-43b7-9365-09675a149a6f`). |
| **2** | **`GET /manga/{id}/aggregate` Quirks** | Empty volume sets (e.g., `translatedLanguage[]=tlh`, `translatedLanguage[]=xx`, or licensed titles like *Delicious in Dungeon* `d90ea6cb-7bc3-4d80-8af0-28557e6c4e17` for `en`+`it`) serialize as `"volumes": []` (JSON array) instead of `{}`. Live chapter objects include `"isUnavailable": false`, `"others": ["<uuid>"]`, `"none"` volume/chapter keys (*Look Back* `ba7908db-5c9e-4f78-9fc1-3b3581f752e9`), and decimal keys (`"113.2"`, `"79.2"`). | `docs/04` sample JSON omits `"isUnavailable": false`. More critically, `ChapterComparator` in `docs/04` short-circuits `if (numA != null && numB == null) return -1;`, causing chapter `"11"` (and `"1198"`) to sort *before* `"10a"`. Must parse numeric prefix first. |
| **3** | **`publishAtSince` Timestamp Validation & `/feed` External Chapters** | Passing `.000Z` or trailing `Z` to `GET /chapter` or `GET /manga/{id}/feed` returns **HTTP `400 Bad Request`** (`validation_exception`) with regex `^\d{4}-[0-1]\d-([0-2]\d|3[0-1])T([0-1]\d|2[0-3]):[0-5]\d:[0-5]\d$`. Additionally, passing `includeEmptyPages=0` on `/manga/{id}/feed` excludes all official simulpub chapters (`pages: 0`, `externalUrl != null`), dropping *One Piece* chapters 1193–1198! | `docs/04` and `docs/05` timestamp formatters are verified correct. However, `docs/05` (`src/services/mangadex.ts` line 335 & Section 4) **must remove `includeEmptyPages=0`** so official MangaPlus/simulpub chapters trigger notifications, and normalize `chapter ?? 'none'` to match `/aggregate`. |
| **4** | **`uploads.mangadex.org` Cover CDN & Hotlink Protection** |1. `HEAD` requests return **HTTP `405 Method Not Allowed`** (`allow: GET, OPTIONS`).<br>2. Empty `User-Agent` returns **HTTP `400 Bad Request`** (`You must set an appropriate User-Agent header`).<br>3. `GET` with `User-Agent: Koma/0.1.0 (...)` and **no `Referer`** (Flutter Mobile `CachedNetworkImage`) returns **HTTP `200 OK`** with the authentic cover (`182,439` bytes, `cache-control: max-age=315360000`).<br>4. `GET` with a third-party `Referer: https://koma.app/` returns **HTTP `200 OK`** (not 403!) but silently swaps the payload for a `59,480`-byte anti-hotlink placeholder image (`etag: "5ed7c990-e858"`, `cache-control: private, no-store`). | Mobile (iOS/Android) `CachedNetworkImage` works out-of-the-box when `User-Agent` is set and `Referer` is omitted. `docs/04` should document the silent `200 OK` placeholder image swap when a non-`mangadex.org` `Referer` header is sent, the `405` on `HEAD`, and the `X-RateLimit-Retry-After` epoch-seconds calculation bug in `MangaDexRateLimitInterceptor`. |

---

## 1. Empirical Check 1: `GET /manga` Payload Shape, Locale Maps, and Relationships

### 1.1 Live Request & Response Headers

```bash
curl -sS -D - -H "User-Agent: KomaDocsAudit/0.1" \
  "https://api.mangadex.org/manga?title=One+Piece&limit=2&includes%5B%5D=cover_art&includes%5B%5D=author"
```

```http
HTTP/2 200 
content-type: application/json
cache-control: max-age=15, public, s-maxage=2592000, stale-while-revalidate=15
date: Fri, 13 Nov 2026 18:03:30 GMT
x-cache: MISS
accept-ranges: bytes
access-control-allow-credentials: true
access-control-expose-headers: *
vary: Origin
md-edge-crs: Tk9ORQ
server: MangaDex
via: HTTP/2.0 EU-CENTRAL-D2x1
x-request-id: 01a1d614-31a1-7c32-a96f-ae0eb03d83ff
referrer-policy: strict-origin
x-content-type-options: nosniff
strict-transport-security: max-age=63072000; includeSubDomains; preload
```

### 1.2 Trimmed Live JSON Payload (`One Piece` + `Solo Leveling` Locale Comparison)

```json
{
  "result": "ok",
  "response": "collection",
  "data": [
    {
      "id": "a1c7c817-4e59-43b7-9365-09675a149a6f",
      "type": "manga",
      "attributes": {
        "title": {
          "ja-ro": "One Piece"
        },
        "altTitles": [
          { "ja": "ワンピース" },
          { "uk": "Ван Піс" },
          { "ru": "One Piece. Большой куш" },
          { "zh": "海贼王" },
          { "ko": "원피스" },
          { "en": "One Piece" },
          { "ur": "ون پیس" }
        ],
        "description": {
          "en": "Gol D. Roger, a man referred to as the \"King of the Pirates,\" is set to be executed by the World Government...",
          "es": "Gol D. Roger era conocido como el \"Rey de los Piratas\"...",
          "ru": "Гол Д. Роджер — человек, известный как «Король Пиратов»...",
          "uk": "Ґол Д. Роджер — чоловік, знаний як \"Король Піратів\"...",
          "es-la": "Una historia épica de piratas, donde narra la historia de \"Monkey D. Luffy\"...",
          "pt-br": "Gol D. Roger era conhecido como o \"Rei dos Piratas\"..."
        },
        "isLocked": true,
        "OriginalLanguage": "ja",
        "lastVolume": "",
        "lastChapter": "",
        "publicationDemographic": "shounen",
        "status": "ongoing",
        "year": 1997,
        "contentRating": "safe",
        "availableTranslatedLanguages": [
          "en", "it", "pt-br", "ru", "fr", "es-la", "pl", "ar", "id", "tr", "vi", "de"
        ]
      },
      "relationships": [
        {
          "id": "b6045e2c-28f4-4ce0-b4dd-b14070f2f5ae",
          "type": "author",
          "attributes": {
            "name": "Oda Eiichirou (尾田栄一郎)",
            "imageUrl": null,
            "version": 5
          }
        },
        {
          "id": "b6045e2c-28f4-4ce0-b4dd-b14070f2f5ae",
          "type": "artist"
        },
        {
          "id": "38383930-d836-4fd7-85f7-ecfebdea3e3c",
          "type": "cover_art",
          "attributes": {
            "description": "",
            "volume": "1",
            "fileName": "2f4aca53-64c7-46ac-ae85-3bc9b3169890.png",
            "locale": "ja",
            "createdAt": "2022-06-13T23:09:29+00:00",
            "updatedAt": "2026-03-25T14:59:13+00:00",
            "version": 3
          }
        },
        {
          "id": "00538a07-ca8f-4b45-a913-932da57b3edc",
          "type": "manga",
          "related": "doujinshi"
        }
      ]
    },
    {
      "id": "a2c1d849-af05-4bbc-b2a7-866ebb10331f",
      "type": "manga",
      "attributes": {
        "title": {
          "en": "One Piece (Official Colored)"
        },
        "altTitles": [
          { "ru": "Ван Пис (Официальное цветное издание)" },
          { "ja": "ONE PIECE カラー版" }
        ],
        "description": {
          "el": "Ο Gol D. Roger ήταν γνωστός ως ο «Βασιλιάς των Πειρατών»...",
          "en": "Gol D. Roger was known as the \"Pirate King,\" the strongest and most infamous being to have sailed the Grand Line..."
        },
        "status": "ongoing",
        "contentRating": "safe"
      },
      "relationships": [
        {
          "id": "b6045e2c-28f4-4ce0-b4dd-b14070f2f5ae",
          "type": "author",
          "attributes": {
            "name": "Oda Eiichirou (尾田栄一郎)"
          }
        },
        {
          "id": "f303e033-a868-42c5-8585-c6b7fe629a50",
          "type": "cover_art",
          "attributes": {
            "fileName": "da0341d8-5526-452c-8bd3-dc8e3cd89f99.jpg"
          }
        }
      ]
    }
  ],
  "limit": 2,
  "offset": 0,
  "total": 45
}
```

### 1.3 Empirical Edge Cases Discovered on `GET /manga`

1. **Primary `attributes.title` Often Lacks `"en"` and `"it"`**:
   Across live MangaDex data, flagship series frequently key `attributes.title` by romanized original script rather than `"en"`:
   - *One Piece* (`a1c7c817-4e59-43b7-9365-09675a149a6f`): `title: {"ja-ro": "One Piece"}` (`"en"` is only in `altTitles`).
   - *Sousou no Frieren* (`b0b721ff-c388-4486-aa0f-c2b0bb321512`): `title: {"ja-ro": "Sousou no Frieren"}` (`"en": "Frieren: Beyond Journey's End"` is only in `altTitles`).
   - *Delicious in Dungeon* (`d90ea6cb-7bc3-4d80-8af0-28557e6c4e17`): `title: {"ja-ro": "Dungeon Meshi"}`.
   - *Solo Leveling* (`32d76d19-8a05-4db0-9fc2-e0b0648fe9d0`): `title: {"ko-ro": "Na Honjaman Level-Up"}` (`"en": "Solo Leveling"` is in `altTitles`, while `description` includes both `"en"` and `"it"`).
   - **Rule for Koma**: Never assume `attributes.title['en']` or `attributes.title['it']` is non-null. Resolution must check `title[preferredLocale]` $\rightarrow$ `altTitles` for `preferredLocale` $\rightarrow$ `title['en']` $\rightarrow$ `altTitles` for `'en'` $\rightarrow$ `title['ja-ro']` / `title['ko-ro']` $\rightarrow$ `title.values.first`.
2. **`altTitles` Is a List of Single-Key Maps with Duplicate Keys**:
   `altTitles` has type `List<Map<String, String>>` where multiple elements frequently share the same language code (e.g., *One Piece* has 3 `"zh"` entries, 3 `"kk"` entries, and 3 `"be"` entries; *Frieren* has 3 `"en"` entries).
3. **Mixed Expanded and Unexpanded `relationships`**:
   Passing `includes[]=cover_art&includes[]=author` expands `"attributes"` **only** on relationships whose `"type"` matches `"cover_art"` or `"author"`. Other relationships on the same manga (`type: "artist"`, `type: "manga"` with `related: "doujinshi" | "spin_off" | "colored"`) remain in the `relationships` array with **no `"attributes"` key** (`attributes == null`).
4. **Original Cover Extension in `fileName`**:
   `cover_art.attributes.fileName` on *One Piece* is `"2f4aca53-64c7-46ac-ae85-3bc9b3169890.png"`. Derived thumbnail URLs append `.256.jpg` or `.512.jpg` **after** the full `fileName` (producing `.../2f4aca53-64c7-46ac-ae85-3bc9b3169890.png.512.jpg`), rather than stripping `.png`. `MangaDexCoverUrlResolver` in `docs/04` (`'$baseUrl/$mangaId/$fileName.512.jpg'`) handles this accurately.
5. **Empty `lastVolume` / `lastChapter` Strings**:
   For ongoing series like *One Piece*, MangaDex returns `"lastVolume": ""` and `"lastChapter": ""` (empty strings `""` rather than `null`), whereas other series return `null`. Deserializers must treat empty strings as `null`.

---

## 2. Empirical Check 2: `GET /manga/{id}/aggregate` Structural Edge Cases

### 2.1 Multi-Volume Series with `"none"` Volume, `isUnavailable`, and `others` Array

Live query on *One Piece* (`a1c7c817-4e59-43b7-9365-09675a149a6f`) with `translatedLanguage[]=en&translatedLanguage[]=it`:

```bash
curl -sS -H "User-Agent: KomaDocsAudit/0.1" \
  "https://api.mangadex.org/manga/a1c7c817-4e59-43b7-9365-09675a149a6f/aggregate?translatedLanguage%5B%5D=en&translatedLanguage%5B%5D=it"
```

```json
{
  "result": "ok",
  "volumes": {
    "none": {
      "volume": "none",
      "count": 13,
      "chapters": {
        "1198": {
          "chapter": "1198",
          "id": "eb3a47c5-faa1-4caa-be39-8abfac63909c",
          "isUnavailable": false,
          "others": [],
          "count": 1
        },
        "1191": {
          "chapter": "1191",
          "id": "391c1555-36ee-423f-a65d-cb5f8abd5286",
          "isUnavailable": false,
          "others": [
            "79a7b406-46c6-40a0-b099-ec7c5ae8a3b2"
          ],
          "count": 2
        }
      }
    },
    "1": {
      "volume": "1",
      "count": 4,
      "chapters": {
        "4": {
          "chapter": "4",
          "id": "38f35f8e-cbf3-43d8-81ea-dce1f920e67c",
          "isUnavailable": false,
          "others": [],
          "count": 1
        },
        "1": {
          "chapter": "1",
          "id": "1be064fa-87cf-4b4e-98eb-f301bdbef107",
          "isUnavailable": false,
          "others": [],
          "count": 1
        }
      }
    }
  }
}
```

### 2.2 Split Decimal Chapters (`"79.2"`, `"113.1"`) and Multi-Group `others` UUIDs

Live query on *The Eminence in Shadow* (`77bee52c-d2d6-44ad-a33a-1734c1fe696a`) with `translatedLanguage[]=en&translatedLanguage[]=it`:

```json
{
  "result": "ok",
  "volumes": {
    "none": {
      "volume": "none",
      "count": 16,
      "chapters": {
        "82.1": {
          "chapter": "82.1",
          "id": "e8313fab-0e45-44e0-8e45-83ebb64edf3d",
          "isUnavailable": false,
          "others": [],
          "count": 1
        },
        "79.2": {
          "chapter": "79.2",
          "id": "c484d893-d292-4f3a-b6a1-6ebce31f40f9",
          "isUnavailable": false,
          "others": [
            "c2a2558a-680e-475b-abc8-5bc1be0b9463"
          ],
          "count": 2
        }
      }
    },
    "18": {
      "volume": "18",
      "count": 5,
      "chapters": {
        "73.2": {
          "chapter": "73.2",
          "id": "56924a95-d1b3-48f7-b96a-7beb8cc98d90",
          "isUnavailable": false,
          "others": [],
          "count": 1
        },
        "73.1": {
          "chapter": "73.1",
          "id": "97485005-fa17-4163-b584-24613e517708",
          "isUnavailable": false,
          "others": [],
          "count": 1
        }
      }
    }
  }
}
```

### 2.3 Unvolumed / Unnumbered Chapter (`"none"` Volume + `"none"` Chapter Key)

Live query on *Look Back* (`ba7908db-5c9e-4f78-9fc1-3b3581f752e9`) with `translatedLanguage[]=en&translatedLanguage[]=it`:

```bash
curl -sS -H "User-Agent: KomaDocsAudit/0.1" \
  "https://api.mangadex.org/manga/ba7908db-5c9e-4f78-9fc1-3b3581f752e9/aggregate?translatedLanguage%5B%5D=en&translatedLanguage%5B%5D=it"
```

```json
{
  "result": "ok",
  "volumes": {
    "none": {
      "volume": "none",
      "count": 1,
      "chapters": {
        "none": {
          "chapter": "none",
          "id": "91e4aa92-de41-4420-8b3b-1da0ee38e62a",
          "isUnavailable": false,
          "others": [],
          "count": 1
        }
      }
    }
  }
}
```

### 2.4 Empty-Volumes PHP `[]` vs `{}` Quirk Confirmed Live

Tested across three live requests:
1. Unmatched ISO language filter: `GET /manga/a1c7c817-4e59-43b7-9365-09675a149a6f/aggregate?translatedLanguage[]=tlh`
2. Non-existent language code: `GET /manga/a1c7c817-4e59-43b7-9365-09675a149a6f/aggregate?translatedLanguage[]=xx`
3. Licensed series with zero `en`/`it` chapters hosted (*Delicious in Dungeon*, `d90ea6cb-7bc3-4d80-8af0-28557e6c4e17`):
   `GET /manga/d90ea6cb-7bc3-4d80-8af0-28557e6c4e17/aggregate?translatedLanguage[]=en&translatedLanguage[]=it`

All three return **HTTP `200 OK`** (`content-length: 28`) with exact payload:

```json
{"result":"ok","volumes":[]}
```

Because MangaDex's PHP Symfony backend serializes an empty PHP array `array()` as JSON `[]` instead of `{}`, any static `Map<String, dynamic>` cast on `json['volumes']` or `volume['chapters']` throws `TypeError: type 'List<dynamic>' is not a subtype of type 'Map<String, dynamic>'`.

### 2.5 Sorting Bug Identified in `docs/04` `ChapterComparator`

In [04-mangadex-api-integration-guide.md](../04-mangadex-api-integration-guide.md#L309-L311), `ChapterComparator.compare` currently writes:

```dart
// BUG in docs/04 lines 309-311:
// One is a number, the other is alphanumeric (number comes first)
if (numA != null && numB == null) return -1;
if (numA == null && numB != null) return 1;
```

Because `double.tryParse('10a')` returns `null` while `double.tryParse('11')` returns `11.0`, comparing `'11'` against `'10a'` hits `numA != null && numB == null` and returns `-1`, sorting `'11'` (and `'1198'`) **before** `'10a'`! See Section 5.2 below for the hardened comparator that extracts the leading numeric prefix (`^(\d+(?:\.\d+)?)(.*)$`) before falling back to pure string comparison.

---

## 3. Empirical Check 3: `publishAtSince` Timestamp Format & `/feed` Simulpub Behavior

### 3.1 Live Timestamp Validation Matrix (`GET /chapter`)

| Test Case | Query Parameter | HTTP Status | Response Payload / Behaviour |
| :--- | :--- | :--- | :--- |
| **3A: Canonical (`YYYY-MM-DDTHH:mm:ss`)** | `publishAtSince=2026-11-12T00:00:00` | **`200 OK`** | Returns valid `"result": "ok", "response": "collection"` |
| **3B: Dart `.toIso8601String()` (`.000Z`)** | `publishAtSince=2026-11-12T00:00:00.000Z` | **`400 Bad Request`** | Rejects with `validation_exception` |
| **3C: Trailing `Z` without ms** | `publishAtSince=2026-11-12T00:00:00Z` | **`400 Bad Request`** | Rejects with `validation_exception` |

#### Exact Live HTTP 400 Error Payload (Tests 3B & 3C)

```json
{
  "result": "error",
  "errors": [
    {
      "id": "9c346772-7b14-5982-b4b6-7b5888522762",
      "status": 400,
      "title": "validation_exception",
      "detail": "Error validating /publishAtSince: Does not match the regex pattern ^\\d{4}-[0-1]\\d-([0-2]\\d|3[0-1])T([0-1]\\d|2[0-3]):[0-5]\\d:[0-5]\\d$",
      "context": null
    }
  ]
}
```

### 3.2 Critical Discovery on `GET /manga/{id}/feed`: `includeEmptyPages=0` Drops Simulpub Releases

In [05-cloud-functions-notification-scheduler.md](../05-cloud-functions-notification-scheduler.md#L335), `MangaDexClient.getMangaFeed` appends `url.searchParams.set('includeEmptyPages', '0')`.

We tested `GET /manga/a1c7c817-4e59-43b7-9365-09675a149a6f/feed?limit=5&order[publishAt]=desc&translatedLanguage[]=en` on *One Piece* with and without `includeEmptyPages=0`:

| Query Configuration | Total Matching Chapters | Top 3 Returned Chapters (`chapter` / `publishAt` / `pages` / `externalUrl`) |
| :--- | :--- | :--- |
| **With `includeEmptyPages=0`** *(current `docs/05`)* | `7` | 1. Ch `1192` (`2026-09-06`, `pages: 1`, `externalUrl: .../1030379`)<br>2. Ch `1188` (`2026-08-26`, `pages: 1`, `externalUrl: .../1029609`)<br>3. Ch `1191` (`2026-08-25`, `pages: 14`, `externalUrl: null`) |
| **Default (Omit `includeEmptyPages=0`)** | `17` | 1. **Ch `1198`** (`2026-11-08`, `pages: 0`, `externalUrl: https://mangaplus.shueisha.co.jp/viewer/1030906`)<br>2. **Ch `1197`** (`2026-11-01`, `pages: 0`, `externalUrl: https://mangaplus.shueisha.co.jp/viewer/1030905`)<br>3. **Ch `1196`** (`2026-10-18`, `pages: 0`, `externalUrl: https://mangaplus.shueisha.co.jp/viewer/1030616`) |

> [!CAUTION]
> **Why `includeEmptyPages=0` Breaks Koma Notifications**:  
> Official simulpub chapters linked by MangaDex (MangaPlus, Viz, K-Manga, Bilibili) have `"pages": 0` and a non-null `"externalUrl"`. Meanwhile, `/manga/{id}/aggregate` **includes** these chapters (`1193`–`1198` appear in *One Piece*'s `/aggregate` response), and Koma is a **Pure Manga Tracker** that links out to MangaDex rather than rendering page images in-app. Setting `includeEmptyPages=0` in `docs/05` causes `checkDailyMangaReleases` to completely miss every new official simulpub chapter!

---

## 4. Empirical Check 4: `uploads.mangadex.org` Cover CDN & Hotlink Protection

Target URL tested:
`https://uploads.mangadex.org/covers/a1c7c817-4e59-43b7-9365-09675a149a6f/2f4aca53-64c7-46ac-ae85-3bc9b3169890.png.512.jpg`

### 4.1 Live CDN Response Matrix

| Test | HTTP Method | `User-Agent` Header | `Referer` Header | HTTP Status | `Content-Length` | `ETag` | `Cache-Control` | Actual Payload Returned |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **4A** | `HEAD` | `KomaDocsAudit/0.1` | *(omitted)* | **`405 Method Not Allowed`** | `14` | *(none)* | `no-store` | `allow: GET, OPTIONS` (`HEAD` rejected by CDN) |
| **4B** | `HEAD` | `Koma/0.1.0 (...)` | *(omitted)* | **`405 Method Not Allowed`** | `14` | *(none)* | `no-store` | `allow: GET, OPTIONS` |
| **4E** | `GET` | *(empty `""`)* | *(omitted)* | **`400 Bad Request`** | `45` | *(none)* | `no-store` | `You must set an appropriate User-Agent header` |
| **4F** | `GET` | `KomaDocsAudit/0.1` | *(omitted)* | **`200 OK`** | `182439` | `"62a7c3a9-2c8a7"` | `max-age=315360000` | Authentic *One Piece* Vol. 1 cover JPEG |
| **4G** | `GET` | `Koma/0.1.0 (https://github.com/mattcianna/koma)` | *(omitted)* | **`200 OK`** | `182439` | `"62a7c3a9-2c8a7"` | `max-age=315360000` | Authentic *One Piece* Vol. 1 cover JPEG (Mobile `CachedNetworkImage` path) |
| **4H** | `GET` | `KomaDocsAudit/0.1` | `https://koma.app/` | **`200 OK`** *(trap!)* | `59480` | `"5ed7c990-e858"` | `private, no-store` | **Anti-hotlink placeholder JPEG** (*"You can read this at: MANGADEX https://mangadex.org/"*) |
| **4I** | `GET` | `KomaDocsAudit/0.1` | `https://mangadex.org/` | **`200 OK`** | `182439` | `"62a7c3a9-2c8a7"` | `max-age=315360000` | Authentic *One Piece* Vol. 1 cover JPEG |

### 4.2 Architectural Implications for Koma

1. **Mobile (`iOS` / `Android`) `CachedNetworkImage` Compatibility**:
   Dart's `HttpClient` on mobile does **not** attach a `Referer` header unless explicitly added, and sends the `httpHeaders` map supplied to `CachedNetworkImage`. With `User-Agent: Koma/0.1.0 (https://github.com/mattcianna/koma)` and no `Referer`, `uploads.mangadex.org` serves the authentic cover with `cache-control: max-age=315360000`.
2. **Silent HTTP `200 OK` Hotlink Trap on Web / Custom Referers**:
   When a request to `uploads.mangadex.org` carries a third-party `Referer` header (such as a browser `<img>` tag without `referrerpolicy="no-referrer"`), MangaDex does **not** return HTTP `403`. Instead, it returns **HTTP `200 OK`** with `cache-control: private, no-store`, `etag: "5ed7c990-e858"`, and a `59,480`-byte placeholder image reading *"You can read this at: MANGADEX — https://mangadex.org/"*. Therefore, Koma's `Dio` and `CachedNetworkImage` configurations must **never** set a custom `Referer` header.
3. **Never Probe Covers with `HEAD`**:
   Because `uploads.mangadex.org` only permits `GET, OPTIONS` (`allow: GET, OPTIONS`) and rejects `HEAD` with `405 Method Not Allowed`, any image preflight or cache validation logic must use `GET` (with `If-None-Match` / `ETag` if conditional validation is needed).

---

## 5. Hardened Production Code Snippets

### 5.1 Hardened Dart Locale & Relationship Parser (`packages/mangadex_api_client`)

```dart
/// Resolves localized strings from MangaDex `title`, `altTitles`, and `description`
/// maps, handling the empirical quirk where flagship series omit `'en'` and `'it'`
/// from `attributes.title` and store them inside `attributes.altTitles`.
class MangaDexLocaleResolver {
  const MangaDexLocaleResolver._();

  /// Safely converts a JSON field that may be `[]` (PHP empty array) into a Map.
  static Map<String, dynamic> sanitizeMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }

  /// Resolves the best display title given user preferred languages (e.g. `['it', 'en']`).
  static String resolveTitle({
    required Object? rawTitle,
    required Object? rawAltTitles,
    List<String> preferredLocales = const ['en', 'it'],
  }) {
    final titleMap = sanitizeMap(rawTitle);
    final altList = rawAltTitles is List ? rawAltTitles : const <Object?>[];

    // 1. Check primary title map for preferred locales in priority order
    for (final locale in preferredLocales) {
      final candidate = titleMap[locale];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    // 2. Search altTitles list of single-key maps for preferred locales
    for (final locale in preferredLocales) {
      for (final item in altList) {
        final map = sanitizeMap(item);
        final candidate = map[locale];
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
    }

    // 3. Fallback to English in primary title or altTitles
    final enTitle = titleMap['en'];
    if (enTitle is String && enTitle.trim().isNotEmpty) {
      return enTitle.trim();
    }
    for (final item in altList) {
      final map = sanitizeMap(item);
      final candidate = map['en'];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    // 4. Fallback to romanized Japanese/Korean/Chinese or first available key
    for (final fallbackKey in const ['ja-ro', 'ko-ro', 'zh-ro', 'ja', 'ko']) {
      final candidate = titleMap[fallbackKey];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    for (final value in titleMap.values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return 'Unknown Title';
  }

  /// Resolves localized description with fallback to `'en'` or first available entry.
  static String? resolveDescription({
    required Object? rawDescription,
    List<String> preferredLocales = const ['en', 'it'],
  }) {
    final descMap = sanitizeMap(rawDescription);
    if (descMap.isEmpty) return null;

    for (final locale in [...preferredLocales, 'en']) {
      final value = descMap[locale];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    for (final value in descMap.values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// Extracts `fileName` from the expanded `cover_art` relationship entry,
  /// ignoring unexpanded relationships where `attributes` is absent/null.
  static String? extractCoverFileName(Object? rawRelationships) {
    if (rawRelationships is! List) return null;
    for (final rel in rawRelationships) {
      final map = sanitizeMap(rel);
      if (map['type'] == 'cover_art') {
        final attrs = sanitizeMap(map['attributes']);
        final fileName = attrs['fileName'];
        if (fileName is String && fileName.isNotEmpty) {
          return fileName;
        }
      }
    }
    return null;
  }
}
```

### 5.2 Hardened Natural/Decimal Chapter Comparator (`packages/manga_repository`)

Fixes the sorting bug in `docs/04` where pure numbers (`"11"`) sorted before alphanumeric chapters (`"10a"`):

```dart
/// Production natural/decimal chapter comparator for MangaDex chapter keys.
///
/// Correctly orders:
/// `"0"` < `"1"` < `"2"` < `"10"` < `"10a"` < `"10b"` < `"10.1"` < `"10.5"` < `"11"` < `"extra"` < `"none"`
class ChapterComparator {
  const ChapterComparator._();

  static final RegExp _prefixRegex = RegExp(r'^(\d+(?:\.\d+)?)(.*)$');

  static int compare(String a, String b) {
    if (a == b) return 0;

    final normA = a.trim();
    final normB = b.trim();
    final lowerA = normA.toLowerCase();
    final lowerB = normB.toLowerCase();

    // Pin "none" (unnumbered chapters/oneshots) to the end
    if (lowerA == 'none' && lowerB == 'none') return 0;
    if (lowerA == 'none') return 1;
    if (lowerB == 'none') return -1;

    final matchA = _prefixRegex.firstMatch(normA);
    final matchB = _prefixRegex.firstMatch(normB);

    // Both start with a numeric value (e.g. "10", "10.5", "10a", "11")
    if (matchA != null && matchB != null) {
      final numA = double.parse(matchA.group(1)!);
      final numB = double.parse(matchB.group(1)!);
      final numDiff = numA.compareTo(numB);
      if (numDiff != 0) return numDiff;

      final suffixA = matchA.group(2)!.trim();
      final suffixB = matchB.group(2)!.trim();
      if (suffixA.isEmpty && suffixB.isNotEmpty) return -1;
      if (suffixA.isNotEmpty && suffixB.isEmpty) return 1;
      return suffixA.compareTo(suffixB);
    }

    // Chapters with a leading number sort before purely non-numeric labels ("extra", "omake")
    if (matchA != null && matchB == null) return -1;
    if (matchA == null && matchB != null) return 1;

    return lowerA.compareTo(lowerB);
  }
}
```

### 5.3 Hardened `X-RateLimit-Retry-After` Parsing in `MangaDexRateLimitInterceptor`

Fixes the epoch-seconds vs. epoch-milliseconds calculation in `docs/04` line 450:

```dart
if (retryAfterHeader != null) {
  final parsed = int.tryParse(retryAfterHeader.trim());
  if (parsed != null) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (parsed < 100000) {
      // Relative delta in seconds
      waitMs = parsed * 1000;
    } else if (parsed < 100000000000) {
      // Unix timestamp in seconds (e.g. 1794593250)
      waitMs = (parsed * 1000) - nowMs;
    } else {
      // Unix timestamp in milliseconds
      waitMs = parsed - nowMs;
    }
  }
}
```

### 5.4 Hardened TypeScript Feed Fetcher (`firebase/functions/src/services/mangadex.ts`)

Removes `includeEmptyPages=0` so official simulpub releases (`pages: 0`, `externalUrl != null`) are captured, and normalizes unnumbered chapters (`chapter: null` $\rightarrow$ `'none'`):

```typescript
public async getMangaFeed(
  mangaId: string,
  languages: string[],
  since: Date,
): Promise<MangaDexChapterData[]> {
  const formattedSince = MangaDexClient.formatPublishAtSince(since);
  const url = new URL(`${CONFIG.mangadex.baseUrl}/manga/${mangaId}/feed`);

  url.searchParams.set('limit', CONFIG.mangadex.feedPageLimit.toString());
  url.searchParams.set('order[publishAt]', 'desc');
  url.searchParams.set('publishAtSince', formattedSince);
  // IMPORTANT: Do NOT set includeEmptyPages=0. Official simulpub chapters
  // (MangaPlus, Viz, K-Manga) have pages=0 and externalUrl!=null, and must
  // still trigger release notifications in Koma.

  for (const lang of languages) {
    url.searchParams.append('translatedLanguage[]', lang);
  }
  // ...
}
```

---

## 6. Recommended Patches for `docs/04` and `docs/05`

### 6.1 Patches for `docs/04-mangadex-api-integration-guide.md`
1. **Section 2.2 (Image CDN Anti-Hotlinking Rules)**: Document that `uploads.mangadex.org` rejects `HEAD` requests with `405 Method Not Allowed`, rejects empty `User-Agent` headers with `400 Bad Request`, and silently returns a `200 OK` anti-hotlink placeholder JPEG (`etag: "5ed7c990-e858"`, `59,480` bytes) if a non-`mangadex.org` `Referer` header is sent.
2. **Section 4.1 (`GET /manga`)**: Add `MangaDexLocaleResolver` showing fallback across `attributes.title` and `attributes.altTitles` (since flagship titles like *One Piece* `a1c7c817-4e59-43b7-9365-09675a149a6f` and *Dungeon Meshi* `d90ea6cb-7bc3-4d80-8af0-28557e6c4e17` only have `{"ja-ro": "..."}` in `title` and keep `"en"` / `"it"` in `altTitles`), plus null-safe `relationships` parsing when `attributes` is omitted on unexpanded relationship types.
3. **Section 4.3 (`GET /manga/{id}/aggregate` & `ChapterComparator`)**:
   - Include `"isUnavailable": false` in the sample `/aggregate` JSON response to match live MangaDex v5 payloads.
   - Replace `ChapterComparator` (lines 289–333) with the regex-prefix version in Section 5.2 so alphanumeric chapters (`"10a"`) sort between `"10"` and `"11"` instead of after `"1198"`.
4. **Section 4.4 (`publishAtSince`)**: Add the exact live HTTP 400 `validation_exception` JSON payload and regex `^\d{4}-[0-1]\d-([0-2]\d|3[0-1])T([0-1]\d|2[0-3]):[0-5]\d:[0-5]\d$`.
5. **Section 5.3 (`MangaDexRateLimitInterceptor.onError`)**: Fix the `X-RateLimit-Retry-After` Unix epoch-seconds conversion (`(parsed * 1000) - DateTime.now().millisecondsSinceEpoch` when `parsed` is a 10-digit epoch timestamp in seconds).

### 6.2 Patches for `docs/05-cloud-functions-notification-scheduler.md`
1. **Section 4 (item 3) & Section 5.3 (`src/services/mangadex.ts` line 335)**: Remove `includeEmptyPages: 0` / `url.searchParams.set('includeEmptyPages', '0')`. Live testing on *One Piece* (`a1c7c817-4e59-43b7-9365-09675a149a6f`) proved that `includeEmptyPages=0` drops chapters 1193–1198 because official MangaPlus simulpub chapters have `pages: 0` and `externalUrl != null`.
2. **Section 5.5 (`src/services/scheduler.ts` line 670)**: Normalize `const chapterNumber = latestChapterAttr.chapter ?? 'none';` so unnumbered chapters/oneshots (`chapter: null` in `/feed`, which `/aggregate` keys as `"none"`) match `sub.readChapters.has('none')` and persist consistently in `latestKnownChapterNumber`.
