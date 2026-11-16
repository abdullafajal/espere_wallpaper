import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../data/search_repository.dart';
import '../domain/search_filter.dart';
import 'search_state.dart';

/// Recent search history (persisted in Hive).
final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
      return RecentSearchesNotifier(ref.watch(storageServiceProvider));
    });

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  final StorageService _storage;

  RecentSearchesNotifier(this._storage) : super(_storage.getSearchHistory());

  Future<void> add(String query) async {
    await _storage.addSearchQuery(query);
    state = _storage.getSearchHistory();
  }

  Future<void> remove(String query) async {
    await _storage.removeSearchQuery(query);
    state = _storage.getSearchHistory();
  }

  Future<void> clear() async {
    await _storage.clearSearchHistory();
    state = const [];
  }
}

/// One results page per initial filter, so stacked result screens (e.g. a
/// category, then a colour) keep independent state.
final searchResultsProvider = StateNotifierProvider.autoDispose
    .family<SearchNotifier, SearchState, SearchFilter>((ref, initial) {
      return SearchNotifier(
        ref.watch(searchRepositoryProvider),
        initial,
        onQuery: (q) => ref.read(recentSearchesProvider.notifier).add(q),
      );
    });

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repository;
  final void Function(String query) _onQuery;

  SearchNotifier(
    this._repository,
    SearchFilter initial, {
    required void Function(String) onQuery,
  }) : _onQuery = onQuery,
       super(SearchState(filter: initial, isLoading: true)) {
    _run(initial, record: false);
  }

  Future<void> search(String query) =>
      applyFilter(state.filter.copyWith(query: query.trim()));

  Future<void> applyFilter(SearchFilter filter) =>
      _run(filter.copyWith(page: 1), record: true);

  Future<void> refresh() => _run(state.filter.copyWith(page: 1), record: false);

  Future<void> _run(SearchFilter filter, {required bool record}) async {
    if (filter.query.isEmpty && filter.color == null) return;
    if (record && filter.query.isNotEmpty) _onQuery(filter.query);

    state = state.copyWith(
      filter: filter,
      isLoading: true,
      photos: const [],
      clearError: true,
    );
    try {
      final results = await _repository.searchPhotos(filter);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        photos: results,
        hasMore: results.length >= 15,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        isRateLimited: e.isRateLimited,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Unable to search right now. Check your connection and try again.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final next = state.filter.copyWith(page: state.filter.page + 1);
    try {
      final more = await _repository.searchPhotos(next);
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        filter: next,
        photos: [...state.photos, ...more],
        hasMore: more.length >= 15,
      );
    } catch (_) {
      if (mounted) state = state.copyWith(isLoadingMore: false);
    }
  }
}
