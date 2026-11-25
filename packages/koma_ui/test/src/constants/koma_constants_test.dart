import 'package:flutter_test/flutter_test.dart';
import 'package:koma_ui/koma_ui.dart';

void main() {
  group('KomaConstants', () {
    test('kKomaUserAgent has correct name, version and URL', () {
      expect(
        kKomaUserAgent,
        equals('Koma/0.1.0 (https://github.com/mattcianna/koma)'),
      );
    });

    test('kKomaUserAgentHeaders contains only User-Agent header', () {
      expect(kKomaUserAgentHeaders, contains('User-Agent'));
      expect(kKomaUserAgentHeaders['User-Agent'], equals(kKomaUserAgent));
      expect(kKomaUserAgentHeaders.containsKey('Referer'), isFalse);
    });

    test('kKomaMinTouchTarget satisfies WCAG 2.2 AA (48dp)', () {
      expect(kKomaMinTouchTarget, equals(48.0));
    });
  });
}
