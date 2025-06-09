import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DemoType {
  /// RWKV Chat
  chat,

  /// RWKV_Fiffthteen_Puzzle
  fifthteenPuzzle,

  /// RWKV_Othello
  othello,

  /// RWKV_Sudoku
  sudoku,

  /// RWKV_Talk
  tts,

  /// RWKV_See
  world;

  Color get seedColor => switch (this) {
    DemoType.chat => Colors.deepPurple,
    DemoType.tts => Colors.green,
    DemoType.world => Colors.blue,
    DemoType.fifthteenPuzzle => Colors.blue,
    DemoType.othello => Colors.green,
    DemoType.sudoku => Colors.teal,
  };

  ColorScheme get colorScheme => switch (this) {
    _ => ColorScheme.fromSeed(seedColor: seedColor),
  };

  ColorScheme get colorSchemeDark => switch (this) {
    _ => ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
  };

  List<DeviceOrientation>? get mobileOrientations => switch (this) {
    _ => [DeviceOrientation.portraitUp],
  };

  List<DeviceOrientation>? get desktopOrientations => switch (this) {
    _ => null,
  };
}
