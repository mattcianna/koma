import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:koma/app/view/app_shell_scaffold.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';

void main() {
  group('AppShellScaffold', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/a',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return AppShellScaffold(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/a',
                    builder: (context, state) =>
                        const Scaffold(body: Center(child: Text('Branch A'))),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/b',
                    builder: (context, state) =>
                        const Scaffold(body: Center(child: Text('Branch B'))),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/c',
                    builder: (context, state) =>
                        const Scaffold(body: Center(child: Text('Branch C'))),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/d',
                    builder: (context, state) =>
                        const Scaffold(body: Center(child: Text('Branch D'))),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    });

    tearDown(() {
      router.dispose();
    });

    Widget buildSubject({
      ThemeData? theme,
      TextScaler textScaler = TextScaler.noScaling,
    }) {
      return MaterialApp.router(
        theme: theme ?? KomaTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child ?? const SizedBox.shrink(),
        ),
      );
    }

    for (final themeEntry in [
      ('light', KomaTheme.light),
      ('dark', KomaTheme.dark),
    ]) {
      testWidgets('meets a11y guidelines under ${themeEntry.$1} theme', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(buildSubject(theme: themeEntry.$2));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    for (final size in [const Size(320, 568), const Size(360, 800)]) {
      testWidgets(
        'renders cleanly on ${size.width}x${size.height} at 200% scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            buildSubject(textScaler: const TextScaler.linear(2)),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('renders all four navigation destinations with proper keys', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byKey(const Key('nav_library')), findsOneWidget);
      expect(find.byKey(const Key('nav_discover')), findsOneWidget);
      expect(find.byKey(const Key('nav_history')), findsOneWidget);
      expect(find.byKey(const Key('nav_settings')), findsOneWidget);
      expect(find.text('Branch A'), findsOneWidget);
    });

    testWidgets('tapping discover destination switches to branch B', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byKey(const Key('nav_discover')));
      await tester.pumpAndSettle();

      expect(find.text('Branch B'), findsOneWidget);
    });

    testWidgets('tapping history destination switches to branch C', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byKey(const Key('nav_history')));
      await tester.pumpAndSettle();

      expect(find.text('Branch C'), findsOneWidget);
    });

    testWidgets('tapping settings destination switches to branch D', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byKey(const Key('nav_settings')));
      await tester.pumpAndSettle();

      expect(find.text('Branch D'), findsOneWidget);
    });

    testWidgets(
      'tapping library destination when selected returns to branch A',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pump();

        await tester.tap(find.byKey(const Key('nav_discover')));
        await tester.pumpAndSettle();
        expect(find.text('Branch B'), findsOneWidget);

        await tester.tap(find.byKey(const Key('nav_library')));
        await tester.pumpAndSettle();
        expect(find.text('Branch A'), findsOneWidget);
      },
    );
  });
}
