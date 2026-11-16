import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class EspereWallpaperApp extends ConsumerWidget {
  const EspereWallpaperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final matchWallpaper = ref.watch(matchWallpaperProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        // Use the wallpaper's key colour when available and enabled,
        // otherwise the Espere logo palette.
        final useWallpaper = matchWallpaper && lightDynamic != null;
        final light = useWallpaper
            ? AppTheme.fromScheme(
                AppTheme.wallpaperScheme(
                  lightDynamic.primary,
                  Brightness.light,
                ),
              )
            : AppTheme.light;
        final dark = useWallpaper
            ? AppTheme.fromScheme(
                AppTheme.wallpaperScheme(
                  (darkDynamic ?? lightDynamic).primary,
                  Brightness.dark,
                ),
              )
            : AppTheme.dark;

        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: dark,
          themeMode: themeMode,
          routerConfig: appRouter,
          builder: (context, child) {
            // Keep system bar icons readable for whichever theme is active.
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: AppTheme.overlayFor(Theme.of(context).brightness),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
