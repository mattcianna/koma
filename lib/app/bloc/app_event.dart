import 'package:auth_repository/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:library_repository/library_repository.dart';

/// {@template app_event}
/// Base class for all application events.
/// {@endtemplate}
sealed class AppEvent extends Equatable {
  /// {@macro app_event}
  const new();

  @override
  List<Object?> get props => [];
}

/// {@template app_user_subscription_requested}
/// Event triggered to initialize subscription to authentication changes.
/// {@endtemplate}
final class AppUserSubscriptionRequested extends AppEvent {
  /// {@macro app_user_subscription_requested}
  const new();
}

/// {@template app_user_changed}
/// Event triggered when the authenticated [AppUser] changes.
/// {@endtemplate}
final class AppUserChanged extends AppEvent {
  /// {@macro app_user_changed}
  const new(this.user);

  /// The updated user entity.
  final AppUser user;

  @override
  List<Object?> get props => [user];
}

/// {@template app_settings_changed}
/// Event triggered when the user's Firestore [UserSettingsProfile] updates.
/// {@endtemplate}
final class AppSettingsChanged extends AppEvent {
  /// {@macro app_settings_changed}
  const new(this.settings);

  /// The updated user settings profile, or `null` if not found.
  final UserSettingsProfile? settings;

  @override
  List<Object?> get props => [settings];
}

/// {@template app_logout_requested}
/// Event triggered when the user requests to sign out.
/// {@endtemplate}
final class AppLogoutRequested extends AppEvent {
  /// {@macro app_logout_requested}
  const new();
}
