import 'package:auth_repository/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:library_repository/library_repository.dart';

/// {@template app_state}
/// Represents the global application state for authentication and user
/// preferences.
/// {@endtemplate}
class AppState extends Equatable {
  /// {@macro app_state}
  const new({
    this.user = AppUser.empty,
    this.preferredLanguages = const ['en', 'it'],
    this.contentRatings = const ['safe', 'suggestive'],
    this.notificationsEnabled = true,
    this.settings,
  });

  /// The currently authenticated [AppUser], or [AppUser.empty] if none.
  final AppUser user;

  /// Preferred languages for MangaDex chapter translations.
  final List<String> preferredLanguages;

  /// Allowed content rating categories.
  final List<String> contentRatings;

  /// Whether push notifications are enabled for the current user.
  final bool notificationsEnabled;

  /// The current user settings profile from Firestore, if available.
  final UserSettingsProfile? settings;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => user.isNotEmpty;

  /// Creates a copy of this [AppState] with the specified fields replaced.
  AppState copyWith({
    AppUser? user,
    List<String>? preferredLanguages,
    List<String>? contentRatings,
    bool? notificationsEnabled,
    UserSettingsProfile? settings,
  }) {
    return AppState(
      user: user ?? this.user,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      contentRatings: contentRatings ?? this.contentRatings,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
    user,
    preferredLanguages,
    contentRatings,
    notificationsEnabled,
    settings,
  ];
}
