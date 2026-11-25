import 'package:equatable/equatable.dart';

/// Base event for discovery and manga search.
abstract class SearchEvent extends Equatable {
  /// Base event constructor.
  const new();

  @override
  List<Object?> get props => [];
}

/// Initial search event, triggering retrieval of popular manga.
class SearchStarted extends SearchEvent {
  /// Creates a [SearchStarted] event.
  const new();
}

/// Fired when the user modifies the search query input text.
class SearchQueryChanged extends SearchEvent {
  /// Creates a [SearchQueryChanged] event.
  const new(this.query);

  /// The updated search query text.
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Fired when the active search results are re-fetched from offset 0.
class SearchRefreshed extends SearchEvent {
  /// Creates a [SearchRefreshed] event.
  const new();
}

/// Fired when scrolling near the bottom to request the next page of results.
class SearchLoadMore extends SearchEvent {
  /// Creates a [SearchLoadMore] event.
  const new();
}

/// Fired when language or content rating preferences change.
class SearchPreferencesUpdated extends SearchEvent {
  /// Creates a [SearchPreferencesUpdated] event.
  const new({
    this.translatedLanguages,
    this.contentRatings,
    this.preferredLocales,
  });

  /// Updated list of translated languages to request.
  final List<String>? translatedLanguages;

  /// Updated list of content ratings to permit.
  final List<String>? contentRatings;

  /// Updated list of preferred locales for title resolution.
  final List<String>? preferredLocales;

  @override
  List<Object?> get props => [
    translatedLanguages,
    contentRatings,
    preferredLocales,
  ];
}
