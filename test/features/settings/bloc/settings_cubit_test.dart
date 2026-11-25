import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/settings/settings.dart';
import 'package:library_repository/library_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notifications_repository/notifications_repository.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository;

class _MockAuthRepository extends Mock implements AuthRepository;

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository;

void main() {
  group('SettingsState', () {
    test('supports value equality', () {
      expect(const SettingsState(), equals(const SettingsState()));
    });

    test('copyWith updates properties correctly', () {
      const state = SettingsState();
      final now = DateTime.now();
      final profile = UserSettingsProfile(
        uid: 'user-1',
        email: 'test@koma.local',
        createdAt: now,
        updatedAt: now,
      );

      final updated = state.copyWith(
        status: SettingsStatus.loaded,
        profile: profile,
        errorMessage: 'error',
        infoMessage: 'saved',
        isSigningOut: true,
        isSyncingToken: true,
      );

      expect(updated.status, equals(SettingsStatus.loaded));
      expect(updated.profile, equals(profile));
      expect(updated.errorMessage, equals('error'));
      expect(updated.infoMessage, equals('saved'));
      expect(updated.isSigningOut, isTrue);
      expect(updated.isSyncingToken, isTrue);
    });

    test('copyWith clears infoMessage and errorMessage when requested', () {
      const state = SettingsState(errorMessage: 'error', infoMessage: 'info');

      final cleared = state.copyWith(
        clearInfoMessage: true,
        clearErrorMessage: true,
      );

      expect(cleared.errorMessage, isNull);
      expect(cleared.infoMessage, isNull);
    });
  });

  group('SettingsCubit', () {
    late LibraryRepository libraryRepository;
    late AuthRepository authRepository;
    late NotificationsRepository notificationsRepository;
    late StreamController<UserSettingsProfile?> settingsController;
    late UserSettingsProfile sampleProfile;

    setUp(() {
      libraryRepository = _MockLibraryRepository();
      authRepository = _MockAuthRepository();
      notificationsRepository = _MockNotificationsRepository();
      settingsController = StreamController<UserSettingsProfile?>.broadcast();

      final now = DateTime.now();
      sampleProfile = UserSettingsProfile(
        uid: 'user-123',
        email: 'reader@koma.app',
        displayName: 'Koma Reader',
        createdAt: now,
        updatedAt: now,
      );

      when(() => libraryRepository.watchUserSettings(any()))
          .thenAnswer((_) => settingsController.stream);

      when(() => authRepository.currentUser).thenReturn(
        const AppUser(
          uid: 'user-123',
          email: 'reader@koma.app',
          displayName: 'Koma Reader',
        ),
      );

      when(
        () => libraryRepository.updateUserSettings(
          uid: any(named: 'uid'),
          displayName: any(named: 'displayName'),
          photoUrl: any(named: 'photoUrl'),
          uiLocale: any(named: 'uiLocale'),
          preferredLanguages: any(named: 'preferredLanguages'),
          contentRatings: any(named: 'contentRatings'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => notificationsRepository.syncDeviceToken(
          uid: any(named: 'uid'),
          deviceId: any(named: 'deviceId'),
          platform: any(named: 'platform'),
          isEmulatorMode: any(named: 'isEmulatorMode'),
        ),
      ).thenAnswer((_) async => 'fake-device-token-12345678901234567890');

      when(
        () => notificationsRepository.unregisterDeviceToken(
          uid: any(named: 'uid'),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer((_) async {});

      when(() => authRepository.logOut()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await settingsController.close();
    });

    test('initial state has loading status', () {
      final cubit = SettingsCubit(
        libraryRepository: libraryRepository,
        authRepository: authRepository,
        notificationsRepository: notificationsRepository,
        uid: 'user-123',
      );

      expect(cubit.state.status, equals(SettingsStatus.loading));
      unawaited(cubit.close());
    });

    blocTest<SettingsCubit, SettingsState>(
      'emits [loaded] when watchUserSettings emits profile',
      build: () => SettingsCubit(
        libraryRepository: libraryRepository,
        authRepository: authRepository,
        notificationsRepository: notificationsRepository,
        uid: 'user-123',
      ),
      act: (_) => settingsController.add(sampleProfile),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.status, 'status', SettingsStatus.loaded)
            .having((s) => s.profile, 'profile', sampleProfile),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'calls ensureUserProfile when watchUserSettings emits null',
      setUp: () {
        when(
          () => libraryRepository.ensureUserProfile(
            uid: any(named: 'uid'),
            email: any(named: 'email'),
            displayName: any(named: 'displayName'),
            photoUrl: any(named: 'photoUrl'),
          ),
        ).thenAnswer((_) async => sampleProfile);
      },
      build: () => SettingsCubit(
        libraryRepository: libraryRepository,
        authRepository: authRepository,
        notificationsRepository: notificationsRepository,
        uid: 'user-123',
      ),
      act: (_) => settingsController.add(null),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.status, 'status', SettingsStatus.loaded)
            .having((s) => s.profile, 'profile', sampleProfile),
      ],
      verify: (_) {
        verify(
          () => libraryRepository.ensureUserProfile(
            uid: 'user-123',
            email: 'reader@koma.app',
            displayName: 'Koma Reader',
          ),
        ).called(1);
      },
    );

    group('togglePreferredLanguage', () {
      blocTest<SettingsCubit, SettingsState>(
        'adds language when not present',
        build: () => SettingsCubit(
          libraryRepository: libraryRepository,
          authRepository: authRepository,
          notificationsRepository: notificationsRepository,
          uid: 'user-123',
        ),
        seed: () => SettingsState(
          status: SettingsStatus.loaded,
          profile: sampleProfile, // ['en', 'it']
        ),
        act: (cubit) => cubit.togglePreferredLanguage('ja'),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.infoMessage,
            'infoMessage',
            'settingsSavedMessage',
          ),
        ],
        verify: (_) {
          verify(
            () => libraryRepository.updateUserSettings(
              uid: 'user-123',
              preferredLanguages: ['en', 'it', 'ja'],
            ),
          ).called(1);
        },
      );

      blocTest<SettingsCubit, SettingsState>(
        'removes language when more than 1 language selected',
        build: () => SettingsCubit(
          libraryRepository: libraryRepository,
          authRepository: authRepository,
          notificationsRepository: notificationsRepository,
          uid: 'user-123',
        ),
        seed: () => SettingsState(
          status: SettingsStatus.loaded,
          profile: sampleProfile, // ['en', 'it']
        ),
        act: (cubit) => cubit.togglePreferredLanguage('it'),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.infoMessage,
            'infoMessage',
            'settingsSavedMessage',
          ),
        ],
        verify: (_) {
          verify(
            () => libraryRepository.updateUserSettings(
              uid: 'user-123',
              preferredLanguages: ['en'],
            ),
          ).called(1);
        },
      );

      blocTest<SettingsCubit, SettingsState>(
        'does NOT remove language when only 1 language selected',
        build: () => SettingsCubit(
          libraryRepository: libraryRepository,
          authRepository: authRepository,
          notificationsRepository: notificationsRepository,
          uid: 'user-123',
        ),
        seed: () => SettingsState(
          status: SettingsStatus.loaded,
          profile: sampleProfile.copyWith(preferredLanguages: const ['en']),
        ),
        act: (cubit) => cubit.togglePreferredLanguage('en'),
        expect: () => <SettingsState>[],
        verify: (_) {
          verifyNever(
            () => libraryRepository.updateUserSettings(
              uid: any(named: 'uid'),
              preferredLanguages: any(named: 'preferredLanguages'),
            ),
          );
        },
      );
    });

    group('toggleContentRating', () {
      blocTest<SettingsCubit, SettingsState>(
        'adds rating when not present',
        build: () => SettingsCubit(
          libraryRepository: libraryRepository,
          authRepository: authRepository,
          notificationsRepository: notificationsRepository,
          uid: 'user-123',
        ),
        seed: () => SettingsState(
          status: SettingsStatus.loaded,
          profile: sampleProfile, // ['safe', 'suggestive']
        ),
        act: (cubit) => cubit.toggleContentRating('erotica'),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.infoMessage,
            'infoMessage',
            'settingsSavedMessage',
          ),
        ],
        verify: (_) {
          verify(
            () => libraryRepository.updateUserSettings(
              uid: 'user-123',
              contentRatings: ['safe', 'suggestive', 'erotica'],
            ),
          ).called(1);
        },
      );

      blocTest<SettingsCubit, SettingsState>(
        'removes rating when more than 1 rating selected',
        build: () => SettingsCubit(
          libraryRepository: libraryRepository,
          authRepository: authRepository,
          notificationsRepository: notificationsRepository,
          uid: 'user-123',
        ),
        seed: () => SettingsState(
          status: SettingsStatus.loaded,
          profile: sampleProfile, // ['safe', 'suggestive']
        ),
        act: (cubit) => cubit.toggleContentRating('suggestive'),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.infoMessage,
            'infoMessage',
            'settingsSavedMessage',
          ),
        ],
        verify: (_) {
          verify(
            () => libraryRepository.updateUserSettings(
              uid: 'user-123',
              contentRatings: ['safe'],
            ),
          ).called(1);
        },
      );

      blocTest<SettingsCubit, SettingsState>(
        'does NOT remove rating when only 1 rating selected',
        build: () => SettingsCubit(
          libraryRepository: libraryRepository,
          authRepository: authRepository,
          notificationsRepository: notificationsRepository,
          uid: 'user-123',
        ),
        seed: () => SettingsState(
          status: SettingsStatus.loaded,
          profile: sampleProfile.copyWith(contentRatings: const ['safe']),
        ),
        act: (cubit) => cubit.toggleContentRating('safe'),
        expect: () => <SettingsState>[],
        verify: (_) {
          verifyNever(
            () => libraryRepository.updateUserSettings(
              uid: any(named: 'uid'),
              contentRatings: any(named: 'contentRatings'),
            ),
          );
        },
      );
    });

    group('notifications', () {
      blocTest<SettingsCubit, SettingsState>(
        'setNotificationsEnabled(true) updates settings and syncs token',
        build: () => SettingsCubit(
          libraryRepository: libraryRepository,
          authRepository: authRepository,
          notificationsRepository: notificationsRepository,
          uid: 'user-123',
        ),
        act: (cubit) => cubit.setNotificationsEnabled(true),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.infoMessage,
            'infoMessage',
            'settingsSavedMessage',
          ),
        ],
        verify: (_) {
          verify(
            () => libraryRepository.updateUserSettings(
              uid: 'user-123',
              notificationsEnabled: true,
            ),
          ).called(1);
          verify(
            () => notificationsRepository.syncDeviceToken(
              uid: 'user-123',
              deviceId: 'device-1',
              platform: 'android',
            ),
          ).called(1);
        },
      );

      blocTest<SettingsCubit, SettingsState>(
        'setNotificationsEnabled(false) updates settings and unregisters token',
        build: () => SettingsCubit(
          libraryRepository: libraryRepository,
          authRepository: authRepository,
          notificationsRepository: notificationsRepository,
          uid: 'user-123',
        ),
        act: (cubit) => cubit.setNotificationsEnabled(false),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.infoMessage,
            'infoMessage',
            'settingsSavedMessage',
          ),
        ],
        verify: (_) {
          verify(
            () => libraryRepository.updateUserSettings(
              uid: 'user-123',
              notificationsEnabled: false,
            ),
          ).called(1);
          verify(
            () => notificationsRepository.unregisterDeviceToken(
              uid: 'user-123',
              deviceId: 'device-1',
            ),
          ).called(1);
        },
      );

      blocTest<SettingsCubit, SettingsState>(
        'syncPushTokenNow sets isSyncingToken and updates message',
        build: () => SettingsCubit(
          libraryRepository: libraryRepository,
          authRepository: authRepository,
          notificationsRepository: notificationsRepository,
          uid: 'user-123',
        ),
        act: (cubit) => cubit.syncPushTokenNow(),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.isSyncingToken,
            'isSyncingToken',
            isTrue,
          ),
          isA<SettingsState>()
              .having((s) => s.isSyncingToken, 'isSyncingToken', isFalse)
              .having(
                (s) => s.infoMessage,
                'infoMessage',
                'settingsTokenSyncedMessage',
              ),
        ],
        verify: (_) {
          verify(
            () => notificationsRepository.syncDeviceToken(
              uid: 'user-123',
              deviceId: 'device-1',
              platform: 'android',
            ),
          ).called(1);
        },
      );
    });

    group('signOut', () {
      blocTest<SettingsCubit, SettingsState>(
        'unregisters token and calls logOut',
        build: () => SettingsCubit(
          libraryRepository: libraryRepository,
          authRepository: authRepository,
          notificationsRepository: notificationsRepository,
          uid: 'user-123',
        ),
        act: (cubit) => cubit.signOut(),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.isSigningOut,
            'isSigningOut',
            isTrue,
          ),
        ],
        verify: (_) {
          verify(
            () => notificationsRepository.unregisterDeviceToken(
              uid: 'user-123',
              deviceId: 'device-1',
            ),
          ).called(1);
          verify(() => authRepository.logOut()).called(1);
        },
      );
    });

    test('clearInfoMessage resets infoMessage', () {
      final cubit = SettingsCubit(
        libraryRepository: libraryRepository,
        authRepository: authRepository,
        notificationsRepository: notificationsRepository,
        uid: 'user-123',
      );

      cubit.emit(cubit.state.copyWith(infoMessage: 'some_info'));
      expect(cubit.state.infoMessage, equals('some_info'));

      cubit.clearInfoMessage();
      expect(cubit.state.infoMessage, isNull);

      unawaited(cubit.close());
    });
  });
}
