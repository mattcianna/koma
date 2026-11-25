import 'package:equatable/equatable.dart';
import 'package:library_repository/library_repository.dart';

/// Status of the reading history audit feed.
enum HistoryStatus {
  /// Initial state before history stream is loaded.
  initial,

  /// Currently loading reading history events.
  loading,

  /// Reading history events successfully loaded.
  loaded,

  /// An error occurred while loading reading history events.
  failure,
}

/// State for the reading history feature.
class HistoryState extends Equatable {
  /// Creates a [HistoryState].
  const new({
    this.status = HistoryStatus.initial,
    this.events = const [],
    this.errorMessage,
  });

  /// The current status of the history feed.
  final HistoryStatus status;

  /// The list of reading history audit events, ordered descending.
  final List<ReadingHistoryEvent> events;

  /// Optional error message if loading failed.
  final String? errorMessage;

  /// Copies this [HistoryState] with optional replacement fields.
  HistoryState copyWith({
    HistoryStatus? status,
    List<ReadingHistoryEvent>? events,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      events: events ?? this.events,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, events, errorMessage];
}
