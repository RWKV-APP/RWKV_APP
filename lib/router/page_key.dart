import 'package:flutter/material.dart';
import 'package:flutter_roleplay/flutter_roleplay.dart' show RoleplayManageModelType;
import 'package:flutter_roleplay/services/role_play_manage.dart' show RoleplayManage;
import 'package:go_router/go_router.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/page/advanced_sesttings.dart' show PageAdvancedSettings;
import 'package:zone/page/font_settings.dart' show PageFontSettings;
import 'package:zone/page/benchmark.dart' show PageBenchmark;
import 'package:zone/page/chat.dart';
import 'package:zone/page/completion/completion_page.dart';
import 'package:zone/page/conversation.dart';
import 'package:zone/page/home.dart';
import 'package:zone/page/lambada.dart';
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
    PageKey.chat => const PageChat(),
    PageKey.neko => const PageChat(),
    PageKey.talk => const PageTalk(),
    PageKey.othello => const PageOthello(),
    PageKey.completion => const CompletionPage(),
    PageKey.sudoku => const PageSudoku(),
    PageKey.home => const PageHome(),
    PageKey.conversation => const PageConversation(),
    PageKey.settings => const PageSettings(),
    PageKey.weightManager => const PageWeightManager(),
    PageKey.translator => const PageTranslator(),
    PageKey.benchmark => const PageBenchmark(),
    PageKey.advancedSettings => const PageAdvancedSettings(),
    PageKey.fontSettings => const PageFontSettings(),
    PageKey.see => const PageSee(),
    PageKey.rolePlaying => RoleplayManage.goRolePlay(
      param['roleName'] ?? '',
      getContext()!,
      onUpdateRolePlaySessionRequired: () => updateRolePlayConversations(),
      onModelDownloadRequired: (type) {
        if (type == RoleplayManageModelType.chat) {
          ModelSelector.show(rolePlayOnly: true);
        } else {
          ModelSelector.show(preferredDemoType: DemoType.tts);
        }
      },
      changeModelCallback: (modelInfo) {
        if (modelInfo?.modelType == RoleplayManageModelType.chat) {
          rolePlayCurrentModel = modelInfo;
          ModelSelector.show(rolePlayOnly: true);
        } else {
          rolePlayTTSModel = modelInfo;
          ModelSelector.show(preferredDemoType: DemoType.tts);
        }
      },
    ),
    PageKey.lambada => const PageLambada(),
    PageKey.ocr => const PageOcr(),
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
    return PageKey.home;
  }

  static List<PageKey> get tabs => [home, conversation, settings];
}
