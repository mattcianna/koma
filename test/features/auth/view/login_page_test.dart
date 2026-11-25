import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/features/auth/auth.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository;

void main() {
  group('LoginPage & LoginView', () {
    late AuthRepository authRepository;

    setUp(() {
      authRepository = _MockAuthRepository();
      when(
        () => authRepository.logInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => authRepository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async {});
      when(() => authRepository.logInWithGoogle()).thenAnswer((_) async {});
      when(() => authRepository.logInWithTestAccount())
          .thenAnswer((_) async {});
    });

    Widget buildSubject({
      bool? showDevQuickLogin,
      TextScaler textScaler = TextScaler.noScaling,
      Size surfaceSize = const Size(800, 1200),
      ThemeData? theme,
    }) {
      return RepositoryProvider<AuthRepository>.value(
        value: authRepository,
        child: MaterialApp(
          theme: theme ?? KomaTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(size: surfaceSize, textScaler: textScaler),
            child: LoginPage(showDevQuickLogin: showDevQuickLogin),
          ),
        ),
      );
    }

    testWidgets('renders all essential elements in sign-in mode', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(showDevQuickLogin: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_email_input')), findsOneWidget);
      expect(find.byKey(const Key('auth_password_input')), findsOneWidget);
      expect(find.byKey(const Key('auth_display_name_input')), findsNothing);
      expect(find.byKey(const Key('auth_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('auth_google_button')), findsOneWidget);
      expect(find.byKey(const Key('auth_toggle_mode_button')), findsOneWidget);
      expect(
        find.byKey(const Key('auth_qa_quick_login_button')),
        findsOneWidget,
      );
    });

    testWidgets('hides QA quick login button when showDevQuickLogin is false', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(showDevQuickLogin: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_qa_quick_login_button')), findsNothing);
    });

    testWidgets('tapping QA quick login button triggers logInWithTestAccount', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(showDevQuickLogin: true));
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('auth_qa_quick_login_button'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();

      await tester.tap(button);
      await tester.pump();

      verify(() => authRepository.logInWithTestAccount()).called(1);
    });

    testWidgets('tapping Google button triggers logInWithGoogle', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auth_google_button')));
      await tester.pump();

      verify(() => authRepository.logInWithGoogle()).called(1);
    });

    testWidgets('shows validation errors when submitting empty form', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);

      verifyNever(
        () => authRepository.logInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('submits credentials on valid inputs in sign-in mode', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('auth_email_input')),
        'reader@koma.io',
      );
      await tester.enterText(
        find.byKey(const Key('auth_password_input')),
        'Secret123',
      );
      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pump();

      verify(
        () => authRepository.logInWithEmailAndPassword(
          email: 'reader@koma.io',
          password: 'Secret123',
        ),
      ).called(1);
    });

    testWidgets('switches to sign-up mode and shows display name field', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('auth_toggle_mode_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_display_name_input')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('auth_email_input')),
        'new@koma.io',
      );
      await tester.enterText(
        find.byKey(const Key('auth_password_input')),
        'Secret123',
      );
      await tester.enterText(
        find.byKey(const Key('auth_display_name_input')),
        'Koma Fan',
      );

      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pump();

      verify(
        () => authRepository.signUp(
          email: 'new@koma.io',
          password: 'Secret123',
          displayName: 'Koma Fan',
        ),
      ).called(1);
    });

    testWidgets('renders without overflow at TextScaler.linear(2.0)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          showDevQuickLogin: true,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('auth_email_input')), findsOneWidget);
      expect(find.byKey(const Key('auth_submit_button')), findsOneWidget);
    });

    testWidgets('displays error banner when authentication fails', (
      tester,
    ) async {
      when(
        () => authRepository.logInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const InvalidCredentialsFailure());

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('auth_email_input')),
        'wrong@koma.io',
      );
      await tester.enterText(
        find.byKey(const Key('auth_password_input')),
        'WrongPass',
      );
      await tester.tap(find.byKey(const Key('auth_submit_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_error_banner')), findsOneWidget);
    });

    testWidgets('password visibility toggle updates icon and tooltip', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byTooltip('Show password'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('meets accessibility guidelines in light and dark themes', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        for (final theme in [KomaTheme.light, KomaTheme.dark]) {
          await tester.pumpWidget(
            buildSubject(theme: theme, showDevQuickLogin: true),
          );
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
              showDevQuickLogin: true,
              textScaler: const TextScaler.linear(2),
              surfaceSize: size,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('auth_email_input')), findsOneWidget);
          expect(find.byKey(const Key('auth_submit_button')), findsOneWidget);
        }
      },
    );
  });
}
