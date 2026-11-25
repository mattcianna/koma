import 'package:equatable/equatable.dart';
import 'package:firestore_library_client/firestore_library_client.dart';

/// Domain model representing a user's settings and reading preferences in Koma.
class UserSettingsProfile extends Equatable {
  /// Creates a [UserSettingsProfile].
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

  /// Factory constructor to map from a data layer [UserProfileRecord].
  factory fromRecord(UserProfileRecord record) {
    return UserSettingsProfile(
      uid: record.uid,
      email: record.email,
      displayName: record.displayName,
      photoUrl: record.photoUrl,
      uiLocale: record.uiLocale,
      preferredLanguages: record.preferredLanguages,
      contentRatings: record.contentRatings,
      notificationsEnabled: record.notificationsEnabled,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  /// Immutable Firebase Auth UID matching the document ID.
  final String uid;

  /// User email address.
  final String email;

  /// Optional human-readable display name.
  final String? displayName;

  /// Optional avatar image URL.
  final String? photoUrl;

  /// User interface locale code (`'en'` or `'it'`).
  final String uiLocale;

  /// User's preferred scanlation languages (e.g. `['en', 'it']`).
  final List<String> preferredLanguages;

  /// Content rating filters (e.g. `['safe', 'suggestive']`).
  final List<String> contentRatings;

  /// Global push notification delivery toggle.
  final bool notificationsEnabled;

  /// Profile creation timestamp (immutable).
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  /// Converts this profile into a data layer [UserProfileRecord].
  UserProfileRecord toRecord() {
    return UserProfileRecord(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      uiLocale: uiLocale,
      preferredLanguages: preferredLanguages,
      contentRatings: contentRatings,
      notificationsEnabled: notificationsEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Copies this [UserSettingsProfile] with optionally replaced fields.
  UserSettingsProfile copyWith({
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
    return UserSettingsProfile(
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
