import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:koma/app/bloc/app_bloc.dart';
import 'package:koma/app/view/app_shell_scaffold.dart';
import 'package:koma/features/auth/auth.dart';
import 'package:koma/features/history/history.dart';
import 'package:koma/features/library/library.dart';
import 'package:koma/features/reader_progress/reader_progress.dart';
import 'package:koma/features/search/search.dart';
import 'package:koma/features/settings/settings.dart';

part 'app_router.g.dart';

List<String> _preferredOsLanguageCodes(BuildContext context) {
  final codes = <String>[];
  for (final locale in View.of(context).platformDispatcher.locales) {
    final code = locale.languageCode;
    if (code.isNotEmpty && !codes.contains(code)) {
      codes.add(code);
    }
  }
  return codes.isEmpty ? const ['en'] : codes;
}

/// {@template login_route}
/// Authentication page route.
/// {@endtemplate}
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  /// {@macro login_route}
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return LoginPage(showDevQuickLogin: AppRouter.showDevQuickLogin);
  }
}

/// {@template app_shell_route_data}
/// Stateful shell route defining the four persistent bottom navigation
/// branches: Library, Discover, History, and Settings.
/// {@endtemplate}
@TypedStatefulShellRoute<AppShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<LibraryBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<LibraryRoute>(path: '/library'),
      ],
    ),
    TypedStatefulShellBranch<DiscoverBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<DiscoverRoute>(path: '/discover'),
      ],
    ),
    TypedStatefulShellBranch<HistoryBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<HistoryRoute>(path: '/history'),
      ],
    ),
    TypedStatefulShellBranch<SettingsBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<SettingsRoute>(path: '/settings'),
      ],
    ),
  ],
)
class AppShellRouteData extends StatefulShellRouteData {
  /// {@macro app_shell_route_data}
  const new();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return AppShellScaffold(navigationShell: navigationShell);
  }
}

/// {@template library_branch_data}
/// Branch definition for the Library tab.
/// {@endtemplate}
class LibraryBranchData extends StatefulShellBranchData {
  /// {@macro library_branch_data}
  const new();
}

/// {@template discover_branch_data}
/// Branch definition for the Discover tab.
/// {@endtemplate}
class DiscoverBranchData extends StatefulShellBranchData {
  /// {@macro discover_branch_data}
  const new();
}

/// {@template history_branch_data}
/// Branch definition for the History tab.
/// {@endtemplate}
class HistoryBranchData extends StatefulShellBranchData {
  /// {@macro history_branch_data}
  const new();
}

/// {@template settings_branch_data}
/// Branch definition for the Settings tab.
/// {@endtemplate}
class SettingsBranchData extends StatefulShellBranchData {
  /// {@macro settings_branch_data}
  const new();
}

/// {@template library_route}
/// Route displaying user's saved manga titles and reading status filters.
/// {@endtemplate}
class LibraryRoute extends GoRouteData with $LibraryRoute {
  /// {@macro library_route}
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final appBlocState = context.watch<AppBloc>().state;
    return LibraryPage(
      key: ValueKey(appBlocState.user.uid),
      uid: appBlocState.user.uid,
      onMangaTap: (mangaId) =>
          unawaited(MangaDetailRoute(mangaId: mangaId).push<void>(context)),
      onDiscoverTap: () => const DiscoverRoute().go(context),
    );
  }
}

/// {@template discover_route}
/// Route displaying MangaDex search and discovery feed.
/// {@endtemplate}
class DiscoverRoute extends GoRouteData with $DiscoverRoute {
  /// {@macro discover_route}
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final appBlocState = context.watch<AppBloc>().state;
    return SearchPage(
      key: ValueKey(appBlocState.user.uid),
      translatedLanguages: appBlocState.preferredLanguages,
      contentRatings: appBlocState.contentRatings,
      preferredLocales: _preferredOsLanguageCodes(context),
      onMangaTap: (mangaId) =>
          unawaited(MangaDetailRoute(mangaId: mangaId).push<void>(context)),
    );
  }
}

