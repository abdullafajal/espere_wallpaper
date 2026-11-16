import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/photo_grid.dart';
import '../../favorites/data/favorites_provider.dart';
import '../../../core/widgets/board_header.dart';
import 'collection_name_dialog.dart';

class CollectionDetailScreen extends ConsumerWidget {
  final String collectionId;

  const CollectionDetailScreen({super.key, required this.collectionId});

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final name = await showCollectionNameDialog(
      context,
      title: 'Rename collection',
      confirmLabel: 'Rename',
      initialValue: current,
    );
    if (name != null) {
      await ref
          .read(collectionsNotifierProvider.notifier)
          .renameCollection(collectionId, name);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: Text('Delete "$name"?'),
        content: const Text(
          'The collection will be removed. Photos stay in your Favorites.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.pop();
    await ref
        .read(collectionsNotifierProvider.notifier)
        .deleteCollection(collectionId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref
        .watch(collectionsNotifierProvider)
        .where((c) => c.id == collectionId);

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyStateView(
          icon: Icons.folder_off_outlined,
          title: 'Collection not found',
          message: 'It may have been deleted.',
        ),
      );
    }
    final collection = matches.first;

    return Scaffold(
      body: PhotoGrid(
        heroScope: 'collection_$collectionId',
        photos: collection.photos,
        emptyIcon: Icons.add_photo_alternate_outlined,
        emptyTitle: 'This collection is empty',
        emptyMessage: 'Open any Pin and tap Save to add it here.',
        leadingSlivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            actions: [
              PopupMenuButton<String>(
                tooltip: 'More options',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'rename') _rename(context, ref, collection.name);
                  if (value == 'delete') _delete(context, ref, collection.name);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'rename',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Rename'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Delete collection'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: BoardHeader(
              title: collection.name,
              count: collection.photoCount,
            ),
          ),
        ],
      ),
    );
  }
}
