class Formatters {
  Formatters._();

  static String formatDimensions(int width, int height) {
    return '$width × $height';
  }

  static String formatMegapixels(int width, int height) {
    final mp = (width * height) / 1000000;
    return '${mp.toStringAsFixed(1)} MP';
  }

  static String estimateFileSize(int width, int height, String quality) {
    final pixels = width * height;
    double mb;

    switch (quality.toLowerCase()) {
      case 'original':
        mb = (pixels * 0.00000045).clamp(1.5, 28.0);
        break;
      case 'large2x':
        mb = (pixels * 0.00000025).clamp(1.0, 10.0);
        break;
      case 'large':
        mb = 2.4;
        break;
      case 'medium':
        mb = 0.8;
        break;
      case 'portrait':
        mb = 1.9;
        break;
      default:
        mb = 1.5;
    }

    if (mb >= 1.0) {
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      return '${(mb * 1024).round()} KB';
    }
  }

  static String formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
