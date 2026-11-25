import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_library_client/src/models/models.dart';

/// Cloud Firestore client managing Koma user profiles, devices, library,
/// and reading history records.
class FirestoreLibraryClient {
  /// Creates a [FirestoreLibraryClient].
  ///
  /// If [firestore] is not provided, defaults to [FirebaseFirestore.instance]
  /// upon first use.
  new({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCollection.doc(uid);

  CollectionReference<Map<String, dynamic>> _devicesCollection(String uid) =>
      _userDoc(uid).collection('devices');

  DocumentReference<Map<String, dynamic>> _deviceDoc(
    String uid,
    String deviceId,
  ) => _devicesCollection(uid).doc(deviceId);

  CollectionReference<Map<String, dynamic>> _libraryCollection(String uid) =>
      _userDoc(uid).collection('library');

  DocumentReference<Map<String, dynamic>> _libraryDoc(
    String uid,
    String mangaId,
  ) => _libraryCollection(uid).doc(mangaId);

  CollectionReference<Map<String, dynamic>> _historyCollection(String uid) =>
      _userDoc(uid).collection('reading_history');

  // ===========================================================================
  // User Profile Operations
  // ===========================================================================

  /// Ensures that a [UserProfileRecord] exists for [uid].
  ///
  /// If the document already exists, the existing record is returned without
  /// mutating immutable fields like `uid` or `createdAt`.
  /// If the document does not exist, a new profile is created with default
  /// settings and server timestamps.
  Future<UserProfileRecord> ensureUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    String uiLocale = 'en',
    List<String> preferredLanguages = const ['en', 'it'],
    List<String> contentRatings = const ['safe', 'suggestive'],
    bool notificationsEnabled = true,
  }) async {
    final docRef = _userDoc(uid);
    final snapshot = await docRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      return UserProfileRecord.fromMap(snapshot.data()!, uid: snapshot.id);
    }

