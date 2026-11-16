import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Opens a search-results page. [title] replaces the search field with a
/// plain heading (used for categories and photographers).
void openSearchResults(
  BuildContext context, {
  String? query,
  String? color,
  String? title,
}) {
  final q = query?.trim();
  final params = <String, String>{
    if (q != null && q.isNotEmpty) 'q': q,
    'color': ?color,
    'title': ?title,
  };
  if (params['q'] == null && params['color'] == null) return;
  context.push(Uri(path: '/results', queryParameters: params).toString());
}
