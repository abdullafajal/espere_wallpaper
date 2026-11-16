import '../../home/domain/photo_model.dart';
import '../domain/search_filter.dart';

class SearchState {
  final SearchFilter filter;
  final List<Photo> photos;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final bool isRateLimited;

  const SearchState({
    this.filter = const SearchFilter(),
    this.photos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.isRateLimited = false,
  });

  SearchState copyWith({
    SearchFilter? filter,
    List<Photo>? photos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
    bool? isRateLimited,
  }) {
    return SearchState(
      filter: filter ?? this.filter,
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRateLimited: isRateLimited ?? this.isRateLimited,
    );
  }
}