    final now = DateTime.now();
    final profile = UserProfileRecord(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      uiLocale: uiLocale,
      preferredLanguages: preferredLanguages,
      contentRatings: contentRatings,
      notificationsEnabled: notificationsEnabled,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(<String, dynamic>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'uiLocale': uiLocale,
      'preferredLanguages': preferredLanguages,
      'contentRatings': contentRatings,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return profile;
  }

  /// Fetches the [UserProfileRecord] for the specified [uid].
  ///
  /// Returns `null` if no profile document exists.
  Future<UserProfileRecord?> getUserProfile(String uid) async {
    final snapshot = await _userDoc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserProfileRecord.fromMap(snapshot.data()!, uid: snapshot.id);
  }

  /// Watches the user profile document for [uid] as a real-time stream.
  ///
  /// Emits `null` if the user document does not exist.
  Stream<UserProfileRecord?> watchUserProfile(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserProfileRecord.fromMap(snapshot.data()!, uid: snapshot.id);
    });
  }

  /// Updates mutable profile settings for [uid].
  ///
  /// Never overwrites or mutates immutable fields (`uid`, `createdAt`).
  Future<void> updateUserSettings({
    required String uid,
    String? displayName,
    String? photoUrl,
    String? uiLocale,
    List<String>? preferredLanguages,
    List<String>? contentRatings,
    bool? notificationsEnabled,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (uiLocale != null) updates['uiLocale'] = uiLocale;
    if (preferredLanguages != null) {
      updates['preferredLanguages'] = preferredLanguages;
    }
    if (contentRatings != null) {
      updates['contentRatings'] = contentRatings;
    }
    if (notificationsEnabled != null) {
      updates['notificationsEnabled'] = notificationsEnabled;
    }

    await _userDoc(uid).update(updates);
  }

  // ===========================================================================
  // Device Token Operations
  // ===========================================================================

  /// Registers or refreshes an FCM push registration token for [deviceId].
  Future<void> upsertDeviceToken({
    required String uid,
    required String deviceId,
    required String token,
    required String platform,
  }) async {
    await _deviceDoc(uid, deviceId).set({
      'token': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Removes a registered device token document when the user logs out.
  Future<void> deleteDeviceToken({
    required String uid,
    required String deviceId,
  }) async {
    await _deviceDoc(uid, deviceId).delete();
  }

  // ===========================================================================
  // Library Operations
  // ===========================================================================

  /// Emits real-time updates for the user's library entries.
  ///
  /// Optionally filters by [status] (e.g. `'Reading'`, `'Completed'`).
  Stream<List<LibraryRecord>> watchLibrary(String uid, {String? status}) {
    Query<Map<String, dynamic>> query = _libraryCollection(uid);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(LibraryRecord.fromDocument).toList(),
    );
  }

  /// Watches a single library entry for [mangaId] as a real-time stream.
  ///
  /// Emits `null` if the manga is not currently in the user's library.
  Stream<LibraryRecord?> watchLibraryEntry({
    required String uid,
    required String mangaId,
  }) {
    return _libraryDoc(uid, mangaId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return LibraryRecord.fromDocument(snapshot);
    });
  }

  /// Fetches a single library entry for [mangaId].
  ///
  /// Returns `null` if the manga is not in the user's library.
  Future<LibraryRecord?> getLibraryEntry({
    required String uid,
    required String mangaId,
  }) async {
    final snapshot = await _libraryDoc(uid, mangaId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return LibraryRecord.fromDocument(snapshot);
  }

  /// Adds a new manga to the library or updates an existing entry.
  ///
  /// When creating a new document, sets `addedAt` to the server timestamp.
  /// When updating an existing document, mutates only updatable fields,
  /// preserving immutable `addedAt`, `uid`, and `mangaId`.
  Future<void> upsertLibraryEntry({
    required String uid,
    required LibraryRecord entry,
  }) async {
    final docRef = _libraryDoc(uid, entry.mangaId);
    final snapshot = await docRef.get();
    final now = FieldValue.serverTimestamp();

    if (!snapshot.exists) {
      await docRef.set(<String, dynamic>{
        'mangaId': entry.mangaId,
        'uid': uid,
        'title': entry.title,
        'coverFileName': entry.coverFileName,
        'status': entry.status,
        'preferredLanguages': entry.preferredLanguages,
        'readChapters': entry.readChapters,
        'readVolumes': entry.readVolumes,
        'lastReadChapter': entry.lastReadChapter,
        'lastReadChapterId': entry.lastReadChapterId,
        'latestKnownChapterId': entry.latestKnownChapterId,
        'latestKnownChapterNumber': entry.latestKnownChapterNumber,
        'addedAt': now,
        'updatedAt': now,
      });
    } else {
      await docRef.update(<String, dynamic>{
        'title': entry.title,
        'coverFileName': entry.coverFileName,
        'status': entry.status,
        'preferredLanguages': entry.preferredLanguages,
        'readChapters': entry.readChapters,
        'readVolumes': entry.readVolumes,
        'lastReadChapter': entry.lastReadChapter,
        'lastReadChapterId': entry.lastReadChapterId,
        'latestKnownChapterId': entry.latestKnownChapterId,
        'latestKnownChapterNumber': entry.latestKnownChapterNumber,
        'updatedAt': now,
      });
    }
  }

  /// Updates the reading status of a library entry.
  Future<void> updateReadingStatus({
    required String uid,
    required String mangaId,
    required String status,
  }) async {
    await _libraryDoc(uid, mangaId).update(<String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the latest released chapter metadata on a library entry.
  Future<void> updateLatestKnownChapter({
    required String uid,
    required String mangaId,
    required String latestKnownChapterNumber,
    String? latestKnownChapterId,
  }) async {
    final updates = <String, dynamic>{
      'latestKnownChapterNumber': latestKnownChapterNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (latestKnownChapterId != null) {
      updates['latestKnownChapterId'] = latestKnownChapterId;
    }
    await _libraryDoc(uid, mangaId).update(updates);
  }

  /// Deletes a manga from the user's library.
  Future<void> removeFromLibrary({
    required String uid,
    required String mangaId,
  }) async {
    await _libraryDoc(uid, mangaId).delete();
  }

  // ===========================================================================
  // Atomic Progress & History Operations
  // ===========================================================================

  /// Toggles the read state of a single chapter atomically.
  ///
  /// When [isRead] is `true`, commits a single [WriteBatch] updating
  /// `users/{uid}/library/{mangaId}` via `FieldValue.arrayUnion` and appending
  /// an immutable `reading_history` event with `actionType: 'chapter_read'`.
  ///
  /// When [isRead] is `false`, removes the chapter number from `readChapters`
  /// via `FieldValue.arrayRemove`.
  Future<void> toggleChapterRead({
    required String uid,
    required String mangaId,
    required String chapterNumber,
    required bool isRead,
    String? chapterId,
    String? mangaTitle,
    String? coverFileName,
  }) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    final libRef = _libraryDoc(uid, mangaId);

    if (isRead) {
      final updateData = <String, dynamic>{
        'readChapters': FieldValue.arrayUnion([chapterNumber]),
        'lastReadChapter': chapterNumber,
        'updatedAt': now,
      };
      if (chapterId != null) {
        updateData['lastReadChapterId'] = chapterId;
      }
      batch.update(libRef, updateData);

      final histRef = _historyCollection(uid).doc();
      batch.set(histRef, <String, dynamic>{
        'eventId': histRef.id,
        'uid': uid,
        'mangaId': mangaId,
        'mangaTitle': mangaTitle ?? '',
        'coverFileName': coverFileName,
        'actionType': 'chapter_read',
        'chapterNumbers': [chapterNumber],
        'volumeNumber': null,
        'chaptersCount': 1,
        'timestamp': now,
      });
    } else {
      batch.update(libRef, {
        'readChapters': FieldValue.arrayRemove([chapterNumber]),
        'updatedAt': now,
      });
    }

    await batch.commit();
  }

  /// Convenience helper to mark a chapter as read atomically.
  Future<void> markChapterRead({
    required String uid,
    required String mangaId,
    required String mangaTitle,
    required String? coverFileName,
    required String chapterNumber,
    required String chapterId,
  }) => toggleChapterRead(
    uid: uid,
    mangaId: mangaId,
    chapterNumber: chapterNumber,
    isRead: true,
    chapterId: chapterId,
    mangaTitle: mangaTitle,
    coverFileName: coverFileName,
  );

  /// Marks an entire volume as read in a single atomic [WriteBatch].
  ///
  /// Chunks `volumeChapterNumbers` at 450 strings per `reading_history`
  /// event to satisfy security rules boundaries, updating `readVolumes`
  /// and `readChapters` via `FieldValue.arrayUnion`.
  Future<void> markVolumeRead({
    required String uid,
    required String mangaId,
    required String mangaTitle,
    required String? coverFileName,
    required String volumeNumber,
    required List<String> volumeChapterNumbers,
    String? lastChapterNumberInVolume,
    String? lastChapterIdInVolume,
  }) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    final libRef = _libraryDoc(uid, mangaId);

    final updateData = <String, dynamic>{
      'readVolumes': FieldValue.arrayUnion([volumeNumber]),
      'readChapters': FieldValue.arrayUnion(volumeChapterNumbers),
      'updatedAt': now,
    };
    if (lastChapterNumberInVolume != null) {
      updateData['lastReadChapter'] = lastChapterNumberInVolume;
    }
    if (lastChapterIdInVolume != null) {
      updateData['lastReadChapterId'] = lastChapterIdInVolume;
    }
    batch.update(libRef, updateData);

    const maxChaptersPerHistoryDoc = 450;
    final chunks = <List<String>>[];
    if (volumeChapterNumbers.isEmpty) {
      chunks.add(<String>[]);
    } else {
      for (
        var i = 0;
        i < volumeChapterNumbers.length;
        i += maxChaptersPerHistoryDoc
      ) {
        final end = (i + maxChaptersPerHistoryDoc < volumeChapterNumbers.length)
            ? i + maxChaptersPerHistoryDoc
            : volumeChapterNumbers.length;
        chunks.add(volumeChapterNumbers.sublist(i, end));
      }
    }

    assert(
      chunks.length + 1 <= 500,
      'Total WriteBatch operations (${chunks.length + 1}) cannot exceed 500.',
    );

    for (final chunk in chunks) {
      final histRef = _historyCollection(uid).doc();
      batch.set(histRef, <String, dynamic>{
        'eventId': histRef.id,
        'uid': uid,
        'mangaId': mangaId,
        'mangaTitle': mangaTitle,
        'coverFileName': coverFileName,
        'actionType': 'volume_read',
        'chapterNumbers': chunk,
        'volumeNumber': volumeNumber,
        'chaptersCount': chunk.isEmpty ? 1 : chunk.length,
        'timestamp': now,
      });
    }

    await batch.commit();
  }

  /// Marks all previous chapters as read atomically in a single hoisted
  /// [WriteBatch].
  ///
  /// Updates `users/{uid}/library/{mangaId}` via `FieldValue.arrayUnion` and
  /// chunks `previousChapterNumbersToMark` at 450 strings per `reading_history`
  /// doc (`actionType: 'bulk_previous_read'`).
  ///
  /// Asserts total batch operations <= 500 per ARGON-BATCH-01.
  Future<void> markPreviousChaptersRead({
    required String uid,
    required String mangaId,
    required String mangaTitle,
    required String? coverFileName,
    required String targetChapterNumber,
    required String targetChapterId,
    required List<String> previousChapterNumbersToMark,
  }) async {
    if (previousChapterNumbersToMark.isEmpty) return;

    const maxChaptersPerHistoryDoc = 450;
    final chunks = <List<String>>[];
    for (
      var i = 0;
      i < previousChapterNumbersToMark.length;
      i += maxChaptersPerHistoryDoc
    ) {
      final end =
          (i + maxChaptersPerHistoryDoc < previousChapterNumbersToMark.length)
          ? i + maxChaptersPerHistoryDoc
          : previousChapterNumbersToMark.length;
      chunks.add(previousChapterNumbersToMark.sublist(i, end));
    }

    assert(
      chunks.length + 1 <= 500,
      'Total WriteBatch operations (${chunks.length + 1}) cannot exceed 500.',
    );

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    final libRef = _libraryDoc(uid, mangaId);
    batch.update(libRef, {
      'readChapters': FieldValue.arrayUnion(previousChapterNumbersToMark),
      'lastReadChapter': targetChapterNumber,
      'lastReadChapterId': targetChapterId,
      'updatedAt': now,
    });

    for (final chunk in chunks) {
      final histRef = _historyCollection(uid).doc();
      batch.set(histRef, <String, dynamic>{
        'eventId': histRef.id,
        'uid': uid,
        'mangaId': mangaId,
        'mangaTitle': mangaTitle,
        'coverFileName': coverFileName,
        'actionType': 'bulk_previous_read',
        'chapterNumbers': chunk,
        'volumeNumber': null,
        'chaptersCount': chunk.length,
        'timestamp': now,
      });
    }

    await batch.commit();
  }

  // ===========================================================================
  // Reading History Queries
  // ===========================================================================

  /// Emits real-time reading history entries for [uid], ordered by `timestamp`
  /// descending.
  Stream<List<ReadingHistoryRecord>> watchReadingHistory(
    String uid, {
    int limit = 50,
  }) {
    return _historyCollection(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ReadingHistoryRecord.fromDocument).toList(),
        );
  }

  /// Fetches a page of reading history events for [uid] ordered descending.
  Future<List<ReadingHistoryRecord>> getReadingHistory(
    String uid, {
    int limit = 50,
  }) async {
    final snapshot = await _historyCollection(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(ReadingHistoryRecord.fromDocument).toList();
  }
}
