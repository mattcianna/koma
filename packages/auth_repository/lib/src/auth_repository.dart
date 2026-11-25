import 'dart:async';

import 'package:auth_repository/src/exceptions/auth_failure.dart';
import 'package:auth_repository/src/models/app_user.dart';
import 'package:firebase_auth_client/firebase_auth_client.dart'
    hide UnknownAuthFailure;

/// {@template auth_repository}
/// Repository managing user authentication and session state.
/// {@endtemplate}
class AuthRepository {
  /// {@macro auth_repository}
  new({FirebaseAuthClient? authClient})
    : _authClient = authClient ?? FirebaseAuthClient();

  final FirebaseAuthClient _authClient;

  /// Canonical email address used for QA test account login bypass.
  static const testAccountEmail = 'test@mangatracker.local';

  /// Canonical password used for QA test account login bypass.
  static const testAccountPassword = 'KomaTest!2026#Dev';

  /// Stream of [AppUser] updates. Emits [AppUser.empty] when unauthenticated.
  Stream<AppUser> get user {
    return _authClient.user.map((clientUser) {
      if (clientUser == null || clientUser.isEmpty) {
        return AppUser.empty;
      }
      return AppUser.fromAuthClientUser(clientUser);
    });
  }

  /// The currently authenticated [AppUser], or [AppUser.empty] if none.
  AppUser get currentUser {
    final clientUser = _authClient.currentUser;
    if (clientUser == null || clientUser.isEmpty) {
      return AppUser.empty;
    }
    return AppUser.fromAuthClientUser(clientUser);
  }

  /// Signs in a user using [email] and [password].
  ///
  /// Throws [InvalidCredentialsFailure] if the credentials are invalid.
  /// Throws [NetworkFailure] if a network error occurs.
  /// Throws [UnknownAuthFailure] on any other error.
  Future<void> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _authClient.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on AuthClientException catch (error) {
      throw AuthFailure.fromAuthClientException(error);
    } catch (error, stackTrace) {
      throw UnknownAuthFailure(error, stackTrace);
    }
  }

  /// Registers a new user account with [email] and [password], optionally
  /// setting their [displayName].
  ///
  /// Throws [EmailAlreadyInUseFailure] if the email is already registered.
  /// Throws [WeakPasswordFailure] if the password is too weak.
  /// Throws [InvalidCredentialsFailure] if the email is invalid.
  /// Throws [NetworkFailure] if a network error occurs.
  /// Throws [UnknownAuthFailure] on any other error.
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      await _authClient.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
    } on AuthClientException catch (error) {
      throw AuthFailure.fromAuthClientException(error);
    } catch (error, stackTrace) {
      throw UnknownAuthFailure(error, stackTrace);
    }
  }

  /// Initiates interactive Google Sign-In and authenticates with Firebase.
  ///
  /// Throws [GoogleSignInCancelledFailure] if the user cancels Google Sign-In.
  /// Throws [GoogleSignInFailure] on Google Sign-In failures.
  /// Throws [NetworkFailure] on network errors.
  /// Throws [EmailAlreadyInUseFailure] if an account exists with a different
  /// credential.
  /// Throws [UnknownAuthFailure] on any other error.
  Future<void> logInWithGoogle() async {
    try {
      await _authClient.signInWithGoogle();
    } on AuthClientException catch (error) {
      throw AuthFailure.fromAuthClientException(error);
    } catch (error, stackTrace) {
      throw UnknownAuthFailure(error, stackTrace);
    }
  }

  /// Signs in using the canonical QA test account credentials.
  ///
  /// Throws [InvalidCredentialsFailure] if the credentials are rejected.
  /// Throws [NetworkFailure] on network errors.
  /// Throws [UnknownAuthFailure] on any other error.
  Future<void> logInWithTestAccount({
    String email = testAccountEmail,
    String password = testAccountPassword,
  }) async {
    await logInWithEmailAndPassword(email: email, password: password);
  }

  /// Signs out the currently authenticated user.
  ///
  /// Throws [NetworkFailure] on network failures.
  /// Throws [UnknownAuthFailure] on any other error.
  Future<void> logOut() async {
    try {
      await _authClient.signOut();
    } on AuthClientException catch (error) {
      throw AuthFailure.fromAuthClientException(error);
    } catch (error, stackTrace) {
      throw UnknownAuthFailure(error, stackTrace);
    }
  }
}
