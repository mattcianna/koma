import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';

part 'manga_detail_event.dart';
part 'manga_detail_state.dart';

/// Business logic component managing manga metadata, aggregate chapter tree,
/// and library progress synchronization.
class MangaDetailBloc extends Bloc<MangaDetailEvent, MangaDetailState> {
  /// Creates a [MangaDetailBloc].
  new({required this.mangaRepository, required this.libraryRepository})
    : super(const MangaDetailState()) {
    on<MangaDetailStarted>(_onStarted);
    on<MangaDetailRefreshed>(_onRefreshed);
    on<_MangaDetailLibraryEntryUpdated>(_onLibraryEntryUpdated);
    on<MangaDetailAddedToLibrary>(_onAddedToLibrary);
    on<MangaDetailStatusChanged>(_onStatusChanged);
    on<MangaDetailRemovedFromLibrary>(_onRemovedFromLibrary);
    on<MangaDetailChapterToggled>(_onChapterToggled);
    on<MangaDetailVolumeMarkedRead>(_onVolumeMarkedRead);
    on<MangaDetailBulkPreviousRequested>(_onBulkPreviousRequested);
    on<MangaDetailBulkPreviousConfirmed>(_onBulkPreviousConfirmed);
    on<MangaDetailBulkPreviousDismissed>(_onBulkPreviousDismissed);
    on<MangaDetailCatchUpRequested>(_onCatchUpRequested);
  }

  /// The underlying manga repository.
  final MangaRepository mangaRepository;

  /// The underlying library repository.
  final LibraryRepository libraryRepository;
  StreamSubscription<LibraryEntry?>? _librarySubscription;

