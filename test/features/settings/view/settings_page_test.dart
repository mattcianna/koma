import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/settings/settings.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:library_repository/library_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notifications_repository/notifications_repository.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository;

class _MockAuthRepository extends Mock implements AuthRepository;

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository;

void main() {
  group('SettingsPage & SettingsView', () {
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
      ).thenAnswer((_) async => 'fake-token-12345678901234567890');

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

    Widget buildSubject({
      double textScaleFactor = 1.0,
      ThemeData? theme,
      Size surfaceSize = const Size(800, 1200),
      Key? pageKey,
    }) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<LibraryRepository>.value(value: libraryRepository),
          RepositoryProvider<AuthRepository>.value(value: authRepository),
          RepositoryProvider<NotificationsRepository>.value(
            value: notificationsRepository,
          ),
        ],
        child: MaterialApp(
          theme: theme ?? KomaTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: surfaceSize,
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: SettingsPage(
              key: pageKey,
              uid: 'user-123',
              userEmail: 'reader@koma.app',
              deviceId: 'test-device',
              platform: 'android',
            ),
          ),
        ),
      );
    }

    testWidgets('renders loading spinner initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders account card and reading preferences', (tester) async {
      await tester.pumpWidget(buildSubject());
      settingsController.add(sampleProfile);
      await tester.pumpAndSettle();

      expect(find.text('Koma Reader'), findsOneWidget);
      expect(find.text('Signed in as reader@koma.app'), findsOneWidget);
      expect(find.byKey(const Key('settings_locale_segmented')), findsNothing);
      expect(find.byKey(const Key('settings_lang_chip_en')), findsOneWidget);
      expect(
        find.byKey(const Key('settings_rating_chip_safe')),
        findsOneWidget,
      );
    });

    testWidgets('toggling scanlation language updates preferences', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      settingsController.add(sampleProfile);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_lang_chip_ja')));
      await tester.pumpAndSettle();

      verify(
        () => libraryRepository.updateUserSettings(
          uid: 'user-123',
          preferredLanguages: ['en', 'it', 'ja'],
        ),
      ).called(1);
    });

    testWidgets('toggling content rating updates preferences', (tester) async {
      await tester.pumpWidget(buildSubject());
      settingsController.add(sampleProfile);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_rating_chip_erotica')));
      await tester.pumpAndSettle();

      verify(
        () => libraryRepository.updateUserSettings(
          uid: 'user-123',
          contentRatings: ['safe', 'suggestive', 'erotica'],
        ),
      ).called(1);
    });

    testWidgets('toggling notifications off unregisters push token', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject());
      settingsController.add(sampleProfile);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      verify(
        () => libraryRepository.updateUserSettings(
          uid: 'user-123',
          notificationsEnabled: false,
        ),
      ).called(1);
      verify(
        () => notificationsRepository.unregisterDeviceToken(
          uid: 'user-123',
          deviceId: 'test-device',
        ),
      ).called(1);
    });

    testWidgets('tapping sync token button triggers syncDeviceToken', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject());
      settingsController.add(sampleProfile);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_sync_token_button')));
      await tester.pumpAndSettle();

      verify(
        () => notificationsRepository.syncDeviceToken(
          uid: 'user-123',
          deviceId: 'test-device',
          platform: 'android',
        ),
      ).called(1);
    });

    testWidgets('sign out button displays confirmation dialog and signs out', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject());
      settingsController.add(sampleProfile);
      await tester.pumpAndSettle();

      // Tap Sign Out button
      await tester.tap(find.byKey(const Key('settings_sign_out_button')));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap Cancel
      await tester.tap(
        find.byKey(const Key('settings_sign_out_cancel_button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => authRepository.logOut());

      // Open again and confirm
      await tester.tap(find.byKey(const Key('settings_sign_out_button')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('settings_sign_out_confirm_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => authRepository.logOut()).called(1);
    });

    testWidgets('renders cleanly at 200% font scale without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject(textScaleFactor: 2));
      settingsController.add(sampleProfile);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Signed in as reader@koma.app'), findsOneWidget);
    });

    testWidgets('meets accessibility guidelines in light and dark themes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        for (final theme in [KomaTheme.light, KomaTheme.dark]) {
          await tester.pumpWidget(buildSubject(theme: theme));
          settingsController.add(sampleProfile);
          await tester.pumpAndSettle();

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      'renders without overflow on narrow 320x568 and 360x800 screens at 2.0x',
      (tester) async {
        for (final size in const [Size(320, 568), Size(360, 800)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            buildSubject(
              pageKey: ValueKey(size),
              textScaleFactor: 2,
              surfaceSize: size,
            ),
          );
          settingsController.add(sampleProfile);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Signed in as reader@koma.app'), findsOneWidget);

          await tester.scrollUntilVisible(
            find.byKey(const Key('settings_lang_chip_en')),
            200,
          );
          expect(
            find.byKey(const Key('settings_lang_chip_en')),
            findsOneWidget,
          );
        }
      },
    );
  });
}
