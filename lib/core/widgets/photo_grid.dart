import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../features/home/domain/photo_model.dart';
import '../storage/storage_service.dart';
import 'empty_state_view.dart';
import 'error_state_view.dart';
import 'photo_tile.dart';
import 'shimmer_placeholder.dart';

const int kMinGridColumns = 2;
const int kMaxGridColumns = 4;
const int kDefaultGridColumns = 2;
const double kGridSpacing = 8;
const double kGridPadding = 8;

/// Grid density shared by every photo grid. Pinch on any grid to change it.
final gridColumnsProvider = StateNotifierProvider<GridColumnsNotifier, int>((
  ref,
) {
  return GridColumnsNotifier(ref.watch(storageServiceProvider));
});

class GridColumnsNotifier extends StateNotifier<int> {
  final StorageService _storage;

  GridColumnsNotifier(this._storage)
    : super(
        (_storage.getGridColumns() ?? kDefaultGridColumns).clamp(
          kMinGridColumns,
          kMaxGridColumns,
        ),
      );

  void set(int columns) {
    final next = columns.clamp(kMinGridColumns, kMaxGridColumns);
    if (next == state) return;
    state = next;
    _storage.setGridColumns(next);
  }
}

/// Columns actually used at [width]: the phone-density preference, scaled up
/// on tablets/desktop so tiles stay a similar physical size.
int effectiveGridColumns(int preferred, double width) {
  final tileTarget = 380 / preferred;
  return (width / tileTarget).floor().clamp(preferred, preferred * 3);
}

/// Pinterest-style masonry photo grid with infinite scroll, pull-to-refresh,
/// pinch-to-zoom density and built-in loading / empty / error states.
///
/// Extra content (app bars, carousels, headers) goes in [leadingSlivers] so
/// everything scrolls together.
class PhotoGrid extends ConsumerStatefulWidget {
  final List<Photo> photos;
  final String heroScope;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;
  final String? errorMessage;
  final bool isRateLimited;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final List<Widget> leadingSlivers;
  final ScrollController? controller;

  const PhotoGrid({
    super.key,
    required this.photos,
    required this.heroScope,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onRefresh,
    this.errorMessage,
    this.isRateLimited = false,
    this.onRetry,
    this.emptyTitle = 'No photos here',
    this.emptyMessage = 'Try a different search or color.',
    this.emptyIcon = Icons.photo_library_outlined,
    this.leadingSlivers = const [],
    this.controller,
  });

  @override
  ConsumerState<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends ConsumerState<PhotoGrid> {
  // Two-finger pinch tracking. A Listener (not a gesture recognizer) is used
  // so one-finger scrolling is never blocked.
  final Map<int, Offset> _pointers = {};
  double? _pinchBaseline;

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) _pinchBaseline = _pinchDistance();
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    final baseline = _pinchBaseline;
    if (_pointers.length != 2 || baseline == null || baseline == 0) return;

    final ratio = _pinchDistance() / baseline;
    final notifier = ref.read(gridColumnsProvider.notifier);
    final columns = ref.read(gridColumnsProvider);
    if (ratio > 1.3 && columns > kMinGridColumns) {
      notifier.set(columns - 1); // spread → bigger tiles
      HapticFeedback.selectionClick();
      _pinchBaseline = _pinchDistance();
    } else if (ratio < 0.75 && columns < kMaxGridColumns) {
      notifier.set(columns + 1); // pinch → more tiles
      HapticFeedback.selectionClick();
      _pinchBaseline = _pinchDistance();
    }
  }

  void _onPointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2) _pinchBaseline = null;
  }

  double _pinchDistance() {
    final points = _pointers.values.toList();
    return (points[0] - points[1]).distance;
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.extentAfter < 800 &&
        widget.hasMore &&
        !widget.isLoading &&
        !widget.isLoadingMore &&
        widget.photos.isNotEmpty) {
      widget.onLoadMore?.call();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final preferred = ref.watch(gridColumnsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final columns = effectiveGridColumns(preferred, width);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final slivers = <Widget>[
      ...widget.leadingSlivers,
      ..._buildBody(context, columns),
      if (widget.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ),
        ),
      SliverToBoxAdapter(child: SizedBox(height: bottomInset + 24)),
    ];

    Widget scrollView = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        controller: widget.controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );

    if (widget.onRefresh != null) {
      scrollView = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        color: cs.primary,
        backgroundColor: cs.surfaceContainerHigh,
        edgeOffset: MediaQuery.paddingOf(context).top,
        child: scrollView,
      );
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: ScrollConfiguration(
        // Allow mouse-drag scrolling on desktop/web too.
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
        child: scrollView,
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, int columns) {
    if (widget.isLoading && widget.photos.isEmpty) {
      return [SliverPhotoGridSkeleton(columns: columns)];
    }

    if (widget.errorMessage != null && widget.photos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorStateView(
            message: widget.errorMessage!,
            isRateLimited: widget.isRateLimited,
            onRetry: widget.onRetry ?? () => widget.onRefresh?.call(),
          ),
        ),
      ];
    }

    if (widget.photos.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateView(
            icon: widget.emptyIcon,
            title: widget.emptyTitle,
            message: widget.emptyMessage,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: kGridPadding),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: columns,
          mainAxisSpacing: columns <= 3 ? 4 : kGridSpacing,
          crossAxisSpacing: kGridSpacing,
          childCount: widget.photos.length,
          itemBuilder: (context, index) {
            final photo = widget.photos[index];
            return PhotoTile(
              key: ValueKey(photo.id),
              photo: photo,
              heroScope: widget.heroScope,
              showCaption: columns <= 3,
              useLargeImage: columns <= 2,
            );
          },
        ),
      ),
    ];
  }
}

/// Shimmering staggered grid shown while the first page loads.
class SliverPhotoGridSkeleton extends StatelessWidget {
  final int columns;
  final int count;

  const SliverPhotoGridSkeleton({
    super.key,
    this.columns = kDefaultGridColumns,
    this.count = 12,
  });

  static const _ratios = [0.66, 1.0, 0.75, 0.56, 0.8, 1.2, 0.7, 0.9];

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: kGridPadding),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: columns,
        mainAxisSpacing: kGridSpacing,
        crossAxisSpacing: kGridSpacing,
        childCount: count,
        itemBuilder: (_, i) => AspectRatio(
          aspectRatio: _ratios[i % _ratios.length],
          child: const ShimmerPlaceholder(borderRadius: 18),
        ),
      ),
    );
  }
}
