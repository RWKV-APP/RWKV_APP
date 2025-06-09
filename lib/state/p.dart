import 'dart:async';
import 'dart:convert';
// ignore: unused_import
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gaimon/gaimon.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart' as ar;
import 'package:rwkv_mobile_flutter/from_rwkv.dart' as from_rwkv;
import 'package:rwkv_mobile_flutter/to_rwkv.dart' as to_rwkv;
import 'package:zone/model/custom_theme.dart' as custom_theme;
import 'package:rwkv_mobile_flutter/rwkv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_info2/system_info2.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zone/args.dart';
import 'package:zone/config.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/func/from_assets_to_temp.dart';
import 'package:zone/gen/assets.gen.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/io.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/model/cell_type.dart';
import 'package:zone/model/cot_display_state.dart';
import 'package:zone/model/conversation.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/group_info.dart';
import 'package:zone/model/language.dart';
import 'package:zone/model/local_file.dart';
import 'package:zone/model/message.dart';
import 'package:zone/model/msg_node.dart';
import 'package:zone/model/thinking_mode.dart';
import 'package:zone/model/tts_instruction.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/page/panel/theme_selector.dart';
import 'package:zone/route/page_key.dart';
import 'package:zone/route/router.dart';
import 'package:zone/widgets/app_update_dialog.dart' show AppUpdateDialog;
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/widgets/pager.dart';
import 'package:zone/model/thinking_mode.dart' as thinking_mode;
import 'package:zone/func/sudoku.dart' as func_sudoku;

part "app.dart";
part "chat.dart";
part "rwkv.dart";
part "othello.dart";
part "file_manager.dart";
part "device.dart";
part "adapter.dart";
part "world.dart";
part "conversation.dart";
part "networking.dart";
part "tts.dart";
part "preference.dart";
part "guard.dart";
part "sudoku.dart";
part "suggestion.dart";
part "dump.dart";
part "msg.dart";

abstract class P {
  static final app = _App();
  static final chat = _Chat();
  static final rwkv = _RWKV();
  static final othello = _Othello();
  static final fileManager = _FileManager();
  static final device = _Device();
  static final adapter = _Adapter();
  static final world = _World();
  static final conversation = _Conversation();
  static final tts = _TTS();
  static final preference = _Preference();
  static final guard = _Guard();
  static final sudoku = _Sudoku();
  static final suggestion = _Suggestion();
  static final dump = _Dump();
  static final msg = _Msg();

  static FV init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await preference._init();
    await app._init();
    await _unorderedInit();
  }

  static FV _unorderedInit() async {
    await Future.wait([
      rwkv._init(),
      chat._init(),
      othello._init(),
      fileManager._init(),
      device._init(),
      adapter._init(),
      world._init(),
      conversation._init(),
      tts._init(),
      guard._init(),
      sudoku._init(),
      suggestion._init(),
      dump._init(),
      msg._init(),
    ]);
  }
}
