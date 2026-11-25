part of 'library_bloc.dart';

/// Status of the library loading process.
enum LibraryStatus {
  /// Initial idle status.
  initial,

  /// Loading library entries.
  loading,

  /// Successfully loaded library entries.
  success,

  /// Failed to load library entries.
  failure,
}

/// Outcome notification for a Home quick mark-as-read action.
final class LibraryQuickMarkFeedback extends Equatable {
  /// Creates a [LibraryQuickMarkFeedback].
  const new({
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterNumber,
    this.isError = false,
  });

  /// Identifier of the manga updated.
  final String mangaId;

  /// Title of the manga for user feedback messages.
  final String mangaTitle;

  /// Chapter number that was marked as read.
  final String chapterNumber;

  /// Whether updating the chapter failed.
  final bool isError;

  @override
  List<Object?> get props => [mangaId, mangaTitle, chapterNumber, isError];
}

/// State representation for the Library feature.
final class LibraryState extends Equatable {
  /// Creates a [LibraryState].
  const new({
    this.status = LibraryStatus.initial,
    this.allEntries = const [],
    this.selectedStatus,
    this.searchQuery = '',
    this.errorMessage,
    this.isRefreshing = false,
    this.markingReadMangaIds = const <String>{},
    this.quickMarkFeedback,
  });

  /// Current loading status.
  final LibraryStatus status;

  /// Full list of raw entries from Firestore for this user.
  final List<LibraryEntry> allEntries;

  /// Active [ReadingStatus] filter, or null for all.
  final ReadingStatus? selectedStatus;

  /// Active search query for filtering by title.
  final String searchQuery;

  /// Optional error message on failure.
  final String? errorMessage;

  /// Whether a manual/pull-to-refresh release check is currently running.
  final bool isRefreshing;

  /// Manga IDs currently executing a quick mark-as-read mutation.
  final Set<String> markingReadMangaIds;

  /// Latest outcome from a quick mark-as-read request.
  final LibraryQuickMarkFeedback? quickMarkFeedback;

  /// Returns whether the user's library contains zero entries overall.
  bool get isLibraryEmpty => allEntries.isEmpty;

  /// Whether the library should render the 3-section Home layout (when no
  /// status filter or search query is active).
  bool get isHomeSectionsView =>
      selectedStatus == null && searchQuery.trim().isEmpty;

  /// Entries belonging in the **To Read** section (`Reading` with unread
  /// chapters or `Plan to Read`).
  List<LibraryEntry> get toReadEntries => allEntries
      .where(
        (entry) =>
            (entry.status == ReadingStatus.reading &&
                calculateUnreadHint(entry) > 0) ||
            entry.status == ReadingStatus.planToRead,
      )
      .toList();

  /// Entries belonging in the **Caught Up** section (`Reading` with zero
  /// unread chapters).
  List<LibraryEntry> get caughtUpEntries => allEntries
      .where(
        (entry) =>
            entry.status == ReadingStatus.reading &&
            calculateUnreadHint(entry) == 0,
      )
      .toList();

  /// Entries belonging in the **On Hold / Finished** section (`Completed`,
  /// `On Hold`, or `Dropped`).
  List<LibraryEntry> get finishedOrPausedEntries => allEntries
      .where(
        (entry) =>
            entry.status == ReadingStatus.completed ||
            entry.status == ReadingStatus.onHold ||
            entry.status == ReadingStatus.dropped,
      )
      .toList();

  /// Returns filtered list of entries based on [selectedStatus]
  /// and [searchQuery].
  List<LibraryEntry> get filteredEntries {
    final query = searchQuery.trim().toLowerCase();
    return allEntries.where((entry) {
      if (selectedStatus != null && entry.status != selectedStatus) {
        return false;
      }
      if (query.isNotEmpty && !entry.title.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Returns whether filter criteria yielded zero results when the
  /// library is not empty.
  bool get isFilterEmpty => !isLibraryEmpty && filteredEntries.isEmpty;

  /// Copies this [LibraryState] with updated fields.
  LibraryState copyWith({
    LibraryStatus? status,
    List<LibraryEntry>? allEntries,
    ReadingStatus? Function()? selectedStatus,
    String? searchQuery,
    String? Function()? errorMessage,
    bool? isRefreshing,
    Set<String>? markingReadMangaIds,
    LibraryQuickMarkFeedback? Function()? quickMarkFeedback,
  }) {
    return LibraryState(
      status: status ?? this.status,
      allEntries: allEntries ?? this.allEntries,
      selectedStatus: selectedStatus != null
          ? selectedStatus()
          : this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      markingReadMangaIds: markingReadMangaIds ?? this.markingReadMangaIds,
      quickMarkFeedback: quickMarkFeedback != null
          ? quickMarkFeedback()
          : this.quickMarkFeedback,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allEntries,
    selectedStatus,
    searchQuery,
    errorMessage,
    isRefreshing,
    markingReadMangaIds,
    quickMarkFeedback,
  ];
}
