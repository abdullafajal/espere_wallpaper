import '../features/home/domain/photo_model.dart';

/// Extra passed to `/photo/:id` so the viewer can start with the already
/// loaded photo and run a hero animation from the exact tile that was tapped.
class PhotoRouteArgs {
  final Photo photo;
  final String? heroTag;

  const PhotoRouteArgs(this.photo, {this.heroTag});
}

String photoHeroTag(String scope, int photoId) => 'photo_${scope}_$photoId';
