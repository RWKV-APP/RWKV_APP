import 'package:flutter/material.dart';

/// 在手机上运行的 App 是哪个类型的
///
///
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
  world
  ;

  Color get _seedColor => switch (this) {
    DemoType.fifthteenPuzzle => Colors.blue,
    DemoType.othello => Colors.green,
    DemoType.sudoku => Colors.teal,
    _ => const Color(0xFF365FD9),
  };

  ColorScheme get colorScheme => switch (this) {
    _ => ColorScheme.fromSeed(seedColor: _seedColor),
  };

  ColorScheme get colorSchemeDark => switch (this) {
    _ => ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
  };
}
