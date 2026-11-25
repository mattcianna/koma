import 'package:equatable/equatable.dart';
import 'package:firestore_library_client/firestore_library_client.dart';

/// Domain model representing a tracked manga entry in the user's library.
class LibraryEntry extends Equatable {
  /// Creates a [LibraryEntry].
  const new({
    required this.mangaId,
    required this.uid,
    required this.title,
    required this.status,
    required this.addedAt,
    required this.updatedAt,
    this.coverFileName,
    this.preferredLanguages = const ['en', 'it'],
    this.readChapters = const <String>{},
    this.readVolumes = const [],
    this.lastReadChapter,
    this.lastReadChapterId,
    this.latestKnownChapterId,
    this.latestKnownChapterNumber,
  });

  /// Factory constructor to map from a data layer [LibraryRecord].
  factory fromRecord(LibraryRecord record) {
    return LibraryEntry(
      mangaId: record.mangaId,
      uid: record.uid,
      title: record.title,
      coverFileName: record.coverFileName,
      status: record.readingStatus,
      preferredLanguages: record.preferredLanguages,
      readChapters: record.readChapters.toSet(),
      readVolumes: record.readVolumes,
      lastReadChapter: record.lastReadChapter,
      lastReadChapterId: record.lastReadChapterId,
      latestKnownChapterId: record.latestKnownChapterId,
      latestKnownChapterNumber: record.latestKnownChapterNumber,
      addedAt: record.addedAt,
      updatedAt: record.updatedAt,
    );
  }

  /// Canonical MangaDex Manga UUID v4 matching the document ID.
  final String mangaId;

  /// Parent user's Firebase Auth UID.
  final String uid;

  /// Primary manga title.
  final String title;

  /// Cover art filename on MangaDex CDN (e.g. `uuid.jpg`).
  final String? coverFileName;

  /// Current reading progress status.
  final ReadingStatus status;

  /// Denormalized scanlation language preferences.
  final List<String> preferredLanguages;

  /// Canonical chapter numbers/keys marked read by the user.
  final Set<String> readChapters;

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

  /// Returns whether a specific [chapterNumber] has been read.
  bool isChapterRead(String chapterNumber) =>
      readChapters.contains(chapterNumber);

  /// Returns whether a specific [volumeNumber] has been marked read.
  bool isVolumeRead(String volumeNumber) => readVolumes.contains(volumeNumber);

  /// Converts this entry into a data layer [LibraryRecord].
  LibraryRecord toRecord() {
    return LibraryRecord(
      mangaId: mangaId,
      uid: uid,
      title: title,
      coverFileName: coverFileName,
      status: status.firestoreValue,
      preferredLanguages: preferredLanguages,
      readChapters: readChapters.toList(),
      readVolumes: readVolumes,
      lastReadChapter: lastReadChapter,
      lastReadChapterId: lastReadChapterId,
      latestKnownChapterId: latestKnownChapterId,
      latestKnownChapterNumber: latestKnownChapterNumber,
      addedAt: addedAt,
      updatedAt: updatedAt,
    );
  }

  /// Copies this [LibraryEntry] with optionally replaced fields.
  LibraryEntry copyWith({
    String? mangaId,
    String? uid,
    String? title,
    String? coverFileName,
    ReadingStatus? status,
    List<String>? preferredLanguages,
    Set<String>? readChapters,
    List<String>? readVolumes,
    String? lastReadChapter,
    String? lastReadChapterId,
    String? latestKnownChapterId,
    String? latestKnownChapterNumber,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return LibraryEntry(
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
