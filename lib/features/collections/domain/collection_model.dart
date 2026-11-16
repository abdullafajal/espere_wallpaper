import '../../home/domain/photo_model.dart';

class CollectionModel {
  final String id;
  final String name;
  final String? coverPhotoUrl;
  final List<Photo> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollectionModel({
    required this.id,
    required this.name,
    this.coverPhotoUrl,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  int get photoCount => photos.length;

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List<dynamic>? ?? [];
    return CollectionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      photos: rawPhotos
          .map((e) => Photo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cover_photo_url': coverPhotoUrl,
      'photos': photos.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CollectionModel copyWith({
    String? id,
    String? name,
    String? coverPhotoUrl,
    List<Photo>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
