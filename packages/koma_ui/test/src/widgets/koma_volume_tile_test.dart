import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('KomaVolumeTile', () {
    testWidgets('renders volume title, progress summary, and children', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaVolumeTile(
          volumeTitle: 'Volume 1',
          progressSummary: '5/5 chapters read',
          isAllRead: true,
          onMarkVolumeRead: () {},
          initiallyExpanded: true,
          children: const [Text('Chapter 1'), Text('Chapter 2')],
        ),
      );

      expect(find.text('Volume 1'), findsOneWidget);
      expect(find.text('5/5 chapters read'), findsOneWidget);
      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('Chapter 2'), findsOneWidget);
    });

    testWidgets(
      'executes onMarkVolumeRead callback when trailing action tapped',
      (tester) async {
        var marked = false;

        await tester.pumpApp(
          KomaVolumeTile(
            volumeTitle: 'Volume 2',
            progressSummary: '3/8 chapters read',
            isAllRead: false,
            onMarkVolumeRead: () => marked = true,
            children: const [],
          ),
        );

        final buttonFinder = find.byType(IconButton);
        expect(buttonFinder, findsOneWidget);

        await tester.tap(buttonFinder);
        expect(marked, isTrue);
      },
    );

    testWidgets('displays appropriate icon and tooltip for read status', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaVolumeTile(
          volumeTitle: 'Volume 3',
          progressSummary: '0/10 chapters read',
          isAllRead: false,
          onMarkVolumeRead: () {},
          children: const [],
        ),
      );

      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

      await tester.pumpApp(
        KomaVolumeTile(
          volumeTitle: 'Volume 3',
          progressSummary: '10/10 chapters read',
          isAllRead: true,
          onMarkVolumeRead: () {},
          children: const [],
        ),
      );

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('trailing button meets >= 48x48dp interactive size', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaVolumeTile(
          volumeTitle: 'Volume 4',
          progressSummary: '2/6 chapters read',
          isAllRead: false,
          onMarkVolumeRead: () {},
          children: const [],
        ),
      );

      final buttonSize = tester.getSize(find.byType(IconButton));
      expect(buttonSize.width, greaterThanOrEqualTo(kKomaMinTouchTarget));
      expect(buttonSize.height, greaterThanOrEqualTo(kKomaMinTouchTarget));
    });

    testWidgets('supports custom markVolumeSemanticsLabel override', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaVolumeTile(
          volumeTitle: 'Volume 5',
          progressSummary: '1/10 chapters read',
          isAllRead: false,
          markVolumeSemanticsLabel: 'Segna Volume 5 come letto',
          onMarkVolumeRead: () {},
          children: const [],
        ),
      );

      expect(find.byTooltip('Segna Volume 5 come letto'), findsOneWidget);
    });

    testWidgets(
      'passes accessibility tap target and label guidelines in light and dark',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpApp(
          KomaVolumeTile(
            volumeTitle: 'Volume 1',
            progressSummary: '5/5 chapters read',
            isAllRead: true,
            onMarkVolumeRead: () {},
            children: const [],
          ),
          theme: KomaTheme.light,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        await tester.pumpApp(
          KomaVolumeTile(
            volumeTitle: 'Volume 1 Dark',
            progressSummary: '0/5 chapters read',
            isAllRead: false,
            onMarkVolumeRead: () {},
            children: const [],
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
          SingleChildScrollView(
            child: KomaVolumeTile(
              volumeTitle: 'Special Omnibus Volume 12: Definitive Edition',
              progressSummary:
                  'All 24 chapters completely read and synchronized',
              isAllRead: true,
              onMarkVolumeRead: () {},
              initiallyExpanded: true,
              children: const [Text('Extended Chapter Title Reflowing Neatly')],
            ),
          ),
          textScaler: const TextScaler.linear(2),
        );

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets(
      'stretches expanded chapter rows across full inner tile width',
      (tester) async {
        await tester.pumpApp(
          SizedBox(
            width: 379,
            child: KomaVolumeTile(
              volumeTitle: 'Volume 1',
              progressSummary: '7/9 read',
              isAllRead: false,
              onMarkVolumeRead: () {},
              initiallyExpanded: true,
              children: [
                KomaChapterRow(
                  chapterNumber: '1',
                  onToggleRead: () {},
                  onOpenMangaDex: () {},
                  onMarkPreviousRead: () {},
                ),
              ],
            ),
          ),
        );

        final rowSize = tester.getSize(find.byType(KomaChapterRow));
        expect(rowSize.width, greaterThanOrEqualTo(377));
      },
    );
  });
}
