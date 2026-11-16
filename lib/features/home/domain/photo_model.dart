class Photo {
  final int id;
  final int width;
  final int height;
  final String url;
  final String photographer;
  final String photographerUrl;
  final int? photographerId;
  final String? avgColor;
  final PhotoSrc src;
  final bool liked;
  final String alt;

  const Photo({
    required this.id,
    required this.width,
    required this.height,
    required this.url,
    required this.photographer,
    required this.photographerUrl,
    this.photographerId,
    this.avgColor,
    required this.src,
    this.liked = false,
    this.alt = '',
  });

  double get aspectRatio {
    if (width > 0 && height > 0) {
      final ratio = width / height;
      // Clamp between 0.55 and 1.8 for balanced staggered masonry grid appearance
      return ratio.clamp(0.55, 1.8);
    }
    return 0.7;
  }

  String get resolutionString => '$width × $height';

  double get megapixels => (width * height) / 1000000;

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as int,
      width: json['width'] as int? ?? 1080,
      height: json['height'] as int? ?? 1920,
      url: json['url'] as String? ?? '',
      photographer: json['photographer'] as String? ?? 'Unknown Photographer',
      photographerUrl: json['photographer_url'] as String? ?? '',
      photographerId: json['photographer_id'] as int?,
      avgColor: json['avg_color'] as String?,
      src: PhotoSrc.fromJson(json['src'] as Map<String, dynamic>? ?? {}),
      liked: json['liked'] as bool? ?? false,
      alt: json['alt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'width': width,
      'height': height,
      'url': url,
      'photographer': photographer,
      'photographer_url': photographerUrl,
      'photographer_id': photographerId,
      'avg_color': avgColor,
      'src': src.toJson(),
      'liked': liked,
      'alt': alt,
    };
  }

  Photo copyWith({
    int? id,
    int? width,
    int? height,
    String? url,
    String? photographer,
    String? photographerUrl,
    int? photographerId,
    String? avgColor,
    PhotoSrc? src,
    bool? liked,
    String? alt,
  }) {
    return Photo(
      id: id ?? this.id,
      width: width ?? this.width,
      height: height ?? this.height,
      url: url ?? this.url,
      photographer: photographer ?? this.photographer,
      photographerUrl: photographerUrl ?? this.photographerUrl,
      photographerId: photographerId ?? this.photographerId,
      avgColor: avgColor ?? this.avgColor,
      src: src ?? this.src,
      liked: liked ?? this.liked,
      alt: alt ?? this.alt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Photo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class PhotoSrc {
  final String original;
  final String large2x;
  final String large;
  final String medium;
  final String small;
  final String portrait;
  final String landscape;
  final String tiny;

  const PhotoSrc({
    required this.original,
    required this.large2x,
    required this.large,
    required this.medium,
    required this.small,
    required this.portrait,
    required this.landscape,
    required this.tiny,
  });

  factory PhotoSrc.fromJson(Map<String, dynamic> json) {
    return PhotoSrc(
      original: json['original'] as String? ?? '',
      large2x: json['large2x'] as String? ?? json['large'] as String? ?? '',
      large: json['large'] as String? ?? '',
      medium: json['medium'] as String? ?? '',
      small: json['small'] as String? ?? '',
      portrait: json['portrait'] as String? ?? '',
      landscape: json['landscape'] as String? ?? '',
      tiny: json['tiny'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original': original,
      'large2x': large2x,
      'large': large,
      'medium': medium,
      'small': small,
      'portrait': portrait,
      'landscape': landscape,
      'tiny': tiny,
    };
  }

  String get optimalThumbnail => medium.isNotEmpty
      ? medium
      : (portrait.isNotEmpty
            ? portrait
            : (large.isNotEmpty ? large : original));

  /// Larger thumbnail for dense-but-big tiles (e.g. 2-column grids, cards).
  String get largeThumbnail => large.isNotEmpty ? large : optimalThumbnail;

  /// Full, uncropped image for the photo viewer.
  String get fullView => large2x.isNotEmpty
      ? large2x
      : (large.isNotEmpty
            ? large
            : (original.isNotEmpty ? original : optimalDetail));

  String get optimalDetail => portrait.isNotEmpty
      ? portrait
      : (large2x.isNotEmpty ? large2x : (large.isNotEmpty ? large : original));
}
