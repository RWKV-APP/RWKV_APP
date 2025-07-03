import 'package:zone/config.dart';
import 'package:zone/page/chat.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zone/page/othello.dart';
import 'package:zone/page/sudoku.dart';

enum PageKey {
  chat,
  othello,
  sudoku;

  String get path => "/$name";

  Widget get scaffold => switch (this) {
    PageKey.chat => const PageChat(),
    PageKey.othello => const PageOthello(),
    PageKey.sudoku => const PageSudoku(),
  };

  GoRoute get route => GoRoute(path: path, builder: (_, _) => scaffold);

  static String get initialLocation => first.path;

  static PageKey get first => PageKey.values.byName(Config.firstPage);
}
