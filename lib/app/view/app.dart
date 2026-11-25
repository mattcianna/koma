import 'dart:async';

import 'package:auth_repository/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:koma/app/bloc/app_bloc.dart';
import 'package:koma/app/router/app_router.dart';
import 'package:koma/l10n/l10n.dart';
import 'package:koma_ui/koma_ui.dart';
import 'package:library_repository/library_repository.dart';
import 'package:manga_repository/manga_repository.dart';
import 'package:notifications_repository/notifications_repository.dart';

/// {@template koma_app}
/// Root application widget configuring dependency injection, themes,
/// localizations, and GoRouter navigation.
/// {@endtemplate}
class KomaApp extends StatefulWidget {
  /// {@macro koma_app}
  const new({
    required this.authRepository,
    required this.mangaRepository,
    required this.libraryRepository,
    required this.notificationsRepository,
    this.appBloc,
    this.router,
    this.isEmulatorMode = false,
    this.showDevQuickLogin = false,
    this.initialLocation,
    super.key,
  });

  /// The repository managing user authentication state.
  final AuthRepository authRepository;

  /// The repository managing MangaDex data and offline cache.
  final MangaRepository mangaRepository;

  /// The repository managing Cloud Firestore user library and history.
  final LibraryRepository libraryRepository;

  /// The repository managing push notification device tokens.
  final NotificationsRepository notificationsRepository;

  /// Optional injected [AppBloc] for testing.
  final AppBloc? appBloc;

  /// Optional injected [GoRouter] for testing.
  final GoRouter? router;

  /// Whether running against local Firebase emulators.
  final bool isEmulatorMode;

  /// Whether to display QA quick login button.
  final bool showDevQuickLogin;

  /// Optional initial navigation location.
  final String? initialLocation;

  @override
  State<KomaApp> createState() => _KomaAppState();
}

class _KomaAppState extends State<KomaApp> {
  late final AppBloc _appBloc;
  late final GoRouter _router;
  late final bool _ownsBloc;

  @override
  void initState() {
    super.initState();
    _ownsBloc = widget.appBloc == null;
    _appBloc =
        widget.appBloc ??
        AppBloc(
          authRepository: widget.authRepository,
          libraryRepository: widget.libraryRepository,
          notificationsRepository: widget.notificationsRepository,
          isEmulatorMode: widget.isEmulatorMode,
        );

    _router =
        widget.router ??
        AppRouter.createRouter(
          appBloc: _appBloc,
          showDevQuickLogin: widget.showDevQuickLogin,
          isEmulatorMode: widget.isEmulatorMode,
          initialLocation: widget.initialLocation,
        );
  }

  @override
  void dispose() {
    if (_ownsBloc) {
      unawaited(_appBloc.close());
    }
    if (widget.router == null) {
      _router.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.authRepository),
        RepositoryProvider.value(value: widget.mangaRepository),
        RepositoryProvider.value(value: widget.libraryRepository),
        RepositoryProvider.value(value: widget.notificationsRepository),
      ],
      child: BlocProvider.value(
        value: _appBloc,
        child: MaterialApp.router(
          title: 'Koma',
          theme: KomaTheme.light,
          darkTheme: KomaTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
