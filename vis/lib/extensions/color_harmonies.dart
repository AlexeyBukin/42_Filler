import 'package:flutter/material.dart';
import 'periodic_shift.dart';

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
