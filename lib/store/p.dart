import 'dart:async';
import 'dart:convert';
// ignore: unused_import
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:collection/collection.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_roleplay/services/role_play_manage.dart' show RoleplayManage;
import 'package:gaimon/gaimon.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart' as mp_audio_stream;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart' as ar;
import 'package:rwkv_downloader/downloader.dart';
import 'package:rwkv_mobile_flutter/from_rwkv.dart' as from_rwkv;
import 'package:rwkv_mobile_flutter/rwkv.dart';
import 'package:rwkv_mobile_flutter/to_rwkv.dart' as to_rwkv;
import 'package:rxdart/rxdart.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart' as shelf_ws;
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:web_socket_channel/web_socket_channel.dart' as ws_channel;
import 'package:sprintf/sprintf.dart' show sprintf;
import 'package:zone/db/db.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/model/backend_status.dart';
import 'package:zone/model/bbox.dart';
import 'package:zone/model/browser_tab.dart';
import 'package:zone/model/browser_window.dart';
import 'package:zone/model/backend_state.dart';
import 'package:zone/model/content_type.dart';
import 'package:zone/model/custom_theme.dart' as custom_theme;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:system_info2/system_info2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zone/args.dart';
import 'package:zone/config.dart';
import 'package:zone/db/db.dart' as db;
import 'package:zone/db/db.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/func/extensions/num.dart';
import 'package:zone/func/from_assets_to_temp.dart';
import 'package:zone/func/is_chinese.dart';
import 'package:zone/func/save_asset_to_file.dart';
import 'package:zone/func/show_image_selector.dart';
import 'package:zone/func/sudoku.dart' as func_sudoku;
import 'package:zone/gen/l10n.dart';
import 'package:zone/io.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/model/cell_type.dart';
import 'package:zone/model/cot_display_state.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/feature_rollout.dart';
import 'package:zone/model/file_download_source.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/group_info.dart';
import 'package:zone/model/lambada_test_item.dart';
import 'package:zone/model/language.dart';
import 'package:zone/model/local_file.dart';
import 'package:zone/model/log_item.dart';
import 'package:zone/model/message.dart';
import 'package:zone/model/message_type.dart';
import 'package:zone/model/msg_node.dart';
import 'package:zone/model/prompt_template.dart';
import 'package:zone/model/ref_info.dart';
import 'package:zone/model/reference.dart';
import 'package:zone/model/sampler_and_penalty_param.dart';
import 'package:zone/model/serve_mode.dart';
import 'package:zone/model/state_log.dart';
import 'package:zone/model/thinking_mode.dart' as thinking_mode;
import 'package:zone/model/tts_instruction.dart';
import 'package:zone/model/user_type.dart';
import 'package:zone/model/version_info.dart';
import 'package:zone/model/web_search_mode.dart';
import 'package:zone/model/wenyan_mode.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/model/font_info.dart';
import 'package:zone/widgets/theme_selector.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/albatross.dart';
import 'package:zone/widgets/batch_settings_panel.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/func/unzip.dart';
import 'package:zone/widgets/version_info_panel.dart';

part "adapter.dart";
part "app.dart";
part "backend.dart";
part "chat.dart";
part "conversation.dart";
part "device.dart";
part "dump.dart";
part "weights.dart";
part "guard.dart";
part "lambada.dart";
part "msg.dart";
part "networking.dart";
part "othello.dart";
part "preference.dart";
part "rwkv.dart";
part "see.dart";
part "sudoku.dart";
part "suggestion.dart";
part "talk.dart";
part "translator.dart";
part "ocr.dart";
part "md_render.dart";
part "font.dart";
part "ui.dart";

abstract class P {
  static final adapter = _Adapter();
  static final app = _App();
  static final backend = _Backend();
  static final chat = _Chat();
  static final conversation = _Conversation();
  static final device = _Device();
  static final dump = _Dump();
  static final weights = _Weights();
  static final guard = _Guard();
  static final lambada = _Lambada();
  static final msg = _Msg();
  static final othello = _Othello();
  static final preference = _Preference();
  static final rwkv = _RWKV();
  static final sudoku = _Sudoku();
  static final suggestion = _Suggestion();
  static final translator = _Translator();
  static final talk = _Talk();
  static final see = _See();
  static final ocr = _Ocr();
  static final mdRender = _MDRender();
  static final font = _Font();
  static final ui = _UI();

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await preference._init();
    } catch (e) {
      qqe('Error initializing preference: $e');
    }

    try {
      await app._init();
    } catch (e) {
      qqe('Error initializing app: $e');
    }

    await _unorderedInit();
  }

  static Future<void> _unorderedInit() async {
    await Future.wait([
      _safeInit(() => rwkv._init(), mark: "rwkv"),
      _safeInit(() => chat._init(), mark: "chat"),
      _safeInit(() => othello._init(), mark: "othello"),
      _safeInit(() => weights._init(), mark: "fileManager"),
      _safeInit(() => device._init(), mark: "device"),
      _safeInit(() => adapter._init(), mark: "adapter"),
      _safeInit(() => see._init(), mark: "see"),
      _safeInit(() => conversation._init(), mark: "conversation"),
      _safeInit(() => talk._init(), mark: "talk"),
      _safeInit(() => guard._init(), mark: "guard"),
      _safeInit(() => sudoku._init(), mark: "sudoku"),
      _safeInit(() => suggestion._init(), mark: "suggestion"),
      _safeInit(() => dump._init(), mark: "dump"),
      _safeInit(() => msg._init(), mark: "msg"),
      _safeInit(() => backend._init(), mark: "backend"),
      _safeInit(() => translator._init(), mark: "translator"),
      _safeInit(() => lambada._init(), mark: "lambada"),
      _safeInit(() => ocr._init(), mark: "ocr"),
      _safeInit(() => mdRender._init(), mark: "mdRender"),
      _safeInit(() => font._init(), mark: "font"),
      _safeInit(() => ui._init(), mark: "ui"),
    ]);
  }

  static Future<void> _safeInit(Future<void> Function() initFunc, {String? mark}) async {
    final name = mark;
    var isCompleted = false;
    var hasWarned = false;

    const check = 2000;
    const timeout = 4000;

    // 启动超时检测
    check.msLater.then((_) {
      if (!isCompleted && !hasWarned) {
        hasWarned = true;
        qqe('Warning: $name initialization is taking longer than ${check}ms');
      }
    });

    try {
      await initFunc().timeout(const Duration(milliseconds: timeout));
      isCompleted = true;
    } on TimeoutException {
      qqe('Error: $name initialization timed out after ${timeout}ms');
      Sentry.captureException(TimeoutException('Initialization timed out after ${timeout}ms'), stackTrace: StackTrace.current);
    } catch (e) {
      isCompleted = true;
      qqe('Error initializing $name: $e');
      Sentry.captureException(e, stackTrace: StackTrace.current);
    }
  }
}
