import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/core/logic/recommendations_match.dart';

void main() {
  group('matchRecommendationsToCatalog', () {
    test('matches by tmdb id', () {
      final trakt = [
        {'title': 'Fight Club', 'year': 1999, 'ids': {'tmdb': 550}}
      ];
      final catalog = [
        {'name': 'Some Weird Name', '_tmdbId': 550}
      ];
      expect(matchRecommendationsToCatalog(trakt, catalog), catalog);
    });

    test('title+year fallback', () {
      final trakt = [
        {'title': 'Inception', 'year': 2010, 'ids': {}}
      ];
      final catalog = [
        {'name': '4K-FR - Inception (2010) [MULTI] [1080p]'}
      ];
      expect(matchRecommendationsToCatalog(trakt, catalog), catalog);
    });

    test('drops no-match', () {
      final trakt = [
        {'title': 'Not In Catalog', 'year': 2020, 'ids': {}}
      ];
      final catalog = [
        {'name': 'Something Else (2020)'}
      ];
      expect(matchRecommendationsToCatalog(trakt, catalog), isEmpty);
    });

    test('empty catalog', () {
      expect(matchRecommendationsToCatalog([{'title': 'Inception', 'year': 2010, 'ids': {}}], []), isEmpty);
    });

    test('empty trakt list', () {
      expect(matchRecommendationsToCatalog([], [{'name': 'Inception (2010)'}]), isEmpty);
    });

    test('dedupes item matched twice', () {
      final trakt = [
        {'title': 'Inception', 'year': 2010, 'ids': {'tmdb': 27205}},
        {'title': 'Inception', 'year': 2010, 'ids': {}},
      ];
      final catalog = [
        {'name': 'Inception (2010)', '_tmdbId': 27205}
      ];
      expect(matchRecommendationsToCatalog(trakt, catalog), catalog);
    });

    test('preserves Trakt order', () {
      final trakt = [
        {'title': 'Second', 'year': 2002, 'ids': {}},
        {'title': 'First', 'year': 2001, 'ids': {}},
      ];
      final catalog = [
        {'name': 'First (2001)'},
        {'name': 'Second (2002)'},
      ];
      final result = matchRecommendationsToCatalog(trakt, catalog);
      expect(result.map((r) => r['name']).toList(), ['Second (2002)', 'First (2001)']);
    });

    test('supports {movie:{...}} wrapped shape', () {
      final trakt = [
        {'movie': {'title': 'Inception', 'year': 2010, 'ids': {}}}
      ];
      final catalog = [
        {'name': 'Inception (2010)'}
      ];
      expect(matchRecommendationsToCatalog(trakt, catalog), catalog);
    });
  });
}
