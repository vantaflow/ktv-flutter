import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/core/logic/format.dart';

void main() {
  group('fmtRemaining', () {
    test('zero', () => expect(fmtRemaining(0), '⏳ 0 min'));
    test('sub-hour', () => expect(fmtRemaining(12 * 60), '⏳ 12 min'));
    test('hour+ padded', () => expect(fmtRemaining(3600 + 5 * 60), '⏳ 1 h 05'));
    test('negative clamped', () => expect(fmtRemaining(-30), '⏳ 0 min'));
  });

  group('fmtClock', () {
    test('sub-hour mm:ss', () => expect(fmtClock(12 * 60 + 5), '12:05'));
    test('hour+ h:mm:ss', () => expect(fmtClock(3600 + 5 * 60 + 9), '1:05:09'));
    test('zero', () => expect(fmtClock(0), '00:00'));
  });
}
