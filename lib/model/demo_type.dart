// Flutter imports:
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

  tts,

  see
  ;

  Color get _seedColor => switch (this) {
    .fifthteenPuzzle => Colors.blue,
    .othello => Colors.green,
    .sudoku => Colors.teal,
    _ => const Color(0xFF365FD9),
  };

  ColorScheme get colorScheme => switch (this) {
    _ => ColorScheme.fromSeed(seedColor: _seedColor),
  };

  ColorScheme get colorSchemeDark => switch (this) {
    _ => ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
  };
}
