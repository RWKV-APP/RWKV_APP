import 'package:zone/page/chat.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zone/page/completion.dart';
import 'package:zone/page/conversation.dart';
import 'package:zone/page/home.dart';
import 'package:zone/page/othello.dart';
import 'package:zone/page/settings.dart';
import 'package:zone/page/sudoku.dart';
import 'package:zone/page/translator.dart';

enum PageKey {
  translator,
  chat,
  completion,
  conversation,
  settings,
  othello,
  sudoku,
  home;

  String get path => "/$name";

  Widget get scaffold => switch (this) {
    PageKey.chat => const PageChat(),
    PageKey.othello => const PageOthello(),
    PageKey.completion => const CompletionPage(),
    PageKey.sudoku => const PageSudoku(),
    PageKey.home => const PageHome(),
    PageKey.conversation => const PageConversation(),
    PageKey.settings => const PageSettings(),
    PageKey.translator => const PageTranslator(),
  };

  //

  GoRoute get route => switch (this) {
    PageKey.translator => GoRoute(
      path: path,
      builder: (context, state) => scaffold,
    ),
    _ => GoRoute(
      path: path,
      pageBuilder: (context, state) => _page(state),
    ),
  };

  Page _page(GoRouterState state) {
    if (!{chat, completion}.contains(this)) {
      return NoTransitionPage<void>(
        key: state.pageKey,
        child: scaffold,
      );
    }
    final page = this == chat ? PageChat(param: state.extra) : scaffold;
    return CustomTransitionPage(
      key: state.pageKey,
      child: page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  static String get initialLocation => first.path;

  static PageKey get first => PageKey.sudoku;
}
