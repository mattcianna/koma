import 'package:equatable/equatable.dart';
import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:library_repository/src/models/reading_history_action_type.dart';

/// Domain model representing an immutable reading history audit event in Koma.
class ReadingHistoryEvent extends Equatable {
  /// Creates a [ReadingHistoryEvent].
  const new({
    required this.eventId,
    required this.uid,
    required this.mangaId,
    required this.mangaTitle,
    required this.actionType,
    required this.chapterNumbers,
    required this.chaptersCount,
    required this.timestamp,
    this.coverFileName,
    this.volumeNumber,
  });

  /// Factory constructor to map from a data layer [ReadingHistoryRecord].
  factory fromRecord(ReadingHistoryRecord record) {
    return ReadingHistoryEvent(
      eventId: record.eventId,
      uid: record.uid,
      mangaId: record.mangaId,
      mangaTitle: record.mangaTitle,
      coverFileName: record.coverFileName,
      actionType: ReadingHistoryActionType.fromValue(record.actionType),
      chapterNumbers: record.chapterNumbers,
      volumeNumber: record.volumeNumber,
      chaptersCount: record.chaptersCount,
      timestamp: record.timestamp,
    );
  }

  /// Unique event ID matching the Firestore document ID.
  final String eventId;

  /// User Auth UID who triggered the action.
  final String uid;

  /// Canonical MangaDex Manga UUID.
  final String mangaId;

  /// Snapshot of the manga title at the time of reading.
  final String mangaTitle;

  /// Snapshot of the cover image filename.
  final String? coverFileName;

  /// Progress action type.
  final ReadingHistoryActionType actionType;

  /// List of chapter numbers marked in this event.
  final List<String> chapterNumbers;

  /// Volume number if [actionType] is [ReadingHistoryActionType.volumeRead].
  final String? volumeNumber;

  /// Total number of chapters marked in this event.
  final int chaptersCount;

  /// Event execution timestamp (immutable).
  final DateTime timestamp;

  /// Converts this event into a data layer [ReadingHistoryRecord].
  ReadingHistoryRecord toRecord() {
    return ReadingHistoryRecord(
      eventId: eventId,
      uid: uid,
      mangaId: mangaId,
      mangaTitle: mangaTitle,
      coverFileName: coverFileName,
      actionType: actionType.value,
      chapterNumbers: chapterNumbers,
      volumeNumber: volumeNumber,
      chaptersCount: chaptersCount,
      timestamp: timestamp,
    );
  }

  /// Copies this [ReadingHistoryEvent] with optionally replaced fields.
  ReadingHistoryEvent copyWith({
    String? eventId,
    String? uid,
    String? mangaId,
    String? mangaTitle,
    String? coverFileName,
    ReadingHistoryActionType? actionType,
    List<String>? chapterNumbers,
    String? volumeNumber,
    int? chaptersCount,
    DateTime? timestamp,
  }) {
    return ReadingHistoryEvent(
      eventId: eventId ?? this.eventId,
      uid: uid ?? this.uid,
      mangaId: mangaId ?? this.mangaId,
      mangaTitle: mangaTitle ?? this.mangaTitle,
      coverFileName: coverFileName ?? this.coverFileName,
      actionType: actionType ?? this.actionType,
      chapterNumbers: chapterNumbers ?? this.chapterNumbers,
      volumeNumber: volumeNumber ?? this.volumeNumber,
      chaptersCount: chaptersCount ?? this.chaptersCount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    eventId,
    uid,
    mangaId,
    mangaTitle,
    coverFileName,
    actionType,
    chapterNumbers,
    volumeNumber,
    chaptersCount,
    timestamp,
  ];
}
