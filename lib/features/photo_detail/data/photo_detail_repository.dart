import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/pexels_client.dart';
import '../../home/domain/photo_model.dart';

final photoDetailRepositoryProvider = Provider<PhotoDetailRepository>((ref) {
  final client = ref.watch(pexelsClientProvider);
  return PhotoDetailRepository(client);
});

class PhotoDetailRepository {
  final PexelsClient _client;

  PhotoDetailRepository(this._client);

  Future<Photo> getPhotoDetails(int id) async {
    final response = await _client.get(ApiEndpoints.photoDetail(id));
    return Photo.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<List<Photo>> getRelatedPhotos(Photo photo, {int perPage = 12}) async {
    // Generate query from photo's alt, or photographer, or category fallback
    String query = 'aesthetic wallpaper';
    if (photo.alt.trim().isNotEmpty) {
      // Extract top keywords from alt text
      final words = photo.alt
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(' ')
          .where((w) => w.length > 3)
          .take(3)
          .join(' ');
      if (words.isNotEmpty) query = words;
    } else if (photo.photographer.isNotEmpty) {
      query = photo.photographer;
    }

    final queryParams = <String, dynamic>{
      'query': query,
      'per_page': perPage,
      'orientation': 'portrait',
    };

    if (photo.avgColor != null) {
      // Could also include general query
    }

    try {
      final response = await _client.get(
        ApiEndpoints.search,
        queryParameters: queryParams,
      );

      final rawPhotos = response.data['photos'] as List<dynamic>? ?? [];
      return rawPhotos
          .map((p) => Photo.fromJson(Map<String, dynamic>.from(p as Map)))
          .where((p) => p.id != photo.id)
          .toList();
    } catch (_) {
      // Fallback to curated if query has no results
      final curated = await _client.get(
        ApiEndpoints.curated,
        queryParameters: {'per_page': perPage},
      );
      final raw = curated.data['photos'] as List<dynamic>? ?? [];
      return raw
          .map((p) => Photo.fromJson(Map<String, dynamic>.from(p as Map)))
          .where((p) => p.id != photo.id)
          .toList();
    }
  }

  Future<List<Photo>> getPhotographerPhotos(
    String photographer, {
    int perPage = 8,
  }) async {
    final response = await _client.get(
      ApiEndpoints.search,
      queryParameters: {'query': photographer, 'per_page': perPage},
    );

    final rawPhotos = response.data['photos'] as List<dynamic>? ?? [];
    return rawPhotos
        .map((p) => Photo.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
  }
}
