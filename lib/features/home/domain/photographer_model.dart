class Photographer {
  final int id;
  final String name;
  final String url;
  final String avatarUrl;
  final String bio;
  final List<String> samplePhotos;

  const Photographer({
    required this.id,
    required this.name,
    required this.url,
    required this.avatarUrl,
    required this.bio,
    this.samplePhotos = const [],
  });

  static const List<Photographer> popularPhotographers = [
    Photographer(
      id: 101,
      name: 'Eberhard Grossgasteiger',
      url: 'https://www.pexels.com/@eberhardgross',
      avatarUrl:
          'https://images.pexels.com/users/avatars/427976/eberhard-grossgasteiger-450.jpeg?auto=compress&fit=crop&h=256&w=256',
      bio: 'Moody mountains, alpine lakes & dramatic fog landscapes.',
      samplePhotos: [
        'https://images.pexels.com/photos/1287145/pexels-photo-1287145.jpeg?auto=compress&cs=tinysrgb&w=400',
        'https://images.pexels.com/photos/167699/pexels-photo-167699.jpeg?auto=compress&cs=tinysrgb&w=400',
      ],
    ),
    Photographer(
      id: 102,
      name: 'Aleksandar Pasaric',
      url: 'https://www.pexels.com/@aleksandar-pasaric',
      avatarUrl:
          'https://images.pexels.com/users/avatars/1057116/aleksandar-pasaric-310.jpeg?auto=compress&fit=crop&h=256&w=256',
      bio: 'Cyberpunk neon, architecture & night cityscapes.',
      samplePhotos: [
        'https://images.pexels.com/photos/2506923/pexels-photo-2506923.jpeg?auto=compress&cs=tinysrgb&w=400',
        'https://images.pexels.com/photos/1758531/pexels-photo-1758531.jpeg?auto=compress&cs=tinysrgb&w=400',
      ],
    ),
    Photographer(
      id: 103,
      name: 'Tobi',
      url: 'https://www.pexels.com/@lazyartistgallery',
      avatarUrl:
          'https://images.pexels.com/users/avatars/619946/tobi-655.jpeg?auto=compress&fit=crop&h=256&w=256',
      bio: 'Aesthetic street photography & artistic urban geometry.',
      samplePhotos: [
        'https://images.pexels.com/photos/2227832/pexels-photo-2227832.jpeg?auto=compress&cs=tinysrgb&w=400',
      ],
    ),
    Photographer(
      id: 104,
      name: 'Fabian Wiktor',
      url: 'https://www.pexels.com/@fabianwiktor',
      avatarUrl:
          'https://images.pexels.com/users/avatars/338275/fabian-wiktor-486.jpeg?auto=compress&fit=crop&h=256&w=256',
      bio: 'Ocean waves, coastal cliffs & golden light serenity.',
      samplePhotos: [
        'https://images.pexels.com/photos/994605/pexels-photo-994605.jpeg?auto=compress&cs=tinysrgb&w=400',
      ],
    ),
  ];
}
