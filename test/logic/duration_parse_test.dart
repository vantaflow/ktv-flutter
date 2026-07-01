import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/core/logic/duration_parse.dart';

void main() {
  group('parseXtreamDuration', () {
    test('prefers HH:MM:SS over unreliable duration_secs', () {
      // Cas réel : duration_secs="153" (minutes) mais "02:33:00" correct.
      expect(parseXtreamDuration({'duration': '02:33:00', 'duration_secs': '153'}), 2 * 3600 + 33 * 60);
    });
    test('falls back to duration_secs when string absent', () {
      expect(parseXtreamDuration({'duration_secs': 6300}), 6300);
    });
    test('parses H:MM:SS', () {
      expect(parseXtreamDuration({'duration': '1:23:45'}), 1 * 3600 + 23 * 60 + 45);
    });
    test('parses MM:SS', () => expect(parseXtreamDuration({'duration': '45:00'}), 45 * 60));
    test('null for missing', () {
      expect(parseXtreamDuration(null), isNull);
      expect(parseXtreamDuration({}), isNull);
      expect(parseXtreamDuration({'duration': ''}), isNull);
      expect(parseXtreamDuration({'duration': 'unknown'}), isNull);
    });
    test('null for zero/negative secs', () {
      expect(parseXtreamDuration({'duration_secs': 0}), isNull);
      expect(parseXtreamDuration({'duration_secs': -10}), isNull);
    });
  });
}
