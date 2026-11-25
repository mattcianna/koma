import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('KomaBulkReadSheet', () {
    testWidgets('renders title, message, and buttons with count', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaBulkReadSheet(
          targetChapterNumber: '25',
          affectedCount: 24,
          titleText: 'Mark Previous as Read?',
          messageText: 'This will mark all chapters up to 25 as read.',
          confirmButtonText: 'Confirm',
          cancelButtonText: 'Cancel',
          onConfirm: () {},
          onCancel: () {},
        ),
      );

      expect(find.text('Mark Previous as Read?'), findsOneWidget);
      expect(
        find.text('This will mark all chapters up to 25 as read.'),
        findsOneWidget,
      );
      expect(find.text('Confirm (24)'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('triggers onConfirm and onCancel callbacks', (tester) async {
      var confirmed = false;
      var canceled = false;

      await tester.pumpApp(
        KomaBulkReadSheet(
          targetChapterNumber: '10',
          affectedCount: 9,
          titleText: 'Title',
          messageText: 'Message',
          confirmButtonText: 'Confirm',
          cancelButtonText: 'Cancel',
          onConfirm: () => confirmed = true,
          onCancel: () => canceled = true,
        ),
      );

      await tester.tap(find.text('Confirm (9)'));
      expect(confirmed, isTrue);

      await tester.tap(find.text('Cancel'));
      expect(canceled, isTrue);
    });

    testWidgets('displays progress indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaBulkReadSheet(
          targetChapterNumber: '5',
          affectedCount: 4,
          titleText: 'Title',
          messageText: 'Message',
          confirmButtonText: 'Confirm',
          cancelButtonText: 'Cancel',
          isLoading: true,
          onConfirm: () {},
          onCancel: () {},
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Confirm (4)'), findsNothing);
    });

    testWidgets('static show method opens bottom sheet and confirms', (
      tester,
    ) async {
      var confirmed = false;

      await tester.pumpApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              unawaited(
                KomaBulkReadSheet.show(
                  context,
                  targetChapterNumber: '30',
                  affectedCount: 29,
                  titleText: 'Bulk Read',
                  messageText: 'Confirm bulk read',
                  confirmButtonText: 'Yes',
                  cancelButtonText: 'No',
                  onConfirm: () => confirmed = true,
                ),
              );
            },
            child: const Text('Open Sheet'),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Bulk Read'), findsOneWidget);
      expect(find.text('Yes (29)'), findsOneWidget);

      await tester.tap(find.text('Yes (29)'));
      expect(confirmed, isTrue);
    });

    testWidgets(
      'static show method cancels and pops dialog with default callback',
      (tester) async {
        await tester.pumpApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                unawaited(
                  KomaBulkReadSheet.show(
                    context,
                    targetChapterNumber: '30',
                    affectedCount: 29,
                    titleText: 'Bulk Read',
                    messageText: 'Confirm bulk read',
                    confirmButtonText: 'Yes',
                    cancelButtonText: 'No',
                    onConfirm: () {},
                  ),
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('No'), findsOneWidget);
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        expect(find.text('Bulk Read'), findsNothing);
      },
    );

    testWidgets('passes loadingSemanticsLabel to CircularProgressIndicator', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaBulkReadSheet(
          targetChapterNumber: '10',
          affectedCount: 9,
          titleText: 'Bulk Read',
          messageText: 'Confirm',
          confirmButtonText: 'Confirm',
          cancelButtonText: 'Cancel',
          isLoading: true,
          loadingSemanticsLabel: 'Caricamento in corso...',
          onConfirm: () {},
          onCancel: () {},
        ),
      );

      final progressFinder = find.byWidgetPredicate(
        (widget) =>
            widget is CircularProgressIndicator &&
            widget.semanticsLabel == 'Caricamento in corso...',
      );
      expect(progressFinder, findsOneWidget);
    });

    testWidgets(
      'passes accessibility tap target and label guidelines in light and dark',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpApp(
          KomaBulkReadSheet(
            targetChapterNumber: '5',
            affectedCount: 4,
            titleText: 'Bulk Read',
            messageText: 'Confirm',
            confirmButtonText: 'Confirm',
            cancelButtonText: 'Cancel',
            onConfirm: () {},
            onCancel: () {},
          ),
          theme: KomaTheme.light,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.pumpApp(
          KomaBulkReadSheet(
            targetChapterNumber: '5',
            affectedCount: 4,
            titleText: 'Bulk Read Dark',
            messageText: 'Confirm',
            confirmButtonText: 'Confirm',
            cancelButtonText: 'Cancel',
            onConfirm: () {},
            onCancel: () {},
          ),
          theme: KomaTheme.dark,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        handle.dispose();
      },
    );

    testWidgets('renders cleanly on 320x568 and 360x800 at 200% font scaling', (
      tester,
    ) async {
      for (final size in const [Size(320, 568), Size(360, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpApp(
          KomaBulkReadSheet(
            targetChapterNumber: '99',
            affectedCount: 98,
            titleText: 'Mark All Previous Chapters as Read In Single Batch?',
            messageText:
                'This operation updates reading history and library progress '
                'atomically across all previous released volumes.',
            confirmButtonText: 'Mark Previous Read',
            cancelButtonText: 'Dismiss Sheet',
            onConfirm: () {},
            onCancel: () {},
          ),
          textScaler: const TextScaler.linear(2),
        );

        expect(tester.takeException(), isNull);
      }
    });
  });
}
