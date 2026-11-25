import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:library_repository/src/models/models.dart';

/// Repository that manages user manga libraries, reading progress, and
/// history audit logs backed by Cloud Firestore.
class LibraryRepository {
  /// Creates a [LibraryRepository].
  ///
  /// If [firestoreLibraryClient] is not provided, an instance will be created.
  new({FirestoreLibraryClient? firestoreLibraryClient})
    : _firestoreLibraryClient =
          firestoreLibraryClient ?? FirestoreLibraryClient();

  final FirestoreLibraryClient _firestoreLibraryClient;

  // ===========================================================================
  // User Profile & Settings
  // ===========================================================================

  /// Ensures that a user profile document exists for [uid].
  ///
  /// If the document already exists, the existing profile is returned.
  /// Otherwise, a new document is created with default preferences.
  Future<UserSettingsProfile> ensureUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    String uiLocale = 'en',
    List<String> preferredLanguages = const ['en', 'it'],
    List<String> contentRatings = const ['safe', 'suggestive'],
    bool notificationsEnabled = true,
  }) async {
    final record = await _firestoreLibraryClient.ensureUserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      uiLocale: uiLocale,
      preferredLanguages: preferredLanguages,
      contentRatings: contentRatings,
      notificationsEnabled: notificationsEnabled,
    );
    return UserSettingsProfile.fromRecord(record);
  }

  /// Watches the user profile document for [uid] as a real-time stream.
  ///
  /// Emits `null` if the user document does not exist.
  Stream<UserSettingsProfile?> watchUserSettings(String uid) {
    return _firestoreLibraryClient
        .watchUserProfile(uid)
        .map(
          (record) =>
              record == null ? null : UserSettingsProfile.fromRecord(record),
        );
  }

  /// Fetches the user settings profile for [uid].
  ///
  /// Returns `null` if no profile document exists.
  Future<UserSettingsProfile?> getUserSettings(String uid) async {
    final record = await _firestoreLibraryClient.getUserProfile(uid);
    return record == null ? null : UserSettingsProfile.fromRecord(record);
  }

  /// Updates mutable user settings and reading preferences for [uid].
  ///
  /// Preserves immutable properties (`uid`, `createdAt`).
  Future<void> updateUserSettings({
    required String uid,
    String? displayName,
    String? photoUrl,
    String? uiLocale,
    List<String>? preferredLanguages,
    List<String>? contentRatings,
    bool? notificationsEnabled,
  }) {
    return _firestoreLibraryClient.updateUserSettings(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      uiLocale: uiLocale,
      preferredLanguages: preferredLanguages,
      contentRatings: contentRatings,
      notificationsEnabled: notificationsEnabled,
    );
  }

  // ===========================================================================
  // Library Tracking
  // ===========================================================================

  /// Emits real-time updates for the user's library entries.
  ///
  /// Optionally filters by [status] (e.g. [ReadingStatus.reading]).
  Stream<List<LibraryEntry>> watchLibrary(String uid, {ReadingStatus? status}) {
    return _firestoreLibraryClient
        .watchLibrary(uid, status: status?.firestoreValue)
        .map((records) => records.map(LibraryEntry.fromRecord).toList());
  }

  /// Watches a single library entry for [mangaId] as a real-time stream.
  ///
  /// Emits `null` if the manga is not currently in the user's library.
  Stream<LibraryEntry?> watchLibraryEntry({
    required String uid,
    required String mangaId,
  }) {
    return _firestoreLibraryClient
        .watchLibraryEntry(uid: uid, mangaId: mangaId)
        .map(
          (record) => record == null ? null : LibraryEntry.fromRecord(record),
        );
  }

  /// Fetches a single library entry for [mangaId].
  ///
  /// Returns `null` if the manga is not in the user's library.
  Future<LibraryEntry?> getLibraryEntry({
    required String uid,
    required String mangaId,
  }) async {
    final record = await _firestoreLibraryClient.getLibraryEntry(
      uid: uid,
      mangaId: mangaId,
    );
    return record == null ? null : LibraryEntry.fromRecord(record);
  }

  /// Adds a new manga to the library or updates an existing entry.
  Future<void> addOrUpdateLibraryEntry({
    required String uid,
    required LibraryEntry entry,
  }) {
    return _firestoreLibraryClient.upsertLibraryEntry(
      uid: uid,
      entry: entry.copyWith(uid: uid).toRecord(),
    );
  }

  /// Updates the [ReadingStatus] of a library entry.
  Future<void> updateStatus({
    required String uid,
    required String mangaId,
    required ReadingStatus status,
  }) {
    return _firestoreLibraryClient.updateReadingStatus(
      uid: uid,
      mangaId: mangaId,
      status: status.firestoreValue,
    );
  }

  /// Updates the latest released chapter metadata of a library entry.
  Future<void> updateLatestKnownChapter({
    required String uid,
    required String mangaId,
    required String latestKnownChapterNumber,
    String? latestKnownChapterId,
  }) {
    return _firestoreLibraryClient.updateLatestKnownChapter(
      uid: uid,
      mangaId: mangaId,
      latestKnownChapterNumber: latestKnownChapterNumber,
      latestKnownChapterId: latestKnownChapterId,
    );
  }

  /// Removes a manga from the user's library.
  Future<void> removeFromLibrary({
    required String uid,
    required String mangaId,
  }) {
    return _firestoreLibraryClient.removeFromLibrary(
      uid: uid,
      mangaId: mangaId,
    );
  }

  // ===========================================================================
  // Atomic Progress & History Operations
  // ===========================================================================

  /// Toggles the read state of a single chapter atomically.
  ///
  /// When [isRead] is `true`, commits a batch updating library progress and
  /// writing an audit entry to `reading_history`.
  /// When [isRead] is `false`, removes the chapter number from library
  /// progress.
  ///
  /// Ensures that [mangaTitle] is non-empty (defaults to `'Untitled Manga'`)
  /// so that Firestore security rules validation succeeds.
  Future<void> toggleChapterRead({
    required String uid,
    required String mangaId,
    required String chapterNumber,
    required bool isRead,
    String? chapterId,
    String? mangaTitle,
    String? coverFileName,
  }) {
    final safeTitle = (mangaTitle != null && mangaTitle.trim().isNotEmpty)
        ? mangaTitle.trim()
        : 'Untitled Manga';

    return _firestoreLibraryClient.toggleChapterRead(
      uid: uid,
      mangaId: mangaId,
      chapterNumber: chapterNumber,
      isRead: isRead,
      chapterId: chapterId,
      mangaTitle: safeTitle,
      coverFileName: coverFileName,
    );
  }

  /// Convenience helper to mark a chapter as read atomically.
  Future<void> markChapterRead({
    required String uid,
    required String mangaId,
    required String chapterNumber,
    required String chapterId,
    String? mangaTitle,
    String? coverFileName,
  }) => toggleChapterRead(
    uid: uid,
    mangaId: mangaId,
    chapterNumber: chapterNumber,
    isRead: true,
    chapterId: chapterId,
    mangaTitle: mangaTitle,
    coverFileName: coverFileName,
  );

  /// Marks an entire volume as read atomically.
  ///
  /// If [volumeChapterNumbers] is empty, only the library entry's `readVolumes`
  /// is updated without creating an invalid 0-chapter history audit record.
  /// If [volumeChapterNumbers] is non-empty, delegates to
  /// [FirestoreLibraryClient.markVolumeRead] with a guaranteed non-empty
  /// [mangaTitle] fallback.
  Future<void> markVolumeRead({
    required String uid,
    required String mangaId,
    required String volumeNumber,
    required List<String> volumeChapterNumbers,
    String? mangaTitle,
    String? coverFileName,
    String? lastChapterNumberInVolume,
    String? lastChapterIdInVolume,
  }) async {
    final safeTitle = (mangaTitle != null && mangaTitle.trim().isNotEmpty)
        ? mangaTitle.trim()
        : 'Untitled Manga';

    if (volumeChapterNumbers.isEmpty) {
      final existingEntry = await _firestoreLibraryClient.getLibraryEntry(
        uid: uid,
        mangaId: mangaId,
      );

      if (existingEntry != null) {
        final updatedVolumes = {
          ...existingEntry.readVolumes,
          volumeNumber,
        }.toList();

        await _firestoreLibraryClient.upsertLibraryEntry(
          uid: uid,
          entry: existingEntry.copyWith(
            readVolumes: updatedVolumes,
            lastReadChapter:
                lastChapterNumberInVolume ?? existingEntry.lastReadChapter,
            lastReadChapterId:
                lastChapterIdInVolume ?? existingEntry.lastReadChapterId,
          ),
        );
      } else {
        final now = DateTime.now();
        await _firestoreLibraryClient.upsertLibraryEntry(
          uid: uid,
          entry: LibraryRecord(
            mangaId: mangaId,
            uid: uid,
            title: safeTitle,
            coverFileName: coverFileName,
            status: ReadingStatus.reading.firestoreValue,
            readVolumes: [volumeNumber],
            lastReadChapter: lastChapterNumberInVolume,
            lastReadChapterId: lastChapterIdInVolume,
            addedAt: now,
            updatedAt: now,
          ),
        );
      }
      return;
    }

    await _firestoreLibraryClient.markVolumeRead(
      uid: uid,
      mangaId: mangaId,
      mangaTitle: safeTitle,
      coverFileName: coverFileName,
      volumeNumber: volumeNumber,
      volumeChapterNumbers: volumeChapterNumbers,
      lastChapterNumberInVolume: lastChapterNumberInVolume,
      lastChapterIdInVolume: lastChapterIdInVolume,
    );
  }

  /// Marks all previous chapters up to [targetChapterNumber] as read
  /// atomically.
  ///
  /// Guarantees that [mangaTitle] is non-empty
  /// (defaults to `'Untitled Manga'`).
  /// If [previousChapterNumbersToMark] is empty, returns immediately.
  Future<void> markPreviousAsRead({
    required String uid,
    required String mangaId,
    required String targetChapterNumber,
    required String targetChapterId,
    required List<String> previousChapterNumbersToMark,
    String? mangaTitle,
    String? coverFileName,
  }) async {
    if (previousChapterNumbersToMark.isEmpty) return;

    final safeTitle = (mangaTitle != null && mangaTitle.trim().isNotEmpty)
        ? mangaTitle.trim()
        : 'Untitled Manga';

    await _firestoreLibraryClient.markPreviousChaptersRead(
      uid: uid,
      mangaId: mangaId,
      mangaTitle: safeTitle,
      coverFileName: coverFileName,
      targetChapterNumber: targetChapterNumber,
      targetChapterId: targetChapterId,
      previousChapterNumbersToMark: previousChapterNumbersToMark,
    );
  }

  // ===========================================================================
  // Reading History Queries
  // ===========================================================================

  /// Emits real-time reading history entries for [uid], ordered descending
  /// by timestamp.
  Stream<List<ReadingHistoryEvent>> watchReadingHistory(
    String uid, {
    int limit = 50,
  }) {
    return _firestoreLibraryClient
        .watchReadingHistory(uid, limit: limit)
        .map((records) => records.map(ReadingHistoryEvent.fromRecord).toList());
  }

  /// Fetches a page of reading history events for [uid] ordered descending.
  Future<List<ReadingHistoryEvent>> getReadingHistory(
    String uid, {
    int limit = 50,
  }) async {
    final records = await _firestoreLibraryClient.getReadingHistory(
      uid,
      limit: limit,
    );
    return records.map(ReadingHistoryEvent.fromRecord).toList();
  }
}
