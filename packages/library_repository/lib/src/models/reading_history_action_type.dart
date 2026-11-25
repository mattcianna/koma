/// Progress action types recorded in user reading history.
enum ReadingHistoryActionType {
  /// A single chapter was read or toggled.
  chapterRead('chapter_read'),

  /// An entire volume was marked as read.
  volumeRead('volume_read'),

  /// Previous chapters were marked as read in bulk.
  bulkPreviousRead('bulk_previous_read');

  new(this.value);

  /// Canonical string value stored in Cloud Firestore.
  final String value;

  /// Resolves a serialized [value] string into a [ReadingHistoryActionType].
  ///
  /// Defaults to [ReadingHistoryActionType.chapterRead] if [value] is null or
  /// unrecognized.
  static ReadingHistoryActionType fromValue(String? value) {
    return ReadingHistoryActionType.values.firstWhere(
      (element) => element.value == value,
      orElse: () => ReadingHistoryActionType.chapterRead,
    );
  }
}
