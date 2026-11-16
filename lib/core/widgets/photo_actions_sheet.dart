import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/route_args.dart';
import '../../features/favorites/data/favorites_provider.dart';
import '../../features/home/domain/photo_model.dart';
import '../../features/photo_detail/presentation/widgets/add_to_collection_dialog.dart';
import '../../features/photo_detail/presentation/widgets/download_resolution_dialog.dart';
import '../utils/wallpaper_helper.dart';

/// Quick actions for a pin, opened from the ⋯ button under a tile.
class PhotoActionsSheet extends ConsumerWidget {
  final Photo photo;
  final String heroTag;

  const PhotoActionsSheet({
    super.key,
    required this.photo,
    required this.heroTag,
  });

  static Future<void> show(BuildContext context, Photo photo, String heroTag) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => PhotoActionsSheet(photo: photo, heroTag: heroTag),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFav = ref.watch(isFavoriteProvider(photo.id));

    void run(void Function() action) {
      Navigator.pop(context);
      action();
    }

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: photo.src.optimalThumbnail,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.alt.isNotEmpty ? photo.alt : 'Photo',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        photo.photographer,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_full_rounded),
            title: const Text('Open'),
            onTap: () => run(
              () => context.push(
                '/photo/${photo.id}',
                extra: PhotoRouteArgs(photo, heroTag: heroTag),
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            ),
            title: Text(isFav ? 'Remove from favorites' : 'Add to favorites'),
            onTap: () => run(
              () => ref.read(favoritesNotifierProvider.notifier).toggle(photo),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.library_add_outlined),
            title: const Text('Save to collection'),
            onTap: () => run(() => AddToCollectionDialog.show(context, photo)),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Download'),
            onTap: () =>
                run(() => DownloadResolutionDialog.show(context, photo)),
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Share'),
            onTap: () => run(
              () => WallpaperHelper.sharePhoto(
                imageUrl: photo.src.optimalDetail,
                photographer: photo.photographer,
                pexelsUrl: photo.url,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
