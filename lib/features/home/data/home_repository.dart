import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/pexels_client.dart';
import '../domain/photo_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final client = ref.watch(pexelsClientProvider);
  return HomeRepository(client);
});

class HomeRepository {
  final PexelsClient _client;

  HomeRepository(this._client);

  Future<List<Photo>> getCuratedPhotos({int page = 1, int perPage = 20}) async {
    final response = await _client.get(
      ApiEndpoints.curated,
      queryParameters: {'page': page, 'per_page': perPage},
    );

    final rawPhotos = response.data['photos'] as List<dynamic>? ?? [];
    return rawPhotos
        .map((p) => Photo.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }

  Future<List<Photo>> getTrendingPhotos({int perPage = 6}) async {
    final response = await _client.get(
      ApiEndpoints.search,
      queryParameters: {
        'query': 'masterpiece wallpaper 4k',
        'orientation': 'portrait',
        'per_page': perPage,
      },
    );

    final rawPhotos = response.data['photos'] as List<dynamic>? ?? [];
    return rawPhotos
        .map((p) => Photo.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }
}
