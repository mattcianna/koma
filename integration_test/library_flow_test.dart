import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:koma/bootstrap.dart';
import 'package:koma/features/history/history.dart';
import 'package:koma/features/library/library.dart';
import 'package:koma/features/reader_progress/reader_progress.dart';
import 'package:koma/features/settings/settings.dart';

/// Helper to poll using bounded pumps until [finder] matches at least
/// one widget.
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 25),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  await tester.pump(step);
  expect(finder, findsAtLeastNWidgets(1));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Koma full library flow end-to-end against Firebase local emulator',
    (tester) async {
      // 1. Initialize Koma with Firebase emulator enabled.
      final app = await createKomaApp(useFirebaseEmulator: true);

      // 2. Ensure initial state begins unauthenticated on /login.
      try {
        await FirebaseAuth.instance.signOut();
      } on Object catch (_) {
        // Fall through if not signed in yet.
      }

      await tester.pumpWidget(app);

      // 3. Wait for Login page with QA quick login button.
      final quickLoginButton = find.byKey(
        const Key('auth_qa_quick_login_button'),
      );
      await _pumpUntilFound(tester, quickLoginButton);

      // 4. Tap QA test account login bypass.
      await tester.ensureVisible(quickLoginButton);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(quickLoginButton);
      await tester.pump(const Duration(milliseconds: 500));

      // 5. Bounded polling until LibraryPage displays seeded Chainsaw Man.
      final chainsawManTitle = find.text('Chainsaw Man');
      await _pumpUntilFound(
        tester,
        chainsawManTitle,
        timeout: const Duration(seconds: 30),
      );
      expect(find.byType(LibraryPage), findsOneWidget);

      // 6. Test status filter chips (Reading -> All).
      final readingFilterChip = find.byKey(const Key('library_filter_reading'));
      if (readingFilterChip.evaluate().isNotEmpty) {
        await tester.tap(readingFilterChip);
        await tester.pump(const Duration(milliseconds: 300));
      }

      final allFilterChip = find.byKey(const Key('library_filter_all'));
      if (allFilterChip.evaluate().isNotEmpty) {
        await tester.tap(allFilterChip);
        await tester.pump(const Duration(milliseconds: 300));
      }

      // 7. Tap Chainsaw Man card to navigate to MangaDetailPage.
      await tester.ensureVisible(chainsawManTitle);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(chainsawManTitle);
      await _pumpUntilFound(
        tester,
        find.byType(MangaDetailPage),
        timeout: const Duration(seconds: 20),
      );
      expect(find.byType(MangaDetailPage), findsOneWidget);

      // 8. Return back to Library.
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        final navLibrary = find.byKey(const Key('nav_library'));
        if (navLibrary.evaluate().isNotEmpty) {
          await tester.tap(navLibrary);
        }
      }
      await _pumpUntilFound(tester, find.byType(LibraryPage));

      // 9. Switch to History tab.
      final navHistory = find.byKey(const Key('nav_history'));
      await tester.tap(navHistory);
      await _pumpUntilFound(tester, find.byType(HistoryPage));
      expect(find.byType(HistoryPage), findsOneWidget);

      // 10. Switch to Settings tab.
      final navSettings = find.byKey(const Key('nav_settings'));
      await tester.tap(navSettings);
      await _pumpUntilFound(tester, find.byType(SettingsPage));
      expect(find.byType(SettingsPage), findsOneWidget);

      // 11. Verify Settings relies on OS locale hierarchy (no custom UI
      // language selector) and can toggle preferred MangaDex languages.
      final jaLangChip = find.byKey(const Key('settings_lang_chip_ja'));
      await _pumpUntilFound(tester, jaLangChip);
      expect(find.byKey(const Key('settings_locale_segmented')), findsNothing);

      await tester.ensureVisible(jaLangChip);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(jaLangChip);
      await tester.pump(const Duration(milliseconds: 500));

      // Restore initial selection so state stays clean.
      await tester.tap(jaLangChip);
      await tester.pump(const Duration(milliseconds: 500));
    },
  );
}
