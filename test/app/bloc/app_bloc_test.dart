import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/app/app.dart';
import 'package:library_repository/library_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notifications_repository/notifications_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

class _MockLibraryRepository extends Mock implements LibraryRepository;

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository;

void main() {
  group('AppBloc', () {
    late AuthRepository authRepository;
    late LibraryRepository libraryRepository;
    late NotificationsRepository notificationsRepository;
    late StreamController<AppUser> userStreamController;
    late StreamController<UserSettingsProfile?> settingsStreamController;

    const testUser = AppUser(
      uid: 'user-123',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/avatar.png',
    );

    final testProfile = UserSettingsProfile(
      uid: 'user-123',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/avatar.png',
      uiLocale: 'it',
      preferredLanguages: const ['it', 'en'],
      contentRatings: const ['safe'],
      notificationsEnabled: false,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    setUp(() {
      authRepository = _MockAuthRepository();
      libraryRepository = _MockLibraryRepository();
      notificationsRepository = _MockNotificationsRepository();
      userStreamController = StreamController<AppUser>.broadcast();
      settingsStreamController =
          StreamController<UserSettingsProfile?>.broadcast();

      when(() => authRepository.user)
          .thenAnswer((_) => userStreamController.stream);
      when(() => authRepository.currentUser).thenReturn(AppUser.empty);
      when(() => authRepository.logOut()).thenAnswer((_) async {});

      when(
        () => libraryRepository.ensureUserProfile(
          uid: any(named: 'uid'),
          email: any(named: 'email'),
          displayName: any(named: 'displayName'),
          photoUrl: any(named: 'photoUrl'),
        ),
      ).thenAnswer((_) async => testProfile);

      when(() => libraryRepository.watchUserSettings(any()))
          .thenAnswer((_) => settingsStreamController.stream);

      when(
        () => notificationsRepository.syncDeviceToken(
          uid: any(named: 'uid'),
          deviceId: any(named: 'deviceId'),
          platform: any(named: 'platform'),
          isEmulatorMode: any(named: 'isEmulatorMode'),
        ),
      ).thenAnswer((_) async => 'fake-token');
    });

    tearDown(() async {
      await userStreamController.close();
      await settingsStreamController.close();
    });

    AppBloc buildBloc({
      bool isEmulatorMode = false,
      String deviceId = 'pixel9-dev',
      String platform = 'android',
    }) {
      return AppBloc(
        authRepository: authRepository,
        libraryRepository: libraryRepository,
        notificationsRepository: notificationsRepository,
        isEmulatorMode: isEmulatorMode,
        deviceId: deviceId,
        platform: platform,
      );
    }

    test('initial state has empty user and is not authenticated', () {
      final bloc = buildBloc();
      expect(bloc.state.user, equals(AppUser.empty));
      expect(bloc.state.isAuthenticated, isFalse);
      expect(bloc.state.preferredLanguages, equals(const ['en', 'it']));
      expect(bloc.state.contentRatings, equals(const ['safe', 'suggestive']));
      expect(bloc.state.notificationsEnabled, isTrue);
      expect(bloc.state.settings, isNull);
      unawaited(bloc.close());
    });

    test('initializes with current user if already authenticated', () {
      when(() => authRepository.currentUser).thenReturn(testUser);
      final bloc = buildBloc();
      expect(bloc.state.user, equals(testUser));
      expect(bloc.state.isAuthenticated, isTrue);
      unawaited(bloc.close());
    });

    blocTest<AppBloc, AppState>(
      'emits authenticated user, calls ensureUserProfile, syncs token, '
      'and updates settings from watchUserSettings',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const AppUserChanged(testUser));
        await Future<void>.delayed(Duration.zero);
        settingsStreamController.add(testProfile);
      },
      expect: () => [
        const AppState(user: testUser),
        AppState(
          user: testUser,
          preferredLanguages: const ['it', 'en'],
          contentRatings: const ['safe'],
          notificationsEnabled: false,
          settings: testProfile,
        ),
      ],
      verify: (_) {
        verify(
          () => libraryRepository.ensureUserProfile(
            uid: testUser.uid,
            email: testUser.email!,
            displayName: testUser.displayName,
            photoUrl: testUser.photoUrl,
          ),
        ).called(1);
        verify(
          () => notificationsRepository.syncDeviceToken(
            uid: testUser.uid,
            deviceId: 'pixel9-dev',
            platform: 'android',
          ),
        ).called(1);
        verify(() => libraryRepository.watchUserSettings(testUser.uid))
            .called(1);
      },
    );

    blocTest<AppBloc, AppState>(
      'handles ensureUserProfile error gracefully and continues',
      setUp: () {
        when(
          () => libraryRepository.ensureUserProfile(
            uid: any(named: 'uid'),
            email: any(named: 'email'),
            displayName: any(named: 'displayName'),
            photoUrl: any(named: 'photoUrl'),
          ),
        ).thenThrow(Exception('Firestore unreachable'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AppUserChanged(testUser)),
      expect: () => [const AppState(user: testUser)],
    );

    blocTest<AppBloc, AppState>(
      'handles syncDeviceToken error gracefully and continues',
      setUp: () {
        when(
          () => notificationsRepository.syncDeviceToken(
            uid: any(named: 'uid'),
            deviceId: any(named: 'deviceId'),
            platform: any(named: 'platform'),
            isEmulatorMode: any(named: 'isEmulatorMode'),
          ),
        ).thenThrow(Exception('FIS Auth Error'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AppUserChanged(testUser)),
      expect: () => [
        const AppState(user: testUser),
        AppState(
          user: testUser,
          preferredLanguages: const ['it', 'en'],
          contentRatings: const ['safe'],
          notificationsEnabled: false,
          settings: testProfile,
        ),
      ],
    );

    blocTest<AppBloc, AppState>(
      'emits empty AppState when user becomes empty',
      seed: () => AppState(user: testUser, settings: testProfile),
      build: buildBloc,
      act: (bloc) => bloc.add(const AppUserChanged(AppUser.empty)),
      expect: () => [const AppState()],
    );

    blocTest<AppBloc, AppState>(
      'calls logOut on authRepository when AppLogoutRequested is received',
      build: buildBloc,
      act: (bloc) => bloc.add(const AppLogoutRequested()),
      verify: (_) {
        verify(() => authRepository.logOut()).called(1);
      },
    );

    blocTest<AppBloc, AppState>(
      'handles logOut failure gracefully',
      setUp: () {
        when(() => authRepository.logOut())
            .thenThrow(Exception('Logout network failure'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AppLogoutRequested()),
      expect: () => <AppState>[],
    );

    test('listens to authRepository.user stream', () async {
      final bloc = buildBloc();
      userStreamController.add(testUser);
      await expectLater(bloc.stream, emits(const AppState(user: testUser)));
      await bloc.close();
    });

    test(
      'AppUserSubscriptionRequested adds AppUserChanged if user present',
      () async {
        when(() => authRepository.currentUser).thenReturn(testUser);
        final bloc = buildBloc()..add(const AppUserSubscriptionRequested());
        await expectLater(
          bloc.stream,
          emits(predicate<AppState>((state) => state.user == testUser)),
        );
        await bloc.close();
      },
    );

    group('AppEvent', () {
      test('props contain expected elements', () {
        expect(const AppUserSubscriptionRequested().props, isEmpty);
        expect(const AppUserChanged(testUser).props, equals([testUser]));
        expect(AppSettingsChanged(testProfile).props, equals([testProfile]));
        expect(const AppLogoutRequested().props, isEmpty);
      });

      test('AppUserSubscriptionRequested supports value equality', () {
        expect(
          const AppUserSubscriptionRequested(),
          equals(const AppUserSubscriptionRequested()),
        );
      });

      test('AppUserChanged supports value equality', () {
        expect(
          const AppUserChanged(testUser),
          equals(const AppUserChanged(testUser)),
        );
      });

      test('AppSettingsChanged supports value equality', () {
        expect(
          AppSettingsChanged(testProfile),
          equals(AppSettingsChanged(testProfile)),
        );
      });

      test('AppLogoutRequested supports value equality', () {
        expect(const AppLogoutRequested(), equals(const AppLogoutRequested()));
      });
    });
  });
}
