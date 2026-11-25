import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:koma/app/app.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notifications_repository/notifications_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

class _MockLibraryRepository extends Mock implements LibraryRepository;

class _MockMangaRepository extends Mock implements MangaRepository;

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository;

class _MockAppBloc extends Mock implements AppBloc;

void main() {
  group('KomaApp', () {
    late AuthRepository authRepository;
    late LibraryRepository libraryRepository;
    late MangaRepository mangaRepository;
    late NotificationsRepository notificationsRepository;
    late AppBloc appBloc;
    late StreamController<AppState> appBlocStreamController;

    const testUser = AppUser(
      uid: 'user-001',
      email: 'user@test.com',
      displayName: 'Koma Tester',
    );

    setUp(() {
      authRepository = _MockAuthRepository();
      libraryRepository = _MockLibraryRepository();
      mangaRepository = _MockMangaRepository();
      notificationsRepository = _MockNotificationsRepository();
      appBloc = _MockAppBloc();
      appBlocStreamController = StreamController<AppState>.broadcast();

      when(() => authRepository.user).thenAnswer((_) => Stream.value(testUser));
      when(() => authRepository.currentUser).thenReturn(testUser);

      when(() => libraryRepository.watchUserSettings(any()))
          .thenAnswer((_) => Stream.value(null));

      when(() => appBloc.stream)
          .thenAnswer((_) => appBlocStreamController.stream);
      when(() => appBloc.state).thenReturn(const AppState(user: testUser));
      when(() => appBloc.close()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await appBlocStreamController.close();
    });

    testWidgets('renders MaterialApp with router and provided repositories', (
      tester,
    ) async {
      final dummyRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('Root Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        KomaApp(
          authRepository: authRepository,
          mangaRepository: mangaRepository,
          libraryRepository: libraryRepository,
          notificationsRepository: notificationsRepository,
          appBloc: appBloc,
          router: dummyRouter,
        ),
      );
      await tester.pump();

      expect(find.text('Root Screen'), findsOneWidget);
      dummyRouter.dispose();
    });

    testWidgets(
      'resolves MaterialApp locale from standard OS locale hierarchy',
      (tester) async {
        tester.platformDispatcher.localesTestValue = const [
          Locale('es', 'ES'),
          Locale('it', 'IT'),
          Locale('en', 'US'),
        ];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);

        final dummyRouter = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Builder(
                builder: (ctx) {
                  final locale = Localizations.localeOf(ctx);
                  return Text('Locale: ${locale.languageCode}');
                },
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          KomaApp(
            authRepository: authRepository,
            mangaRepository: mangaRepository,
            libraryRepository: libraryRepository,
            notificationsRepository: notificationsRepository,
            appBloc: appBloc,
            router: dummyRouter,
          ),
        );
        await tester.pump();

        expect(find.text('Locale: it'), findsOneWidget);

        tester.platformDispatcher.localesTestValue = const [
          Locale('fr', 'FR'),
          Locale('de', 'DE'),
        ];
        await tester.pumpAndSettle();

        expect(find.text('Locale: en'), findsOneWidget);
        dummyRouter.dispose();
      },
    );

    testWidgets('creates AppBloc internally if not injected and disposes it', (
      tester,
    ) async {
      final dummyRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('Internal Bloc Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        KomaApp(
          authRepository: authRepository,
          mangaRepository: mangaRepository,
          libraryRepository: libraryRepository,
          notificationsRepository: notificationsRepository,
          router: dummyRouter,
        ),
      );
      await tester.pump();

      expect(find.text('Internal Bloc Screen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      dummyRouter.dispose();
    });

    testWidgets(
      'renders KomaApp with default router when router not injected',
      (tester) async {
        when(() => authRepository.user)
            .thenAnswer((_) => Stream.value(testUser));
        when(() => authRepository.currentUser).thenReturn(testUser);
        when(() => libraryRepository.watchLibrary(any()))
            .thenAnswer((_) => Stream.value(<LibraryEntry>[]));
        when(() => libraryRepository.watchReadingHistory(any()))
            .thenAnswer((_) => Stream.value(<ReadingHistoryEvent>[]));
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
            uid: 'user-001',
            email: 'user@test.com',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );
        when(
          () => notificationsRepository.syncDeviceToken(
            uid: any(named: 'uid'),
            deviceId: any(named: 'deviceId'),
            platform: any(named: 'platform'),
            isEmulatorMode: any(named: 'isEmulatorMode'),
          ),
        ).thenAnswer((_) async => 'fake-token');

        await tester.pumpWidget(
          KomaApp(
            authRepository: authRepository,
            mangaRepository: mangaRepository,
            libraryRepository: libraryRepository,
            notificationsRepository: notificationsRepository,
            isEmulatorMode: true,
            showDevQuickLogin: true,
          ),
        );
        await tester.pump();

        expect(find.byType(KomaApp), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });
}
