import 'package:equatable/equatable.dart';
import 'package:manga_repository/manga_repository.dart';

/// Loading status for discovery search.
enum SearchStatus {
  /// Initial idle state before any search request is initiated.
  initial,

  /// Initial or query change search request in flight.
  loading,

  /// Search completed successfully.
  success,

  /// Search request failed.
  failure,
}

/// Typed categories for search failures.
enum SearchErrorKind {
  /// MangaDex rate limits were exceeded (HTTP 429).
  rateLimit,

  /// Network connectivity failure prevented search.
  network,

  /// Generic or unexpected repository error occurred.
  generic,
}

/// {@template search_state}
/// State representation for manga search and discovery.
/// {@endtemplate}
class SearchState extends Equatable {
  /// {@macro search_state}
  const new({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.hasMore = false,
    this.offset = 0,
    this.isLoadingMore = false,
    this.errorKind,
    this.translatedLanguages = const ['en', 'it'],
    this.contentRatings = const ['safe', 'suggestive'],
    this.preferredLocales = const ['en', 'it'],
  });

  /// The active request status.
  final SearchStatus status;

  /// The current query string.
  final String query;

  /// The accumulated list of fetched [Manga] entities.
  final List<Manga> results;

  /// Whether additional results can be paginated.
  final bool hasMore;

  /// The current pagination offset for subsequent fetches.
  final int offset;

  /// Whether an append-pagination request is actively in-flight.
  final bool isLoadingMore;

  /// Categorized failure kind if [status] is [SearchStatus.failure].
  final SearchErrorKind? errorKind;

  /// Filter languages requested from MangaDex.
  final List<String> translatedLanguages;

  /// Filter content ratings requested from MangaDex.
  final List<String> contentRatings;

  /// Preferred locales for resolving localized manga titles.
  final List<String> preferredLocales;

  /// Whether the results represent popular manga rather than a user query.
  bool get isPopular => query.trim().isEmpty;

  /// Whether the primary search is loading.
  bool get isLoading => status == SearchStatus.loading;

  /// Whether the search succeeded.
  bool get isSuccess => status == SearchStatus.success;

  /// Whether the search failed.
  bool get isFailure => status == SearchStatus.failure;

  /// Creates a copy of this state with updated attributes.
  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Manga>? results,
    bool? hasMore,
    int? offset,
    bool? isLoadingMore,
    SearchErrorKind? Function()? errorKind,
    List<String>? translatedLanguages,
    List<String>? contentRatings,
    List<String>? preferredLocales,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorKind: errorKind != null ? errorKind() : this.errorKind,
      translatedLanguages: translatedLanguages ?? this.translatedLanguages,
      contentRatings: contentRatings ?? this.contentRatings,
      preferredLocales: preferredLocales ?? this.preferredLocales,
    );
  }

  @override
  List<Object?> get props => [
    status,
    query,
    results,
    hasMore,
    offset,
    isLoadingMore,
    errorKind,
    translatedLanguages,
    contentRatings,
    preferredLocales,
  ];
}
