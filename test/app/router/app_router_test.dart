import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:koma/app/app.dart';
import 'package:koma/features/auth/auth.dart';
import 'package:koma/features/history/history.dart';
import 'package:koma/features/library/library.dart';
import 'package:koma/features/reader_progress/reader_progress.dart';
import 'package:koma/features/search/search.dart';
import 'package:koma/features/settings/settings.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notifications_repository/notifications_repository.dart';

class _MockAppBloc extends Mock implements AppBloc;

class _MockAuthRepository extends Mock implements AuthRepository;

class _MockLibraryRepository extends Mock implements LibraryRepository;

class _MockMangaRepository extends Mock implements MangaRepository;

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository;

void main() {
  group('AppRouter', () {
    late AppBloc appBloc;
    late AuthRepository authRepository;
    late LibraryRepository libraryRepository;
    late MangaRepository mangaRepository;
    late NotificationsRepository notificationsRepository;
    late StreamController<AppState> appBlocStreamController;

    const testUser = AppUser(
      uid: 'test-uid-123',
      email: 'user@test.com',
      displayName: 'Test User',
    );

    setUp(() {
      appBloc = _MockAppBloc();
      authRepository = _MockAuthRepository();
      libraryRepository = _MockLibraryRepository();
      mangaRepository = _MockMangaRepository();
      notificationsRepository = _MockNotificationsRepository();
      appBlocStreamController = StreamController<AppState>.broadcast();

      when(() => appBloc.stream)
          .thenAnswer((_) => appBlocStreamController.stream);
      when(() => appBloc.state).thenReturn(const AppState());

      when(() => authRepository.user)
          .thenAnswer((_) => Stream.value(AppUser.empty));
      when(() => authRepository.currentUser).thenReturn(AppUser.empty);

      when(
        () => libraryRepository.ensureUserProfile(
          uid: any(named: 'uid'),
          email: any(named: 'email'),
          displayName: any(named: 'displayName'),
          photoUrl: any(named: 'photoUrl'),
          uiLocale: any(named: 'uiLocale'),
          preferredLanguages: any(named: 'preferredLanguages'),
          contentRatings: any(named: 'contentRatings'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).thenAnswer(
        (_) async => UserSettingsProfile(
          uid: 'test-uid-123',
          email: 'user@test.com',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );

      when(
        () => libraryRepository.watchLibraryEntry(
          uid: any(named: 'uid'),
          mangaId: any(named: 'mangaId'),
        ),
      ).thenAnswer((_) => Stream.value(null));

      when(() => libraryRepository.watchLibrary(any()))
          .thenAnswer((_) => Stream.value(<LibraryEntry>[]));
      when(() => libraryRepository.watchReadingHistory(any()))
          .thenAnswer((_) => Stream.value(<ReadingHistoryEvent>[]));
      when(() => libraryRepository.watchUserSettings(any()))
          .thenAnswer((_) => Stream.value(null));

      when(
        () => mangaRepository.searchManga(
          query: any(named: 'query'),
          translatedLanguages: any(named: 'translatedLanguages'),
          contentRatings: any(named: 'contentRatings'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          preferredLocales: any(named: 'preferredLocales'),
        ),
      ).thenAnswer((_) async => <Manga>[]);

      when(
        () => mangaRepository.getMangaDetails(
          any(),
          preferredLocales: any(named: 'preferredLocales'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => const Manga(id: 'manga-abc', title: 'Test Manga'),
      );

      when(
        () => mangaRepository.getMangaAggregate(
          any(),
          translatedLanguages: any(named: 'translatedLanguages'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer((_) async => const ChapterAggregate(mangaId: 'manga-abc'));

      when(() => notificationsRepository.getDeviceId())
          .thenAnswer((_) async => 'test-device');
    });

    tearDown(() async {
      await appBlocStreamController.close();
    });

    Widget buildSubject(GoRouter router) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: authRepository),
          RepositoryProvider<LibraryRepository>.value(value: libraryRepository),
          RepositoryProvider<MangaRepository>.value(value: mangaRepository),
          RepositoryProvider<NotificationsRepository>.value(
            value: notificationsRepository,
          ),
        ],
        child: BlocProvider<AppBloc>.value(
          value: appBloc,
          child: MaterialApp.router(
            theme: KomaTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
    }

    testWidgets('unauthenticated user at /library is redirected to /login', (
      tester,
    ) async {
      when(() => appBloc.state).thenReturn(const AppState());

      final router = AppRouter.createRouter(
        appBloc: appBloc,
        initialLocation: '/library',
      );

      await tester.pumpWidget(buildSubject(router));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(router.state.matchedLocation, equals('/login'));
      router.dispose();
    });

    testWidgets('unauthenticated user at /manga/manga-1 redirects to /login', (
      tester,
    ) async {
      when(() => appBloc.state).thenReturn(const AppState());

      final router = AppRouter.createRouter(
        appBloc: appBloc,
        initialLocation: '/manga/manga-1',
      );

      await tester.pumpWidget(buildSubject(router));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(router.state.matchedLocation, equals('/login'));
      router.dispose();
    });

    testWidgets('authenticated user at /login is redirected to /library', (
      tester,
    ) async {
      when(() => appBloc.state).thenReturn(const AppState(user: testUser));

      final router = AppRouter.createRouter(
        appBloc: appBloc,
        initialLocation: '/login',
      );

      await tester.pumpWidget(buildSubject(router));
      await tester.pump();

      expect(find.byType(LibraryPage), findsOneWidget);
      expect(router.state.matchedLocation, equals('/library'));
      router.dispose();
    });

    testWidgets('authenticated user at / is redirected to /library', (
      tester,
    ) async {
      when(() => appBloc.state).thenReturn(const AppState(user: testUser));

      final router = AppRouter.createRouter(
        appBloc: appBloc,
        initialLocation: '/',
      );

      await tester.pumpWidget(buildSubject(router));
      await tester.pump();

      expect(find.byType(LibraryPage), findsOneWidget);
      expect(router.state.matchedLocation, equals('/library'));
      router.dispose();
    });

    testWidgets('authenticated user can navigate between bottom nav tabs', (
      tester,
    ) async {
      when(() => appBloc.state).thenReturn(const AppState(user: testUser));

      final router = AppRouter.createRouter(
        appBloc: appBloc,
        initialLocation: '/library',
      );

      await tester.pumpWidget(buildSubject(router));
      await tester.pump();

      expect(find.byType(LibraryPage), findsOneWidget);

      // Navigate to Discover
      router.go('/discover');
      await tester.pump();
      expect(find.byType(SearchPage), findsOneWidget);

      // Navigate to History
      router.go('/history');
      await tester.pump();
      expect(find.byType(HistoryPage), findsOneWidget);

      // Navigate to Settings
      router.go('/settings');
      await tester.pump();
      expect(find.byType(SettingsPage), findsOneWidget);

      router.dispose();
    });

    testWidgets('navigating to /manga/:mangaId opens MangaDetailPage', (
      tester,
    ) async {
      when(() => appBloc.state).thenReturn(const AppState(user: testUser));

      final router = AppRouter.createRouter(
        appBloc: appBloc,
        initialLocation: '/manga/manga-abc',
      );

      await tester.pumpWidget(buildSubject(router));
      await tester.pump();

      expect(find.byType(MangaDetailPage), findsOneWidget);
      router.dispose();
    });

    test(
      'GoRouterRefreshStream notifies listeners on stream emission',
      () async {
        final controller = StreamController<int>();
        var notified = false;

        final refreshStream = GoRouterRefreshStream(controller.stream)
          ..addListener(() {
            notified = true;
          });

        controller.add(1);
        await Future<void>.delayed(Duration.zero);

        expect(notified, isTrue);

        refreshStream.dispose();
        await controller.close();
      },
    );

    test('branch data constructors instantiate correctly', () {
      expect(const LibraryBranchData(), isNotNull);
      expect(const DiscoverBranchData(), isNotNull);
      expect(const HistoryBranchData(), isNotNull);
      expect(const SettingsBranchData(), isNotNull);
    });

    testWidgets('LibraryRoute onMangaTap navigates to manga detail', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => appBloc.state).thenReturn(const AppState(user: testUser));
      when(() => libraryRepository.watchLibrary(any())).thenAnswer(
        (_) => Stream.value([
          LibraryEntry(
            mangaId: 'csm-id',
            uid: 'test-uid-123',
            title: 'Chainsaw Man',
            status: ReadingStatus.reading,
            addedAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ]),
      );

      final router = AppRouter.createRouter(
        appBloc: appBloc,
        initialLocation: '/library',
      );

      await tester.pumpWidget(buildSubject(router));
      await tester.pump();

      expect(find.text('Chainsaw Man'), findsOneWidget);
      await tester.tap(find.text('Chainsaw Man'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(router.state.matchedLocation, equals('/manga/csm-id'));
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LibraryPage), findsOneWidget);
      router.dispose();
    });

    testWidgets('DiscoverRoute onMangaTap navigates to manga detail', (
      tester,
    ) async {
      when(() => appBloc.state).thenReturn(const AppState(user: testUser));
      when(
        () => mangaRepository.searchManga(
          query: any(named: 'query'),
          translatedLanguages: any(named: 'translatedLanguages'),
          contentRatings: any(named: 'contentRatings'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          preferredLocales: any(named: 'preferredLocales'),
        ),
      ).thenAnswer(
        (_) async => [const Manga(id: 'frieren-id', title: 'Frieren')],
      );

      final router = AppRouter.createRouter(
        appBloc: appBloc,
        initialLocation: '/discover',
      );

      await tester.pumpWidget(buildSubject(router));
      await tester.pump();

      expect(find.text('Frieren'), findsOneWidget);
      await tester.tap(find.text('Frieren'));
      await tester.pump();

      expect(router.state.matchedLocation, equals('/manga/frieren-id'));
      router.dispose();
    });

    testWidgets('HistoryRoute onMangaTap navigates to manga detail', (
      tester,
    ) async {
      when(() => appBloc.state).thenReturn(const AppState(user: testUser));
      when(() => libraryRepository.watchReadingHistory(any())).thenAnswer(
        (_) => Stream.value([
          ReadingHistoryEvent(
            eventId: 'evt-1',
            uid: testUser.uid,
            mangaId: 'history-manga-id',
            mangaTitle: 'History Manga',
            actionType: ReadingHistoryActionType.chapterRead,
            chapterNumbers: const ['1'],
            chaptersCount: 1,
            timestamp: DateTime.now(),
          ),
        ]),
      );

      final router = AppRouter.createRouter(
        appBloc: appBloc,
        initialLocation: '/history',
      );

      await tester.pumpWidget(buildSubject(router));
      await tester.pump();

      expect(find.text('History Manga'), findsOneWidget);
      await tester.tap(find.text('History Manga'));
      await tester.pump();

      expect(router.state.matchedLocation, equals('/manga/history-manga-id'));
      router.dispose();
    });
  });
}
