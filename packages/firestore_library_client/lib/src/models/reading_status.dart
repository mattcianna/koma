/// Reading status enum for manga tracking in Koma.
enum ReadingStatus {
  /// Actively reading the manga.
  reading('Reading'),

  /// Planned to read in the future.
  planToRead('Plan to Read'),

  /// Fully completed the manga.
  completed('Completed'),

  /// Reading temporarily placed on hold.
  onHold('On Hold'),

  /// Discontinued / dropped reading.
  dropped('Dropped');

  new(this.firestoreValue);

  /// Canonical string representation stored in Cloud Firestore.
  final String firestoreValue;

  /// Resolves a [firestoreValue] string into a [ReadingStatus].
  ///
  /// Defaults to [ReadingStatus.planToRead] if [value] is null or unrecognized.
  static ReadingStatus fromFirestore(String? value) {
    return ReadingStatus.values.firstWhere(
      (element) => element.firestoreValue == value,
      orElse: () => ReadingStatus.planToRead,
    );
  }
}
