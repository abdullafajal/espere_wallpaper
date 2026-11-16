import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/storage_service.dart';
import '../../collections/domain/collection_model.dart';
import '../../home/domain/photo_model.dart';

final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, List<Photo>>((ref) {
      final storage = ref.watch(storageServiceProvider);
      return FavoritesNotifier(storage);
    });

class FavoritesNotifier extends StateNotifier<List<Photo>> {
  final StorageService _storage;

  FavoritesNotifier(this._storage) : super([]) {
    loadFavorites();
  }

  void loadFavorites() {
    state = _storage.getFavorites();
  }

  Future<bool> toggle(Photo photo) async {
    final isAdded = await _storage.toggleFavorite(photo);
    loadFavorites();
    return isAdded;
  }

  Future<void> remove(int photoId) async {
    await _storage.removeFavorite(photoId);
    loadFavorites();
  }
}

final isFavoriteProvider = Provider.family<bool, int>((ref, photoId) {
  final favorites = ref.watch(favoritesNotifierProvider);
  return favorites.any((p) => p.id == photoId);
});

final collectionsNotifierProvider =
    StateNotifierProvider<CollectionsNotifier, List<CollectionModel>>((ref) {
      final storage = ref.watch(storageServiceProvider);
      return CollectionsNotifier(storage);
    });

class CollectionsNotifier extends StateNotifier<List<CollectionModel>> {
  final StorageService _storage;

  CollectionsNotifier(this._storage) : super([]) {
    loadCollections();
  }

  void loadCollections() {
    state = _storage.getCollections();
  }

  Future<CollectionModel> createCollection(
    String name, {
    Photo? initialPhoto,
  }) async {
    final collection = await _storage.createCollection(
      name,
      initialPhoto: initialPhoto,
    );
    loadCollections();
    return collection;
  }

  Future<void> renameCollection(String id, String newName) async {
    await _storage.renameCollection(id, newName);
    loadCollections();
  }

  Future<void> deleteCollection(String id) async {
    await _storage.deleteCollection(id);
    loadCollections();
  }

  Future<void> addPhotoToCollection(String collectionId, Photo photo) async {
    await _storage.addPhotoToCollection(collectionId, photo);
    loadCollections();
  }

  Future<void> removePhotoFromCollection(
    String collectionId,
    int photoId,
  ) async {
    await _storage.removePhotoFromCollection(collectionId, photoId);
    loadCollections();
  }
}
