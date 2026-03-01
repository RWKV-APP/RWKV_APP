// Flutter imports:
import 'package:flutter/material.dart';

Color averageColors(Color c1, Color c2) {
  int r = ((c1.r * 255.0).round() & 0xff + (c2.r * 255.0).round() & 0xff) ~/ 2;
  int g = ((c1.g * 255.0).round() & 0xff + (c2.g * 255.0).round() & 0xff) ~/ 2;
  int b = ((c1.b * 255.0).round() & 0xff + (c2.b * 255.0).round() & 0xff) ~/ 2;
  int a = ((c1.a * 255.0).round() & 0xff + (c2.a * 255.0).round() & 0xff) ~/ 2;

  return Color.fromARGB(a, r, g, b);
}

extension ColorAverage on Color {
  Color average(Color other) {
    return averageColors(this, other);
  }
}
