import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/navigation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/color_swatches.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../app/route_args.dart';
import '../../home/domain/photo_model.dart';
import '../../home/presentation/home_notifier.dart';
import 'search_notifier.dart';

/// "Search" tab. Idle: browse photographers, colours, categories and popular
/// searches. Focused: recent and suggested queries that match the input.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    ref.read(recentSearchesProvider.notifier).add(q);
    _focusNode.unfocus();
    openSearchResults(context, query: q);
  }

  void _exitSearchMode() {
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _focusNode.hasFocus || _controller.text.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: _controller,
                      focusNode: _focusNode,
                      hintText: 'Search for ideas',
                      onSubmitted: _submit,
                      onBack: searching ? _exitSearchMode : null,
                      onClear: _controller.clear,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: searching
                    ? _Suggestions(
                        key: const ValueKey('suggestions'),
                        input: _controller.text,
                        onPick: (q) {
                          _controller.text = q;
                          _submit(q);
                        },
                        onFill: (q) => _controller.value = TextEditingValue(
                          text: q,
                          selection: TextSelection.collapsed(offset: q.length),
                        ),
                      )
                    : const _Browse(key: ValueKey('browse')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Suggestions (search mode) ─────────────────────────────────────────────

class _Suggestions extends ConsumerWidget {
  final String input;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onFill;

  const _Suggestions({
    super.key,
    required this.input,
    required this.onPick,
    required this.onFill,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final needle = input.trim().toLowerCase();
    bool matches(String s) =>
        needle.isEmpty || s.toLowerCase().contains(needle);

    final recents = ref
        .watch(recentSearchesProvider)
        .where(matches)
        .take(8)
        .toList();
    final suggestions = [
      ...AppConstants.popularSearches,
      ...AppConstants.categories.map((c) => c.name),
    ].where((s) => matches(s) && !recents.contains(s)).take(8).toList();

    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (needle.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.search_rounded),
            title: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Search for '),
                  TextSpan(
                    text: '"${input.trim()}"',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            onTap: () => onPick(input.trim()),
          ),
        if (recents.isNotEmpty) ...[
          SectionHeader(
            title: 'Recent',
            actionLabel: 'Clear all',
            onAction: () => ref.read(recentSearchesProvider.notifier).clear(),
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          ),
          for (final q in recents)
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(q),
              onTap: () => onPick(q),
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () =>
                    ref.read(recentSearchesProvider.notifier).remove(q),
              ),
            ),
        ],
        if (suggestions.isNotEmpty) ...[
          const SectionHeader(
            title: 'Suggestions',
            padding: EdgeInsets.fromLTRB(16, 8, 8, 0),
          ),
          for (final q in suggestions)
            ListTile(
              leading: const Icon(Icons.trending_up_rounded),
              title: Text(q),
              onTap: () => onPick(q),
              trailing: IconButton(
                tooltip: 'Edit query',
                icon: Transform.rotate(
                  angle: -0.785,
                  child: const Icon(Icons.arrow_upward_rounded, size: 20),
                ),
                onPressed: () => onFill(q),
              ),
            ),
        ],
        if (recents.isEmpty && suggestions.isEmpty && needle.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Search millions of free, high-resolution photos.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Browse (idle) ─────────────────────────────────────────────────────────

class _Browse extends ConsumerWidget {
  const _Browse({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final trending = ref.watch(
      homeNotifierProvider.select((s) => s.trendingPhotos),
    );

    return CustomScrollView(
      slivers: [
        if (trending.isNotEmpty)
          SliverToBoxAdapter(child: _HeroCarousel(photos: trending)),
        const SliverToBoxAdapter(child: _CenteredHeader('Ideas for you')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.55,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _IdeaTile(category: AppConstants.categories[i]),
              childCount: AppConstants.categories.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: _CenteredHeader('Explore by color')),
        SliverToBoxAdapter(
          child: ColorSwatchRow(
            onSelected: (slug) {
              if (slug == null) return;
              final name = slug[0].toUpperCase() + slug.substring(1);
              openSearchResults(context, color: slug, title: name);
            },
          ),
        ),
        const SliverToBoxAdapter(child: _CenteredHeader('Popular searches')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final term in AppConstants.popularSearches)
                  ActionChip(
                    shape: const StadiumBorder(),
                    side: BorderSide.none,
                    backgroundColor: cs.surfaceContainerHigh,
                    avatar: Icon(
                      Icons.search_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                    label: Text(term),
                    onPressed: () => openSearchResults(context, query: term),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
        ),
      ],
    );
  }
}

class _CenteredHeader extends StatelessWidget {
  final String text;

  const _CenteredHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Swipeable trending hero with title overlay and page dots.
class _HeroCarousel extends StatefulWidget {
  final List<Photo> photos;

  const _HeroCarousel({required this.photos});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, i) {
              final photo = widget.photos[i];
              final heroTag = photoHeroTag('search_hero', photo.id);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: PressScale(
                  scale: 0.98,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: heroTag,
                          child: CachedNetworkImage(
                            imageUrl: photo.src.largeThumbnail,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const ShimmerPlaceholder(),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.35, 1],
                              colors: [Colors.transparent, Color(0xCC020B14)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 22,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Trending today',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                photo.alt.isNotEmpty
                                    ? photo.alt
                                    : photo.photographer,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            onTap: () => context.push(
                              '/photo/${photo.id}',
                              extra: PhotoRouteArgs(photo, heroTag: heroTag),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.photos.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page ? cs.onSurface : cs.outlineVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _IdeaTile extends StatelessWidget {
  final CategoryItem category;

  const _IdeaTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressScale(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: category.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ShimmerPlaceholder(),
              errorWidget: (_, _, _) =>
                  ColoredBox(color: theme.colorScheme.surfaceContainerHigh),
            ),
            const ColoredBox(color: Color(0x66020B14)),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => context.push('/category/${category.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
