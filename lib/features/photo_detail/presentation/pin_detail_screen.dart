import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../app/route_args.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/wallpaper_helper.dart';
import '../../../core/widgets/color_swatches.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/photo_grid.dart';
import '../../../core/widgets/photo_tile.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../favorites/data/favorites_provider.dart';
import '../../home/domain/photo_model.dart';
import 'in_app_browser_screen.dart';
import 'photo_detail_screen.dart' show photoByIdProvider;
import 'widgets/add_to_collection_dialog.dart';
import 'widgets/download_resolution_dialog.dart';
import 'widgets/photo_info_sheet.dart' show relatedPhotosProvider;
import 'widgets/set_wallpaper_bottom_sheet.dart';

const double _imageRadius = 28;
const double _dismissDistance = 100;

/// Aspect ratio used for the close-up image.
double pinImageRatio(Photo photo) => photo.width > 0 && photo.height > 0
    ? (photo.width / photo.height).clamp(0.5, 1.8).toDouble()
    : 0.75;

/// Pin close-up, Pinterest style.
///
/// * the tapped tile grows into the rounded hero image (and shrinks back)
/// * tap the image to open the full-screen viewer
/// * pull down from the top to shrink the page and dismiss it
/// * "More to explore" masonry continues below
class PinDetailScreen extends ConsumerStatefulWidget {
  final int photoId;
  final Photo? initialPhoto;
  final String? heroTag;

  const PinDetailScreen({
    super.key,
    required this.photoId,
    this.initialPhoto,
    this.heroTag,
  });

