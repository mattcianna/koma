import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koma/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('resolves demo-koma emulator fallback on Android and iOS when '
        'unconfigured', () {
      if (DefaultFirebaseOptions.isConfigured) {
        final android = DefaultFirebaseOptions.currentPlatform();
        expect(android.projectId, isNotEmpty);
        expect(android.apiKey, isNotEmpty);
        return;
      }

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final android = DefaultFirebaseOptions.currentPlatform(useEmulator: true);
      expect(android.projectId, equals('demo-koma'));
      expect(android.apiKey, equals('demo-api-key'));

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ios = DefaultFirebaseOptions.currentPlatform(useEmulator: true);
      expect(ios.projectId, equals('demo-koma'));
      expect(ios.iosBundleId, equals('com.ciannavei.koma'));
    });

    test('throws StateError when unconfigured and not in emulator mode', () {
      if (DefaultFirebaseOptions.isConfigured) return;

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        DefaultFirebaseOptions.currentPlatform,
        throwsA(isA<StateError>()),
      );
    });

    test('throws UnsupportedError on desktop platforms', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(
        () => DefaultFirebaseOptions.currentPlatform(useEmulator: true),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
