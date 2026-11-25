import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('MangaDexTimestampFormatter', () {
    final mangaDexRegex = RegExp(
      r'^\d{4}-[0-1]\d-([0-2]\d|3[0-1])T([0-1]\d|2[0-3]):[0-5]\d:[0-5]\d$',
    );

    test('formats UTC timestamp matching MangaDex strict regex', () {
      final dt = DateTime.utc(2026, 11, 13, 9, 5, 2);
      final formatted = formatMangaDexTimestamp(dt);

      expect(formatted, equals('2026-11-13T09:05:02'));
      expect(mangaDexRegex.hasMatch(formatted), isTrue);
      expect(formatted.contains('.000'), isFalse);
      expect(formatted.endsWith('Z'), isFalse);
    });

    test('converts non-UTC DateTime to UTC before formatting', () {
      // Local time with explicit offset
      final local = DateTime(2026, 5, 1, 14, 30, 45);
      final formatted = MangaDexTimestampFormatter.format(local);

      final expectedUtc = local.toUtc();
      final expectedHour = expectedUtc.hour.toString().padLeft(2, '0');
      final expectedMinute = expectedUtc.minute.toString().padLeft(2, '0');

      expect(formatted, contains('T$expectedHour:$expectedMinute:45'));
      expect(mangaDexRegex.hasMatch(formatted), isTrue);
    });
  });
}
