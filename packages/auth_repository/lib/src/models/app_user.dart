import 'package:equatable/equatable.dart';
import 'package:firebase_auth_client/firebase_auth_client.dart';

/// {@template app_user}
/// Represents an authenticated user in the domain layer.
/// {@endtemplate}
class AppUser extends Equatable {
  /// {@macro app_user}
  const new({required this.uid, this.email, this.displayName, this.photoUrl});

  /// Creates an [AppUser] from an [AuthClientUser].
  factory fromAuthClientUser(AuthClientUser clientUser) {
    if (clientUser.isEmpty) {
      return AppUser.empty;
    }
    return AppUser(
      uid: clientUser.uid,
      email: clientUser.email,
      displayName: clientUser.displayName,
      photoUrl: clientUser.photoUrl,
    );
  }

  /// The unique identifier of the user.
  final String uid;

  /// The primary email address of the user, if available.
  final String? email;

  /// The display name of the user, if available.
  final String? displayName;

  /// The profile photo URL of the user, if available.
  final String? photoUrl;

  /// Empty user representation for unauthenticated state.
  static const empty = AppUser(uid: '');

  /// Whether the user is empty / unauthenticated.
  bool get isEmpty => this == AppUser.empty;

  /// Whether the user is not empty / authenticated.
  bool get isNotEmpty => this != AppUser.empty;

  /// Creates a copy of this [AppUser] with the given fields replaced.
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl];
}
