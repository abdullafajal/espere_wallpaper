import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/wallpaper_helper.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../favorites/data/favorites_provider.dart';
import '../../home/domain/photo_model.dart';
import '../data/photo_detail_repository.dart';
import 'widgets/add_to_collection_dialog.dart';
import 'widgets/download_resolution_dialog.dart';
import 'widgets/photo_info_sheet.dart';
import 'widgets/set_wallpaper_bottom_sheet.dart';

final photoByIdProvider = FutureProvider.autoDispose.family<Photo, int>((
  ref,
  id,
) {
  return ref.watch(photoDetailRepositoryProvider).getPhotoDetails(id);
});

/// Full-screen photo viewer.
///
/// * tap — show / hide the controls
/// * pinch or double-tap — zoom
/// * swipe down — close, swipe up — details & similar photos
class PhotoDetailScreen extends ConsumerStatefulWidget {
  final int photoId;
  final Photo? initialPhoto;
  final String? heroTag;

  const PhotoDetailScreen({
    super.key,
    required this.photoId,
    this.initialPhoto,
    this.heroTag,
  });

  @override
  ConsumerState<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends ConsumerState<PhotoDetailScreen> {
  final _transform = TransformationController();
  bool _chromeVisible = true;
  bool _zoomed = false;
  double _dragOffset = 0;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void dispose() {
    _transform.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    SystemChrome.setEnabledSystemUIMode(
      _chromeVisible ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  void _onDoubleTap() {
    if (_zoomed) {
      _transform.value = Matrix4.identity();
    } else {
      const scale = 2.5;
      final p = _doubleTapPosition;
      _transform.value = Matrix4.identity()
        ..translateByDouble(-p.dx * (scale - 1), -p.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    }
    setState(() => _zoomed = !_zoomed);
  }

  void _onDragEnd(DragEndDetails d, Photo photo) {
    final v = d.primaryVelocity ?? 0;
    if (_dragOffset > 120 || v > 900) {
      context.pop();
      return;
    }
    if (_dragOffset < -60 || v < -700) {
      PhotoInfoSheet.show(context, photo);
    }
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialPhoto;
    if (initial != null) return _buildViewer(initial);

    final async = ref.watch(photoByIdProvider(widget.photoId));
    return async.when(
      data: _buildViewer,
      loading: () => const Scaffold(
        backgroundColor: AppColors.viewer,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyStateView(
          icon: Icons.broken_image_outlined,
          title: "Couldn't open this photo",
          message: 'Check your connection and try again.',
          buttonText: 'Try again',
          buttonIcon: Icons.refresh_rounded,
          onButtonPressed: () =>
              ref.invalidate(photoByIdProvider(widget.photoId)),
        ),
      ),
    );
  }

  Widget _buildViewer(Photo photo) {
    final dismissProgress = (_dragOffset.abs() / 400).clamp(0.0, 1.0);
    final chromeOpacity = _chromeVisible && _dragOffset == 0 ? 1.0 : 0.0;

    Widget image = CachedNetworkImage(
      imageUrl: photo.src.fullView,
      fit: BoxFit.contain,
      fadeInDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      // Show the grid thumbnail (already cached) until the large image arrives.
      placeholder: (_, _) => Image(
        image: CachedNetworkImageProvider(photo.src.optimalThumbnail),
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
      errorWidget: (_, _, _) => const Icon(
        Icons.broken_image_outlined,
        color: Colors.white54,
        size: 48,
      ),
    );
    if (widget.heroTag != null) {
      image = Hero(tag: widget.heroTag!, child: image);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(Brightness.dark),
      child: Scaffold(
        backgroundColor: AppColors.viewer.withValues(
          alpha: 1 - dismissProgress,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleChrome,
                onDoubleTapDown: (d) => _doubleTapPosition = d.localPosition,
                onDoubleTap: _onDoubleTap,
                onVerticalDragUpdate: _zoomed
                    ? null
                    : (d) => setState(() => _dragOffset += d.delta.dy),
                onVerticalDragEnd: _zoomed ? null : (d) => _onDragEnd(d, photo),
                child: Transform.translate(
                  offset: Offset(
                    0,
                    _dragOffset > 0 ? _dragOffset : _dragOffset * 0.3,
                  ),
                  child: InteractiveViewer(
                    transformationController: _transform,
                    minScale: 1,
                    maxScale: 5,
                    onInteractionEnd: (_) {
                      final zoomed =
                          _transform.value.getMaxScaleOnAxis() > 1.01;
                      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                    },
                    child: SizedBox.expand(child: image),
                  ),
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _Chrome(
                visible: chromeOpacity > 0,
                gradientFromTop: true,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Add to collection',
                          icon: const Icon(
                            Icons.library_add_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              AddToCollectionDialog.show(context, photo),
                        ),
                        IconButton(
                          tooltip: 'Details',
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => PhotoInfoSheet.show(context, photo),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom action bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _Chrome(
                visible: chromeOpacity > 0,
                gradientFromTop: false,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: _ActionBar(photo: photo),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fading gradient scrim that holds viewer controls.
class _Chrome extends StatelessWidget {
  final bool visible;
  final bool gradientFromTop;
  final Widget child;

  const _Chrome({
    required this.visible,
    required this.gradientFromTop,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: gradientFromTop
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              end: gradientFromTop
                  ? Alignment.bottomCenter
                  : Alignment.topCenter,
              colors: [
                AppColors.viewer.withValues(alpha: 0.75),
                AppColors.viewer.withValues(alpha: 0),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  final Photo photo;

  const _ActionBar({required this.photo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(isFavoriteProvider(photo.id));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ViewerAction(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () => WallpaperHelper.sharePhoto(
            imageUrl: photo.src.optimalDetail,
            photographer: photo.photographer,
            pexelsUrl: photo.url,
          ),
        ),
        _ViewerAction(
          icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: 'Favorite',
          color: isFav ? _onDarkAccent(context) : null,
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(favoritesNotifierProvider.notifier).toggle(photo);
          },
        ),
        _ViewerAction(
          icon: Icons.wallpaper_rounded,
          label: 'Set as',
          onTap: () => SetWallpaperBottomSheet.show(context, photo),
        ),
        _ViewerAction(
          icon: Icons.download_outlined,
          label: 'Download',
          onTap: () => DownloadResolutionDialog.show(context, photo),
        ),
      ],
    );
  }
}

class _ViewerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ViewerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color ?? Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A light accent tone that reads well on the dark viewer background.
Color _onDarkAccent(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return cs.brightness == Brightness.dark ? cs.primary : cs.inversePrimary;
}
