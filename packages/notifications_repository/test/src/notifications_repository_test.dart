import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notifications_repository/notifications_repository.dart';

class _MockFirestoreLibraryClient extends Mock
    implements FirestoreLibraryClient;

class _MockFirebaseMessaging extends Mock implements FirebaseMessaging;

class _MockNotificationSettings extends Mock implements NotificationSettings;

void main() {
  group('NotificationsRepository', () {
    late FirestoreLibraryClient firestoreClient;
    late FirebaseMessaging firebaseMessaging;
    late NotificationSettings authorizedSettings;
    late NotificationSettings deniedSettings;
    late StreamController<String> tokenRefreshController;
    late NotificationsRepository repository;

    const testUid = 'koma-test-uid-001';
    const testDeviceId = 'pixel-9-device-001';
    const testPlatform = 'android';
    const validFcmToken = 'fcm-token-at-least-32-chars-long-0123456789-abcdef';

    setUp(() {
      firestoreClient = _MockFirestoreLibraryClient();
      firebaseMessaging = _MockFirebaseMessaging();
      authorizedSettings = _MockNotificationSettings();
      deniedSettings = _MockNotificationSettings();
      tokenRefreshController = StreamController<String>.broadcast();

      when(() => authorizedSettings.authorizationStatus)
          .thenReturn(AuthorizationStatus.authorized);
      when(() => deniedSettings.authorizationStatus)
          .thenReturn(AuthorizationStatus.denied);

      when(
        () => firebaseMessaging.requestPermission(
          alert: any(named: 'alert'),
          announcement: any(named: 'announcement'),
          badge: any(named: 'badge'),
          carPlay: any(named: 'carPlay'),
          criticalAlert: any(named: 'criticalAlert'),
          provisional: any(named: 'provisional'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => authorizedSettings);

      when(() => firebaseMessaging.getToken())
          .thenAnswer((_) async => validFcmToken);

      when(() => firebaseMessaging.onTokenRefresh)
          .thenAnswer((_) => tokenRefreshController.stream);

      when(
        () => firestoreClient.upsertDeviceToken(
          uid: any(named: 'uid'),
          deviceId: any(named: 'deviceId'),
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => firestoreClient.deleteDeviceToken(
          uid: any(named: 'uid'),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer((_) async {});

      repository = NotificationsRepository(
        firestoreClient: firestoreClient,
        firebaseMessaging: firebaseMessaging,
      );
    });

    tearDown(() async {
      await tokenRefreshController.close();
    });

    group('constructor and deviceIdProvider', () {
      test('initializes with default values', () {
        final repo = NotificationsRepository(firestoreClient: firestoreClient);
        expect(repo.firestoreClient, equals(firestoreClient));
        expect(repo.firebaseMessaging, isNull);
        expect(repo.deviceIdProvider, isNull);
      });

      test('getDeviceId returns provider result when configured', () async {
        final repo = NotificationsRepository(
          firestoreClient: firestoreClient,
          deviceIdProvider: () async => 'custom-id-999',
        );

        expect(repo.deviceIdProvider, isNotNull);
        final deviceId = await repo.getDeviceId();
        expect(deviceId, equals('custom-id-999'));
      });

      test('getDeviceId returns null when provider is null', () async {
        final deviceId = await repository.getDeviceId();
        expect(deviceId, isNull);
      });
    });

    group('requestPermission', () {
      test('delegates to FirebaseMessaging and returns settings', () async {
        final result = await repository.requestPermission();
        expect(result.authorizationStatus, AuthorizationStatus.authorized);
        verify(() => firebaseMessaging.requestPermission()).called(1);
      });

      test(
        'wraps exception in NotificationsFailure when request fails',
        () async {
          when(
            () => firebaseMessaging.requestPermission(
              alert: any(named: 'alert'),
              announcement: any(named: 'announcement'),
              badge: any(named: 'badge'),
              carPlay: any(named: 'carPlay'),
              criticalAlert: any(named: 'criticalAlert'),
              provisional: any(named: 'provisional'),
              sound: any(named: 'sound'),
            ),
          ).thenThrow(Exception('Permission platform channel error'));

          expect(
            () => repository.requestPermission(),
            throwsA(isA<NotificationsFailure>()),
          );
        },
      );
    });

    group('onTokenRefresh', () {
      test('emits tokens from FirebaseMessaging.onTokenRefresh', () async {
        final emitted = <String>[];
        final sub = repository.onTokenRefresh.listen(emitted.add);

        tokenRefreshController
          ..add('token-1')
          ..add('token-2');
        await pumpEventQueue();

        expect(emitted, equals(['token-1', 'token-2']));
        await sub.cancel();
      });
    });

    group('syncDeviceToken', () {
      group('in live / non-emulator mode (isEmulatorMode == false)', () {
        test('successfully retrieves token and upserts to Firestore', () async {
          final token = await repository.syncDeviceToken(
            uid: testUid,
            deviceId: testDeviceId,
            platform: testPlatform,
          );

          expect(token, equals(validFcmToken));
          verify(
            () => firestoreClient.upsertDeviceToken(
              uid: testUid,
              deviceId: testDeviceId,
              token: validFcmToken,
              platform: testPlatform,
            ),
          ).called(1);
        });

        test('returns null gracefully when permission is denied', () async {
          when(
            () => firebaseMessaging.requestPermission(
              alert: any(named: 'alert'),
              announcement: any(named: 'announcement'),
              badge: any(named: 'badge'),
              carPlay: any(named: 'carPlay'),
              criticalAlert: any(named: 'criticalAlert'),
              provisional: any(named: 'provisional'),
              sound: any(named: 'sound'),
            ),
          ).thenAnswer((_) async => deniedSettings);

          final token = await repository.syncDeviceToken(
            uid: testUid,
            deviceId: testDeviceId,
            platform: testPlatform,
          );

          expect(token, isNull);
          verifyNever(() => firebaseMessaging.getToken());
          verifyNever(
            () => firestoreClient.upsertDeviceToken(
              uid: any(named: 'uid'),
              deviceId: any(named: 'deviceId'),
              token: any(named: 'token'),
              platform: any(named: 'platform'),
            ),
          );
        });

        test('returns null gracefully when requestPermission throws', () async {
          when(
            () => firebaseMessaging.requestPermission(
              alert: any(named: 'alert'),
              announcement: any(named: 'announcement'),
              badge: any(named: 'badge'),
              carPlay: any(named: 'carPlay'),
              criticalAlert: any(named: 'criticalAlert'),
              provisional: any(named: 'provisional'),
              sound: any(named: 'sound'),
            ),
          ).thenThrow(Exception('OS permission failure'));

          final token = await repository.syncDeviceToken(
            uid: testUid,
            deviceId: testDeviceId,
            platform: testPlatform,
          );

          expect(token, isNull);
          verifyNever(
            () => firestoreClient.upsertDeviceToken(
              uid: any(named: 'uid'),
              deviceId: any(named: 'deviceId'),
              token: any(named: 'token'),
              platform: any(named: 'platform'),
            ),
          );
        });

        test(
          'returns null gracefully when getToken throws FirebaseException',
          () async {
            when(() => firebaseMessaging.getToken()).thenThrow(
              FirebaseException(
                plugin: 'firebase_messaging',
                code: 'FIS_AUTH_ERROR',
                message: 'Firebase Installations service auth error',
              ),
            );

            final token = await repository.syncDeviceToken(
              uid: testUid,
              deviceId: testDeviceId,
              platform: testPlatform,
            );

            expect(token, isNull);
            verifyNever(
              () => firestoreClient.upsertDeviceToken(
                uid: any(named: 'uid'),
                deviceId: any(named: 'deviceId'),
                token: any(named: 'token'),
                platform: any(named: 'platform'),
              ),
            );
          },
        );

        test('returns null gracefully when getToken returns null', () async {
          when(() => firebaseMessaging.getToken())
              .thenAnswer((_) async => null);

          final token = await repository.syncDeviceToken(
            uid: testUid,
            deviceId: testDeviceId,
            platform: testPlatform,
          );

          expect(token, isNull);
          verifyNever(
            () => firestoreClient.upsertDeviceToken(
              uid: any(named: 'uid'),
              deviceId: any(named: 'deviceId'),
              token: any(named: 'token'),
              platform: any(named: 'platform'),
            ),
          );
        });

        test(
          'returns null gracefully when getToken is shorter than 32 chars',
          () async {
            when(() => firebaseMessaging.getToken())
                .thenAnswer((_) async => 'short-token-less-than-32');

            final token = await repository.syncDeviceToken(
              uid: testUid,
              deviceId: testDeviceId,
              platform: testPlatform,
            );

            expect(token, isNull);
            verifyNever(
              () => firestoreClient.upsertDeviceToken(
                uid: any(named: 'uid'),
                deviceId: any(named: 'deviceId'),
                token: any(named: 'token'),
                platform: any(named: 'platform'),
              ),
            );
          },
        );

        test(
          'throws NotificationsFailure when Firestore upsert fails',
          () async {
            when(
              () => firestoreClient.upsertDeviceToken(
                uid: any(named: 'uid'),
                deviceId: any(named: 'deviceId'),
                token: any(named: 'token'),
                platform: any(named: 'platform'),
              ),
            ).thenThrow(Exception('Firestore write rejected'));

            expect(
              () => repository.syncDeviceToken(
                uid: testUid,
                deviceId: testDeviceId,
                platform: testPlatform,
              ),
              throwsA(isA<NotificationsFailure>()),
            );
          },
        );
      });

      group('in emulator mode (isEmulatorMode == true)', () {
        test('uses live token if available and valid length >= 32', () async {
          final token = await repository.syncDeviceToken(
            uid: testUid,
            deviceId: testDeviceId,
            platform: testPlatform,
            isEmulatorMode: true,
          );

          expect(token, equals(validFcmToken));
          verify(
            () => firestoreClient.upsertDeviceToken(
              uid: testUid,
              deviceId: testDeviceId,
              token: validFcmToken,
              platform: testPlatform,
            ),
          ).called(1);
        });

        test(
          'generates fallback token when getToken throws FIS_AUTH_ERROR',
          () async {
            when(() => firebaseMessaging.getToken()).thenThrow(
              FirebaseException(
                plugin: 'firebase_messaging',
                code: 'FIS_AUTH_ERROR',
                message: 'Simulated physical Pixel 9 offline emulator error',
              ),
            );

            final token = await repository.syncDeviceToken(
              uid: testUid,
              deviceId: testDeviceId,
              platform: testPlatform,
              isEmulatorMode: true,
            );

            expect(token, isNotNull);
            expect(token!.length, greaterThanOrEqualTo(32));
            expect(token, equals('pixel9-physical-dev-token-$testDeviceId'));
            verify(
              () => firestoreClient.upsertDeviceToken(
                uid: testUid,
                deviceId: testDeviceId,
                token: token,
                platform: testPlatform,
              ),
            ).called(1);
          },
        );

        test(
          'generates fallback token when getToken throws general Exception',
          () async {
            when(() => firebaseMessaging.getToken())
                .thenThrow(Exception('General failure'));

            final token = await repository.syncDeviceToken(
              uid: testUid,
              deviceId: testDeviceId,
              platform: testPlatform,
              isEmulatorMode: true,
            );

            expect(token, isNotNull);
            expect(token!.length, greaterThanOrEqualTo(32));
            expect(token, startsWith('pixel9-physical-dev-token-'));
            verify(
              () => firestoreClient.upsertDeviceToken(
                uid: testUid,
                deviceId: testDeviceId,
                token: token,
                platform: testPlatform,
              ),
            ).called(1);
          },
        );

        test('generates fallback token when getToken returns null', () async {
          when(() => firebaseMessaging.getToken())
              .thenAnswer((_) async => null);

          final token = await repository.syncDeviceToken(
            uid: testUid,
            deviceId: testDeviceId,
            platform: testPlatform,
            isEmulatorMode: true,
          );

          expect(token, isNotNull);
          expect(token!.length, greaterThanOrEqualTo(32));
          verify(
            () => firestoreClient.upsertDeviceToken(
              uid: testUid,
              deviceId: testDeviceId,
              token: token,
              platform: testPlatform,
            ),
          ).called(1);
        });

        test(
          'generates fallback token when getToken returns token < 32 chars',
          () async {
            when(() => firebaseMessaging.getToken())
                .thenAnswer((_) async => 'short');

            final token = await repository.syncDeviceToken(
              uid: testUid,
              deviceId: testDeviceId,
              platform: testPlatform,
              isEmulatorMode: true,
            );

            expect(token, isNotNull);
            expect(token!.length, greaterThanOrEqualTo(32));
            expect(token, startsWith('pixel9-physical-dev-token-'));
          },
        );

        test(
          'generates fallback token when requestPermission throws',
          () async {
            when(
              () => firebaseMessaging.requestPermission(
                alert: any(named: 'alert'),
                announcement: any(named: 'announcement'),
                badge: any(named: 'badge'),
                carPlay: any(named: 'carPlay'),
                criticalAlert: any(named: 'criticalAlert'),
                provisional: any(named: 'provisional'),
                sound: any(named: 'sound'),
              ),
            ).thenThrow(Exception('Permission channel crashed'));

            final token = await repository.syncDeviceToken(
              uid: testUid,
              deviceId: testDeviceId,
              platform: testPlatform,
              isEmulatorMode: true,
            );

            expect(token, isNotNull);
            expect(token!.length, greaterThanOrEqualTo(32));
          },
        );

        test(
          'pads fallback token when deviceId is very short (< 6 chars)',
          () async {
            when(() => firebaseMessaging.getToken()).thenThrow(
              FirebaseException(
                plugin: 'firebase_messaging',
                code: 'FIS_AUTH_ERROR',
              ),
            );

            // Base 'pixel9-physical-dev-token-1' is 27 chars, padded to 32
            const shortDeviceId = '1';
            final token = await repository.syncDeviceToken(
              uid: testUid,
              deviceId: shortDeviceId,
              platform: testPlatform,
              isEmulatorMode: true,
            );

            expect(token, isNotNull);
            expect(token!.length, greaterThanOrEqualTo(32));
            expect(token, equals('pixel9-physical-dev-token-100000'));
            verify(
              () => firestoreClient.upsertDeviceToken(
                uid: testUid,
                deviceId: shortDeviceId,
                token: token,
                platform: testPlatform,
              ),
            ).called(1);
          },
        );
      });
    });

    group('unregisterDeviceToken', () {
      test('calls firestoreClient.deleteDeviceToken', () async {
        await repository.unregisterDeviceToken(
          uid: testUid,
          deviceId: testDeviceId,
        );

        verify(
          () => firestoreClient.deleteDeviceToken(
            uid: testUid,
            deviceId: testDeviceId,
          ),
        ).called(1);
      });

      test(
        'wraps exception in NotificationsFailure when delete fails',
        () async {
          when(
            () => firestoreClient.deleteDeviceToken(
              uid: any(named: 'uid'),
              deviceId: any(named: 'deviceId'),
            ),
          ).thenThrow(Exception('Firestore delete failure'));

          expect(
            () => repository.unregisterDeviceToken(
              uid: testUid,
              deviceId: testDeviceId,
            ),
            throwsA(isA<NotificationsFailure>()),
          );
        },
      );
    });

    group('subscribeToTokenRefresh', () {
      test(
        'upserts refreshed token to Firestore and invokes onTokenSynced',
        () async {
          final syncedTokens = <String>[];
          final sub = repository.subscribeToTokenRefresh(
            uid: testUid,
            deviceId: testDeviceId,
            platform: testPlatform,
            onTokenSynced: syncedTokens.add,
          );

          tokenRefreshController.add(validFcmToken);
          await pumpEventQueue();

          expect(syncedTokens, equals([validFcmToken]));
          verify(
            () => firestoreClient.upsertDeviceToken(
              uid: testUid,
              deviceId: testDeviceId,
              token: validFcmToken,
              platform: testPlatform,
            ),
          ).called(1);

          await sub.cancel();
        },
      );

      test('ignores refreshed tokens shorter than 32 characters', () async {
        final syncedTokens = <String>[];
        final sub = repository.subscribeToTokenRefresh(
          uid: testUid,
          deviceId: testDeviceId,
          platform: testPlatform,
          onTokenSynced: syncedTokens.add,
        );

        tokenRefreshController.add('too-short-token');
        await pumpEventQueue();

        expect(syncedTokens, isEmpty);
        verifyNever(
          () => firestoreClient.upsertDeviceToken(
            uid: any(named: 'uid'),
            deviceId: any(named: 'deviceId'),
            token: any(named: 'token'),
            platform: any(named: 'platform'),
          ),
        );

        await sub.cancel();
      });

      test(
        'invokes onError when Firestore upsert fails during refresh',
        () async {
          final errors = <Object>[];
          when(
            () => firestoreClient.upsertDeviceToken(
              uid: any(named: 'uid'),
              deviceId: any(named: 'deviceId'),
              token: any(named: 'token'),
              platform: any(named: 'platform'),
            ),
          ).thenThrow(Exception('Firestore write failed'));

          final sub = repository.subscribeToTokenRefresh(
            uid: testUid,
            deviceId: testDeviceId,
            platform: testPlatform,
            onError: (err, st) => errors.add(err),
          );

          tokenRefreshController.add(validFcmToken);
          await pumpEventQueue();

          expect(errors, hasLength(1));
          await sub.cancel();
        },
      );

      test('invokes onError when stream emits an error', () async {
        final errors = <Object>[];
        final sub = repository.subscribeToTokenRefresh(
          uid: testUid,
          deviceId: testDeviceId,
          platform: testPlatform,
          onError: (err, st) => errors.add(err),
        );

        tokenRefreshController.addError(Exception('FCM stream error'));
        await pumpEventQueue();

        expect(errors, hasLength(1));
        await sub.cancel();
      });
    });
  });
}
