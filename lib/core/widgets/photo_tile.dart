import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/route_args.dart';
import '../../features/favorites/data/favorites_provider.dart';
import '../../features/home/domain/photo_model.dart';
import '../utils/color_utils.dart';
import 'photo_actions_sheet.dart';
import 'press_scale.dart';

/// Pinterest-style pin: rounded image at its natural aspect ratio, with an
/// optional caption and ⋯ menu underneath. Tap opens, long-press favourites.
class PhotoTile extends ConsumerWidget {
  final Photo photo;
  final String heroScope;
  final bool showCaption;
  final bool useLargeImage;
  final double radius;

  const PhotoTile({
    super.key,
    required this.photo,
    required this.heroScope,
    this.showCaption = true,
    this.useLargeImage = false,
    this.radius = 18,
  });

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final added = await ref
        .read(favoritesNotifierProvider.notifier)
        .toggle(photo);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added ? 'Added to Favorites' : 'Removed from Favorites',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isFav = ref.watch(isFavoriteProvider(photo.id));
    final placeholder = ColorUtils.hexToColor(
      photo.avgColor,
      fallback: cs.surfaceContainerHigh,
    );
    final heroTag = photoHeroTag(heroScope, photo.id);
    final label = photo.alt.isNotEmpty
        ? photo.alt
        : 'Photo by ${photo.photographer}';

    final image = PressScale(
      child: Semantics(
        button: true,
        label: label,
        hint: 'Long-press to ${isFav ? 'remove from' : 'add to'} favorites',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: AspectRatio(
            aspectRatio: photo.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: placeholder),
                Hero(
                  tag: heroTag,
                  child: CachedNetworkImage(
                    imageUrl: useLargeImage
                        ? photo.src.largeThumbnail
                        : photo.src.optimalThumbnail,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 220),
                    placeholder: (_, _) => ColoredBox(color: placeholder),
                    errorWidget: (_, _, _) => ColoredBox(
                      color: cs.surfaceContainerHigh,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                if (isFav)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: cs.primary,
                      ),
                    ),
                  ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => context.push(
                      '/photo/${photo.id}',
                      extra: PhotoRouteArgs(photo, heroTag: heroTag),
                    ),
                    onLongPress: () => _toggleFavorite(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!showCaption) return image;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        image,
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  photo.alt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              height: 32,
              child: IconButton(
                tooltip: 'More options',
                padding: EdgeInsets.zero,
                iconSize: 20,
                icon: Icon(Icons.more_horiz_rounded, color: cs.onSurface),
                onPressed: () =>
                    PhotoActionsSheet.show(context, photo, heroTag),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
