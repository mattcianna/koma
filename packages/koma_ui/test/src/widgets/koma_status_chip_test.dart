import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('KomaStatusChip', () {
    testWidgets('renders all 5 status types correctly', (tester) async {
      for (final status in KomaStatusType.values) {
        await tester.pumpApp(
          KomaStatusChip(status: status, label: status.name),
        );

        expect(find.text(status.name), findsOneWidget);
      }
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpApp(
        KomaStatusChip(
          status: KomaStatusType.reading,
          label: 'Reading',
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('Reading'));
      expect(tapped, isTrue);
    });

    testWidgets('renders non-interactive version when onTap is null', (
      tester,
    ) async {
      await tester.pumpApp(
        const KomaStatusChip(
          status: KomaStatusType.completed,
          label: 'Completed',
        ),
      );

      expect(find.byType(InkWell), findsNothing);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('interactive chip meets >= 48x48dp touch target', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaStatusChip(
          status: KomaStatusType.onHold,
          label: 'On Hold',
          onTap: () {},
        ),
      );

      final chipSize = tester.getSize(find.byType(InkWell));
      expect(chipSize.height, greaterThanOrEqualTo(kKomaMinTouchTarget));
      expect(chipSize.width, greaterThanOrEqualTo(kKomaMinTouchTarget));
    });

    testWidgets('renders selected styling with semantics and check icon', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaStatusChip(
          status: KomaStatusType.planToRead,
          label: 'Plan to Read',
          isSelected: true,
          onTap: () {},
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.selected == true &&
            widget.properties.label == 'Plan to Read' &&
            widget.properties.button == true,
      );
      expect(semanticsFinder, findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('supports custom semanticsLabel and semanticsSelected', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaStatusChip(
          status: KomaStatusType.reading,
          label: 'In Corso',
          semanticsLabel: 'Stato di lettura: In Corso',
          semanticsSelected: true,
          onTap: () {},
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.selected == true &&
            widget.properties.label == 'Stato di lettura: In Corso',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets(
      'non-interactive chip emits non-button semantics without duplication',
      (tester) async {
        await tester.pumpApp(
          const KomaStatusChip(
            status: KomaStatusType.completed,
            label: 'Completed',
            semanticsLabel: 'Status: Completed',
          ),
        );

        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Status: Completed' &&
              widget.properties.button != true,
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );

    testWidgets(
      'passes accessibility tap target and label guidelines in light and dark',
      (tester) async {
        final handle = tester.ensureSemantics();

        // Light theme check
        await tester.pumpApp(
          KomaStatusChip(
            status: KomaStatusType.reading,
            label: 'Reading',
            onTap: () {},
          ),
          theme: KomaTheme.light,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        // Dark theme check
        await tester.pumpApp(
          KomaStatusChip(
            status: KomaStatusType.reading,
            label: 'Reading',
            isSelected: true,
            onTap: () {},
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
          KomaStatusChip(
            status: KomaStatusType.dropped,
            label: 'Dropped Series With Very Long Multi-Word Name',
            onTap: () {},
          ),
          textScaler: const TextScaler.linear(2),
        );

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('reflows without layout overflow at 200% font scaling', (
      tester,
    ) async {
      await tester.pumpApp(
        KomaStatusChip(
          status: KomaStatusType.dropped,
          label: 'Dropped Series Filter',
          onTap: () {},
        ),
        textScaler: const TextScaler.linear(2),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
