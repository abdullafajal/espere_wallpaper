class SearchFilter {
  final String query;
  final String? color;
  final String orientation;
  final String size;
  final int page;
  final int perPage;

  const SearchFilter({
    this.query = '',
    this.color,
    this.orientation = 'all',
    this.size = 'all',
    this.page = 1,
    this.perPage = 20,
  });

  bool get hasActiveFilters =>
      (color != null && color!.isNotEmpty) ||
      orientation != 'all' ||
      size != 'all';

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};

    // If query is empty but color is set, search using the color as query keyword
    final effectiveQuery = query.trim().isNotEmpty
        ? query.trim()
        : (color != null && color!.isNotEmpty ? color! : 'wallpaper');

    params['query'] = effectiveQuery;

    if (color != null && color!.isNotEmpty) {
      params['color'] = color;
    }

    if (orientation != 'all') {
      params['orientation'] = orientation;
    }

    if (size != 'all') {
      params['size'] = size;
    }

    return params;
  }

  SearchFilter copyWith({
    String? query,
    String? color,
    bool clearColor = false,
    String? orientation,
    String? size,
    int? page,
    int? perPage,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      color: clearColor ? null : (color ?? this.color),
      orientation: orientation ?? this.orientation,
      size: size ?? this.size,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SearchFilter &&
      other.query == query &&
      other.color == color &&
      other.orientation == orientation &&
      other.size == size &&
      other.page == page &&
      other.perPage == perPage;

  @override
  int get hashCode =>
      Object.hash(query, color, orientation, size, page, perPage);
}
