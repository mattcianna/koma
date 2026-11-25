import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firestore_library_client/src/models/reading_status.dart';

/// Personal library entry record representing `users/{uid}/library/{mangaId}`.
class LibraryRecord extends Equatable {
  /// Creates a [LibraryRecord].
  const new({
    required this.mangaId,
    required this.uid,
    required this.title,
    required this.status,
    required this.addedAt,
    required this.updatedAt,
    this.coverFileName,
    this.preferredLanguages = const ['en', 'it'],
    this.readChapters = const [],
    this.readVolumes = const [],
    this.lastReadChapter,
    this.lastReadChapterId,
    this.latestKnownChapterId,
    this.latestKnownChapterNumber,
  });

  /// Creates a [LibraryRecord] from a Firestore [DocumentSnapshot].
  factory fromDocument(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return LibraryRecord.fromMap(data, mangaId: snapshot.id);
  }

  /// Deserializes a [LibraryRecord] from a raw map.
  factory fromMap(Map<String, dynamic> map, {String? mangaId, String? uid}) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return LibraryRecord(
      mangaId: (map['mangaId'] as String?) ?? mangaId ?? '',
      uid: (map['uid'] as String?) ?? uid ?? '',
      title: (map['title'] as String?) ?? '',
      coverFileName: map['coverFileName'] as String?,
      status:
          (map['status'] as String?) ?? ReadingStatus.planToRead.firestoreValue,
      preferredLanguages: parseStringList(map['preferredLanguages']),
      readChapters: parseStringList(map['readChapters']),
      readVolumes: parseStringList(map['readVolumes']),
      lastReadChapter: map['lastReadChapter'] as String?,
      lastReadChapterId: map['lastReadChapterId'] as String?,
      latestKnownChapterId: map['latestKnownChapterId'] as String?,
      latestKnownChapterNumber: map['latestKnownChapterNumber'] as String?,
      addedAt: parseDateTime(map['addedAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  /// MangaDex Manga UUID v4 matching the document ID.
  final String mangaId;

  /// Parent user's Firebase Auth UID.
  final String uid;

  /// Primary manga title.
  final String title;

  /// Cover art filename on MangaDex CDN (e.g. `uuid.jpg`).
  final String? coverFileName;

  /// Firestore status string (`'Reading'`, `'Plan to Read'`, etc.).
  final String status;

  /// Denormalized scanlation language preferences.
  final List<String> preferredLanguages;

  /// Canonical chapter numbers/keys marked read by the user.
  final List<String> readChapters;

  /// Volume numbers marked read by the user.
  final List<String> readVolumes;

  /// Human-readable number of the last read chapter (e.g. `"104.5"`).
  final String? lastReadChapter;

  /// MangaDex Chapter UUID of the last read chapter.
  final String? lastReadChapterId;

  /// Latest published chapter UUID discovered from feed/aggregate.
  final String? latestKnownChapterId;

  /// Latest published chapter number (e.g. `"105"`).
  final String? latestKnownChapterNumber;

  /// Timestamp when this manga was added to the library (immutable).
  final DateTime addedAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  /// Typed [ReadingStatus] enum parsed from [status].
  ReadingStatus get readingStatus => ReadingStatus.fromFirestore(status);

  /// Serializes this record into a Firestore document map.
  Map<String, dynamic> toMap() {
    return {
      'mangaId': mangaId,
      'uid': uid,
      'title': title,
      'coverFileName': coverFileName,
      'status': status,
      'preferredLanguages': preferredLanguages,
      'readChapters': readChapters,
      'readVolumes': readVolumes,
      'lastReadChapter': lastReadChapter,
      'lastReadChapterId': lastReadChapterId,
      'latestKnownChapterId': latestKnownChapterId,
      'latestKnownChapterNumber': latestKnownChapterNumber,
      'addedAt': Timestamp.fromDate(addedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copies this record with modified fields.
  LibraryRecord copyWith({
    String? mangaId,
    String? uid,
    String? title,
    String? coverFileName,
    String? status,
    List<String>? preferredLanguages,
    List<String>? readChapters,
    List<String>? readVolumes,
    String? lastReadChapter,
    String? lastReadChapterId,
    String? latestKnownChapterId,
    String? latestKnownChapterNumber,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return LibraryRecord(
      mangaId: mangaId ?? this.mangaId,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      coverFileName: coverFileName ?? this.coverFileName,
      status: status ?? this.status,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      readChapters: readChapters ?? this.readChapters,
      readVolumes: readVolumes ?? this.readVolumes,
      lastReadChapter: lastReadChapter ?? this.lastReadChapter,
      lastReadChapterId: lastReadChapterId ?? this.lastReadChapterId,
      latestKnownChapterId: latestKnownChapterId ?? this.latestKnownChapterId,
      latestKnownChapterNumber:
          latestKnownChapterNumber ?? this.latestKnownChapterNumber,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    mangaId,
    uid,
    title,
    coverFileName,
    status,
    preferredLanguages,
    readChapters,
    readVolumes,
    lastReadChapter,
    lastReadChapterId,
    latestKnownChapterId,
    latestKnownChapterNumber,
    addedAt,
    updatedAt,
  ];
}
