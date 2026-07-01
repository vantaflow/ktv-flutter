import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/core/logic/tmdb_match.dart';

void main() {
  group('ktvPickResult', () {
    test('exact title scores highest', () {
      final results = <Map<String, dynamic>>[
        {'title': 'Fight Club', 'popularity': 50, 'poster_path': '/x.jpg', 'overview': 'desc'},
        {'title': 'Fight Club 2', 'popularity': 10},
      ];
      expect(ktvPickResult(results, 'Fight Club')?['title'], 'Fight Club');
    });

    test('year bonus breaks ties toward right release', () {
      final results = <Map<String, dynamic>>[
        {'title': 'Dune', 'release_date': '1984-01-01'},
        {'title': 'Dune', 'release_date': '2021-01-01'},
      ];
      expect(ktvPickResult(results, 'Dune', 2021)?['release_date'], '2021-01-01');
    });

    test('rejects below threshold (score < 60)', () {
      expect(ktvPickResult([{'title': 'Completely Unrelated Movie'}], 'My Query Title'), isNull);
    });

    test('empty results', () => expect(ktvPickResult([], 'Inception'), isNull));
    test('empty query', () => expect(ktvPickResult([{'title': 'Inception'}], ''), isNull));
  });
}
