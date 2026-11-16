import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../collections/presentation/collection_name_dialog.dart';
import '../../../favorites/data/favorites_provider.dart';
import '../../../home/domain/photo_model.dart';

/// "Add to" sheet: create a collection or toggle membership in existing ones.
class AddToCollectionDialog extends ConsumerWidget {
  final Photo photo;

  const AddToCollectionDialog({super.key, required this.photo});

  static Future<void> show(BuildContext context, Photo photo) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddToCollectionDialog(photo: photo),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final collections = ref.watch(collectionsNotifierProvider);
    final notifier = ref.read(collectionsNotifierProvider.notifier);

    Widget thumb(Widget child) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: 48, height: 48, child: child),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Add to', style: theme.textTheme.titleLarge),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: thumb(
              ColoredBox(
                color: cs.primaryContainer,
                child: Icon(Icons.add_rounded, color: cs.onPrimaryContainer),
              ),
            ),
            title: const Text('New collection'),
            onTap: () async {
              final name = await showCollectionNameDialog(context);
              if (name != null) {
                await notifier.createCollection(name, initialPhoto: photo);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Added to "$name"')));
                }
              }
            },
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 16,
              ),
              itemCount: collections.length,
              itemBuilder: (context, i) {
                final c = collections[i];
                final contains = c.photos.any((p) => p.id == photo.id);
                return CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  value: contains,
                  secondary: thumb(
                    c.coverPhotoUrl == null
                        ? ColoredBox(
                            color: cs.surfaceContainerHigh,
                            child: Icon(
                              Icons.photo_library_outlined,
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: c.coverPhotoUrl!,
                            fit: BoxFit.cover,
                          ),
                  ),
                  title: Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    c.photoCount == 1 ? '1 item' : '${c.photoCount} items',
                  ),
                  onChanged: (v) => v == true
                      ? notifier.addPhotoToCollection(c.id, photo)
                      : notifier.removePhotoFromCollection(c.id, photo.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
