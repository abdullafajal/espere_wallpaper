import 'package:flutter/material.dart';
import '../../../../core/utils/wallpaper_helper.dart';
import '../../../home/domain/photo_model.dart';
import 'wallpaper_mockup_preview_dialog.dart';

/// "Set as" sheet: system picker, live preview, or one-tap apply.
class SetWallpaperBottomSheet extends StatefulWidget {
  final Photo photo;

  const SetWallpaperBottomSheet({super.key, required this.photo});

  static Future<void> show(BuildContext context, Photo photo) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SetWallpaperBottomSheet(photo: photo),
    );
  }

  @override
  State<SetWallpaperBottomSheet> createState() =>
      _SetWallpaperBottomSheetState();
}

class _SetWallpaperBottomSheetState extends State<SetWallpaperBottomSheet> {
  bool _busy = false;
  double _progress = 0;
  String _status = '';

  Future<void> _openSystemPicker() async {
    setState(() {
      _busy = true;
      _status = 'Preparing wallpaper…';
      _progress = 0;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await WallpaperHelper.openSystemWallpaperChooser(
        imageUrl: widget.photo.src.original,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't open the wallpaper picker: $e")),
      );
    }
  }

  Future<void> _apply(String screen, String label) async {
    setState(() {
      _busy = true;
      _status = 'Setting $label…';
      _progress = 0;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await WallpaperHelper.setWallpaper(
        imageUrl: widget.photo.src.optimalDetail,
        screen: screen,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text('Wallpaper set: $label')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't set wallpaper: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Set as wallpaper', style: theme.textTheme.titleLarge),
          ),
          if (_busy)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_status ${_progress > 0 ? '${(_progress * 100).toInt()}%' : ''}',
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
          else ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.crop_rotate_rounded),
              title: const Text('Crop & set with system picker'),
              subtitle: const Text(
                'Recommended · adjust framing before applying',
              ),
              onTap: _openSystemPicker,
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.smartphone_rounded),
              title: const Text('Preview on a phone'),
              subtitle: const Text('See it on the lock and home screen'),
              onTap: () {
                Navigator.pop(context);
                WallpaperMockupPreviewDialog.show(context, widget.photo);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'Quick apply',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _apply('home', 'home screen'),
                      child: const Text('Home'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _apply('lock', 'lock screen'),
                      child: const Text('Lock'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _apply('both', 'home & lock screens'),
                      child: const Text('Both'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
