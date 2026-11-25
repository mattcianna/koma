import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:koma/features/search/bloc/search_event.dart';
import 'package:koma/features/search/bloc/search_state.dart';
import 'package:manga_repository/manga_repository.dart';

/// {@template search_bloc}
/// Bloc coordinating MangaDex title searches, pagination, and debounce logic.
/// {@endtemplate}
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  /// {@macro search_bloc}
  new({
    required this.mangaRepository,
    Duration debounceDuration = const Duration(milliseconds: 350),
    List<String> translatedLanguages = const ['en', 'it'],
    List<String> contentRatings = const ['safe', 'suggestive'],
    List<String> preferredLocales = const ['en', 'it'],
  }) : super(
         SearchState(
           translatedLanguages: translatedLanguages,
           contentRatings: contentRatings,
           preferredLocales: preferredLocales,
         ),
       ) {
    on<SearchStarted>(_onStarted);
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: _debounce(debounceDuration),
    );
    on<SearchRefreshed>(_onRefreshed);
    on<SearchLoadMore>(_onLoadMore);
    on<SearchPreferencesUpdated>(_onPreferencesUpdated);
  }

  /// The underlying manga repository.
  final MangaRepository mangaRepository;

  /// Default number of items requested per page.
  static const int pageSize = 20;

  static EventTransformer<Event> _debounce<Event>(Duration duration) {
    if (duration == Duration.zero) {
      return (events, mapper) => events.asyncExpand(mapper);
    }
    return (events, mapper) {
      return _DebounceStreamTransformer<Event>(duration)
          .bind(events)
          .asyncExpand(mapper);
    };
  }

  Future<void> _onStarted(
    SearchStarted event,
    Emitter<SearchState> emit,
  ) async {
    await _fetchInitial(emit, query: state.query);
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query == state.query && state.status == SearchStatus.success) {
      return;
    }
    await _fetchInitial(emit, query: event.query);
  }

  Future<void> _onRefreshed(
    SearchRefreshed event,
    Emitter<SearchState> emit,
  ) async {
    await _fetchInitial(emit, query: state.query);
  }

  Future<void> _fetchInitial(
    Emitter<SearchState> emit, {
    required String query,
    List<String>? translatedLanguages,
    List<String>? contentRatings,
    List<String>? preferredLocales,
  }) async {
    final langs = translatedLanguages ?? state.translatedLanguages;
    final ratings = contentRatings ?? state.contentRatings;
    final locales = preferredLocales ?? state.preferredLocales;

    emit(
      state.copyWith(
        status: SearchStatus.loading,
        query: query,
        errorKind: () => null,
        offset: 0,
        translatedLanguages: langs,
        contentRatings: ratings,
        preferredLocales: locales,
      ),
    );

    final trimmed = query.trim();
    try {
      final results = await mangaRepository.searchManga(
        query: trimmed.isEmpty ? null : trimmed,
        translatedLanguages: langs,
        contentRatings: ratings,
        preferredLocales: locales,
      );

      emit(
        state.copyWith(
          status: SearchStatus.success,
          results: results,
          offset: results.length,
          hasMore: results.length >= pageSize,
          errorKind: () => null,
        ),
      );
    } on MangaRateLimitException {
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorKind: () => SearchErrorKind.rateLimit,
        ),
      );
    } on MangaNetworkException {
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorKind: () => SearchErrorKind.network,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorKind: () => SearchErrorKind.generic,
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    SearchLoadMore event,
    Emitter<SearchState> emit,
  ) async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.status != SearchStatus.success) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    final trimmed = state.query.trim();
    try {
      final results = await mangaRepository.searchManga(
        query: trimmed.isEmpty ? null : trimmed,
        offset: state.offset,
        translatedLanguages: state.translatedLanguages,
        contentRatings: state.contentRatings,
        preferredLocales: state.preferredLocales,
      );

      final combined = [...state.results, ...results];
      emit(
        state.copyWith(
          isLoadingMore: false,
          results: combined,
          offset: state.offset + results.length,
          hasMore: results.length >= pageSize,
        ),
      );
    } on Object {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onPreferencesUpdated(
    SearchPreferencesUpdated event,
    Emitter<SearchState> emit,
  ) async {
    await _fetchInitial(
      emit,
      query: state.query,
      translatedLanguages: event.translatedLanguages,
      contentRatings: event.contentRatings,
      preferredLocales: event.preferredLocales,
    );
  }
}

class _DebounceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  const new(this.duration);

  final Duration duration;

  @override
  Stream<T> bind(Stream<T> stream) {
    Timer? timer;
    StreamController<T>? controller;
    StreamSubscription<T>? subscription;

    controller = StreamController<T>(
      onListen: () {
        subscription = stream.listen(
          (data) {
            timer?.cancel();
            timer = Timer(duration, () {
              if (controller != null && !controller.isClosed) {
                controller.add(data);
              }
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            controller?.addError(error, stackTrace);
          },
          onDone: () {
            timer?.cancel();
            unawaited(controller?.close());
          },
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () {
        timer?.cancel();
        return subscription?.cancel();
      },
    );

    return controller.stream;
  }
}
