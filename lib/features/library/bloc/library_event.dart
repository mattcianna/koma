part of 'library_bloc.dart';

/// Base class for all [LibraryEvent]s.
sealed class LibraryEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Dispatched when the library page initializes or requests subscription.
final class LibraryStarted extends LibraryEvent {
  /// Creates a [LibraryStarted] event.
  const new({required this.uid});

  /// The user ID to watch the library for.
  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Dispatched when the user selects or deselects a status filter chip.
final class LibraryStatusFilterChanged extends LibraryEvent {
  /// Creates a [LibraryStatusFilterChanged] event.
  const new(this.status);

  /// The selected [ReadingStatus], or `null` for all.
  final ReadingStatus? status;

  @override
  List<Object?> get props => [status];
}

/// Dispatched when the search text in the filter field changes.
final class LibrarySearchQueryChanged extends LibraryEvent {
  /// Creates a [LibrarySearchQueryChanged] event.
  const new(this.query);

  /// The filter search query string.
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Dispatched when the user pulls to refresh or requests a live release check.
final class LibraryRefreshRequested extends LibraryEvent {
  /// Creates a [LibraryRefreshRequested] event.
  const new();
}

/// Dispatched when the user taps the quick-read button on a Home card.
final class LibraryQuickMarkLatestReadRequested extends LibraryEvent {
  /// Creates a [LibraryQuickMarkLatestReadRequested] event.
  const new(this.entry);

  /// The library entry whose latest known chapter should be marked as read.
  final LibraryEntry entry;

  @override
  List<Object?> get props => [entry];
}

/// Dispatched when the library view stops or closes its subscription.
final class LibraryStopped extends LibraryEvent {
  /// Creates a [LibraryStopped] event.
  const new();
}