/// {@template history_route}
/// Route displaying the chronological reading history feed.
/// {@endtemplate}
class HistoryRoute extends GoRouteData with $HistoryRoute {
  /// {@macro history_route}
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final appBlocState = context.watch<AppBloc>().state;
    return HistoryPage(
      key: ValueKey(appBlocState.user.uid),
      uid: appBlocState.user.uid,
      onMangaTap: (mangaId) =>
          unawaited(MangaDetailRoute(mangaId: mangaId).push<void>(context)),
    );
  }
}

/// {@template settings_route}
/// Route displaying preferences, language, and account options.
/// {@endtemplate}
class SettingsRoute extends GoRouteData with $SettingsRoute {
  /// {@macro settings_route}
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final appBlocState = context.watch<AppBloc>().state;
    return SettingsPage(
      key: ValueKey(appBlocState.user.uid),
      uid: appBlocState.user.uid,
      userEmail: appBlocState.user.email,
      displayName: appBlocState.user.displayName,
      photoUrl: appBlocState.user.photoUrl,
      isEmulatorMode: AppRouter.isEmulatorMode,
    );
  }
}

/// {@template manga_detail_route}
/// Route to view manga details, chapters, and track reading progress.
/// {@endtemplate}
@TypedGoRoute<MangaDetailRoute>(path: '/manga/:mangaId')
class MangaDetailRoute extends GoRouteData with $MangaDetailRoute {
  /// {@macro manga_detail_route}
  const new({required this.mangaId, this.highlightChapter});

  /// Canonical MangaDex manga UUID.
  final String mangaId;

  /// Optional chapter number to highlight upon opening.
  final String? highlightChapter;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final appBlocState = context.watch<AppBloc>().state;
    return MangaDetailPage(
      key: ValueKey(mangaId),
      mangaId: mangaId,
      uid: appBlocState.user.uid,
      highlightChapter: highlightChapter,
      translatedLanguages: appBlocState.preferredLanguages,
      preferredLocales: _preferredOsLanguageCodes(context),
      onBackFallback: () => const LibraryRoute().go(context),
    );
  }
}

/// {@template app_router}
/// Application router managing routes, deep links, and authentication guards.
/// {@endtemplate}
abstract final class AppRouter {
  /// Explicit flag to display QA quick login button.
  static bool showDevQuickLogin = false;

  /// Whether the app is operating against local Firebase emulators.
  static bool isEmulatorMode = false;

  /// Creates and configures the [GoRouter] instance.
  static GoRouter createRouter({
    required AppBloc appBloc,
    Stream<dynamic>? refreshStream,
    bool showDevQuickLogin = false,
    bool isEmulatorMode = false,
    String? initialLocation,
  }) {
    AppRouter.showDevQuickLogin = showDevQuickLogin;
    AppRouter.isEmulatorMode = isEmulatorMode;

    return GoRouter(
      initialLocation: initialLocation ?? '/library',
      debugLogDiagnostics: kDebugMode,
      refreshListenable: GoRouterRefreshStream(refreshStream ?? appBloc.stream),
      redirect: (context, state) {
        final isAuthenticated = appBloc.state.isAuthenticated;
        final matchedLocation = state.matchedLocation;
        final isLoggingIn = matchedLocation == '/login';

        if (!isAuthenticated) {
          return isLoggingIn ? null : '/login';
        }

        if (isLoggingIn || matchedLocation == '/') {
          return '/library';
        }

        return null;
      },
      routes: $appRoutes,
    );
  }
}

/// {@template go_router_refresh_stream}
/// Converts a [Stream] to a [ChangeNotifier] for `GoRouter.refreshListenable`.
/// {@endtemplate}
class GoRouterRefreshStream extends ChangeNotifier {
  /// {@macro go_router_refresh_stream}
  new(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
