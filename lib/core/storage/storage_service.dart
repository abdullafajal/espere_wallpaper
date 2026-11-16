import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/collections/domain/collection_model.dart';
import '../../features/home/domain/photo_model.dart';
import 'hive_boxes.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(HiveBoxes.favorites);
    await Hive.openBox(HiveBoxes.collections);
    await Hive.openBox(HiveBoxes.searchHistory);
    await Hive.openBox(HiveBoxes.appSettings);
  }

  Box get _favoritesBox => Hive.box(HiveBoxes.favorites);
  Box get _collectionsBox => Hive.box(HiveBoxes.collections);
  Box get _searchHistoryBox => Hive.box(HiveBoxes.searchHistory);
  Box get _appSettingsBox => Hive.box(HiveBoxes.appSettings);

  // Favorites
  List<Photo> getFavorites() {
    final list = <Photo>[];
    for (final key in _favoritesBox.keys) {
      final data = _favoritesBox.get(key);
      if (data is Map) {
        try {
          list.add(Photo.fromJson(Map<String, dynamic>.from(data)));
        } catch (_) {}
      }
    }
    return list.reversed.toList();
  }

  bool isFavorite(int photoId) {
    return _favoritesBox.containsKey(photoId.toString());
  }

  Future<bool> toggleFavorite(Photo photo) async {
    final key = photo.id.toString();
    if (_favoritesBox.containsKey(key)) {
      await _favoritesBox.delete(key);
      return false;
    } else {
      await _favoritesBox.put(key, photo.toJson());
      return true;
    }
  }

  Future<void> removeFavorite(int photoId) async {
    await _favoritesBox.delete(photoId.toString());
  }

  // Collections
  List<CollectionModel> getCollections() {
    final list = <CollectionModel>[];
    for (final key in _collectionsBox.keys) {
      final data = _collectionsBox.get(key);
      if (data is Map) {
        try {
          list.add(CollectionModel.fromJson(Map<String, dynamic>.from(data)));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<CollectionModel> createCollection(
    String name, {
    Photo? initialPhoto,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final photos = initialPhoto != null ? [initialPhoto] : <Photo>[];
    final collection = CollectionModel(
      id: id,
      name: name.trim(),
      coverPhotoUrl: initialPhoto?.src.optimalThumbnail,
      photos: photos,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _collectionsBox.put(id, collection.toJson());
    return collection;
  }

  Future<void> renameCollection(String id, String newName) async {
    final data = _collectionsBox.get(id);
    if (data is Map) {
      final collection = CollectionModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      final updated = collection.copyWith(
        name: newName.trim(),
        updatedAt: DateTime.now(),
      );
      await _collectionsBox.put(id, updated.toJson());
    }
  }

  Future<void> deleteCollection(String id) async {
    await _collectionsBox.delete(id);
  }

  Future<void> addPhotoToCollection(String collectionId, Photo photo) async {
    final data = _collectionsBox.get(collectionId);
    if (data is Map) {
      final collection = CollectionModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      final exists = collection.photos.any((p) => p.id == photo.id);
      if (!exists) {
        final updatedPhotos = List<Photo>.from(collection.photos)
          ..insert(0, photo);
        final updated = collection.copyWith(
          photos: updatedPhotos,
          coverPhotoUrl: updatedPhotos.isNotEmpty
              ? updatedPhotos.first.src.optimalThumbnail
              : null,
          updatedAt: DateTime.now(),
        );
        await _collectionsBox.put(collectionId, updated.toJson());
      }
    }
  }

  Future<void> removePhotoFromCollection(
    String collectionId,
    int photoId,
  ) async {
    final data = _collectionsBox.get(collectionId);
    if (data is Map) {
      final collection = CollectionModel.fromJson(
        Map<String, dynamic>.from(data),
      );
      final updatedPhotos = collection.photos
          .where((p) => p.id != photoId)
          .toList();
      final updated = collection.copyWith(
        photos: updatedPhotos,
        coverPhotoUrl: updatedPhotos.isNotEmpty
            ? updatedPhotos.first.src.optimalThumbnail
            : null,
        updatedAt: DateTime.now(),
      );
      await _collectionsBox.put(collectionId, updated.toJson());
    }
  }

  // Search History
  List<String> getSearchHistory() {
    final raw = _searchHistoryBox.get('recent_queries');
    if (raw is List) {
      return List<String>.from(raw);
    }
    return [];
  }

  Future<void> addSearchQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final current = getSearchHistory();
    current.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
    current.insert(0, clean);

    // Keep max 20 recent searches
    if (current.length > 20) {
      current.removeRange(20, current.length);
    }
    await _searchHistoryBox.put('recent_queries', current);
  }

  Future<void> removeSearchQuery(String query) async {
    final current = getSearchHistory();
    current.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
    await _searchHistoryBox.put('recent_queries', current);
  }

  Future<void> clearSearchHistory() async {
    await _searchHistoryBox.delete('recent_queries');
  }

  // App Settings (Theme Mode)
  ThemeMode getThemeMode() {
    final modeString = _appSettingsBox.get('theme_mode') as String?;
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _appSettingsBox.put('theme_mode', mode.name);
  }

  // Grid density (columns), changed by pinch-to-zoom on photo grids.
  int? getGridColumns() => _appSettingsBox.get('grid_columns') as int?;

  Future<void> setGridColumns(int columns) async {
    await _appSettingsBox.put('grid_columns', columns);
  }

  // Wallpaper-matched colours (Material You). On by default.
  bool getMatchWallpaper() =>
      _appSettingsBox.get('match_wallpaper', defaultValue: true) as bool;

  Future<void> setMatchWallpaper(bool value) async {
    await _appSettingsBox.put('match_wallpaper', value);
  }
}
