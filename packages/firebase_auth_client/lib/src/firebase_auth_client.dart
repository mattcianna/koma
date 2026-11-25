import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_client/src/exceptions/auth_client_exception.dart';
import 'package:firebase_auth_client/src/models/auth_client_user.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// {@template firebase_auth_client}
/// Client that manages authentication workflows using Firebase Authentication
/// and Google Sign-In.
/// {@endtemplate}
class FirebaseAuthClient {
  /// {@macro firebase_auth_client}
  new({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Stream of [AuthClientUser] emitted on authentication state changes.
  Stream<AuthClientUser?> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser?._toAuthClientUser();
    });
  }

  /// Returns the currently authenticated [AuthClientUser], or `null` if none.
  AuthClientUser? get currentUser {
    return _firebaseAuth.currentUser?._toAuthClientUser();
  }

  /// Signs in a user using [email] and [password].
  ///
  /// Throws [InvalidCredentialsAuthFailure] if credentials are invalid.
  /// Throws [NetworkAuthFailure] if a network error occurs.
  /// Throws [UnknownAuthFailure] on any other error.
  Future<AuthClientUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const UnknownAuthFailure('Firebase user was null after sign-in.');
      }
      return user._toAuthClientUser();
    } on AuthClientException {
      rethrow;
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _mapFirebaseAuthException(error, stackTrace);
    } catch (error, stackTrace) {
      throw UnknownAuthFailure(error, stackTrace);
    }
  }

  /// Registers a new user account with [email] and [password], optionally
  /// setting their [displayName].
  ///
  /// Throws [EmailAlreadyInUseAuthFailure] if the email is already registered.
  /// Throws [WeakPasswordAuthFailure] if the password is too weak.
  /// Throws [InvalidCredentialsAuthFailure] if the email is malformed.
  /// Throws [NetworkAuthFailure] if a network error occurs.
  /// Throws [UnknownAuthFailure] on any other error.
  Future<AuthClientUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const UnknownAuthFailure('Firebase user was null after sign-up.');
      }

      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
        return AuthClientUser(
          uid: user.uid,
          email: user.email,
          displayName: displayName,
          photoUrl: user.photoURL,
        );
      }

      return user._toAuthClientUser();
    } on AuthClientException {
      rethrow;
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _mapFirebaseAuthException(error, stackTrace);
    } catch (error, stackTrace) {
      throw UnknownAuthFailure(error, stackTrace);
    }
  }

  /// Initiates interactive Google Sign-In and authenticates with Firebase.
  ///
  /// Throws [GoogleSignInCancelledAuthFailure] if the user cancels the prompt.
  /// Throws [GoogleSignInAuthFailure] on Google Sign-In failures.
  /// Throws [NetworkAuthFailure] on network failures.
  /// Throws [EmailAlreadyInUseAuthFailure] if an account exists with a
  /// different credential.
  Future<AuthClientUser> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const GoogleSignInCancelledAuthFailure();
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const GoogleSignInAuthFailure(
          'Firebase user was null after Google credential sign-in.',
        );
      }
      return user._toAuthClientUser();
    } on AuthClientException {
      rethrow;
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _mapFirebaseAuthException(error, stackTrace, isGoogleSignIn: true);
    } catch (error, stackTrace) {
      throw GoogleSignInAuthFailure(error, stackTrace);
    }
  }

  /// Signs out the currently authenticated user from both Firebase and Google.
  ///
  /// Throws [NetworkAuthFailure] on network failures.
  /// Throws [UnknownAuthFailure] on any other error.
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } on FirebaseAuthException catch (error, stackTrace) {
      throw _mapFirebaseAuthException(error, stackTrace);
    } catch (error, stackTrace) {
      throw UnknownAuthFailure(error, stackTrace);
    }
  }

  AuthClientException _mapFirebaseAuthException(
    FirebaseAuthException exception,
    StackTrace stackTrace, {
    bool isGoogleSignIn = false,
  }) {
    switch (exception.code) {
      case 'invalid-credential':
      case 'invalid-email':
      case 'wrong-password':
      case 'user-not-found':
      case 'user-disabled':
        return InvalidCredentialsAuthFailure(exception, stackTrace);
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return EmailAlreadyInUseAuthFailure(exception, stackTrace);
      case 'weak-password':
        return WeakPasswordAuthFailure(exception, stackTrace);
      case 'network-request-failed':
        return NetworkAuthFailure(exception, stackTrace);
      default:
        return isGoogleSignIn
            ? GoogleSignInAuthFailure(exception, stackTrace)
            : UnknownAuthFailure(exception, stackTrace);
    }
  }
}

extension on User {
  AuthClientUser _toAuthClientUser() {
    return AuthClientUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoURL,
    );
  }
}