  Future<void> _onStarted(
    MangaDetailStarted event,
    Emitter<MangaDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        status: MangaDetailStatus.loading,
        mangaId: event.mangaId,
        uid: event.uid,
        preferredLocales: event.preferredLocales,
        translatedLanguages: event.translatedLanguages,
      ),
    );

    await _librarySubscription?.cancel();
    _librarySubscription = libraryRepository
        .watchLibraryEntry(uid: event.uid, mangaId: event.mangaId)
        .listen(
          (entry) => add(_MangaDetailLibraryEntryUpdated(entry)),
          onError: (Object _) {
            // Error in library entry stream does not break metadata loading.
          },
        );

    try {
      final results = await Future.wait([
        mangaRepository.getMangaDetails(
          event.mangaId,
          preferredLocales: event.preferredLocales,
        ),
        mangaRepository.getMangaAggregate(
          event.mangaId,
          translatedLanguages: event.translatedLanguages,
        ),
      ]);

      final aggregate = results[1] as ChapterAggregate;
      emit(
        state.copyWith(
          status: MangaDetailStatus.success,
          manga: results[0] as Manga,
          aggregate: aggregate,
        ),
      );
      await _syncLatestKnownFromAggregate(aggregate);
    } on Object catch (error) {
      emit(
        state.copyWith(
          status: MangaDetailStatus.failure,
          errorMessage: error.toString,
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    MangaDetailRefreshed event,
    Emitter<MangaDetailState> emit,
  ) async {
    if (state.mangaId.isEmpty) return;
    try {
      final results = await Future.wait([
        mangaRepository.getMangaDetails(
          state.mangaId,
          preferredLocales: state.preferredLocales,
          forceRefresh: true,
        ),
        mangaRepository.getMangaAggregate(
          state.mangaId,
          translatedLanguages: state.translatedLanguages,
          forceRefresh: true,
        ),
      ]);

      final aggregate = results[1] as ChapterAggregate;
      emit(state.copyWith(manga: results[0] as Manga, aggregate: aggregate));
      await _syncLatestKnownFromAggregate(aggregate);
    } on Object catch (_) {
      // Retain existing state on background refresh failure.
    }
  }

  void _onLibraryEntryUpdated(
    _MangaDetailLibraryEntryUpdated event,
    Emitter<MangaDetailState> emit,
  ) {
    emit(state.copyWith(libraryEntry: () => event.entry));
    final aggregate = state.aggregate;
    if (event.entry != null && aggregate != null) {
      unawaited(_syncLatestKnownFromAggregate(aggregate));
    }
  }

  Future<void> _onAddedToLibrary(
    MangaDetailAddedToLibrary event,
    Emitter<MangaDetailState> emit,
  ) async {
    final latest = _latestNumberedChapter(state.aggregate);
    final entry = _buildNewEntry(event.status, latest: latest);

    await libraryRepository.addOrUpdateLibraryEntry(
      uid: state.uid,
      entry: entry,
    );
  }

  LibraryEntry _buildNewEntry(ReadingStatus status, {MangaChapter? latest}) {
    final now = DateTime.now();
    return LibraryEntry(
      mangaId: state.mangaId,
      uid: state.uid,
      title: state.manga?.title ?? 'Untitled Manga',
      coverFileName: state.manga?.coverFileName,
      status: status,
      preferredLanguages: state.translatedLanguages.isNotEmpty
          ? state.translatedLanguages
          : const ['en', 'it'],
      latestKnownChapterNumber: latest?.chapterNumber,
      latestKnownChapterId: latest?.id,
      addedAt: now,
      updatedAt: now,
    );
  }

  MangaChapter? _latestNumberedChapter(ChapterAggregate? aggregate) {
    final chapters = aggregate?.orderedChapters;
    if (chapters == null || chapters.isEmpty) return null;
    for (var i = chapters.length - 1; i >= 0; i--) {
      if (chapters[i].chapterNumber != 'none') return chapters[i];
    }
    return chapters.last;
  }

  Future<void> _syncLatestKnownFromAggregate(ChapterAggregate aggregate) async {
    final entry = state.libraryEntry;
    final latest = _latestNumberedChapter(aggregate);
    if (entry == null || latest == null) return;
    if (entry.latestKnownChapterNumber == latest.chapterNumber &&
        entry.latestKnownChapterId == latest.id) {
      return;
    }

    try {
      await libraryRepository.updateLatestKnownChapter(
        uid: state.uid,
        mangaId: state.mangaId,
        latestKnownChapterNumber: latest.chapterNumber,
        latestKnownChapterId: latest.id,
      );
    } on Object catch (_) {
      // Best-effort metadata sync; never interrupts reading UI.
    }
  }

  Future<void> _onStatusChanged(
    MangaDetailStatusChanged event,
    Emitter<MangaDetailState> emit,
  ) async {
    if (state.libraryEntry != null) {
      await libraryRepository.updateStatus(
        uid: state.uid,
        mangaId: state.mangaId,
        status: event.status,
      );
    } else {
      add(MangaDetailAddedToLibrary(event.status));
    }
  }

  Future<void> _onRemovedFromLibrary(
    MangaDetailRemovedFromLibrary event,
    Emitter<MangaDetailState> emit,
  ) async {
    await libraryRepository.removeFromLibrary(
      uid: state.uid,
      mangaId: state.mangaId,
    );
  }

  Future<void> _onChapterToggled(
    MangaDetailChapterToggled event,
    Emitter<MangaDetailState> emit,
  ) async {
    final rawId = event.chapter.id.trim();
    final safeChapterId = (rawId.isNotEmpty && rawId.length <= 36)
        ? rawId
        : null;

    await libraryRepository.toggleChapterRead(
      uid: state.uid,
      mangaId: state.mangaId,
      chapterNumber: event.chapter.chapterNumber,
      isRead: event.isRead,
      chapterId: safeChapterId,
      mangaTitle: state.manga?.title,
      coverFileName: state.manga?.coverFileName,
    );
  }

  Future<void> _onVolumeMarkedRead(
    MangaDetailVolumeMarkedRead event,
    Emitter<MangaDetailState> emit,
  ) async {
    final chapters = event.volume.chapters;
    await libraryRepository.markVolumeRead(
      uid: state.uid,
      mangaId: state.mangaId,
      volumeNumber: event.volume.volumeNumber,
      volumeChapterNumbers: chapters.map((c) => c.chapterNumber).toList(),
      mangaTitle: state.manga?.title,
      coverFileName: state.manga?.coverFileName,
      lastChapterNumberInVolume: chapters.isNotEmpty
          ? chapters.last.chapterNumber
          : null,
      lastChapterIdInVolume: chapters.isNotEmpty ? chapters.last.id : null,
    );
  }

  void _onBulkPreviousRequested(
    MangaDetailBulkPreviousRequested event,
    Emitter<MangaDetailState> emit,
  ) {
    final aggregate = state.aggregate;
    final alreadyRead = state.libraryEntry?.readChapters ?? const <String>{};
    if (aggregate == null) return;

    final unreadList = mangaRepository.computePreviousUnreadChapters(
      aggregate: aggregate,
      upToChapterNumber: event.targetChapter.chapterNumber,
      alreadyReadChapters: alreadyRead,
    );

    emit(
      state.copyWith(
        pendingBulkChapter: () => event.targetChapter,
        pendingBulkUnreadChapters: unreadList,
      ),
    );
  }

  Future<void> _onBulkPreviousConfirmed(
    MangaDetailBulkPreviousConfirmed event,
    Emitter<MangaDetailState> emit,
  ) async {
    final target = state.pendingBulkChapter;
    final unreadList = state.pendingBulkUnreadChapters;
    if (target == null || unreadList.isEmpty) {
      emit(
        state.copyWith(
          pendingBulkChapter: () => null,
          pendingBulkUnreadChapters: const [],
        ),
      );
      return;
    }

    emit(state.copyWith(isBulkActionLoading: true));
    try {
      await libraryRepository.markPreviousAsRead(
        uid: state.uid,
        mangaId: state.mangaId,
        targetChapterNumber: target.chapterNumber,
        targetChapterId: target.id,
        previousChapterNumbersToMark: unreadList,
        mangaTitle: state.manga?.title,
        coverFileName: state.manga?.coverFileName,
      );
    } finally {
      emit(
        state.copyWith(
          pendingBulkChapter: () => null,
          pendingBulkUnreadChapters: const [],
          isBulkActionLoading: false,
        ),
      );
    }
  }

  void _onBulkPreviousDismissed(
    MangaDetailBulkPreviousDismissed event,
    Emitter<MangaDetailState> emit,
  ) {
    emit(
      state.copyWith(
        pendingBulkChapter: () => null,
        pendingBulkUnreadChapters: const [],
      ),
    );
  }

  Future<void> _onCatchUpRequested(
    MangaDetailCatchUpRequested event,
    Emitter<MangaDetailState> emit,
  ) async {
    final aggregate = state.aggregate;
    if (aggregate == null || aggregate.orderedChapters.isEmpty) return;

    final target =
        _latestNumberedChapter(aggregate) ?? aggregate.orderedChapters.last;
    final alreadyRead = state.libraryEntry?.readChapters ?? const <String>{};
    final unreadList = mangaRepository.computePreviousUnreadChapters(
      aggregate: aggregate,
      upToChapterNumber: target.chapterNumber,
      alreadyReadChapters: alreadyRead,
    );

    emit(state.copyWith(isBulkActionLoading: true));
    try {
      if (state.libraryEntry == null) {
        await libraryRepository.addOrUpdateLibraryEntry(
          uid: state.uid,
          entry: _buildNewEntry(ReadingStatus.reading, latest: target),
        );
      }

      if (unreadList.isNotEmpty) {
        await libraryRepository.markPreviousAsRead(
          uid: state.uid,
          mangaId: state.mangaId,
          targetChapterNumber: target.chapterNumber,
          targetChapterId: target.id,
          previousChapterNumbersToMark: unreadList,
          mangaTitle: state.manga?.title,
          coverFileName: state.manga?.coverFileName,
        );
      }

      if (state.libraryEntry != null &&
          state.libraryEntry!.status != ReadingStatus.reading) {
        await libraryRepository.updateStatus(
          uid: state.uid,
          mangaId: state.mangaId,
          status: ReadingStatus.reading,
        );
      }

      await libraryRepository.updateLatestKnownChapter(
        uid: state.uid,
        mangaId: state.mangaId,
        latestKnownChapterNumber: target.chapterNumber,
        latestKnownChapterId: target.id,
      );
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isBulkActionLoading: false));
      }
    }
  }

  @override
  Future<void> close() {
    unawaited(_librarySubscription?.cancel());
    return super.close();
  }
}
