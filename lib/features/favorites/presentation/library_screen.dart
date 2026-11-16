import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/photo_grid.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/underline_tabs.dart';
import '../../collections/presentation/collection_name_dialog.dart';
import '../../home/domain/photo_model.dart';
import '../data/favorites_provider.dart';

/// "Saved" tab, Pinterest style: Pins (favourites) and Boards (collections)
/// behind underline tabs, with a local search and a create button.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _search = TextEditingController();
  int _tab = 0; // 0 = Pins, 1 = Boards
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _createBoard() async {
    final name = await showCollectionNameDialog(context, title: 'New board');
    if (name != null) {
      await ref
          .read(collectionsNotifierProvider.notifier)
          .createCollection(name);
      if (mounted) setState(() => _tab = 1);
    }
  }

  bool _matches(String text) =>
      _query.isEmpty || text.toLowerCase().contains(_query);

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesNotifierProvider);
    final collections = ref.watch(collectionsNotifierProvider);

    final header = SliverAppBar(
      floating: true,
      snap: true,
      toolbarHeight: 64,
      titleSpacing: 4,
      title: Row(
        children: [
          const SettingsAvatarButton(),
          Expanded(
            child: UnderlineTabs(
              labels: const ['Pins', 'Boards'],
              selected: _tab,
              scrollable: false,
              padding: EdgeInsets.zero,
              onSelect: (i) => setState(() => _tab = i),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  controller: _search,
                  hintText: _tab == 0
                      ? 'Search your Pins'
                      : 'Search your boards',
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                  onClear: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              IconButton(
                tooltip: 'New board',
                iconSize: 30,
                icon: const Icon(Icons.add_rounded),
                onPressed: _createBoard,
              ),
            ],
          ),
        ),
      ),
    );

    if (_tab == 0) {
      final pins = favorites
          .where((p) => _matches('${p.alt} ${p.photographer}'))
          .toList();
      return Scaffold(
        body: PhotoGrid(
          key: const ValueKey('saved_pins'),
          heroScope: 'saved',
          photos: pins,
          emptyIcon: Icons.favorite_border_rounded,
          emptyTitle: _query.isEmpty
              ? 'Save ideas you love'
              : 'No matching Pins',
          emptyMessage: _query.isEmpty
              ? 'Tap the heart on any Pin, or long-press it in the feed. Your Pins stay on this device.'
              : 'Try a different word.',
          leadingSlivers: [header],
        ),
      );
    }

    final boards = collections.where((c) => _matches(c.name)).toList();
    final showAll = _query.isEmpty || _matches('all pins favorites');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          header,
          if (boards.isEmpty && !showAll)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                icon: Icons.search_off_rounded,
                title: 'No matching boards',
                message: 'Try a different word.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.98,
                ),
                delegate: SliverChildListDelegate([
                  if (showAll)
                    _BoardCard(
                      name: 'All Pins',
                      photos: favorites,
                      subtitle: _pins(favorites.length),
                      onTap: () => context.push('/favorites'),
                    ),
                  for (final c in boards)
                    _BoardCard(
                      name: c.name,
                      photos: c.photos,
                      subtitle: '${_pins(c.photoCount)} · ${_ago(c.updatedAt)}',
                      onTap: () => context.push('/collection/${c.id}'),
                    ),
                ]),
              ),
            ),
          if (collections.isEmpty && _query.isEmpty)
            SliverToBoxAdapter(
              child: EmptyStateView(
                icon: Icons.dashboard_customize_outlined,
                title: 'Organize your ideas',
                message:
                    'Create boards like "Calm mountains" or "Night city" to group the Pins you save.',
                buttonText: 'Create board',
                buttonIcon: Icons.add_rounded,
                onButtonPressed: _createBoard,
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
          ),
        ],
      ),
    );
  }
}

String _pins(int n) => n == 1 ? '1 Pin' : '$n Pins';

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inDays >= 365) return '${d.inDays ~/ 365}y';
  if (d.inDays >= 7) return '${d.inDays ~/ 7}w';
  if (d.inDays >= 1) return '${d.inDays}d';
  if (d.inHours >= 1) return '${d.inHours}h';
  return 'now';
}

/// Board with a Pinterest-style collage cover: one large image on the left,
/// two stacked on the right.
class _BoardCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final List<Photo> photos;
  final VoidCallback onTap;

  const _BoardCard({
    required this.name,
    required this.subtitle,
    required this.photos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget cell(int i) {
      if (i >= photos.length) return ColoredBox(color: cs.surfaceContainerHigh);
      return CachedNetworkImage(
        imageUrl: photos[i].src.optimalThumbnail,
        fit: BoxFit.cover,
        placeholder: (_, _) => ColoredBox(color: cs.surfaceContainerHigh),
        errorWidget: (_, _, _) => ColoredBox(color: cs.surfaceContainerHigh),
      );
    }

    return Semantics(
      button: true,
      label: '$name, $subtitle',
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.45,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: cell(0)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: cell(1)),
                            const SizedBox(height: 2),
                            Expanded(child: cell(2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
