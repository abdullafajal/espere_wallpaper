class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.pexels.com/v1';

  static const String curated = '/curated';
  static const String search = '/search';

  static String photoDetail(int id) => '/photos/$id';
}
