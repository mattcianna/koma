import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

class _FakeSpacingExtension extends ThemeExtension<KomaSpacing> {
  const new();

  @override
  ThemeExtension<KomaSpacing> copyWith() => this;

  @override
  ThemeExtension<KomaSpacing> lerp(
    ThemeExtension<KomaSpacing>? other,
    double t,
  ) => this;
}

void main() {
  group('KomaSpacing', () {
    test('default spacing tokens follow 8dp grid', () {
      const spacing = KomaSpacing();
      expect(spacing.xxs, equals(4.0));
      expect(spacing.xs, equals(8.0));
      expect(spacing.sm, equals(12.0));
      expect(spacing.md, equals(16.0));
      expect(spacing.lg, equals(24.0));
      expect(spacing.xlg, equals(32.0));
      expect(spacing.xxlg, equals(48.0));
    });

    test('directional getters provide valid EdgeInsetsDirectional', () {
      const spacing = KomaSpacing();
      expect(
        spacing.horizontalXs,
        equals(const EdgeInsetsDirectional.symmetric(horizontal: 8)),
      );
      expect(
        spacing.horizontalSm,
        equals(const EdgeInsetsDirectional.symmetric(horizontal: 12)),
      );
      expect(
        spacing.horizontalMd,
        equals(const EdgeInsetsDirectional.symmetric(horizontal: 16)),
      );
      expect(
        spacing.horizontalLg,
        equals(const EdgeInsetsDirectional.symmetric(horizontal: 24)),
      );

      expect(
        spacing.verticalXs,
        equals(const EdgeInsetsDirectional.symmetric(vertical: 8)),
      );
      expect(
        spacing.verticalSm,
        equals(const EdgeInsetsDirectional.symmetric(vertical: 12)),
      );
      expect(
        spacing.verticalMd,
        equals(const EdgeInsetsDirectional.symmetric(vertical: 16)),
      );
      expect(
        spacing.verticalLg,
        equals(const EdgeInsetsDirectional.symmetric(vertical: 24)),
      );

      expect(spacing.allXs, equals(const EdgeInsetsDirectional.all(8)));
      expect(spacing.allSm, equals(const EdgeInsetsDirectional.all(12)));
      expect(spacing.allMd, equals(const EdgeInsetsDirectional.all(16)));
      expect(spacing.allLg, equals(const EdgeInsetsDirectional.all(24)));
      expect(spacing.allXlg, equals(const EdgeInsetsDirectional.all(32)));
      expect(spacing.allXxlg, equals(const EdgeInsetsDirectional.all(48)));

      expect(
        spacing.screenMargin,
        equals(const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16)),
      );
      expect(spacing.cardPadding, equals(const EdgeInsetsDirectional.all(12)));
    });

    test('copyWith works as expected', () {
      const spacing = KomaSpacing();
      final copied = spacing.copyWith(
        xxs: 2,
        xs: 6,
        sm: 10,
        md: 14,
        lg: 20,
        xlg: 30,
        xxlg: 40,
      );

      expect(copied.xxs, equals(2.0));
      expect(copied.xs, equals(6.0));
      expect(copied.sm, equals(10.0));
      expect(copied.md, equals(14.0));
      expect(copied.lg, equals(20.0));
      expect(copied.xlg, equals(30.0));
      expect(copied.xxlg, equals(40.0));

      final emptyCopy = spacing.copyWith();
      expect(emptyCopy.xxs, equals(spacing.xxs));
    });

    test('lerp interpolates spacing values', () {
      const a = KomaSpacing(xs: 10, md: 20);
      const b = KomaSpacing(xs: 20, md: 40);

      final result = a.lerp(b, 0.5);
      expect(result.xs, equals(15.0));
      expect(result.md, equals(30.0));

      expect(a.lerp(null, 0.5), equals(a));
      expect(a.lerp(const _FakeSpacingExtension(), 0.5), equals(a));
    });
  });
}
