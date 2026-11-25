import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/history/history.dart';
import 'package:library_repository/library_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository;

void main() {
  group('HistoryState', () {
    test('supports value equality', () {
      expect(const HistoryState(), equals(const HistoryState()));
    });

    test('copyWith updates properties correctly', () {
      const state = HistoryState();
      final now = DateTime.now();
      final event = ReadingHistoryEvent(
        eventId: 'evt-1',
        uid: 'user-1',
        mangaId: 'manga-1',
        mangaTitle: 'Chainsaw Man',
        actionType: ReadingHistoryActionType.chapterRead,
        chapterNumbers: const ['10'],
        chaptersCount: 1,
        timestamp: now,
      );

      final updated = state.copyWith(
        status: HistoryStatus.loaded,
        events: [event],
        errorMessage: 'none',
      );

      expect(updated.status, equals(HistoryStatus.loaded));
      expect(updated.events, equals([event]));
      expect(updated.errorMessage, equals('none'));
    });
  });

  group('HistoryCubit', () {
    late LibraryRepository libraryRepository;
    late StreamController<List<ReadingHistoryEvent>> historyController;

    setUp(() {
      libraryRepository = _MockLibraryRepository();
      historyController =
          StreamController<List<ReadingHistoryEvent>>.broadcast();
      when(
        () => libraryRepository.watchReadingHistory(
          any(),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => historyController.stream);
    });

    tearDown(() async {
      await historyController.close();
    });

    test('initial state has loading status', () {
      final cubit = HistoryCubit(
        libraryRepository: libraryRepository,
        uid: 'user-123',
      );

      expect(cubit.state.status, equals(HistoryStatus.loading));
      expect(cubit.state.events, isEmpty);
      unawaited(cubit.close());
    });

    blocTest<HistoryCubit, HistoryState>(
      'emits [loaded] when history stream emits events',
      build: () =>
          HistoryCubit(libraryRepository: libraryRepository, uid: 'user-123'),
      act: (_) {
        final now = DateTime.now();
        historyController.add([
          ReadingHistoryEvent(
            eventId: 'evt-1',
            uid: 'user-123',
            mangaId: 'manga-1',
            mangaTitle: 'Frieren',
            actionType: ReadingHistoryActionType.chapterRead,
            chapterNumbers: const ['1'],
            chaptersCount: 1,
            timestamp: now,
          ),
        ]);
      },
      expect: () => [
        isA<HistoryState>()
            .having((s) => s.status, 'status', HistoryStatus.loaded)
            .having((s) => s.events.length, 'events.length', 1),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'emits [failure] when history stream throws error',
      build: () =>
          HistoryCubit(libraryRepository: libraryRepository, uid: 'user-123'),
      act: (_) {
        historyController.addError(Exception('Firestore network error'));
      },
      expect: () => [
        isA<HistoryState>()
            .having((s) => s.status, 'status', HistoryStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('Firestore network error'),
            ),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'refresh re-subscribes and emits loading before next events',
      build: () =>
          HistoryCubit(libraryRepository: libraryRepository, uid: 'user-123'),
      seed: () => const HistoryState(status: HistoryStatus.loaded),
      act: (cubit) {
        cubit.refresh();
        historyController.add([]);
      },
      expect: () => [
        isA<HistoryState>().having(
          (s) => s.status,
          'status',
          HistoryStatus.loading,
        ),
        isA<HistoryState>().having(
          (s) => s.status,
          'status',
          HistoryStatus.loaded,
        ),
      ],
    );
  });
}
