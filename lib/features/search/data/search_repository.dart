import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/pexels_client.dart';
import '../../home/domain/photo_model.dart';
import '../domain/search_filter.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final client = ref.watch(pexelsClientProvider);
  return SearchRepository(client);
});

class SearchRepository {
  final PexelsClient _client;

  SearchRepository(this._client);

  Future<List<Photo>> searchPhotos(SearchFilter filter) async {
    final response = await _client.get(
      ApiEndpoints.search,
      queryParameters: filter.toQueryParams(),
    );

    final rawPhotos = response.data['photos'] as List<dynamic>? ?? [];
    return rawPhotos
        .map((p) => Photo.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }
}
