import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class WallpaperHelper {
  WallpaperHelper._();

  static const MethodChannel _channel = MethodChannel(
    'com.espere.wallpaper/wallpaper',
  );

  /// Downloads the image and launches Android's native system wallpaper crop and set screen
  static Future<bool> openSystemWallpaperChooser({
    required String imageUrl,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'espere_wall_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');

      final dio = Dio();
      await dio.download(
        imageUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        final result = await _channel.invokeMethod<bool>(
          'openSystemWallpaperChooser',
          {'filePath': file.path},
        );
        return result ?? false;
      } else {
        return true;
      }
    } catch (e) {
      debugPrint('Error opening system wallpaper chooser: $e');
      rethrow;
    }
  }

  /// Downloads the image from the given URL and applies it as wallpaper on Android
  /// [screen]: 'home', 'lock', or 'both'
  static Future<bool> setWallpaper({
    required String imageUrl,
    required String screen,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'espere_wall_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');

      final dio = Dio();
      await dio.download(
        imageUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        final result = await _channel.invokeMethod<bool>('setWallpaper', {
          'filePath': file.path,
          'screen': screen,
        });
        return result ?? false;
      } else {
        // On non-Android platforms, image was downloaded successfully
        return true;
      }
    } catch (e) {
      debugPrint('Error setting wallpaper: $e');
      rethrow;
    }
  }

  /// Downloads the image into the device's Gallery / MediaStore (Pictures/Espere Wallpaper)
  static Future<String> downloadImage({
    required String imageUrl,
    required String photoId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cleanId = photoId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'Espere_$cleanId.jpg';
      final tempFile = File('${tempDir.path}/$fileName');

      final dio = Dio();
      await dio.download(
        imageUrl,
        tempFile.path,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        final savedLocation = await _channel.invokeMethod<String>(
          'saveImageToGallery',
          {'filePath': tempFile.path, 'displayName': fileName},
        );
        return savedLocation ?? 'Pictures/Espere Wallpaper/$fileName';
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        final finalFile = File('${docDir.path}/$fileName');
        await tempFile.copy(finalFile.path);
        return finalFile.path;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
      rethrow;
    }
  }

  /// Shares the image via system share sheet
  static Future<void> sharePhoto({
    required String imageUrl,
    required String photographer,
    required String pexelsUrl,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'share_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');

      final dio = Dio();
      await dio.download(imageUrl, file.path);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Photo by $photographer on Pexels:\n$pexelsUrl\n\nShared via Espere Wallpaper',
      );
    } catch (e) {
      // Fallback to text share if download fails
      // ignore: deprecated_member_use
      await Share.share(
        'Photo by $photographer on Pexels:\n$pexelsUrl\n\nShared via Espere Wallpaper',
      );
    }
  }
}
