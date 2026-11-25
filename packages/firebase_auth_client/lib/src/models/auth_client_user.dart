import 'package:equatable/equatable.dart';

/// {@template auth_client_user}
/// Represents an authenticated user from the authentication client.
/// {@endtemplate}
class AuthClientUser extends Equatable {
  /// {@macro auth_client_user}
  const new({required this.uid, this.email, this.displayName, this.photoUrl});

  /// The unique identifier of the user.
  final String uid;

  /// The primary email address of the user, if available.
  final String? email;

  /// The display name of the user, if available.
  final String? displayName;

  /// The profile photo URL of the user, if available.
  final String? photoUrl;

  /// Empty user representation for unauthenticated state.
  static const empty = AuthClientUser(uid: '');

  /// Whether the user is empty/unauthenticated.
  bool get isEmpty => this == AuthClientUser.empty;

  /// Whether the user is not empty/authenticated.
  bool get isNotEmpty => this != AuthClientUser.empty;

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl];
}
