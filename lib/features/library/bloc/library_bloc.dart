import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:koma/features/library/models/library_helpers.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';

part 'library_event.dart';
part 'library_state.dart';

/// Business logic component managing library tracking, status filtering,
/// and local title search.
class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  /// Creates a [LibraryBloc] backed by [LibraryRepository].
  new({required this.libraryRepository, this.mangaRepository})
    : super(const LibraryState()) {
    on<LibraryStarted>(_onStarted);
    on<LibraryStatusFilterChanged>(_onStatusFilterChanged);
    on<LibrarySearchQueryChanged>(_onSearchQueryChanged);
    on<LibraryRefreshRequested>(_onRefreshRequested);
    on<LibraryQuickMarkLatestReadRequested>(_onQuickMarkLatestReadRequested);
    on<LibraryStopped>(_onStopped);
  }

  /// The underlying library repository.
  final LibraryRepository libraryRepository;

  /// Optional manga repository for syncing latest release counts on Home.
  final MangaRepository? mangaRepository;

  String? _activeUid;
  var _hasTriggeredInitialSync = false;

  Future<void> _onStarted(
    LibraryStarted event,
    Emitter<LibraryState> emit,
  ) async {
    _activeUid = event.uid;
    _hasTriggeredInitialSync = false;
    emit(state.copyWith(status: LibraryStatus.loading));
    await emit.forEach<List<LibraryEntry>>(
      libraryRepository.watchLibrary(event.uid),
      onData: (entries) {
        if (!_hasTriggeredInitialSync &&
            entries.isNotEmpty &&
            mangaRepository != null) {
          _hasTriggeredInitialSync = true;
          unawaited(
            _syncLatestReleases(event.uid, entries, forceRefresh: true),
          );
        }
        return state.copyWith(
          status: LibraryStatus.success,
          allEntries: entries,
        );
      },
      onError: (error, _) => state.copyWith(
        status: LibraryStatus.failure,
        errorMessage: error.toString,
      ),
    );
  }

  Future<void> _onRefreshRequested(
    LibraryRefreshRequested event,
    Emitter<LibraryState> emit,
  ) async {
    final uid = _activeUid;
    if (uid == null || mangaRepository == null || state.allEntries.isEmpty) {
      return;
    }
    emit(state.copyWith(isRefreshing: true));
    try {
      await _syncLatestReleases(uid, state.allEntries, forceRefresh: true);
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isRefreshing: false));
      }
    }
  }

  Future<void> _syncLatestReleases(
    String uid,
    List<LibraryEntry> entries, {
    required bool forceRefresh,
  }) async {
    final repo = mangaRepository;
    if (repo == null) return;

    for (final entry in entries) {
      if (isClosed) return;
      final shouldCheck =
          entry.status == ReadingStatus.reading ||
          entry.status == ReadingStatus.planToRead ||
          entry.latestKnownChapterNumber == null;
      if (!shouldCheck) continue;

      try {
        final latest = await repo.getLatestReleasedChapter(
          entry.mangaId,
          translatedLanguages: entry.preferredLanguages.isEmpty
              ? const ['en', 'it']
              : entry.preferredLanguages,
          forceRefresh: forceRefresh,
        );
        if (isClosed || latest == null) continue;
        if (latest.chapterNumber != entry.latestKnownChapterNumber ||
            latest.id != entry.latestKnownChapterId) {
          await libraryRepository.updateLatestKnownChapter(
            uid: uid,
            mangaId: entry.mangaId,
            latestKnownChapterNumber: latest.chapterNumber,
            latestKnownChapterId: latest.id,
          );
        }
      } on Object catch (_) {
        // Ignore individual title refresh errors so other titles continue.
      }
    }
  }

  void _onStatusFilterChanged(
    LibraryStatusFilterChanged event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(selectedStatus: () => event.status));
  }

  void _onSearchQueryChanged(
    LibrarySearchQueryChanged event,
    Emitter<LibraryState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onQuickMarkLatestReadRequested(
    LibraryQuickMarkLatestReadRequested event,
    Emitter<LibraryState> emit,
  ) async {
    final uid = _activeUid ?? event.entry.uid;
    if (uid.isEmpty) return;

    final latestChapter = event.entry.latestKnownChapterNumber?.trim();
    if (latestChapter == null ||
        latestChapter.isEmpty ||
        latestChapter == 'none') {
      return;
    }

    if (state.markingReadMangaIds.contains(event.entry.mangaId)) return;

    emit(
      state.copyWith(
        markingReadMangaIds: {
          ...state.markingReadMangaIds,
          event.entry.mangaId,
        },
        quickMarkFeedback: () => null,
      ),
    );

    final rawChapterId = event.entry.latestKnownChapterId?.trim();
    final safeChapterId =
        (rawChapterId != null &&
            rawChapterId.isNotEmpty &&
            rawChapterId.length <= 36)
        ? rawChapterId
        : null;

    try {
      await libraryRepository.toggleChapterRead(
        uid: uid,
        mangaId: event.entry.mangaId,
        chapterNumber: latestChapter,
        isRead: true,
        chapterId: safeChapterId,
        mangaTitle: event.entry.title,
        coverFileName: event.entry.coverFileName,
      );
      if (isClosed) return;
      final remaining = {...state.markingReadMangaIds}
        ..remove(event.entry.mangaId);
      emit(
        state.copyWith(
          markingReadMangaIds: remaining,
          quickMarkFeedback: () => LibraryQuickMarkFeedback(
            mangaId: event.entry.mangaId,
            mangaTitle: event.entry.title,
            chapterNumber: latestChapter,
          ),
        ),
      );
    } on Object catch (_) {
      if (isClosed) return;
      final remaining = {...state.markingReadMangaIds}
        ..remove(event.entry.mangaId);
      emit(
        state.copyWith(
          markingReadMangaIds: remaining,
          quickMarkFeedback: () => LibraryQuickMarkFeedback(
            mangaId: event.entry.mangaId,
            mangaTitle: event.entry.title,
            chapterNumber: latestChapter,
            isError: true,
          ),
        ),
      );
    }
  }

  void _onStopped(LibraryStopped event, Emitter<LibraryState> emit) {
    emit(const LibraryState());
  }
}
