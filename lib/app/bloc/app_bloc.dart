import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koma/app/bloc/app_event.dart';
import 'package:koma/app/bloc/app_state.dart';
import 'package:library_repository/library_repository.dart';
import 'package:notifications_repository/notifications_repository.dart';

/// {@template app_bloc}
/// Global application BLoC managing authentication session lifecycle,
/// user settings synchronization, and push notification device token
/// registration.
/// {@endtemplate}
class AppBloc extends Bloc<AppEvent, AppState> {
  /// {@macro app_bloc}
  new({
    required this.authRepository,
    required this.libraryRepository,
    required this.notificationsRepository,
    this.isEmulatorMode = false,
    this.deviceId = 'pixel9-dev',
    this.platform = 'android',
  }) : super(AppState(user: authRepository.currentUser)) {
    on<AppUserSubscriptionRequested>(_onUserSubscriptionRequested);
    on<AppUserChanged>(_onUserChanged);
    on<AppSettingsChanged>(_onSettingsChanged);
    on<AppLogoutRequested>(_onLogoutRequested);

    _userSubscription = authRepository.user.listen((user) {
      add(AppUserChanged(user));
    });
  }

  /// The repository managing user authentication state.
  final AuthRepository authRepository;

  /// The repository managing Cloud Firestore user library and history.
  final LibraryRepository libraryRepository;

  /// The repository managing push notification device tokens.
  final NotificationsRepository notificationsRepository;

  /// Whether operating against Firebase emulators.
  final bool isEmulatorMode;

  /// The device ID for push token sync.
  final String deviceId;

  /// The client platform identifier (`'android'` or `'ios'`).
  final String platform;

  StreamSubscription<AppUser>? _userSubscription;
  StreamSubscription<UserSettingsProfile?>? _settingsSubscription;

  Future<void> _onUserSubscriptionRequested(
    AppUserSubscriptionRequested event,
    Emitter<AppState> emit,
  ) async {
    // If current user is already present, emit and trigger profile sync.
    final currentUser = authRepository.currentUser;
    if (currentUser.isNotEmpty) {
      add(AppUserChanged(currentUser));
    }
  }

  Future<void> _onUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    final user = event.user;
    if (user.isEmpty) {
      await _settingsSubscription?.cancel();
      _settingsSubscription = null;
      emit(const AppState());
      return;
    }

    // Emit authenticated state immediately.
    emit(state.copyWith(user: user));

    // Best-effort profile initialization.
    try {
      final profile = await libraryRepository.ensureUserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoUrl,
      );
      emit(
        state.copyWith(
          preferredLanguages: profile.preferredLanguages,
          contentRatings: profile.contentRatings,
          notificationsEnabled: profile.notificationsEnabled,
          settings: profile,
        ),
      );
    } on Object catch (_) {
      // Graceful fallback if Firestore is momentarily unavailable.
    }

    // Subscribe to live Firestore user settings changes immediately so reading
    // preference updates never wait on FCM/FIS token sync.
    await _settingsSubscription?.cancel();
    _settingsSubscription = libraryRepository
        .watchUserSettings(user.uid)
        .listen((settings) {
          add(AppSettingsChanged(settings));
        });

    // Best-effort push notification device token sync (non-blocking).
    unawaited(_syncDeviceTokenSafely(user.uid));
  }

  Future<void> _syncDeviceTokenSafely(String uid) async {
    try {
      await notificationsRepository.syncDeviceToken(
        uid: uid,
        deviceId: deviceId,
        platform: platform,
        isEmulatorMode: isEmulatorMode,
      );
    } on Object catch (_) {
      // Graceful fallback for missing Play Services / FIS in emulator.
    }
  }

  void _onSettingsChanged(AppSettingsChanged event, Emitter<AppState> emit) {
    final settings = event.settings;
    if (settings != null) {
      emit(
        state.copyWith(
          preferredLanguages: settings.preferredLanguages,
          contentRatings: settings.contentRatings,
          notificationsEnabled: settings.notificationsEnabled,
          settings: settings,
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AppLogoutRequested event,
    Emitter<AppState> emit,
  ) async {
    try {
      await authRepository.logOut();
    } on Object catch (_) {
      // Best-effort logout.
    }
  }

  @override
  Future<void> close() {
    unawaited(_userSubscription?.cancel());
    unawaited(_settingsSubscription?.cancel());
    return super.close();
  }
}
