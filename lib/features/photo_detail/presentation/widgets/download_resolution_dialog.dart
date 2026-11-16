import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/wallpaper_helper.dart';
import '../../../home/domain/photo_model.dart';

class _Option {
  final String label;
  final String resolution;
  final String size;
  final String url;
  final String? badge;
  final IconData icon;

  const _Option(
    this.label,
    this.resolution,
    this.size,
    this.url,
    this.icon, [
    this.badge,
  ]);
}

/// Download sheet: pick a resolution, see progress inline.
class DownloadResolutionDialog extends StatefulWidget {
  final Photo photo;

  const DownloadResolutionDialog({super.key, required this.photo});

  static Future<void> show(BuildContext context, Photo photo) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DownloadResolutionDialog(photo: photo),
    );
  }

  @override
  State<DownloadResolutionDialog> createState() =>
      _DownloadResolutionDialogState();
}

class _DownloadResolutionDialogState extends State<DownloadResolutionDialog> {
  bool _isDownloading = false;
  double _progress = 0;
  String _quality = '';

  Future<void> _download(_Option opt) async {
    final photo = widget.photo;
    if (opt.label == 'Original') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.download_outlined),
          title: const Text('Download original?'),
          content: Text(
            'This is the full ${photo.resolutionString} file, about '
            '${Formatters.estimateFileSize(photo.width, photo.height, 'original')}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Download'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() {
      _isDownloading = true;
      _quality = opt.label;
      _progress = 0;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      await WallpaperHelper.downloadImage(
        imageUrl: opt.url,
        photoId: '${photo.id}_${opt.label.toLowerCase().replaceAll(' ', '_')}',
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Saved to your device')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      messenger.showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = widget.photo;
    final options = [
      _Option(
        'Original',
        p.resolutionString,
        Formatters.estimateFileSize(p.width, p.height, 'original'),
        p.src.original,
        Icons.hd_outlined,
        'Best',
      ),
      _Option(
        'Large',
        '${(p.width * 0.7).round()} × ${(p.height * 0.7).round()}',
        Formatters.estimateFileSize(p.width, p.height, 'large2x'),
        p.src.large2x,
        Icons.photo_outlined,
        'Recommended',
      ),
      _Option(
        'Phone wallpaper',
        '800 × 1200',
        '~1.9 MB',
        p.src.portrait,
        Icons.smartphone_rounded,
      ),
      _Option(
        'Small',
        '350 px tall',
        '~800 KB',
        p.src.medium,
        Icons.photo_size_select_small_rounded,
      ),
    ];

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
            child: Text('Download', style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Choose a size · ${Formatters.formatMegapixels(p.width, p.height)} original',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Downloading $_quality… ${(_progress * 100).toInt()}%',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            )
          else
            for (final o in options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Icon(o.icon),
                title: Text(o.label),
                subtitle: Text('${o.resolution} · ${o.size}'),
                trailing: o.badge == null
                    ? null
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: o.badge == 'Recommended'
                              ? cs.secondaryContainer
                              : cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          o.badge!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: o.badge == 'Recommended'
                                ? cs.onSecondaryContainer
                                : cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                onTap: () => _download(o),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
