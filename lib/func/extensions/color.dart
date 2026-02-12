import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/store/p.dart';

extension RWKVColorExtension on Color {
  Color l(double toLight) {
    final __r = max(r + (255 - r) * toLight, 255);
    final __g = max(g + (255 - g) * toLight, 255);
    final __b = max(b + (255 - b) * toLight, 255);
    return Color.fromARGB(a.toInt(), __r.toInt(), __g.toInt(), __b.toInt());
  }

  Color d(double toDark) {
    final __r = r * (1 - toDark);
    final __g = g * (1 - toDark);
    final __b = b * (1 - toDark);
    return Color.fromARGB(a.toInt(), __r.toInt(), __g.toInt(), __b.toInt());
  }

  Color darkerWhenLight(double v) {
    final isLight = P.app.theme.q == .light;
    return isLight ? d(v) : l(v);
  }

  Color lighterWhenDark(double v) {
    final isLight = P.app.theme.q == .light;
    return isLight ? l(v) : d(v);
  }

  Color toGray(double v) {
    int r = (this.r * 255.0).round().clamp(0, 255);
    int g = (this.g * 255.0).round().clamp(0, 255);
    int b = (this.b * 255.0).round().clamp(0, 255);
    int a = (this.a * 255.0).round().clamp(0, 255);
    final __r = (r > 127 ? (r - (r - 127) * v) : r + (127 - r) * v);
    final __g = (g > 127 ? (g - (g - 127) * v) : g + (127 - g) * v);
    final __b = (b > 127 ? (b - (b - 127) * v) : b + (127 - b) * v);
    qqr("\na: $a,\nr: $r,\ng: $g,\nb: $b,\n__r: $__r, \n__g: $__g, \n__b: $__b");
    return Color.fromARGB(a.toInt(), __r.toInt(), __g.toInt(), __b.toInt());
  }
}
