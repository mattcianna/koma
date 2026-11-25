import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:koma/l10n/l10n.dart';

/// {@template app_shell_scaffold}
/// Application shell scaffold providing the primary bottom navigation bar
/// across the Library, Discover, History, and Settings branch destinations.
/// {@endtemplate}
class AppShellScaffold extends StatelessWidget {
  /// {@macro app_shell_scaffold}
  const new({required this.navigationShell, super.key});

  /// The active navigation shell containing branch state and views.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: FocusTraversalGroup(child: navigationShell),
      bottomNavigationBar: FocusTraversalGroup(
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            NavigationDestination(
              key: const Key('nav_library'),
              icon: const Icon(Icons.collections_bookmark_outlined),
              selectedIcon: const Icon(Icons.collections_bookmark_rounded),
              label: l10n.navLibrary,
              tooltip: l10n.navLibrary,
            ),
            NavigationDestination(
              key: const Key('nav_discover'),
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore_rounded),
              label: l10n.navDiscover,
              tooltip: l10n.navDiscover,
            ),
            NavigationDestination(
              key: const Key('nav_history'),
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history_rounded),
              label: l10n.navHistory,
              tooltip: l10n.navHistory,
            ),
            NavigationDestination(
              key: const Key('nav_settings'),
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: l10n.navSettings,
              tooltip: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
