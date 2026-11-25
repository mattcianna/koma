import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('ChapterComparator', () {
    test('correctly orders canonical sequence with natural sorting', () {
      final input = [
        'none',
        '11',
        '10.5',
        'extra',
        '10b',
        '1',
        '10a',
        '0',
        '10.1',
        '2',
        '10',
      ]..sort(ChapterComparator.compare);

      expect(
        input,
        equals([
          '0',
          '1',
          '2',
          '10',
          '10a',
          '10b',
          '10.1',
          '10.5',
          '11',
          'extra',
          'none',
        ]),
      );
    });

    test(
      'orders "10a" before "11" (fixes Argon-01 empirical sorting trap)',
      () {
        expect(ChapterComparator.compare('10a', '11'), isNegative);
        expect(ChapterComparator.compare('11', '10a'), isPositive);
        expect(ChapterComparator.compare('10', '10a'), isNegative);
        expect(ChapterComparator.compare('10a', '10'), isPositive);
      },
    );

    test('orders split decimal chapters correctly', () {
      expect(ChapterComparator.compare('79.1', '79.2'), isNegative);
      expect(ChapterComparator.compare('79.2', '79.1'), isPositive);
      expect(ChapterComparator.compare('79.2', '79.2'), isZero);
    });

    test('always pushes "none" (unnumbered oneshots) to the end', () {
      expect(ChapterComparator.compare('none', 'none'), isZero);
      expect(ChapterComparator.compare('None', 'none'), isZero);
      expect(ChapterComparator.compare('none', '1'), isPositive);
      expect(ChapterComparator.compare('1', 'none'), isNegative);
      expect(ChapterComparator.compare('extra', 'none'), isNegative);
      expect(ChapterComparator.compare('none', 'extra'), isPositive);
    });

    test('sorts purely non-numeric labels alphabetically after numeric', () {
      expect(ChapterComparator.compare('1', 'extra'), isNegative);
      expect(ChapterComparator.compare('extra', '1'), isPositive);
      expect(ChapterComparator.compare('extra', 'omake'), isNegative);
      expect(ChapterComparator.compare('omake', 'extra'), isPositive);
    });

    test('handles whitespace and case trimming', () {
      expect(ChapterComparator.compare(' 10 ', '10'), isZero);
      expect(ChapterComparator.compare('10A', '10a'), isZero);
    });
  });
}
