import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:notifications_repository/src/notifications_failure.dart';

/// {@template notifications_repository}
/// Domain repository responsible for managing FCM device tokens and
/// synchronizing them with Cloud Firestore.
/// {@endtemplate}
class NotificationsRepository {
  /// {@macro notifications_repository}
  new({
    required this.firestoreClient,
    this.firebaseMessaging,
    this.deviceIdProvider,
  });

  /// The underlying Firestore library client.
  final FirestoreLibraryClient firestoreClient;

  /// The optional [FirebaseMessaging] instance.
  final FirebaseMessaging? firebaseMessaging;

  /// The optional device identifier provider.
  final Future<String> Function()? deviceIdProvider;

  FirebaseMessaging get _messaging =>
      firebaseMessaging ?? FirebaseMessaging.instance;

  /// Retrieves the device identifier using [deviceIdProvider] if configured.
  Future<String?> getDeviceId() async => await deviceIdProvider?.call();

  /// Stream emitting new FCM push tokens as they are refreshed or rotated.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Requests notification permissions from the host operating system.
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    try {
      return await _messaging.requestPermission(
        alert: alert,
        announcement: announcement,
        badge: badge,
        carPlay: carPlay,
        criticalAlert: criticalAlert,
        provisional: provisional,
        sound: sound,
      );
    } on Exception catch (error, stackTrace) {
      throw NotificationsFailure(
        'Failed to request notification permission.',
        error,
        stackTrace,
      );
    }
  }

  /// Synchronizes the FCM device push token with Cloud Firestore.
  ///
  /// Requests notification permission and retrieves the registration token.
  ///
  /// If [isEmulatorMode] is `true` and the token is unavailable, invalid,
  /// or throws (e.g. `FIS_AUTH_ERROR`), generates a deterministic fallback
  /// token >= 32 characters in length and persists it to Firestore.
  ///
  /// If [isEmulatorMode] is `false` and permission is denied or token
  /// retrieval fails, returns `null` gracefully without throwing.
  Future<String?> syncDeviceToken({
    required String uid,
    required String deviceId,
    required String platform,
    bool isEmulatorMode = false,
  }) async {
    String? token;

    try {
      final settings = await _messaging.requestPermission();
      if (!isEmulatorMode &&
          settings.authorizationStatus == AuthorizationStatus.denied) {
        developer.log(
          'Notification permission denied for device $deviceId.',
          name: 'NotificationsRepository',
        );
        return null;
      }

      token = await _messaging.getToken();
    } on Exception catch (error, stackTrace) {
      if (!isEmulatorMode) {
        developer.log(
          'Failed to retrieve FCM device token: $error',
          name: 'NotificationsRepository',
          error: error,
          stackTrace: stackTrace,
        );
        return null;
      }
    }

    if (isEmulatorMode && (token == null || token.length < 32)) {
      token = _generateFallbackToken(deviceId);
    }

    if (token == null || token.length < 32) {
      developer.log(
        'FCM token is empty or shorter than 32 characters.',
        name: 'NotificationsRepository',
      );
      return null;
    }

    try {
      await firestoreClient.upsertDeviceToken(
        uid: uid,
        deviceId: deviceId,
        token: token,
        platform: platform,
      );
      return token;
    } on NotificationsFailure {
      rethrow;
    } on Exception catch (error, stackTrace) {
      throw NotificationsFailure(
        'Failed to upsert device token to Firestore.',
        error,
        stackTrace,
      );
    }
  }

  /// Unregisters the device push token document from Cloud Firestore.
  Future<void> unregisterDeviceToken({
    required String uid,
    required String deviceId,
  }) async {
    try {
      await firestoreClient.deleteDeviceToken(uid: uid, deviceId: deviceId);
    } on NotificationsFailure {
      rethrow;
    } on Exception catch (error, stackTrace) {
      throw NotificationsFailure(
        'Failed to unregister device token.',
        error,
        stackTrace,
      );
    }
  }

  /// Subscribes to FCM token refresh events and automatically updates
  /// the token in Firestore for the specified [uid] and [deviceId].
  ///
  /// Returns a [StreamSubscription] for cancellation.
  StreamSubscription<String> subscribeToTokenRefresh({
    required String uid,
    required String deviceId,
    required String platform,
    void Function(String token)? onTokenSynced,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return onTokenRefresh.listen((token) async {
      if (token.length < 32) return;
      try {
        await firestoreClient.upsertDeviceToken(
          uid: uid,
          deviceId: deviceId,
          token: token,
          platform: platform,
        );
        onTokenSynced?.call(token);
      } on Exception catch (error, stackTrace) {
        onError?.call(error, stackTrace);
      }
    }, onError: onError);
  }

  static String _generateFallbackToken(String deviceId) {
    final base = 'pixel9-physical-dev-token-$deviceId';
    if (base.length < 32) {
      return base.padRight(32, '0');
    }
    return base;
  }
}
