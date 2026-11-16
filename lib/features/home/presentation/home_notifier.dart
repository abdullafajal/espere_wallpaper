import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../data/home_repository.dart';
import 'home_state.dart';

final homeNotifierProvider = StateNotifierProvider<HomeNotifier, HomeState>((
  ref,
) {
  final repository = ref.watch(homeRepositoryProvider);
  return HomeNotifier(repository);
});

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;

  HomeNotifier(this._repository) : super(const HomeState(isLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repository.getCuratedPhotos(page: 1, perPage: 20),
        _repository.getTrendingPhotos(perPage: 6),
      ]);

      final curated = results[0];
      final trending = results[1];

      state = state.copyWith(
        isLoading: false,
        page: 1,
        curatedPhotos: curated,
        trendingPhotos: trending,
        hasMore: curated.isNotEmpty,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        isRateLimited: e.isRateLimited,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Failed to load photography. Please check your connection.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final newPhotos = await _repository.getCuratedPhotos(
        page: nextPage,
        perPage: 20,
      );

      state = state.copyWith(
        isLoadingMore: false,
        page: nextPage,
        curatedPhotos: [...state.curatedPhotos, ...newPhotos],
        hasMore: newPhotos.isNotEmpty && newPhotos.length >= 15,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}
