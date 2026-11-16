import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/wallpaper_helper.dart';
import '../../../home/domain/photo_model.dart';

class WallpaperMockupPreviewDialog extends StatefulWidget {
  final Photo photo;

  const WallpaperMockupPreviewDialog({super.key, required this.photo});

  static void show(BuildContext context, Photo photo) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Wallpaper Preview',
      barrierColor: AppColors.viewer.withAlpha(235),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => Theme(
        data: AppTheme.darkVariantOf(Theme.of(context)),
        child: WallpaperMockupPreviewDialog(photo: photo),
      ),
      transitionBuilder: (_, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        );
      },
    );
  }

  @override
  State<WallpaperMockupPreviewDialog> createState() =>
      _WallpaperMockupPreviewDialogState();
}

class _WallpaperMockupPreviewDialogState
    extends State<WallpaperMockupPreviewDialog> {
  bool _isLockScreen = true; // true = Lock Screen, false = Home Screen
  bool _isApplying = false;
  double _progress = 0.0;
  String _statusMessage = '';

  Future<void> _openSystemWallpaperScreen() async {
    setState(() {
      _isApplying = true;
      _statusMessage = 'Preparing Android wallpaper screen...';
      _progress = 0.05;
    });

    try {
      await WallpaperHelper.openSystemWallpaperChooser(
        imageUrl: widget.photo.src.original,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = p;
              _statusMessage =
                  'Downloading wallpaper (${(p * 100).toInt()}%)...';
            });
          }
        },
      );

      if (mounted) {
        setState(() => _isApplying = false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _applyWallpaper(String screen) async {
    setState(() {
      _isApplying = true;
      _statusMessage = 'Downloading wallpaper...';
      _progress = 0.1;
    });

    try {
      final success = await WallpaperHelper.setWallpaper(
        imageUrl: widget.photo.src.optimalDetail,
        screen: screen,
        onProgress: (p) {
          setState(() {
            _progress = p;
            _statusMessage = 'Applying to ${screen.toUpperCase()} screen...';
          });
        },
      );

      if (mounted) {
        setState(() {
          _isApplying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Wallpaper set: ${screen == 'both' ? 'home & lock screens' : '$screen screen'}'
                  : 'Wallpaper downloaded',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error applying wallpaper: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeString = DateFormat('HH:mm').format(now);
    final dateString = DateFormat('EEEE, MMMM d').format(now);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  // Toggle Lock / Home Screen Preview
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.darkOutlineVariant),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isLockScreen = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _isLockScreen
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Lock Screen',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _isLockScreen
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isLockScreen = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: !_isLockScreen
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Home Screen',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: !_isLockScreen
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Phone Mockup Frame
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 19,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(38),
                      border: Border.all(
                        color: AppColors.darkOutlineVariant,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(50),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Wallpaper Image
                          CachedNetworkImage(
                            imageUrl: widget.photo.src.optimalDetail,
                            fit: BoxFit.cover,
                          ),

                          // Phone Punch-Hole Camera
                          Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),

                          // Status Bar icons
                          Positioned(
                            top: 12,
                            left: 20,
                            right: 20,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  timeString,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.wifi,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.battery_full,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Mockup Content: Lock Screen vs Home Screen
                          if (_isLockScreen) ...[
                            // Lock Screen: Clock & Date
                            Positioned(
                              top: 60,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    timeString,
                                    style: const TextStyle(color: Colors.white)
                                        .copyWith(
                                          fontSize: 54,
                                          fontWeight: FontWeight.w300,
                                          letterSpacing: -1.0,
                                          shadows: [
                                            const Shadow(
                                              color: Colors.black54,
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                  ),
                                  Text(
                                    dateString,
                                    style:
                                        TextStyle(
                                          color: Colors.white.withAlpha(220),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ).copyWith(
                                          shadows: [
                                            const Shadow(
                                              color: Colors.black54,
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            // Bottom Lock Actions
                            Positioned(
                              bottom: 24,
                              left: 24,
                              right: 24,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(100),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.flashlight_on_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(100),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Home Screen: App icons grid mockup
                            Positioned(
                              top: 70,
                              left: 16,
                              right: 16,
                              child: Column(
                                children: [
                                  // Search pill widget
                                  Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(90),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.search,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                        Spacer(),
                                        Icon(
                                          Icons.mic,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  // Grid of 4x2 icons
                                  GridView.count(
                                    shrinkWrap: true,
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 18,
                                    crossAxisSpacing: 12,
                                    children: [
                                      _buildAppIcon(
                                        Icons.phone,
                                        Theme.of(context).colorScheme.secondary,
                                      ),
                                      _buildAppIcon(
                                        Icons.message,
                                        AppColors.darkPrimary,
                                      ),
                                      _buildAppIcon(Icons.camera, Colors.white),
                                      _buildAppIcon(
                                        Icons.music_note,
                                        Theme.of(context).colorScheme.secondary,
                                      ),
                                      _buildAppIcon(
                                        Icons.map,
                                        AppColors.darkPrimary,
                                      ),
                                      _buildAppIcon(Icons.mail, Colors.white),
                                      _buildAppIcon(
                                        Icons.settings,
                                        AppColors.darkOnSurfaceVariant,
                                      ),
                                      _buildAppIcon(
                                        Icons.photo,
                                        Theme.of(context).colorScheme.secondary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Applying Progress Overlay
                          if (_isApplying)
                            Container(
                              color: Colors.black.withAlpha(190),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        value: _progress > 0 ? _progress : null,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _statusMessage,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Set Wallpaper Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(
                  top: BorderSide(color: AppColors.darkOutlineVariant),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isApplying
                          ? null
                          : _openSystemWallpaperScreen,
                      icon: const Icon(Icons.crop_rotate_rounded, size: 20),
                      label: const Text('Crop & set with system picker'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isApplying
                              ? null
                              : () => _applyWallpaper('home'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Home Screen'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isApplying
                              ? null
                              : () => _applyWallpaper('lock'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Lock Screen'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isApplying
                              ? null
                              : () => _applyWallpaper('both'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Both'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(110),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Center(child: Icon(icon, size: 20, color: color)),
    );
  }
}
