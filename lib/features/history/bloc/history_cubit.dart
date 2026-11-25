import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:koma/features/history/bloc/history_state.dart';
import 'package:library_repository/library_repository.dart';

/// Cubit managing real-time reading history audit logs for a given user.
class HistoryCubit extends Cubit<HistoryState> {
  /// Creates a [HistoryCubit] and starts watching reading history for [uid].
  new({required this.libraryRepository, required this.uid, this.limit = 50})
    : super(const HistoryState(status: HistoryStatus.loading)) {
    _subscribe();
  }

  /// The repository used to fetch reading history records.
  final LibraryRepository libraryRepository;

  /// The user ID whose history is being watched.
  final String uid;

  /// The maximum number of historical events to fetch.
  final int limit;

  StreamSubscription<List<ReadingHistoryEvent>>? _subscription;

  void _subscribe() {
    unawaited(_subscription?.cancel());
    _subscription = libraryRepository
        .watchReadingHistory(uid, limit: limit)
        .listen(
          (events) => emit(
            state.copyWith(status: HistoryStatus.loaded, events: events),
          ),
          onError: (Object error, StackTrace stackTrace) => emit(
            state.copyWith(
              status: HistoryStatus.failure,
              errorMessage: error.toString(),
            ),
          ),
        );
  }

  /// Refreshes the reading history stream.
  void refresh() {
    emit(state.copyWith(status: HistoryStatus.loading));
    _subscribe();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
