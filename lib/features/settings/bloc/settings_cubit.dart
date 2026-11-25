import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:koma/features/settings/bloc/settings_state.dart';
import 'package:library_repository/library_repository.dart';
import 'package:notifications_repository/notifications_repository.dart';

/// Cubit managing user profile preferences, scanlation language filters,
/// content ratings, FCM push notification tokens, and authentication sign-out.
class SettingsCubit extends Cubit<SettingsState> {
  /// Creates a [SettingsCubit] and starts watching user settings.
  new({
    required this.libraryRepository,
    required this.authRepository,
    required this.notificationsRepository,
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isEmulatorMode = false,
    this.deviceId = 'device-1',
    this.platform = 'android',
  }) : super(const SettingsState(status: SettingsStatus.loading)) {
    _init();
  }

  /// Repository providing access to user profile settings in Firestore.
  final LibraryRepository libraryRepository;

  /// Repository managing authentication session and logout.
  final AuthRepository authRepository;

  /// Repository managing device push tokens and FCM synchronization.
  final NotificationsRepository notificationsRepository;

  /// The user ID whose settings are managed.
  final String uid;

  /// The user's primary email address for profile creation fallback.
  final String? email;

  /// Optional display name.
  final String? displayName;

  /// Optional photo URL.
  final String? photoUrl;

  /// Whether running against the Firebase emulator suite.
  final bool isEmulatorMode;

  /// Unique client device identifier for push tokens.
  final String deviceId;

  /// Client host platform identifier (`'android'` or `'ios'`).
  final String platform;

  StreamSubscription<UserSettingsProfile?>? _subscription;

  void _init() {
    unawaited(_subscription?.cancel());
    _subscription = libraryRepository.watchUserSettings(uid).listen(
      (profile) {
        if (profile == null) {
          unawaited(_ensureProfile());
        } else {
          emit(state.copyWith(status: SettingsStatus.loaded, profile: profile));
        }
      },
      onError: (Object error, StackTrace stackTrace) => emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: error.toString(),
        ),
      ),
    );
  }

  Future<void> _ensureProfile() async {
    try {
      final candidateEmail = email ?? authRepository.currentUser.email;
      final effectiveEmail =
          (candidateEmail != null && candidateEmail.isNotEmpty)
          ? candidateEmail
          : 'user@koma.local';
      final profile = await libraryRepository.ensureUserProfile(
        uid: uid,
        email: effectiveEmail,
        displayName: displayName ?? authRepository.currentUser.displayName,
        photoUrl: photoUrl ?? authRepository.currentUser.photoUrl,
      );
      emit(state.copyWith(status: SettingsStatus.loaded, profile: profile));
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Toggles a scanlation language code in preferred scanlation languages.
  ///
  /// Guarantees that at least one preferred language remains selected.
  Future<void> togglePreferredLanguage(String lang) async {
    final current = state.profile?.preferredLanguages ?? const ['en', 'it'];
    final List<String> updated;
    if (current.contains(lang)) {
      if (current.length <= 1) {
        return;
      }
      updated = current.where((l) => l != lang).toList();
    } else {
      updated = [...current, lang];
    }

    try {
      await libraryRepository.updateUserSettings(
        uid: uid,
        preferredLanguages: updated,
      );
      emit(state.copyWith(infoMessage: 'settingsSavedMessage'));
    } on Exception catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  /// Toggles a content rating level (`'safe'`, `'suggestive'`, `'erotica'`).
  ///
  /// Guarantees that at least one content rating remains selected.
  Future<void> toggleContentRating(String rating) async {
    final current =
        state.profile?.contentRatings ?? const ['safe', 'suggestive'];
    final List<String> updated;
    if (current.contains(rating)) {
      if (current.length <= 1) {
        return;
      }
      updated = current.where((r) => r != rating).toList();
    } else {
      updated = [...current, rating];
    }

    try {
      await libraryRepository.updateUserSettings(
        uid: uid,
        contentRatings: updated,
      );
      emit(state.copyWith(infoMessage: 'settingsSavedMessage'));
    } on Exception catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  /// Updates the global notification toggle and synchronizes the push token.
  // ignore: avoid_positional_boolean_parameters
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await libraryRepository.updateUserSettings(
        uid: uid,
        notificationsEnabled: enabled,
      );
      if (enabled) {
        await notificationsRepository.syncDeviceToken(
          uid: uid,
          deviceId: deviceId,
          platform: platform,
          isEmulatorMode: isEmulatorMode,
        );
      } else {
        await notificationsRepository.unregisterDeviceToken(
          uid: uid,
          deviceId: deviceId,
        );
      }
      emit(state.copyWith(infoMessage: 'settingsSavedMessage'));
    } on Exception catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  /// Explicitly synchronizes the FCM device push token with Firestore.
  Future<String?> syncPushTokenNow() async {
    emit(state.copyWith(isSyncingToken: true));
    try {
      final token = await notificationsRepository.syncDeviceToken(
        uid: uid,
        deviceId: deviceId,
        platform: platform,
        isEmulatorMode: isEmulatorMode,
      );
      emit(
        state.copyWith(
          isSyncingToken: false,
          infoMessage: 'settingsTokenSyncedMessage',
        ),
      );
      return token;
    } on Exception catch (error) {
      emit(
        state.copyWith(isSyncingToken: false, errorMessage: error.toString()),
      );
      return null;
    }
  }

  /// Signs the user out of the application and unregisters the push token.
  Future<void> signOut() async {
    emit(state.copyWith(isSigningOut: true));
    try {
      await notificationsRepository.unregisterDeviceToken(
        uid: uid,
        deviceId: deviceId,
      );
    } on Exception {
      // Best-effort unregistration on sign-out.
    }

    try {
      await authRepository.logOut();
    } on Exception catch (error) {
      emit(state.copyWith(isSigningOut: false, errorMessage: error.toString()));
    }
  }

  /// Clears transient informational status message.
  void clearInfoMessage() {
    emit(state.copyWith(clearInfoMessage: true));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
