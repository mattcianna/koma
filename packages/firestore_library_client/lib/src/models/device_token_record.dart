import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Device token record representing `users/{uid}/devices/{deviceId}`.
class DeviceTokenRecord extends Equatable {
  /// Creates a [DeviceTokenRecord].
  const new({
    required this.deviceId,
    required this.token,
    required this.platform,
    required this.updatedAt,
  });

  /// Creates a [DeviceTokenRecord] from a Firestore [DocumentSnapshot].
  factory fromDocument(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return DeviceTokenRecord.fromMap(data, deviceId: snapshot.id);
  }

  /// Deserializes a [DeviceTokenRecord] from a raw map.
  factory fromMap(Map<String, dynamic> map, {String? deviceId}) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    return DeviceTokenRecord(
      deviceId: (map['deviceId'] as String?) ?? deviceId ?? '',
      token: (map['token'] as String?) ?? '',
      platform: (map['platform'] as String?) ?? 'android',
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  /// Unique client hardware or install identifier matching the document ID.
  final String deviceId;

  /// FCM push registration token.
  final String token;

  /// Operating system platform (`'android'` or `'ios'`).
  final String platform;

  /// Last token update timestamp.
  final DateTime updatedAt;

  /// Serializes this record into a Firestore document map.
  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'token': token,
      'platform': platform,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copies this record with modified fields.
  DeviceTokenRecord copyWith({
    String? deviceId,
    String? token,
    String? platform,
    DateTime? updatedAt,
  }) {
    return DeviceTokenRecord(
      deviceId: deviceId ?? this.deviceId,
      token: token ?? this.token,
      platform: platform ?? this.platform,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [deviceId, token, platform, updatedAt];
}
