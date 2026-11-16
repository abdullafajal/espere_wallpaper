import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/photo_grid.dart';
import '../../favorites/data/favorites_provider.dart';
import '../../search/presentation/search_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final favorites = ref.watch(favoritesNotifierProvider).length;
    final collections = ref.watch(collectionsNotifierProvider).length;
    final themeMode = ref.watch(themeModeProvider);
    final matchWallpaper = ref.watch(matchWallpaperProvider);
    final columns = ref.watch(gridColumnsProvider);
    final history = ref.watch(recentSearchesProvider);

    Widget groupTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          // Brand card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const BrandLogo(size: 80),
                    const SizedBox(height: 12),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.appTagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.favorite_rounded),
                          label: Text('$favorites favorites'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.photo_album_outlined),
                          label: Text('$collections collections'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          groupTitle('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ),

          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.palette_outlined),
            title: const Text('Match wallpaper colors'),
            subtitle: const Text(
              'Use colors from your phone wallpaper (Android 12+). '
              'Turn off to use the Espere logo colors.',
            ),
            value: matchWallpaper,
            onChanged: (v) => ref.read(matchWallpaperProvider.notifier).set(v),
          ),
          groupTitle('Photo grid'),
          ListTile(
            leading: const Icon(Icons.grid_view_rounded),
            title: const Text('Photos per row'),
            subtitle: const Text('Tip: pinch any grid to change this'),
            trailing: Text('$columns', style: theme.textTheme.titleMedium),
          ),
          Slider(
            value: columns.toDouble(),
            min: kMinGridColumns.toDouble(),
            max: kMaxGridColumns.toDouble(),
            divisions: kMaxGridColumns - kMinGridColumns,
            label: '$columns',
            onChanged: (v) =>
                ref.read(gridColumnsProvider.notifier).set(v.round()),
          ),

          groupTitle('Privacy'),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('Clear search history'),
            subtitle: Text(
              history.isEmpty
                  ? 'No recent searches'
                  : '${history.length} recent searches',
            ),
            enabled: history.isNotEmpty,
            onTap: () async {
              await ref.read(recentSearchesProvider.notifier).clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search history cleared')),
                );
              }
            },
          ),
          const ListTile(
            leading: Icon(Icons.phone_android_rounded),
            title: Text('Stored on this device'),
            subtitle: Text(
              'Favorites, collections and history never leave your phone',
            ),
          ),

          groupTitle('About'),
          ListTile(
            leading: const Icon(Icons.public_rounded),
            title: const Text('Photos provided by Pexels'),
            subtitle: const Text('Free high-resolution photography'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _open('https://www.pexels.com'),
          ),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: const Text('Pexels API'),
            subtitle: const Text('Documentation and terms'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _open('https://www.pexels.com/api/documentation/'),
          ),
        ],
      ),
    );
  }
}
