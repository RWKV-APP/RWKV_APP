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
    .fifthteenPuzzle => const Color(0xFF007AFF), // Apple iOS Blue
    .othello => const Color(0xFF34C759), // Apple iOS Green
    .sudoku => const Color(0xFF5AC8FA), // Apple iOS Cyan
    _ => const Color(0xFF007AFF), // Apple iOS Blue
  };

  ColorScheme get colorScheme => switch (this) {
    _ => ColorScheme.fromSeed(seedColor: _seedColor),
  };

  ColorScheme get colorSchemeDark => switch (this) {
    _ => ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
  };
}
