
/// Helps with periodic values.
///
/// Mostly used with [HSVColor] where hue is such a value.
///
extension PeriodicShiftExtension on double {
  /// Works like [num.clamp] but for periodic values (no offset)
  double insidePeriodWithLength(double periodLength) {
    if (periodLength == 0) {
      throw IntegerDivisionByZeroException();
    }
    final periodsNumber = this ~/ periodLength;
    final periodsDiff = periodsNumber * periodLength;
    return this - periodsDiff;
  }

  // Imagine array or repetitive periods of numbers
  // Like 1..3, 3..5, 5..7 and so on with 1..3 being 'core' period
  // This function maps double to it's position in the 'core' period
  // For example, 6.3 becomes 2.3 with period from 1 to 3

  /// Works like [num.clamp] but for periodic values (with offset)
  double insidePeriod({double from = 0, double to = 1}) {
    if (from >= to) {
      throw IntegerDivisionByZeroException();
    }
    final offset = from;
    final periodLength = to - offset;
    final thisShifted = this - offset;
    final thisShiftedInsidePeriod =
    thisShifted.insidePeriodWithLength(periodLength);
    return thisShiftedInsidePeriod + offset;
  }
}