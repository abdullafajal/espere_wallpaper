class AppConstants {
  AppConstants._();

  static const String appName = 'Espere Wallpaper';
  static const String appTagline = 'Discover & Curate Exceptional Photography';

  // Categories required by prompt:
  // Nature, Architecture, Technology, Travel, Animals, Cars, Food, People, Fashion, Abstract, Space, Minimalism, Wallpapers
  static const List<CategoryItem> categories = [
    CategoryItem(
      id: 'nature',
      name: 'Nature',
      query: 'Nature landscape',
      imageUrl:
          'https://images.pexels.com/photos/15286/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'architecture',
      name: 'Architecture',
      query: 'Architecture modern building',
      imageUrl:
          'https://images.pexels.com/photos/2227832/pexels-photo-2227832.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'technology',
      name: 'Technology',
      query: 'Technology futuristic',
      imageUrl:
          'https://images.pexels.com/photos/373543/pexels-photo-373543.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'travel',
      name: 'Travel',
      query: 'Travel adventure destination',
      imageUrl:
          'https://images.pexels.com/photos/1271619/pexels-photo-1271619.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'animals',
      name: 'Animals',
      query: 'Wildlife animals portrait',
      imageUrl:
          'https://images.pexels.com/photos/247502/pexels-photo-247502.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'cars',
      name: 'Cars',
      query: 'Supercar automotive luxury',
      imageUrl:
          'https://images.pexels.com/photos/3802510/pexels-photo-3802510.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'food',
      name: 'Food',
      query: 'Gourmet culinary food styling',
      imageUrl:
          'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'people',
      name: 'People',
      query: 'People portrait emotion aesthetic',
      imageUrl:
          'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'fashion',
      name: 'Fashion',
      query: 'High fashion editorial style',
      imageUrl:
          'https://images.pexels.com/photos/1926769/pexels-photo-1926769.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'abstract',
      name: 'Abstract',
      query: 'Abstract texture fluid gradient',
      imageUrl:
          'https://images.pexels.com/photos/2110951/pexels-photo-2110951.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'space',
      name: 'Space',
      query: 'Cosmos space galaxy astronomy',
      imageUrl:
          'https://images.pexels.com/photos/2150/sky-space-dark-galaxy.jpg?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'minimalism',
      name: 'Minimalism',
      query: 'Minimalist clean aesthetic empty space',
      imageUrl:
          'https://images.pexels.com/photos/247791/pexels-photo-247791.png?auto=compress&cs=tinysrgb&w=600',
    ),
    CategoryItem(
      id: 'wallpapers',
      name: 'Wallpapers',
      query: 'Phone wallpaper 4k vertical aesthetic',
      imageUrl:
          'https://images.pexels.com/photos/167699/pexels-photo-167699.jpeg?auto=compress&cs=tinysrgb&w=600',
    ),
  ];

  static const List<String> popularSearches = [
    'Aesthetic dark',
    'Cyberpunk neon',
    'Moody foggy forest',
    'Minimalist architecture',
    'Retro vintage car',
    'Dramatic mountain sunset',
    'Tokyo rainy night',
    'Cosmic aurora',
    'Macro raindrops',
    'Desert sand dunes',
  ];

  static const List<String> orientations = [
    'all',
    'landscape',
    'portrait',
    'square',
  ];

  static const List<String> imageSizes = ['all', 'large', 'medium', 'small'];

  static const int perPageDefault = 20;
}

class CategoryItem {
  final String id;
  final String name;
  final String query;
  final String imageUrl;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.query,
    required this.imageUrl,
  });
}
