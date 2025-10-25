import 'package:flutter/material.dart';

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

  Color get _seedColor => switch (this) {
    DemoType.chat => const Color(0xFF365FD9),
    DemoType.tts => Colors.green,
    DemoType.world => Colors.blue,
    DemoType.fifthteenPuzzle => Colors.blue,
    DemoType.othello => Colors.green,
    DemoType.sudoku => Colors.teal,
  };

  ColorScheme get colorScheme => switch (this) {
    _ => ColorScheme.fromSeed(seedColor: _seedColor),
  };

  ColorScheme get colorSchemeDark => switch (this) {
    _ => ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
  };

}
