import 'package:flutter_test/flutter_test.dart';
import 'package:notifications_repository/notifications_repository.dart';

void main() {
  group('NotificationsFailure', () {
    test('supports value equality', () {
      expect(
        const NotificationsFailure('error'),
        equals(const NotificationsFailure('error')),
      );
      expect(
        const NotificationsFailure('error 1'),
        isNot(equals(const NotificationsFailure('error 2'))),
      );
    });

    test('has expected default message', () {
      const failure = NotificationsFailure();
      expect(failure.message, 'An unknown notifications failure occurred.');
      expect(failure.cause, isNull);
      expect(failure.stackTrace, isNull);
    });

    test('supports named constructor factory', () {
      final cause = Exception('boom');
      final stackTrace = StackTrace.current;
      final failure = NotificationsFailure.from(
        message: 'custom message',
        cause: cause,
        stackTrace: stackTrace,
      );

      expect(failure.message, 'custom message');
      expect(failure.cause, cause);
      expect(failure.stackTrace, stackTrace);
    });

    test('toString includes message and cause', () {
      final cause = Exception('root-cause');
      final failure = NotificationsFailure('Failure msg', cause);
      expect(failure.toString(), contains('Failure msg'));
      expect(failure.toString(), contains('root-cause'));
    });
  });
}
