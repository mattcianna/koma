import 'package:equatable/equatable.dart';
import 'package:library_repository/library_repository.dart';

/// Status of the settings feature.
enum SettingsStatus {
  /// Initial state before settings stream is loaded.
  initial,

  /// Currently loading user settings.
  loading,

  /// User settings loaded successfully.
  loaded,

  /// An error occurred loading or updating settings.
  failure,
}

/// State for the user settings feature.
class SettingsState extends Equatable {
  /// Creates a [SettingsState].
  const new({
    this.status = SettingsStatus.initial,
    this.profile,
    this.errorMessage,
    this.infoMessage,
    this.isSigningOut = false,
    this.isSyncingToken = false,
  });

  /// The status of loading user settings.
  final SettingsStatus status;

  /// The active user settings profile, if loaded.
  final UserSettingsProfile? profile;

  /// Error message from failed operations.
  final String? errorMessage;

  /// Transient status or confirmation message key.
  final String? infoMessage;

  /// Whether a sign-out operation is currently in progress.
  final bool isSigningOut;

  /// Whether an FCM push token sync is in progress.
  final bool isSyncingToken;

  /// Copies this state with optional replaced fields.
  SettingsState copyWith({
    SettingsStatus? status,
    UserSettingsProfile? profile,
    String? errorMessage,
    String? infoMessage,
    bool? isSigningOut,
    bool? isSyncingToken,
    bool clearInfoMessage = false,
    bool clearErrorMessage = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfoMessage ? null : (infoMessage ?? this.infoMessage),
      isSigningOut: isSigningOut ?? this.isSigningOut,
      isSyncingToken: isSyncingToken ?? this.isSyncingToken,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    errorMessage,
    infoMessage,
    isSigningOut,
    isSyncingToken,
  ];
}
