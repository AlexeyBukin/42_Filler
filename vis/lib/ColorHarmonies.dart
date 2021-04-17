import 'package:flutter/material.dart';

extension PeriodicShift on double {
  double insidePeriodWithLength(double periodLength) {
    if (periodLength == 0) {
      throw IntegerDivisionByZeroException();
    }
    final periodsNumber = this ~/ periodLength;
    final periodsDiff = periodsNumber * periodLength;
    return this - periodsDiff;
  }

  // For example we have periodic ranges 1..4, 5..8, 9..12 and so on
  // Let's call 1..4 the chosen one, we want to get result in it
  // Take number 11, its third in range 9..12 so it IS THIRD.
  // Now lets get THIRD number in range 1...4 and the result is 3
  // God bless this code
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

extension ColorHarmonies on Color {

  Color withHueShifted(double shift) {
    shift *= 360;
    var color = HSVColor.fromColor(this);
    var hue = (color.hue + shift).insidePeriod(from: 0, to: 360);
    print("old hue: ${color.hue}, new: $hue");
    return color.withHue(hue).toColor();
  }

  Color complementary() {
    return this.withHueShifted(0.5);
  }

  List<Color> analogous({double offset = 1/12}) {
    var list = List<Color>.filled(3, this);
    list[0] = this.withHueShifted(offset);
    list[2] = this.withHueShifted(-1 * offset);
    return list;
  }

  List<Color> triadic({double offset = 1/12}) {
    return this.analogous(offset: 1/3);
  }

  List<Color> square({double offset = 1/12}) {
    return this.analogous(offset: 1/4)..add(this.complementary());
  }

  List<Color> splitComplementary({double offset = 1/12}) {
    final complementary = this.complementary();
    var list = complementary.analogous(offset: offset);
    list[1] = this;
    return list;
  }
}
