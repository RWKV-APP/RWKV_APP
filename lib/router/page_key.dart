import 'package:flutter/material.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart' show RoleplayManage;
import 'package:go_router/go_router.dart';
import 'package:zone/page/advanced_sesttings.dart' show PageAdvancedSettings;
import 'package:zone/page/benchmark.dart' show PageBenchmark;
import 'package:zone/page/chat.dart';
import 'package:zone/page/completion.dart';
import 'package:zone/page/conversation.dart';
import 'package:zone/page/home.dart';
import 'package:zone/page/othello.dart';
import 'package:zone/page/settings.dart';
import 'package:zone/page/sudoku.dart';
import 'package:zone/page/talk.dart';
import 'package:zone/page/translator.dart';
import 'package:zone/router/router.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/page/lambada.dart';
import 'package:zone/widgets/role_play_item.dart';

enum PageKey {
  translator,
  chat,
  completion,
  conversation,
  settings,
  advancedSettings,
  benchmark,
  othello,
  sudoku,
  rolePlaying,
  home,
  talk,
  neko,
  lambada;

  String get path => "/$name";

  bool get hasTransition => {chat, completion, advancedSettings, rolePlaying}.contains(this);

  Widget scaffold(Map<String, String> param) => switch (this) {
    PageKey.chat => const PageChat(),
    PageKey.neko => const PageChat(),
    PageKey.talk => const PageTalk(),
    PageKey.othello => const PageOthello(),
    PageKey.completion => const CompletionPage(),
    PageKey.sudoku => const PageSudoku(),
    PageKey.home => const PageHome(),
    PageKey.conversation => const PageConversation(),
    PageKey.settings => const PageSettings(),
    PageKey.translator => const PageTranslator(),
    PageKey.benchmark => const PageBenchmark(),
    PageKey.advancedSettings => const PageAdvancedSettings(),
    PageKey.rolePlaying => RoleplayManage.goRolePlay(
      param['roleName'] ?? '',
      getContext()!,
      onUpdateRolePlaySessionRequired: () => updateRolePlayConversations(),
      onModelDownloadRequired: () => ModelSelector.show(rolePlayOnly: true),
      changeModelCallback: (modelInfo) {
        rolePlayCurrentModel = modelInfo;
        ModelSelector.show(rolePlayOnly: true);
      },
    ),
    PageKey.lambada => const PageLambada(),
  };

  GoRoute get route {
    if (PageKey.tabs.contains(this)) {
      return GoRoute(
        path: path,
        pageBuilder: (context, state) => NoTransitionPage(child: scaffold({})),
      );
    }
    return GoRoute(
      path: path,
      builder: (context, state) {
        return scaffold(state.extra as Map<String, String>? ?? {});
      },
    );
  }

  static String get initialLocation => first.path;

  static PageKey get first => PageKey.home;

  static List<PageKey> get tabs => [home, conversation, settings];
}
