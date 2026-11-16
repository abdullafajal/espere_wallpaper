import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/photo_grid.dart';
import '../../../core/widgets/underline_tabs.dart';
import '../../search/domain/search_filter.dart';
import '../../search/presentation/search_notifier.dart';
import 'home_notifier.dart';

/// Home feed: big wordmark, soft brand-tinted header, topic tabs
/// ("All", "Nature", "Cars"…) and a masonry grid of pins.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _topic = 0; // 0 = All, otherwise AppConstants.categories[_topic - 1]

  @override
  Widget build(BuildContext context) {
    final topics = ['All', ...AppConstants.categories.map((c) => c.name)];
    final header = _HomeHeader(
      topics: topics,
      selected: _topic,
      onSelect: (i) => setState(() => _topic = i),
    );

    if (_topic == 0) {
      final state = ref.watch(homeNotifierProvider);
      final notifier = ref.read(homeNotifierProvider.notifier);
      return Scaffold(
        body: PhotoGrid(
          key: const ValueKey('topic_all'),
          heroScope: 'home_all',
          photos: state.curatedPhotos,
          isLoading: state.isLoading,
          isLoadingMore: state.isLoadingMore,
          hasMore: state.hasMore,
          onLoadMore: notifier.loadMore,
          onRefresh: notifier.refresh,
          errorMessage: state.errorMessage,
          isRateLimited: state.isRateLimited,
          onRetry: notifier.loadInitial,
          leadingSlivers: [header],
        ),
      );
    }

    final category = AppConstants.categories[_topic - 1];
    final provider = searchResultsProvider(SearchFilter(query: category.query));
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    return Scaffold(
      body: PhotoGrid(
        key: ValueKey('topic_${category.id}'),
        heroScope: 'home_${category.id}',
        photos: state.photos,
        isLoading: state.isLoading,
        isLoadingMore: state.isLoadingMore,
        hasMore: state.hasMore,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        errorMessage: state.errorMessage,
        isRateLimited: state.isRateLimited,
        onRetry: notifier.refresh,
        leadingSlivers: [header],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final List<String> topics;
  final int selected;
  final ValueChanged<int> onSelect;

  const _HomeHeader({
    required this.topics,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      floating: true,
      snap: true,
      toolbarHeight: 64,
      titleSpacing: 16,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      // A soft wash of the accent colour that fades into the page.
      flexibleSpace: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(
                  cs.primaryContainer.withValues(alpha: isDark ? 0.35 : 0.55),
                  cs.surface,
                ),
                cs.surface,
              ],
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          const BrandLogo(size: 32),
          const SizedBox(width: 10),
          Text(
            'Espere',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Search',
          icon: Icon(Icons.search_rounded, size: 27, color: cs.onSurface),
          onPressed: () => context.go('/search'),
        ),
        IconButton(
          tooltip: 'Settings',
          icon: Icon(Icons.settings_outlined, size: 25, color: cs.onSurface),
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 6),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: UnderlineTabs(
          labels: topics,
          selected: selected,
          onSelect: onSelect,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }
}
