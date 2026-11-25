import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('KomaChapterRow', () {
    testWidgets('renders chapter number, title, and metadata', (tester) async {
      await tester.pumpApp(
        KomaChapterRow(
          chapterNumber: '42',
          title: 'The Great Encounter',
          publishDate: '3 days ago',
          scanlationGroup: 'ScanGroup',
          hostIndicator: 'ExternalHost',
          onToggleRead: () {},
          onOpenMangaDex: () {},
          onMarkPreviousRead: () {},
        ),
      );

      expect(find.text('Ch. 42 - The Great Encounter'), findsOneWidget);
      expect(
        find.text('3 days ago • ScanGroup • ExternalHost'),
        findsOneWidget,
      );
    });

    testWidgets('triggers onToggleRead via checkbox button and row tap', (
      tester,
    ) async {
      var toggleCount = 0;

      await tester.pumpApp(
        KomaChapterRow(
          chapterNumber: '1',
          onToggleRead: () => toggleCount++,
          onOpenMangaDex: () {},
          onMarkPreviousRead: () {},
        ),
      );

      // Tap on toggle checkbox icon button
      final checkboxFinder = find.byTooltip('Mark chapter read');
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      expect(toggleCount, equals(1));

      // Tap anywhere on the row body
      await tester.tap(find.text('Chapter 1'));
      expect(toggleCount, equals(2));
    });

    testWidgets('triggers onOpenMangaDex callback', (tester) async {
      var opened = false;

      await tester.pumpApp(
        KomaChapterRow(
          chapterNumber: '10',
          onToggleRead: () {},
          onOpenMangaDex: () => opened = true,
          onMarkPreviousRead: () {},
        ),
      );

      final openFinder = find.byTooltip('Open chapter on MangaDex');
      expect(openFinder, findsOneWidget);

      await tester.tap(openFinder);
      expect(opened, isTrue);
    });

    testWidgets(
      'triggers onMarkPreviousRead via action button and row long-press',
      (tester) async {
        var markPreviousCount = 0;

        await tester.pumpApp(
          KomaChapterRow(
            chapterNumber: '15',
            onToggleRead: () {},
            onOpenMangaDex: () {},
            onMarkPreviousRead: () => markPreviousCount++,
          ),
        );

        final actionButtonFinder = find.byTooltip(
          'Mark previous chapters as read',
        );
        expect(actionButtonFinder, findsOneWidget);

        await tester.tap(actionButtonFinder);
        expect(markPreviousCount, equals(1));

        // Long press on the row
        await tester.longPress(find.text('Chapter 15'));
        expect(markPreviousCount, equals(2));
      },
    );

    testWidgets('displays appropriate checkbox icon based on isRead state', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaChapterRow(
          chapterNumber: '5',
          onToggleRead: () {},
          onOpenMangaDex: () {},
          onMarkPreviousRead: () {},
        ),
      );

      expect(
        find.byIcon(Icons.check_box_outline_blank_rounded),
        findsOneWidget,
      );

      await tester.pumpApp(
        KomaChapterRow(
          chapterNumber: '5',
          isRead: true,
          onToggleRead: () {},
          onOpenMangaDex: () {},
          onMarkPreviousRead: () {},
        ),
      );

      expect(find.byIcon(Icons.check_box_rounded), findsOneWidget);
    });

    testWidgets('interactive action buttons meet >= 48x48dp target', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaChapterRow(
          chapterNumber: '8',
          onToggleRead: () {},
          onOpenMangaDex: () {},
          onMarkPreviousRead: () {},
        ),
      );

      final iconButtons = tester.widgetList<IconButton>(
        find.byType(IconButton),
      );
      expect(iconButtons.length, equals(3));

      for (final btn in iconButtons) {
        expect(
          btn.constraints?.minWidth,
          greaterThanOrEqualTo(kKomaMinTouchTarget),
        );
        expect(
          btn.constraints?.minHeight,
          greaterThanOrEqualTo(kKomaMinTouchTarget),
        );
      }
    });

    testWidgets('supports custom localized labels and hints', (tester) async {
      await tester.pumpApp(
        KomaChapterRow(
          chapterNumber: '1',
          chapterTitleLabel: 'Capitolo 1 - Inizio',
          toggleSemanticsLabel: 'Segna capitolo 1 come letto',
          openMangaDexSemanticsLabel: 'Apri capitolo su MangaDex',
          markPreviousReadSemanticsLabel:
              'Segna capitoli precedenti come letti',
          tapHint: 'Tocca per segnare come letto',
          longPressHint: 'Tieni premuto per segnare i precedenti',
          onToggleRead: () {},
          onOpenMangaDex: () {},
          onMarkPreviousRead: () {},
        ),
      );

      expect(find.text('Capitolo 1 - Inizio'), findsOneWidget);
      expect(find.byTooltip('Segna capitolo 1 come letto'), findsOneWidget);
      expect(find.byTooltip('Apri capitolo su MangaDex'), findsOneWidget);
      expect(
        find.byTooltip('Segna capitoli precedenti come letti'),
        findsOneWidget,
      );

      final rowSemanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.hintOverrides?.onTapHint ==
                'Tocca per segnare come letto' &&
            widget.properties.hintOverrides?.onLongPressHint ==
                'Tieni premuto per segnare i precedenti',
      );
      expect(rowSemanticsFinder, findsOneWidget);
    });

    testWidgets(
      'passes accessibility tap target and label guidelines in light and dark',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpApp(
          KomaChapterRow(
            chapterNumber: '12',
            title: 'Test Chapter',
            onToggleRead: () {},
            onOpenMangaDex: () {},
            onMarkPreviousRead: () {},
          ),
          theme: KomaTheme.light,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.pumpApp(
          KomaChapterRow(
            chapterNumber: '12',
            title: 'Test Chapter Dark',
            isRead: true,
            onToggleRead: () {},
            onOpenMangaDex: () {},
            onMarkPreviousRead: () {},
          ),
          theme: KomaTheme.dark,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        handle.dispose();
      },
    );

    testWidgets('stacks actions below title in LayoutBuilder when width < 260 '
        'or scale >= 1.5', (tester) async {
      await tester.pumpApp(
        KomaChapterRow(
          chapterNumber: '99',
          title: 'Stacked Chapter Row',
          publishDate: '1 day ago',
          onToggleRead: () {},
          onOpenMangaDex: () {},
          onMarkPreviousRead: () {},
        ),
        textScaler: const TextScaler.linear(1.8),
      );

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets(
      'expands to full parent width and stays single row at 379dp width',
      (tester) async {
        await tester.pumpApp(
          SizedBox(
            width: 379,
            child: KomaChapterRow(
              chapterNumber: '1',
              title: 'Chapter 1',
              onToggleRead: () {},
              onOpenMangaDex: () {},
              onMarkPreviousRead: () {},
            ),
          ),
        );

        expect(find.byType(Wrap), findsNothing);
        expect(tester.getSize(find.byType(KomaChapterRow)).width, equals(379));
      },
    );

    testWidgets(
      'stacks actions and fills full width at narrow 240dp parent width',
      (tester) async {
        await tester.pumpApp(
          SizedBox(
            width: 240,
            child: KomaChapterRow(
              chapterNumber: '2',
              title: 'Narrow Chapter',
              onToggleRead: () {},
              onOpenMangaDex: () {},
              onMarkPreviousRead: () {},
            ),
          ),
        );

        expect(find.byType(Wrap), findsOneWidget);
        expect(tester.getSize(find.byType(KomaChapterRow)).width, equals(240));
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
          KomaChapterRow(
            chapterNumber: '100.5',
            title: 'Extra Chapter With an Exceptionally Long Narrative Title',
            publishDate: 'September 15, 2026',
            scanlationGroup: 'High Quality Scanlation Syndicate',
            hostIndicator: 'MangaDex External Reader',
            onToggleRead: () {},
            onOpenMangaDex: () {},
            onMarkPreviousRead: () {},
          ),
          textScaler: const TextScaler.linear(2),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Wrap), findsOneWidget);
      }
    });
  });
}
