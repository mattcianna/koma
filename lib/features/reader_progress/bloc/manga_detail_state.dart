part of 'manga_detail_bloc.dart';

/// Loading status for the manga detail view.
enum MangaDetailStatus {
  /// Initial idle status.
  initial,

  /// Loading manga details and aggregate.
  loading,

  /// Successfully loaded details and aggregate.
  success,

  /// Error loading details or aggregate.
  failure,
}

/// State representation for the Manga Detail feature.
final class MangaDetailState extends Equatable {
  /// Creates a [MangaDetailState].
  const new({
    this.status = MangaDetailStatus.initial,
    this.mangaId = '',
    this.uid = '',
    this.preferredLocales = const ['en', 'it'],
    this.translatedLanguages = const ['en', 'it'],
    this.manga,
    this.aggregate,
    this.libraryEntry,
    this.errorMessage,
    this.pendingBulkChapter,
    this.pendingBulkUnreadChapters = const [],
    this.isBulkActionLoading = false,
  });

  /// Loading status.
  final MangaDetailStatus status;

  /// Target manga UUID.
  final String mangaId;

  /// Current user ID.
  final String uid;

  /// Preferred locales for resolving localized text.
  final List<String> preferredLocales;

  /// Translated languages for aggregate query.
  final List<String> translatedLanguages;

  /// Fetched domain [Manga] entity.
  final Manga? manga;

  /// Fetched domain [ChapterAggregate] tree.
  final ChapterAggregate? aggregate;

  /// Active user's [LibraryEntry] for this manga, if tracked.
  final LibraryEntry? libraryEntry;

  /// Optional error message on failure.
  final String? errorMessage;

  /// The target chapter for an in-flight or requested bulk read action.
  final MangaChapter? pendingBulkChapter;

  /// The computed list of unread chapter numbers preceding
  /// [pendingBulkChapter].
  final List<String> pendingBulkUnreadChapters;

  /// Whether a bulk read write operation is currently in flight.
  final bool isBulkActionLoading;

  /// Whether this manga currently exists in the user's library.
  bool get isInLibrary => libraryEntry != null;

  /// Total count of chapters marked read by the user for this manga.
  int get readChaptersCount => libraryEntry?.readChapters.length ?? 0;

  /// Total count of released chapters discovered across all volumes.
  int get totalChaptersCount => aggregate?.orderedChapters.length ?? 0;

  /// Count of released chapters not yet marked read by the user.
  int get unreadChaptersCount {
    final chapters = aggregate?.orderedChapters;
    if (chapters == null || chapters.isEmpty) return 0;
    final read = libraryEntry?.readChapters ?? const <String>{};
    return chapters.where((c) => !read.contains(c.chapterNumber)).length;
  }

  /// Copies this [MangaDetailState] with updated fields.
  MangaDetailState copyWith({
    MangaDetailStatus? status,
    String? mangaId,
    String? uid,
    List<String>? preferredLocales,
    List<String>? translatedLanguages,
    Manga? manga,
    ChapterAggregate? aggregate,
    LibraryEntry? Function()? libraryEntry,
    String? Function()? errorMessage,
    MangaChapter? Function()? pendingBulkChapter,
    List<String>? pendingBulkUnreadChapters,
    bool? isBulkActionLoading,
  }) {
    return MangaDetailState(
      status: status ?? this.status,
      mangaId: mangaId ?? this.mangaId,
      uid: uid ?? this.uid,
      preferredLocales: preferredLocales ?? this.preferredLocales,
      translatedLanguages: translatedLanguages ?? this.translatedLanguages,
      manga: manga ?? this.manga,
      aggregate: aggregate ?? this.aggregate,
      libraryEntry: libraryEntry != null ? libraryEntry() : this.libraryEntry,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      pendingBulkChapter: pendingBulkChapter != null
          ? pendingBulkChapter()
          : this.pendingBulkChapter,
      pendingBulkUnreadChapters:
          pendingBulkUnreadChapters ?? this.pendingBulkUnreadChapters,
      isBulkActionLoading: isBulkActionLoading ?? this.isBulkActionLoading,
    );
  }

  @override
  List<Object?> get props => [
    status,
    mangaId,
    uid,
    preferredLocales,
    translatedLanguages,
    manga,
    aggregate,
    libraryEntry,
    errorMessage,
    pendingBulkChapter,
    pendingBulkUnreadChapters,
    isBulkActionLoading,
  ];
}
