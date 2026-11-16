import 'package:flutter/material.dart';

class ColorUtils {
  ColorUtils._();

  static Color hexToColor(
    String? hexString, {
    Color fallback = const Color(0xFFE7ECF0), // navy-tinted surface
  }) {
    if (hexString == null || hexString.isEmpty) return fallback;

    String cleanHex = hexString.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    } else if (cleanHex.length != 8) {
      return fallback;
    }

    try {
      final value = int.parse(cleanHex, radix: 16);
      return Color(value);
    } catch (_) {
      return fallback;
    }
  }

  static String colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  static bool isDark(Color color) {
    return color.computeLuminance() < 0.5;
  }
}
