import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// User profile record representing `users/{uid}` in Cloud Firestore.
class UserProfileRecord extends Equatable {
  /// Creates a [UserProfileRecord].
  const new({
    required this.uid,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.photoUrl,
    this.uiLocale = 'en',
    this.preferredLanguages = const ['en', 'it'],
    this.contentRatings = const ['safe', 'suggestive'],
    this.notificationsEnabled = true,
  });

  /// Creates a [UserProfileRecord] from a Firestore [DocumentSnapshot].
  factory fromDocument(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return UserProfileRecord.fromMap(data, uid: snapshot.id);
  }

  /// Deserializes a [UserProfileRecord] from a raw map.
  factory fromMap(Map<String, dynamic> map, {String? uid}) {
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

    List<String> parseStringList(dynamic value, List<String> fallback) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return fallback;
    }

    return UserProfileRecord(
      uid: (map['uid'] as String?) ?? uid ?? '',
      email: (map['email'] as String?) ?? '',
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      uiLocale: (map['uiLocale'] as String?) ?? 'en',
      preferredLanguages: parseStringList(map['preferredLanguages'], const [
        'en',
        'it',
      ]),
      contentRatings: parseStringList(map['contentRatings'], const [
        'safe',
        'suggestive',
      ]),
      notificationsEnabled: (map['notificationsEnabled'] as bool?) ?? true,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  /// Immutable Firebase Auth UID matching the document ID.
  final String uid;

  /// User email address.
  final String email;

  /// Optional human-readable display name.
  final String? displayName;

  /// Optional avatar URL.
  final String? photoUrl;

  /// User interface locale code (`'en'` or `'it'`).
  final String uiLocale;

  /// User's preferred scanlation languages (e.g. `['en', 'it']`).
  final List<String> preferredLanguages;

  /// Content rating filters (e.g. `['safe', 'suggestive']`).
  final List<String> contentRatings;

  /// Global push notification toggle.
  final bool notificationsEnabled;

  /// Creation timestamp (immutable in security rules).
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  /// Serializes this record into a Firestore document map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'uiLocale': uiLocale,
      'preferredLanguages': preferredLanguages,
      'contentRatings': contentRatings,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copies this record with modified fields.
  UserProfileRecord copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? uiLocale,
    List<String>? preferredLanguages,
    List<String>? contentRatings,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileRecord(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      uiLocale: uiLocale ?? this.uiLocale,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      contentRatings: contentRatings ?? this.contentRatings,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoUrl,
    uiLocale,
    preferredLanguages,
    contentRatings,
    notificationsEnabled,
    createdAt,
    updatedAt,
  ];
}
