import 'package:zone/page/chat.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zone/page/conversation.dart';
import 'package:zone/page/home.dart';
import 'package:zone/page/othello.dart';
import 'package:zone/page/settings.dart';
import 'package:zone/page/sudoku.dart';

enum PageKey {
  chat,
  conversation,
  settings,
  othello,
  sudoku,
  home;

  String get path => "/$name";

  Widget get scaffold => switch (this) {
    PageKey.chat => const PageChat(),
    PageKey.othello => const PageOthello(),
    PageKey.sudoku => const PageSudoku(),
    PageKey.home => const PageHome(),
    PageKey.conversation => const PageConversation(),
    PageKey.settings => const PageSettings(),
  };

  GoRoute get route => GoRoute(
    path: path,
    pageBuilder: (context, state) => NoTransitionPage<void>(
      key: state.pageKey,
      child: scaffold,
    ),
  );

  static String get initialLocation => first.path;

  static PageKey get first => PageKey.home;
}
