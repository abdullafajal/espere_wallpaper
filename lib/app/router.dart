import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/brand_logo.dart';
import '../features/collections/presentation/collection_detail_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/favorites/presentation/library_screen.dart';
import '../features/home/domain/photo_model.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/photo_detail/presentation/photo_detail_screen.dart';
import '../features/photo_detail/presentation/pin_detail_screen.dart';
import '../features/search/domain/search_filter.dart';
import '../features/search/presentation/search_results_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'route_args.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class _Destination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _Destination(this.icon, this.selectedIcon, this.label);
}

const _destinations = [
  _Destination(Icons.home_outlined, Icons.home_rounded, 'Home'),
  _Destination(Icons.search_rounded, Icons.manage_search_rounded, 'Search'),
  _Destination(Icons.bookmarks_outlined, Icons.bookmarks_rounded, 'Library'),
];

/// App shell: bottom navigation bar on phones, navigation rail on wide screens.
class _AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _AppShell({required this.shell});

  void _onSelect(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              indicatorColor: Theme.of(context).colorScheme.primaryContainer,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: BrandLogo(size: 40),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _destinations.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                _FloatingNavButton(
                  destination: _destinations[i],
                  selected: shell.currentIndex == i,
                  onTap: () => _onSelect(i),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the floating rounded-square navigation buttons.
class _FloatingNavButton extends StatelessWidget {
  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  const _FloatingNavButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: destination.label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: Tooltip(
        message: destination.label,
        child: Material(
          color: selected
              ? cs.primaryContainer
              : (isDark ? cs.surfaceContainerHigh : cs.surface),
          elevation: 6,
          shadowColor: cs.shadow.withValues(alpha: isDark ? 0.6 : 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: SizedBox(
              width: 66,
              height: 62,
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 30,
                color: selected ? cs.onPrimaryContainer : cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

PhotoRouteArgs? _photoArgs(Object? extra) => extra is PhotoRouteArgs
    ? extra
    : (extra is Photo ? PhotoRouteArgs(extra) : null);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
          ],
        ),
      ],
    ),

    // Full-screen routes above the shell.
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/photo/:id',
      pageBuilder: (context, state) {
        final args = _photoArgs(state.extra);
        return CustomTransitionPage(
          key: state.pageKey,
          opaque: false,
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          child: PinDetailScreen(
            photoId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            initialPhoto: args?.photo,
            heroTag: args?.heroTag,
          ),
          // The image itself flies via Hero; the rest of the page fades in
          // and lifts slightly, like a pin opening.
          transitionsBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/view/:id',
      pageBuilder: (context, state) {
        final args = _photoArgs(state.extra);
        return CustomTransitionPage(
          key: state.pageKey,
          opaque: false,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          child: PhotoDetailScreen(
            photoId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            initialPhoto: args?.photo,
            heroTag: args?.heroTag,
          ),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/results',
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return SearchResultsScreen(
          initialFilter: SearchFilter(query: q['q'] ?? '', color: q['color']),
          title: q['title'],
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/category/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final category = AppConstants.categories.firstWhere(
          (c) => c.id == id,
          orElse: () => AppConstants.categories.first,
        );
        return SearchResultsScreen(
          initialFilter: SearchFilter(query: category.query),
          title: category.name,
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/favorites',
      builder: (_, _) => const FavoritesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/collection/:id',
      builder: (context, state) => CollectionDetailScreen(
        collectionId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      builder: (_, _) => const SettingsScreen(),
    ),
  ],
);
