import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

class _FakeColorsExtension extends ThemeExtension<KomaColors> {
  const new();

  @override
  ThemeExtension<KomaColors> copyWith() => this;

  @override
  ThemeExtension<KomaColors> lerp(
    ThemeExtension<KomaColors>? other,
    double t,
  ) => this;
}

void main() {
  group('KomaColors', () {
    test('light preset has expected tokens', () {
      const colors = KomaColors.light;
      expect(colors.reading, equals(const Color(0xFFBE123C)));
      expect(colors.onReading, equals(const Color(0xFFFFFFFF)));
      expect(colors.planToRead, equals(const Color(0xFF6D28D9)));
      expect(colors.onPlanToRead, equals(const Color(0xFFFFFFFF)));
      expect(colors.completed, equals(const Color(0xFF047857)));
      expect(colors.onCompleted, equals(const Color(0xFFFFFFFF)));
      expect(colors.onHold, equals(const Color(0xFFB45309)));
      expect(colors.onOnHold, equals(const Color(0xFFFFFFFF)));
      expect(colors.dropped, equals(const Color(0xFF475569)));
      expect(colors.onDropped, equals(const Color(0xFFFFFFFF)));
      expect(colors.unreadBadge, equals(const Color(0xFFBE123C)));
      expect(colors.onUnreadBadge, equals(const Color(0xFFFFFFFF)));
      expect(colors.inkBorder, equals(const Color(0xFF78716C)));
    });

    test('dark preset has expected tokens', () {
      const colors = KomaColors.dark;
      expect(colors.reading, equals(const Color(0xFFFB7185)));
      expect(colors.onReading, equals(const Color(0xFF4C0519)));
      expect(colors.planToRead, equals(const Color(0xFFC4B5FD)));
      expect(colors.onPlanToRead, equals(const Color(0xFF2E1065)));
      expect(colors.completed, equals(const Color(0xFF34D399)));
      expect(colors.onCompleted, equals(const Color(0xFF064E3B)));
      expect(colors.onHold, equals(const Color(0xFFFBBF24)));
      expect(colors.onOnHold, equals(const Color(0xFF451A03)));
      expect(colors.dropped, equals(const Color(0xFF94A3B8)));
      expect(colors.onDropped, equals(const Color(0xFF0F172A)));
      expect(colors.unreadBadge, equals(const Color(0xFFE11D48)));
      expect(colors.onUnreadBadge, equals(const Color(0xFFFFFFFF)));
      expect(colors.inkBorder, equals(const Color(0xFF71717A)));
    });

    test('copyWith overrides fields properly', () {
      const original = KomaColors.light;
      final copied = original.copyWith(
        reading: Colors.red,
        onReading: Colors.black,
        planToRead: Colors.blue,
        onPlanToRead: Colors.yellow,
        completed: Colors.green,
        onCompleted: Colors.purple,
        onHold: Colors.orange,
        onOnHold: Colors.grey,
        dropped: Colors.brown,
        onDropped: Colors.cyan,
        unreadBadge: Colors.pink,
        onUnreadBadge: Colors.lime,
        inkBorder: Colors.teal,
      );

      expect(copied.reading, equals(Colors.red));
      expect(copied.onReading, equals(Colors.black));
      expect(copied.planToRead, equals(Colors.blue));
      expect(copied.onPlanToRead, equals(Colors.yellow));
      expect(copied.completed, equals(Colors.green));
      expect(copied.onCompleted, equals(Colors.purple));
      expect(copied.onHold, equals(Colors.orange));
      expect(copied.onOnHold, equals(Colors.grey));
      expect(copied.dropped, equals(Colors.brown));
      expect(copied.onDropped, equals(Colors.cyan));
      expect(copied.unreadBadge, equals(Colors.pink));
      expect(copied.onUnreadBadge, equals(Colors.lime));
      expect(copied.inkBorder, equals(Colors.teal));
    });

    test('copyWith without arguments retains original values', () {
      const original = KomaColors.light;
      final copied = original.copyWith();

      expect(copied.reading, equals(original.reading));
      expect(copied.inkBorder, equals(original.inkBorder));
    });

    test('lerp blends tokens correctly', () {
      const start = KomaColors.light;
      const end = KomaColors.dark;

      final mid = start.lerp(end, 0.5);
      expect(mid.reading, equals(Color.lerp(start.reading, end.reading, 0.5)));
      expect(
        mid.inkBorder,
        equals(Color.lerp(start.inkBorder, end.inkBorder, 0.5)),
      );

      expect(start.lerp(null, 0.5), equals(start));
      expect(start.lerp(const _FakeColorsExtension(), 0.5), equals(start));
    });
  });
}
