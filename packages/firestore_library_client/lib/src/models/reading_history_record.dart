import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Reading history audit entry representing `users/{uid}/reading_history/{eventId}`.
class ReadingHistoryRecord extends Equatable {
  /// Creates a [ReadingHistoryRecord].
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

  /// Creates a [ReadingHistoryRecord] from a Firestore [DocumentSnapshot].
  factory fromDocument(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return ReadingHistoryRecord.fromMap(data, eventId: snapshot.id);
  }

  /// Deserializes a [ReadingHistoryRecord] from a raw map.
  factory fromMap(Map<String, dynamic> map, {String? eventId, String? uid}) {
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

    final chapters = parseStringList(map['chapterNumbers']);
    final count = (map['chaptersCount'] as num?)?.toInt() ?? chapters.length;

    return ReadingHistoryRecord(
      eventId: (map['eventId'] as String?) ?? eventId ?? '',
      uid: (map['uid'] as String?) ?? uid ?? '',
      mangaId: (map['mangaId'] as String?) ?? '',
      mangaTitle: (map['mangaTitle'] as String?) ?? '',
      coverFileName: map['coverFileName'] as String?,
      actionType: (map['actionType'] as String?) ?? 'chapter_read',
      chapterNumbers: chapters,
      volumeNumber: map['volumeNumber'] as String?,
      chaptersCount: count,
      timestamp: parseDateTime(map['timestamp']),
    );
  }

  /// Unique event ID matching the document ID.
  final String eventId;

  /// User Auth UID who triggered the action.
  final String uid;

  /// Canonical MangaDex Manga UUID.
  final String mangaId;

  /// Snapshot of the manga title at the time of reading.
  final String mangaTitle;

  /// Snapshot of the cover image filename.
  final String? coverFileName;

  /// Progress action type (`'chapter_read'`, `'volume_read'`,
  /// `'bulk_previous_read'`).
  final String actionType;

  /// List of chapter numbers marked in this event.
  final List<String> chapterNumbers;

  /// Volume number if [actionType] is `'volume_read'`.
  final String? volumeNumber;

  /// Total number of chapters marked in this event.
  final int chaptersCount;

  /// Event creation timestamp.
  final DateTime timestamp;

  /// Serializes this record into a Firestore document map.
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'uid': uid,
      'mangaId': mangaId,
      'mangaTitle': mangaTitle,
      'coverFileName': coverFileName,
      'actionType': actionType,
      'chapterNumbers': chapterNumbers,
      'volumeNumber': volumeNumber,
      'chaptersCount': chaptersCount,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Copies this record with modified fields.
  ReadingHistoryRecord copyWith({
    String? eventId,
    String? uid,
    String? mangaId,
    String? mangaTitle,
    String? coverFileName,
    String? actionType,
    List<String>? chapterNumbers,
    String? volumeNumber,
    int? chaptersCount,
    DateTime? timestamp,
  }) {
    return ReadingHistoryRecord(
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