  @override
  ConsumerState<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends ConsumerState<PinDetailScreen>
    with SingleTickerProviderStateMixin {
  // How far the page has been pulled down past the top (drives scale/radius).
  double _pull = 0;
  double _scrollY = 0; // content scroll offset (for the solid top bar)
  bool _dismissing = false;
  double _springFrom = 0;
  late final AnimationController _springBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  @override
  void initState() {
    super.initState();
    _springBack.addListener(() {
      final t = Curves.easeOutCubic.transform(_springBack.value);
      setState(() => _pull = _springFrom * (1 - t));
    });
  }

  @override
  void dispose() {
    _springBack.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || _dismissing) return false;
    if (n is ScrollUpdateNotification && n.metrics.pixels != _scrollY) {
      setState(() => _scrollY = n.metrics.pixels);
    }

    if (n is OverscrollNotification &&
        n.overscroll < 0 &&
        n.dragDetails != null) {
      // Dragging down at the very top: the page follows the finger.
      _springBack.stop();
      setState(() => _pull += -n.overscroll * 0.8);
    } else if (n is ScrollUpdateNotification &&
        n.dragDetails != null &&
        _pull > 0) {
      // Dragging back up while pulled: undo the pull first.
      setState(() => _pull = math.max(0, _pull - n.scrollDelta!.abs()));
    } else if (n is ScrollEndNotification && _pull > 0) {
      if (_pull > _dismissDistance) {
        _dismissing = true;
        HapticFeedback.lightImpact();
        context.pop();
      } else {
        _springFrom = _pull;
        _springBack.forward(from: 0);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialPhoto;
    if (initial != null) return _buildPage(initial);

    return ref
        .watch(photoByIdProvider(widget.photoId))
        .when(
          data: _buildPage,
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            appBar: AppBar(),
            body: EmptyStateView(
              icon: Icons.broken_image_outlined,
              title: "Couldn't open this pin",
              message: 'Check your connection and try again.',
              buttonText: 'Try again',
              buttonIcon: Icons.refresh_rounded,
              onButtonPressed: () =>
                  ref.invalidate(photoByIdProvider(widget.photoId)),
            ),
          ),
        );
  }

  Widget _buildPage(Photo photo) {
    final cs = Theme.of(context).colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final progress = (_pull / 300).clamp(0.0, 1.0);
    final scale = 1 - progress * 0.12;
    final radius = progress * 40;
    final imageHeight = MediaQuery.sizeOf(context).width / pinImageRatio(photo);
    // Show the bar once the image's bottom edge reaches the back button.
    final barVisible = _scrollY > imageHeight - 72;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fades away as the page is pulled down, revealing the grid behind.
          Positioned.fill(
            child: ColoredBox(
              color: cs.surface.withValues(alpha: 1 - progress),
            ),
          ),
          Transform.translate(
            offset: Offset(0, _pull * 0.5),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: ColoredBox(
                  color: cs.surface,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: ScrollConfiguration(
                      // No stretch/glow: pull-to-dismiss is the overscroll effect.
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(overscroll: false),
                      child: CustomScrollView(
                        physics: const ClampingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(child: SizedBox(height: topInset)),
                          SliverToBoxAdapter(
                            child: _HeroImage(
                              photo: photo,
                              heroTag: widget.heroTag,
                            ),
                          ),
                          SliverToBoxAdapter(child: _ActionRow(photo: photo)),
                          SliverToBoxAdapter(
                            child: _CreatorAndInfo(photo: photo),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                28,
                                16,
                                12,
                              ),
                              child: Text(
                                'More to explore',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          _MoreToExplore(photo: photo),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: MediaQuery.paddingOf(context).bottom + 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Status bar strip, then a solid bar once the image has scrolled away.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset,
            child: ColoredBox(
              color: cs.surface.withValues(alpha: 1 - progress),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !barVisible,
              child: AnimatedOpacity(
                opacity: barVisible && _pull == 0 ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  height: topInset + 60,
                  padding: EdgeInsets.only(top: topInset, left: 68, right: 16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(
                      bottom: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    photo.alt.isNotEmpty ? photo.alt : photo.photographer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Back button: floating over the image, flat inside the bar.
          Positioned(
            top: topInset + 8,
            left: 12,
            child: AnimatedOpacity(
              opacity: _pull > 8 ? 0 : 1,
              duration: const Duration(milliseconds: 120),
              child: Material(
                color: barVisible ? Colors.transparent : cs.surface,
                shape: const CircleBorder(),
                elevation: barVisible ? 0 : 3,
                shadowColor: cs.shadow.withValues(alpha: 0.3),
                child: IconButton(
                  tooltip: 'Back',
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: cs.onSurface,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final Photo photo;
  final String? heroTag;

  const _HeroImage({required this.photo, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = ColorUtils.hexToColor(
      photo.avgColor,
      fallback: cs.surfaceContainerHigh,
    );
    final ratio = pinImageRatio(photo);

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(_imageRadius),
      child: ColoredBox(
        color: placeholder,
        child: CachedNetworkImage(
          imageUrl: photo.src.large2x.isNotEmpty
              ? photo.src.large2x
              : photo.src.fullView,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          placeholder: (_, _) => Image(
            image: CachedNetworkImageProvider(photo.src.optimalThumbnail),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
          errorWidget: (_, _, _) => ColoredBox(color: placeholder),
        ),
      ),
    );

    return AspectRatio(
      aspectRatio: ratio,
      child: Semantics(
        button: true,
        label: 'Open full screen',
        child: GestureDetector(
          onTap: () => context.push(
            '/view/${photo.id}',
            extra: PhotoRouteArgs(photo, heroTag: heroTag),
          ),
          child: heroTag == null
              ? image
              : Hero(
                  tag: heroTag!,
                  // Grow the corner radius from the tile's to the close-up's
                  // while the image flies, so the morph looks continuous.
                  flightShuttleBuilder: (_, animation, _, _, _) =>
                      AnimatedBuilder(
                        animation: animation,
                        builder: (_, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(
                            lerpDouble(18, _imageRadius, animation.value)!,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: photo.src.optimalThumbnail,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                          ),
                        ),
                      ),
                  child: image,
                ),
        ),
      ),
    );
  }
}

class _ActionRow extends ConsumerWidget {
  final Photo photo;

  const _ActionRow({required this.photo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isFav = ref.watch(isFavoriteProvider(photo.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: isFav ? 'Remove from favorites' : 'Favorite',
            iconSize: 28,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, a) =>
                  ScaleTransition(scale: a, child: child),
              child: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(isFav),
                color: isFav ? cs.primary : cs.onSurface,
              ),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(favoritesNotifierProvider.notifier).toggle(photo);
            },
          ),
          IconButton(
            tooltip: 'Set as wallpaper',
            iconSize: 26,
            icon: Icon(Icons.wallpaper_rounded, color: cs.onSurface),
            onPressed: () => SetWallpaperBottomSheet.show(context, photo),
          ),
          IconButton(
            tooltip: 'Share',
            iconSize: 26,
            icon: Icon(Icons.ios_share_rounded, color: cs.onSurface),
            onPressed: () => WallpaperHelper.sharePhoto(
              imageUrl: photo.src.optimalDetail,
              photographer: photo.photographer,
              pexelsUrl: photo.url,
            ),
          ),
          IconButton(
            tooltip: 'Download',
            iconSize: 26,
            icon: Icon(Icons.download_rounded, color: cs.onSurface),
            onPressed: () => DownloadResolutionDialog.show(context, photo),
          ),
          IconButton(
            tooltip: 'Details',
            iconSize: 26,
            icon: Icon(Icons.info_outline_rounded, color: cs.onSurface),
            onPressed: () => _PinDetailsSheet.show(context, photo),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => AddToCollectionDialog.show(context, photo),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorAndInfo extends StatelessWidget {
  final Photo photo;

  const _CreatorAndInfo({required this.photo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo.alt.isNotEmpty) ...[
            Text(
              photo.alt,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Creator
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  photo.photographer.isNotEmpty
                      ? photo.photographer[0].toUpperCase()
                      : 'P',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.photographer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Photographer on Pexels',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (photo.photographerUrl.isNotEmpty)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.surfaceContainerHigh,
                    foregroundColor: cs.onSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () => InAppBrowserScreen.open(
                    context,
                    title: photo.photographer,
                    url: photo.photographerUrl,
                  ),
                  child: const Text('View profile'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pin details shown in a popup sheet (opened from the ⓘ button).
class _PinDetailsSheet extends StatelessWidget {
  final Photo photo;

  const _PinDetailsSheet({required this.photo});

  static Future<void> show(BuildContext context, Photo photo) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _PinDetailsSheet(photo: photo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final avg = ColorUtils.hexToColor(
      photo.avgColor,
      fallback: cs.surfaceContainerHigh,
    );
    final hex = (photo.avgColor ?? ColorUtils.colorToHex(avg)).toUpperCase();
    final orientation = photo.width == photo.height
        ? 'Square'
        : (photo.width > photo.height ? 'Landscape' : 'Portrait');

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: photo.src.optimalThumbnail,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Photo by ${photo.photographer}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: const Icon(Icons.photo_size_select_actual_outlined),
                    label: 'Resolution',
                    value: photo.resolutionString,
                  ),
                  const _InfoDivider(),
                  _InfoRow(
                    icon: const Icon(Icons.camera_outlined),
                    label: 'Megapixels',
                    value: Formatters.formatMegapixels(
                      photo.width,
                      photo.height,
                    ),
                  ),
                  const _InfoDivider(),
                  _InfoRow(
                    icon: Icon(
                      orientation == 'Portrait'
                          ? Icons.crop_portrait_rounded
                          : (orientation == 'Square'
                                ? Icons.crop_square_rounded
                                : Icons.crop_landscape_rounded),
                    ),
                    label: 'Orientation',
                    value: orientation,
                  ),
                  const _InfoDivider(),
                  _InfoRow(
                    icon: ColorDot(color: avg, size: 22),
                    label: 'Average color',
                    value: hex,
                    trailing: Icons.copy_rounded,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: hex));
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text('Copied $hex')));
                    },
                  ),
                  if (photo.url.isNotEmpty) ...[
                    const _InfoDivider(),
                    _InfoRow(
                      icon: const Icon(Icons.public_rounded),
                      label: 'Source',
                      value: 'Pexels',
                      trailing: Icons.chevron_right_rounded,
                      onTap: () => InAppBrowserScreen.open(
                        context,
                        title: 'Pexels',
                        url: photo.url,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final IconData? trailing;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            IconTheme(
              data: IconThemeData(color: cs.onSurfaceVariant, size: 22),
              child: SizedBox(width: 24, child: Center(child: icon)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Icon(trailing, size: 18, color: cs.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 54,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
  );
}

class _MoreToExplore extends ConsumerWidget {
  final Photo photo;

  const _MoreToExplore({required this.photo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref.watch(relatedPhotosProvider(photo));
    const ratios = [0.7, 1.0, 0.8, 0.6, 0.9, 0.75];

    Widget grid(int count, Widget Function(int) builder) => SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: kGridPadding),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: kGridSpacing,
        childCount: count,
        itemBuilder: (_, i) => builder(i),
      ),
    );

    return related.when(
      data: (photos) => photos.isEmpty
          ? const SliverToBoxAdapter(child: SizedBox.shrink())
          : grid(
              photos.length,
              (i) => PhotoTile(photo: photos[i], heroScope: 'more_${photo.id}'),
            ),
      loading: () => grid(
        6,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AspectRatio(
            aspectRatio: ratios[i],
            child: const ShimmerPlaceholder(borderRadius: 18),
          ),
        ),
      ),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}
