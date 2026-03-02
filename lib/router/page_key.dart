// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_roleplay/flutter_roleplay.dart' show RoleplayManageModelType;
import 'package:flutter_roleplay/services/role_play_manage.dart' show RoleplayManage;
import 'package:go_router/go_router.dart';

// Project imports:
import 'package:zone/page/advanced_sesttings.dart' show PageAdvancedSettings;
import 'package:zone/page/benchmark.dart' show PageBenchmark;
import 'package:zone/page/bot_message_bottom_preview.dart';
import 'package:zone/page/chat.dart';
import 'package:zone/page/completion/completion_page.dart';
import 'package:zone/page/conversation.dart';
import 'package:zone/page/font_settings.dart' show PageFontSettings;
import 'package:zone/page/home.dart';
import 'package:zone/page/interactions_preview.dart';
import 'package:zone/page/ocr.dart';
import 'package:zone/page/othello.dart';
import 'package:zone/page/see.dart';
import 'package:zone/page/settings.dart';
import 'package:zone/page/sudoku.dart';
import 'package:zone/page/talk.dart';
import 'package:zone/page/translator.dart';
import 'package:zone/page/weight_manager.dart';
import 'package:zone/router/router.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/widgets/role_play_item.dart';
import 'package:zone/widgets/tts_group_item.dart';

enum PageKey {
  translator,
  chat,
  completion,
  conversation,
  settings,
  advancedSettings,
  fontSettings,
  benchmark,
  interactionsPreview,
  botMessageBottomPreview,
  othello,
  sudoku,
  rolePlaying,
  home,
  talk,
  neko,
  lambada,
  see,
  ocr,
  weightManager,
  ;

  String get path => "/$name";

  bool get hasTransition => {chat, completion, advancedSettings, fontSettings, rolePlaying}.contains(this);

  Widget scaffold(Map<String, String> param) => switch (this) {
    chat => const PageChat(),
    neko => const PageChat(),
    talk => const PageTalk(),
    othello => const PageOthello(),
    completion => const CompletionPage(),
    sudoku => const PageSudoku(),
    home => const PageHome(),
    conversation => const PageConversation(),
    settings => const PageSettings(),
    weightManager => const PageWeightManager(),
    translator => const PageTranslator(),
    benchmark => const PageBenchmark(),
    interactionsPreview => const PageInteractionsPreview(),
    botMessageBottomPreview => const PageBotMessageBottomPreview(),
    lambada => const PageBenchmark(),
    advancedSettings => const PageAdvancedSettings(),
    fontSettings => const PageFontSettings(),
    see => const PageSee(),
    rolePlaying => RoleplayManage.goRolePlay(
      param['roleName'] ?? '',
      getContext()!,
      onUpdateRolePlaySessionRequired: () => updateRolePlayConversations(),
      onModelDownloadRequired: (type) {
        if (type == RoleplayManageModelType.chat) {
          ModelSelector.show(rolePlayOnly: true);
        } else {
          ModelSelector.show(preferredDemoType: .tts);
        }
      },
      changeModelCallback: (modelInfo) {
        if (modelInfo?.modelType == RoleplayManageModelType.chat) {
          rolePlayCurrentModel = modelInfo;
          ModelSelector.show(rolePlayOnly: true);
        } else {
          rolePlayTTSModel = modelInfo;
          ModelSelector.show(preferredDemoType: .tts);
        }
      },
    ),
    ocr => const PageOcr(),
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

  static PageKey get first {
    return .home;
  }

  static List<PageKey> get tabs => [home, conversation, settings];
}
