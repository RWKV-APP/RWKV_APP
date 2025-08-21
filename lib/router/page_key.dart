import 'package:zone/page/advanced_sesttings.dart' show PageAdvancedSettings;
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
  advancedSettings,
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
    PageKey.advancedSettings => const PageAdvancedSettings(),
  };

  GoRoute get route {
    if (PageKey.tabs.contains(this)) {
      return GoRoute(
        path: path,
        pageBuilder: (context, state) => NoTransitionPage(child: scaffold),
      );
    }
    return GoRoute(path: path, builder: (context, state) => scaffold);
  }

  static String get initialLocation => first.path;

  static PageKey get first => PageKey.home;

  static List<PageKey> get tabs => [home, conversation, settings];
}
