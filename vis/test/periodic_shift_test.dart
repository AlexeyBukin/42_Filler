
// ``` flutter test test/periodic_shift_test.dart ```

import 'package:filler/extensions/periodic_shift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  final epsilon = 0.000001;

  group('insidePeriodWithLength', () {

    test('if value is inside the period it must stay the same', () {
      expect(1.0.insidePeriodWithLength(5), 1);
    });

    test('if value is on the edge it should be minimal', () {
      expect(5.0.insidePeriodWithLength(1), 0);
    });

    test('this is common situation with integers', () {
      expect(8.0.insidePeriodWithLength(3), 2);
    });

    test('this is common situation with value as double', () {
      expect(8.3.insidePeriodWithLength(3), closeTo(2.3, epsilon));
    });

    test('this is common situation with value as double', () {
      expect(7.0.insidePeriodWithLength(2.5), closeTo(2, epsilon));
    });

    test('this is common situation with both as double', () {
      expect(7.3.insidePeriodWithLength(2.5), closeTo(2.3, epsilon));
    });

  });

  group('insidePeriod', () {

    test('if value is inside the period it must stay the same', () {
      expect(1.0.insidePeriod(from: 0, to: 5), 1);
    });

    test('if value is on the edge it should be minimal', () {
      expect(8.0.insidePeriod(from: 1, to: 2), closeTo(1, epsilon));
    });

    test('this is common situation', () {
      expect(1.3.insidePeriod(from: 0, to: 1), closeTo(0.3, epsilon));
    });

  });
}
