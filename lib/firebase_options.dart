import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart' show appFlavor;

const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const String _messagingSenderId = String.fromEnvironment(
  'FIREBASE_MESSAGING_SENDER_ID',
);
const String _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
const String _androidApiKey = String.fromEnvironment(
  'FIREBASE_ANDROID_API_KEY',
);
const String _androidAppIdProd = String.fromEnvironment(
  'FIREBASE_ANDROID_APP_ID_PROD',
);
const String _androidAppIdDev = String.fromEnvironment(
  'FIREBASE_ANDROID_APP_ID_DEV',
);
const String _androidAppIdStg = String.fromEnvironment(
  'FIREBASE_ANDROID_APP_ID_STG',
);
const String _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
const String _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
const String _iosClientId = String.fromEnvironment('FIREBASE_IOS_CLIENT_ID');
const String _iosBundleId = String.fromEnvironment(
  'FIREBASE_IOS_BUNDLE_ID',
  defaultValue: 'com.ciannavei.koma',
);

/// Compile-time [FirebaseOptions] loader decoupled from personal credentials.
///
/// Supply values via `--dart-define-from-file=.env.firebase.json` (see
/// `.env.firebase.json.example`) for cloud builds, or run with
/// `--dart-define=USE_FIREBASE_EMULATOR=true` to use the zero-config local
/// `demo-koma` emulator fallback.
abstract final class DefaultFirebaseOptions {
  /// Whether cloud Firebase configuration defines were provided at build time.
  static bool get isConfigured =>
      _projectId.isNotEmpty && !_projectId.startsWith('YOUR_');

  /// Returns the [FirebaseOptions] matching the active platform and flavor.
  ///
  /// When [isConfigured] is `false` and [useEmulator] is `true`, returns safe
  /// `demo-koma` options suitable for the Firebase Local Emulator Suite.
  /// Throws a [StateError] when [isConfigured] and [useEmulator] are both
  /// `false`.
  static FirebaseOptions currentPlatform({bool useEmulator = false}) {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _resolveAndroid(useEmulator: useEmulator);
      case TargetPlatform.iOS:
        return _resolveIos(useEmulator: useEmulator);
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for '
          '$defaultTargetPlatform.',
        );
    }
  }

  static FirebaseOptions _resolveAndroid({required bool useEmulator}) {
    if (!isConfigured) {
      if (useEmulator) {
        return const FirebaseOptions(
          apiKey: 'demo-api-key',
          appId: '1:000000000000:android:0000000000000000000000',
          messagingSenderId: '000000000000',
          projectId: 'demo-koma',
          storageBucket: 'demo-koma.appspot.com',
        );
      }
      _throwUnconfiguredError();
    }

    final appId = switch (appFlavor) {
      'development' =>
        _androidAppIdDev.isNotEmpty ? _androidAppIdDev : _androidAppIdProd,
      'staging' =>
        _androidAppIdStg.isNotEmpty ? _androidAppIdStg : _androidAppIdProd,
      _ => _androidAppIdProd,
    };

    return FirebaseOptions(
      apiKey: _androidApiKey,
      appId: appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket,
    );
  }

  static FirebaseOptions _resolveIos({required bool useEmulator}) {
    if (!isConfigured) {
      if (useEmulator) {
        return const FirebaseOptions(
          apiKey: 'demo-api-key',
          appId: '1:000000000000:ios:0000000000000000000000',
          messagingSenderId: '000000000000',
          projectId: 'demo-koma',
          storageBucket: 'demo-koma.appspot.com',
          iosBundleId: _iosBundleId,
        );
      }
      _throwUnconfiguredError();
    }

    return FirebaseOptions(
      apiKey: _iosApiKey,
      appId: _iosAppId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket,
      iosClientId: _iosClientId.isEmpty ? null : _iosClientId,
      iosBundleId: _iosBundleId,
    );
  }

  static Never _throwUnconfiguredError() {
    throw StateError(
      'Firebase is not configured. Pass '
      '--dart-define-from-file=.env.firebase.json (see '
      '.env.firebase.json.example) or run against the Firebase Local Emulator '
      'Suite with --dart-define=USE_FIREBASE_EMULATOR=true.',
    );
  }
}
