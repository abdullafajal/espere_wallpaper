import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/color_swatches.dart';
import '../../../core/widgets/photo_grid.dart';
import '../domain/search_filter.dart';
import 'search_notifier.dart';
import 'widgets/search_filter_bottom_sheet.dart';

/// Results for a query, colour, category or photographer, with an editable
/// search field (or a plain title) and a row of filter chips.
class SearchResultsScreen extends ConsumerStatefulWidget {
  final SearchFilter initialFilter;
  final String? title;

  const SearchResultsScreen({
    super.key,
    required this.initialFilter,
    this.title,
  });

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialFilter.query,
  );
  late final String _heroScope = 'results_${identityHashCode(this)}';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFilters(SearchNotifier notifier, SearchFilter filter) {
    SearchFilterBottomSheet.show(
      context: context,
      currentFilter: filter,
      onApply: notifier.applyFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = searchResultsProvider(widget.initialFilter);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final hasTitle = widget.title != null;

    return Scaffold(
      body: PhotoGrid(
        heroScope: _heroScope,
        photos: state.photos,
        isLoading: state.isLoading,
        isLoadingMore: state.isLoadingMore,
        hasMore: state.hasMore,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        errorMessage: state.errorMessage,
        isRateLimited: state.isRateLimited,
        onRetry: notifier.refresh,
        emptyIcon: Icons.image_search_rounded,
        emptyTitle: 'No results',
        emptyMessage: 'Try different words, or remove some filters.',
        leadingSlivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            automaticallyImplyLeading: hasTitle,
            toolbarHeight: hasTitle ? kToolbarHeight : 72,
            titleSpacing: hasTitle ? 0 : 12,
            title: hasTitle
                ? Text(widget.title!)
                : AppSearchBar(
                    controller: _controller,
                    onBack: () => context.pop(),
                    onSubmitted: (q) {
                      if (q.trim().isNotEmpty) notifier.search(q);
                    },
                    onClear: _controller.clear,
                  ),
          ),
          SliverToBoxAdapter(
            child: _FilterChips(
              filter: state.filter,
              onOpen: () => _openFilters(notifier, state.filter),
              onClearColor: () =>
                  notifier.applyFilter(state.filter.copyWith(clearColor: true)),
              lockColor: hasTitle && widget.initialFilter.color != null,
            ),
          ),
        ],
      ),
    );
  }
}

String _cap(String v) => v[0].toUpperCase() + v.substring(1);

class _FilterChips extends StatelessWidget {
  final SearchFilter filter;
  final VoidCallback onOpen;
  final VoidCallback onClearColor;
  final bool lockColor;

  const _FilterChips({
    required this.filter,
    required this.onOpen,
    required this.onClearColor,
    required this.lockColor,
  });

  @override
  Widget build(BuildContext context) {
    final swatch = AppColors.swatchFor(filter.color);
    const arrow = Icon(Icons.arrow_drop_down_rounded, size: 20);

    Widget dropChip(String label, bool active) => FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(label), arrow],
      ),
      selected: active,
      showCheckmark: false,
      onSelected: (_) => onOpen(),
    );

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: [
          ActionChip(
            avatar: Badge(
              isLabelVisible: filter.hasActiveFilters,
              smallSize: 7,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.tune_rounded),
            ),
            label: const Text('Filters'),
            onPressed: onOpen,
          ),
          const SizedBox(width: 8),
          if (swatch != null && !lockColor)
            InputChip(
              avatar: ColorDot(color: swatch.color, size: 18),
              label: Text(swatch.name),
              selected: true,
              showCheckmark: false,
              onPressed: onOpen,
              onDeleted: onClearColor,
            )
          else if (!lockColor)
            dropChip('Color', false),
          if (!lockColor) const SizedBox(width: 8),
          dropChip(
            filter.orientation == 'all'
                ? 'Orientation'
                : _cap(filter.orientation),
            filter.orientation != 'all',
          ),
          const SizedBox(width: 8),
          dropChip(
            filter.size == 'all' ? 'Size' : _cap(filter.size),
            filter.size != 'all',
          ),
        ],
      ),
    );
  }
}
