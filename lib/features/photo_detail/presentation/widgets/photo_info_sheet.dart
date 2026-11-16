import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/color_swatches.dart';
import '../../../../core/widgets/photo_grid.dart';
import '../../../../core/widgets/photo_tile.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../home/domain/photo_model.dart';
import '../../data/photo_detail_repository.dart';
import '../in_app_browser_screen.dart';
import 'add_to_collection_dialog.dart';

final relatedPhotosProvider = FutureProvider.autoDispose
    .family<List<Photo>, Photo>((ref, photo) {
      return ref.watch(photoDetailRepositoryProvider).getRelatedPhotos(photo);
    });

/// Swipe-up details: description, photographer, technical info and
/// similar photos.
class PhotoInfoSheet extends ConsumerWidget {
  final Photo photo;
  final ScrollController scrollController;

  const PhotoInfoSheet({
    super.key,
    required this.photo,
    required this.scrollController,
  });

  static Future<void> show(BuildContext context, Photo photo) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 1,
        builder: (_, controller) =>
            PhotoInfoSheet(photo: photo, scrollController: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final related = ref.watch(relatedPhotosProvider(photo));
    final avg = ColorUtils.hexToColor(
      photo.avgColor,
      fallback: cs.surfaceContainerHigh,
    );
    final hex = (photo.avgColor ?? ColorUtils.colorToHex(avg)).toUpperCase();

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              photo.alt.isNotEmpty ? photo.alt : 'Photo details',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.library_add_outlined),
                  label: const Text('Add to collection'),
                  onPressed: () => AddToCollectionDialog.show(context, photo),
                ),
                const SizedBox(width: 8),
                if (photo.url.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.open_in_new_rounded),
                    label: const Text('View on Pexels'),
                    onPressed: () => InAppBrowserScreen.open(
                      context,
                      title: 'Pexels',
                      url: photo.url,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Details',
            padding: EdgeInsets.fromLTRB(24, 12, 16, 0),
          ),
        ),
        SliverList.list(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Text(
                  photo.photographer.isNotEmpty
                      ? photo.photographer[0].toUpperCase()
                      : 'P',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              title: Text(photo.photographer),
              subtitle: const Text('Photographer on Pexels'),
              trailing: photo.photographerUrl.isEmpty
                  ? null
                  : const Icon(Icons.chevron_right_rounded),
              onTap: photo.photographerUrl.isEmpty
                  ? null
                  : () => InAppBrowserScreen.open(
                      context,
                      title: photo.photographer,
                      url: photo.photographerUrl,
                    ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.photo_size_select_actual_outlined),
              title: Text(photo.resolutionString),
              subtitle: Text(
                Formatters.formatMegapixels(photo.width, photo.height),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: ColorDot(color: avg, size: 24),
              title: Text(hex),
              subtitle: const Text('Average color · tap to copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: hex));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Copied $hex')));
              },
            ),
          ],
        ),
        const SliverToBoxAdapter(
          child: SectionHeader(
            title: 'More like this',
            padding: EdgeInsets.fromLTRB(24, 16, 16, 8),
          ),
        ),
        ...related.when(
          data: (photos) => photos.isEmpty
              ? [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No similar photos found.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ]
              : [
                  _grid(
                    photos.length,
                    (i) => PhotoTile(
                      photo: photos[i],
                      heroScope: 'related_${photo.id}',
                      showCaption: false,
                      radius: 14,
                    ),
                  ),
                ],
          loading: () => [
            _grid(
              9,
              (i) => AspectRatio(
                aspectRatio: i.isEven ? 0.7 : 1,
                child: const ShimmerPlaceholder(borderRadius: 14),
              ),
            ),
          ],
          error: (_, _) => [const SliverToBoxAdapter(child: SizedBox.shrink())],
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
        ),
      ],
    );
  }

  Widget _grid(int count, Widget Function(int) builder) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 3,
        mainAxisSpacing: kGridSpacing,
        crossAxisSpacing: kGridSpacing,
        childCount: count,
        itemBuilder: (_, i) => builder(i),
      ),
    );
  }
}
