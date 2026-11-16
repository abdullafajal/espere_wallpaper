import '../domain/photo_model.dart';

class HomeState {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final List<Photo> curatedPhotos;
  final List<Photo> trendingPhotos;
  final String? errorMessage;
  final bool isRateLimited;

  const HomeState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.curatedPhotos = const [],
    this.trendingPhotos = const [],
    this.errorMessage,
    this.isRateLimited = false,
  });

  HomeState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    List<Photo>? curatedPhotos,
    List<Photo>? trendingPhotos,
    String? errorMessage,
    bool clearError = false,
    bool? isRateLimited,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      curatedPhotos: curatedPhotos ?? this.curatedPhotos,
      trendingPhotos: trendingPhotos ?? this.trendingPhotos,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isRateLimited: isRateLimited ?? this.isRateLimited,
    );
  }
}
