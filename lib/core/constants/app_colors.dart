import 'package:flutter/material.dart';

/// Espere brand palette.
///
/// Every UI colour in the app comes from the two colours sampled from
/// `logo.png` — navy `#0F3E6D` and leaf green `#80CF00` — plus white.
/// Surfaces and text are tints/shades of the navy, so nothing off-brand
/// ever appears in the chrome.
class AppColors {
  AppColors._();

  // ── Brand (sampled from logo.png) ──────────────────────────────────────
  static const Color navy = Color(0xFF0F3E6D);
  static const Color leaf = Color(0xFF80CF00);
  static const Color white = Color(0xFFFFFFFF);

  // ── Light scheme: white tinted with navy ───────────────────────────────
  static const Color lightSurface = white;
  static const Color lightSurfaceLowest = white;
  static const Color lightSurfaceLow = Color(0xFFF5F7F9); // 4% navy
  static const Color lightSurfaceContainer = Color(0xFFEEF2F5); // 7% navy
  static const Color lightSurfaceHigh = Color(0xFFE7ECF0); // 10% navy
  static const Color lightSurfaceHighest = Color(0xFFDDE4EB); // 14% navy
  static const Color lightOnSurface = Color(0xFF08223C); // navy shade
  static const Color lightOnSurfaceVariant = Color(0xFF4B6E91); // navy tint
  static const Color lightOutline = Color(0xFFABBBCC);
  static const Color lightOutlineVariant = Color(0xFFDDE4EB);
  static const Color lightPrimaryContainer = Color(0xFFD6E3F1);
  static const Color lightLeafContainer = Color(0xFFE8F6D1); // leaf tint
  static const Color lightOnLeafContainer = Color(0xFF2D4800); // leaf shade

  // ── Dark scheme: navy shaded towards black ─────────────────────────────
  static const Color darkSurface = Color(0xFF071B2F);
  static const Color darkSurfaceLowest = Color(0xFF041322);
  static const Color darkSurfaceLow = Color(0xFF0B2238);
  static const Color darkSurfaceContainer = Color(0xFF0E2740);
  static const Color darkSurfaceHigh = Color(0xFF132E4A);
  static const Color darkSurfaceHighest = Color(0xFF193654);
  static const Color darkOnSurface = Color(0xFFE9EEF4);
  static const Color darkOnSurfaceVariant = Color(0xFFB7C5D3);
  static const Color darkOutline = Color(0xFF6F8BA7);
  static const Color darkOutlineVariant = Color(0xFF22405F);
  static const Color darkPrimary = Color(0xFFA9C7E8); // light navy tone
  static const Color darkOnPrimaryContainer = Color(0xFFD3E3F5);
  static const Color darkLeafContainer = Color(0xFF263E00);
  static const Color darkOnLeafContainer = Color(0xFFC6EC8A);

  /// Photo viewer background — always dark, like a gallery app's viewer.
  static const Color viewer = Color(0xFF020B14);

  // ── Search-by-colour swatches ──────────────────────────────────────────
  // These are *content* filters for the Pexels API, not UI colours: each one
  // must show the real hue the user is searching for.
  static const List<ColorSwatchItem> searchColors = [
    ColorSwatchItem('Red', 'red', Color(0xFFE53935)),
    ColorSwatchItem('Orange', 'orange', Color(0xFFFB8C00)),
    ColorSwatchItem('Yellow', 'yellow', Color(0xFFFDD835)),
    ColorSwatchItem('Green', 'green', Color(0xFF43A047)),
    ColorSwatchItem('Turquoise', 'turquoise', Color(0xFF26A69A)),
    ColorSwatchItem('Blue', 'blue', Color(0xFF1E88E5)),
    ColorSwatchItem('Violet', 'violet', Color(0xFF8E24AA)),
    ColorSwatchItem('Pink', 'pink', Color(0xFFEC407A)),
    ColorSwatchItem('Brown', 'brown', Color(0xFF795548)),
    ColorSwatchItem('Black', 'black', Color(0xFF111111)),
    ColorSwatchItem('Gray', 'gray', Color(0xFF9E9E9E)),
    ColorSwatchItem('White', 'white', Color(0xFFFAFAFA)),
  ];

  static ColorSwatchItem? swatchFor(String? slug) {
    if (slug == null) return null;
    for (final s in searchColors) {
      if (s.slug == slug.toLowerCase()) return s;
    }
    return null;
  }
}

class ColorSwatchItem {
  final String name;
  final String slug;
  final Color color;

  const ColorSwatchItem(this.name, this.slug, this.color);
}
