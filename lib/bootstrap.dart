import 'dart:async';
import 'dart:developer';

import 'package:auth_repository/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_client/firebase_auth_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firestore_library_client/firestore_library_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:koma/app/app.dart';
import 'package:koma/firebase_options.dart';
import 'package:koma_cache_client/koma_cache_client.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:notifications_repository/notifications_repository.dart';

const bool _useFirebaseEmulatorEnv = bool.hasEnvironment(
  'USE_FIREBASE_EMULATOR',
);

const bool _useFirebaseEmulatorDefine = bool.fromEnvironment(
  'USE_FIREBASE_EMULATOR',
);

const String _firebaseEmulatorHostDefine = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
);

/// Creates and initializes the top-level [KomaApp] widget.
///
/// Ensures bindings, initializes Firebase and local SQLite databases,
/// configures emulator endpoints if requested, and wires up all domain
/// repositories.
Future<Widget> createKomaApp({
  bool useFirebaseEmulator = false,
  String? emulatorHostOverride,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final isEmulator = _useFirebaseEmulatorEnv
      ? _useFirebaseEmulatorDefine
      : useFirebaseEmulator;
  final hasExplicitHost =
      (emulatorHostOverride != null && emulatorHostOverride.isNotEmpty) ||
      _firebaseEmulatorHostDefine.isNotEmpty;
  final host = (emulatorHostOverride != null && emulatorHostOverride.isNotEmpty)
      ? emulatorHostOverride
      : (_firebaseEmulatorHostDefine.isNotEmpty
            ? _firebaseEmulatorHostDefine
            : '127.0.0.1');

  final firebaseOptions = DefaultFirebaseOptions.currentPlatform(
    useEmulator: isEmulator,
  );

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: firebaseOptions);
    }
  } on Object catch (error, stackTrace) {
    log(
      'Firebase initialization completed with note: $error',
      name: 'bootstrap',
      stackTrace: stackTrace,
    );
  }

  if (isEmulator) {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      await FirebaseAuth.instance.useAuthEmulator(
        host,
        9099,
        automaticHostMapping: !hasExplicitHost,
      );
      FirebaseFirestore.instance.useFirestoreEmulator(
        host,
        8080,
        automaticHostMapping: !hasExplicitHost,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Firebase emulator attachment note: $error',
        name: 'bootstrap',
        stackTrace: stackTrace,
      );
    }
  } else {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Firestore settings note: $error',
        name: 'bootstrap',
        stackTrace: stackTrace,
      );
    }
  }

  final cacheClient = KomaCacheClient(driftDatabase(name: 'koma_cache'));
  final apiClient = MangaDexApiClient(MangaDexApiClient.createDefaultDio());
  final authClient = FirebaseAuthClient();
  final firestoreClient = FirestoreLibraryClient();

  final authRepository = AuthRepository(authClient: authClient);
  final mangaRepository = MangaRepository(
    apiClient: apiClient,
    cacheClient: cacheClient,
  );
  final libraryRepository = LibraryRepository(
    firestoreLibraryClient: firestoreClient,
  );
  final notificationsRepository = NotificationsRepository(
    firestoreClient: firestoreClient,
  );

  return KomaApp(
    authRepository: authRepository,
    mangaRepository: mangaRepository,
    libraryRepository: libraryRepository,
    notificationsRepository: notificationsRepository,
    isEmulatorMode: isEmulator,
    showDevQuickLogin: isEmulator,
  );
}

/// Bootstraps the application, registering global error handlers and running
/// the root widget returned by [createKomaApp].
Future<void> bootstrap({bool defaultUseFirebaseEmulator = false}) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log(error.toString(), stackTrace: stack);
    return true;
  };

  final app = await createKomaApp(
    useFirebaseEmulator: defaultUseFirebaseEmulator,
  );
  if (kDebugMode) {
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(app);
}
