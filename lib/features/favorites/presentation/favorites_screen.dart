import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/board_header.dart';
import '../../../core/widgets/photo_grid.dart';
import '../data/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesNotifierProvider);

    return Scaffold(
      body: PhotoGrid(
        heroScope: 'favorites',
        photos: favorites,
        emptyIcon: Icons.favorite_border_rounded,
        emptyTitle: 'No favorites yet',
        emptyMessage:
            'Tap the heart on any photo, or long-press it in a grid, to keep it here. '
            'Favorites are saved on this device.',
        leadingSlivers: [
          const SliverAppBar(floating: true, snap: true),
          SliverToBoxAdapter(
            child: BoardHeader(title: 'All Pins', count: favorites.length),
          ),
        ],
      ),
    );
  }
}
