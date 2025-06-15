// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_Hant locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh_Hant';

  static String m0(demoName) => "歡迎探索 ${demoName}";

  static String m2(flag, nameCN, nameEN) =>
      "模仿 ${flag} ${nameCN}(${nameEN}) 的聲音";

  static String m4(memUsed, memFree) => "已用記憶體：${memUsed}，剩餘記憶體：${memFree}";

  static String m5(modelName) => "您目前正在使用 ${modelName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("關於"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("根據: "),
    "all_done": MessageLookupByLibrary.simpleMessage("全部完成"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "應用程式內測群",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("應用程式語言"),
    "application_settings": MessageLookupByLibrary.simpleMessage("應用程式設定"),
    "apply": MessageLookupByLibrary.simpleMessage("應用"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage("確定要刪除這個模型嗎？"),
    "auto": MessageLookupByLibrary.simpleMessage("自動"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("返回聊天"),
    "black": MessageLookupByLibrary.simpleMessage("黑方"),
    "black_score": MessageLookupByLibrary.simpleMessage("黑方得分"),
    "black_wins": MessageLookupByLibrary.simpleMessage("黑方獲勝！"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "機器人訊息已編輯，現在可以傳送新訊息",
    ),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("無法生成"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("取消下載"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("暫不更新"),
    "chat_copied_to_clipboard": MessageLookupByLibrary.simpleMessage("已複製到剪貼簿"),
    "chat_empty_message": MessageLookupByLibrary.simpleMessage("請輸入訊息內容"),
    "chat_model_name": MessageLookupByLibrary.simpleMessage("模型名稱"),
    "chat_please_select_a_model": MessageLookupByLibrary.simpleMessage(
      "請選擇一個模型",
    ),
    "chat_resume": MessageLookupByLibrary.simpleMessage("繼續"),
    "chat_title": MessageLookupByLibrary.simpleMessage("RWKV 聊天"),
    "chat_welcome_to_use": m0,
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage("您需要先下載模型才能使用"),
    "chatting": MessageLookupByLibrary.simpleMessage("聊天中"),
    "chinese": MessageLookupByLibrary.simpleMessage("中文"),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage("選擇預設角色"),
    "clear": MessageLookupByLibrary.simpleMessage("清除"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "點擊此處選擇新模型",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "點擊此處開始新聊天",
    ),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage("點擊選擇模型"),
    "continue_download": MessageLookupByLibrary.simpleMessage("繼續下載"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "繼續使用較小模型",
    ),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("點擊上方按鈕建立新會話"),
    "current_turn": MessageLookupByLibrary.simpleMessage("目前回合"),
    "decode": MessageLookupByLibrary.simpleMessage("解碼"),
    "delete": MessageLookupByLibrary.simpleMessage("刪除"),
    "delete_all": MessageLookupByLibrary.simpleMessage("全部刪除"),
    "difficulty": MessageLookupByLibrary.simpleMessage("難度"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "難度必須大於 0",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "難度必須小於 81",
    ),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "download_all": MessageLookupByLibrary.simpleMessage("下載全部"),
    "download_missing": MessageLookupByLibrary.simpleMessage("下載缺失檔案"),
    "download_model": MessageLookupByLibrary.simpleMessage("下載模型"),
    "download_source": MessageLookupByLibrary.simpleMessage("下載來源"),
    "draw": MessageLookupByLibrary.simpleMessage("平局！"),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage("請確保裝置記憶體充足，否則可能導致應用程式崩潰"),
    "exploring": MessageLookupByLibrary.simpleMessage("探索中..."),
    "extra_large": MessageLookupByLibrary.simpleMessage("特大 (130%)"),
    "feedback": MessageLookupByLibrary.simpleMessage("回饋問題"),
    "filter": MessageLookupByLibrary.simpleMessage(
      "你好，這個問題我暫時無法回答，讓我們換個話題再聊聊吧。",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("錄音完成"),
    "follow_system": MessageLookupByLibrary.simpleMessage("跟隨系統"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "在 Twitter 上關注我們",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("字體設定"),
    "font_size": MessageLookupByLibrary.simpleMessage("字體大小"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("預設 (100%)"),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "game_over": MessageLookupByLibrary.simpleMessage("遊戲結束！"),
    "generate": MessageLookupByLibrary.simpleMessage("生成"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("生成世界上最難的數獨"),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "生成隨機數獨",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("生成中..."),
    "hide_stack": MessageLookupByLibrary.simpleMessage("隱藏思維鏈堆疊"),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "按住錄音，鬆開發送",
    ),
    "human": MessageLookupByLibrary.simpleMessage("人類"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage("我想讓 RWKV 說..."),
    "imitate": m2,
    "imitate_target": MessageLookupByLibrary.simpleMessage("使用"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage("當搜尋深度和寬度都大於 2 時，將啟動上下文搜尋"),
    "inference_is_done": MessageLookupByLibrary.simpleMessage("🎉 推論完成"),
    "inference_is_running": MessageLookupByLibrary.simpleMessage("推論中"),
    "intonations": MessageLookupByLibrary.simpleMessage("語氣詞"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "歡迎探索 RWKV v7 系列大型語言模型，包含 0.1B/0.4B/1.5B/2.9B 參數版本，專為行動裝置最佳化，載入後可完全離線執行，無需伺服器通訊",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("無效數獨"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("無效值"),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("輪到你了～"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "加入我們的 Discord 伺服器",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage("加入社群"),
    "just_watch_me": MessageLookupByLibrary.simpleMessage("😎 看我表演！"),
    "large": MessageLookupByLibrary.simpleMessage("大 (120%)"),
    "license": MessageLookupByLibrary.simpleMessage("開源許可證"),
    "loading": MessageLookupByLibrary.simpleMessage("載入中..."),
    "medium": MessageLookupByLibrary.simpleMessage("中 (110%)"),
    "memory_used": m4,
    "model_settings": MessageLookupByLibrary.simpleMessage("模型設定"),
    "my_voice": MessageLookupByLibrary.simpleMessage("我的聲音"),
    "network_error": MessageLookupByLibrary.simpleMessage("網路錯誤"),
    "new_chat": MessageLookupByLibrary.simpleMessage("新聊天"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("開始新聊天"),
    "new_game": MessageLookupByLibrary.simpleMessage("新遊戲"),
    "new_version_found": MessageLookupByLibrary.simpleMessage("發現新版本"),
    "no_cell_available": MessageLookupByLibrary.simpleMessage("無子可下"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("沒有數獨"),
    "number": MessageLookupByLibrary.simpleMessage("數字"),
    "ok": MessageLookupByLibrary.simpleMessage("確定"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("或者選擇一個 wav 檔案，讓 RWKV 模仿它。"),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "或開始一個空白聊天",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "players": MessageLookupByLibrary.simpleMessage("玩家"),
    "playing_partial_generated_audio": MessageLookupByLibrary.simpleMessage(
      "正在播放部分已生成的語音",
    ),
    "please_check_the_result": MessageLookupByLibrary.simpleMessage("請檢查結果"),
    "please_enter_a_number_0_means_empty": MessageLookupByLibrary.simpleMessage(
      "請輸入一個數字。0 表示空。",
    ),
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage("請授予使用麥克風的權限"),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage("請先載入模型"),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "請選擇 World 類型",
    ),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "請選擇應用程式語言",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage("請選擇字體大小"),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "請輸入難度",
    ),
    "please_wait_for_it_to_finish": MessageLookupByLibrary.simpleMessage(
      "請等待推論完成",
    ),
    "please_wait_for_the_model_to_finish_generating":
        MessageLookupByLibrary.simpleMessage("請等待模型生成完成"),
    "please_wait_for_the_model_to_generate":
        MessageLookupByLibrary.simpleMessage("請等待模型生成"),
    "please_wait_for_the_model_to_load": MessageLookupByLibrary.simpleMessage(
      "請等待模型載入",
    ),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("預設聲音"),
    "prefer": MessageLookupByLibrary.simpleMessage("使用"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("使用中文推論"),
    "prefill": MessageLookupByLibrary.simpleMessage("預填"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQ 群 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQ 群 2"),
    "reason": MessageLookupByLibrary.simpleMessage("推論"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("推論模式"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("正在錄音..."),
    "remaining": MessageLookupByLibrary.simpleMessage("剩餘時間："),
    "reselect_model": MessageLookupByLibrary.simpleMessage("重新選擇模型"),
    "reset": MessageLookupByLibrary.simpleMessage("重置"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV 聊天"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("搜尋寬度"),
    "search_depth": MessageLookupByLibrary.simpleMessage("搜尋深度"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("選擇模型"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("選擇 World 類型"),
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage("傳送訊息給 RWKV"),
    "server_error": MessageLookupByLibrary.simpleMessage("伺服器錯誤"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("會話配置"),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("設定網格值"),
    "show_stack": MessageLookupByLibrary.simpleMessage("顯示思維鏈堆疊"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "推薦至少選擇 1.5B 模型，效果更好",
    ),
    "small": MessageLookupByLibrary.simpleMessage("小 (90%)"),
    "speed": MessageLookupByLibrary.simpleMessage("下載速度："),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage("開始新聊天"),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage("點擊下方按鈕開始新聊天"),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("開始對局"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("開始聊天"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("開始推論"),
    "technical_research_group": MessageLookupByLibrary.simpleMessage("技術研發群"),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage("數獨無效"),
    "thinking": MessageLookupByLibrary.simpleMessage("思考中..."),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("這是世界上最難的數獨"),
    "thought_result": MessageLookupByLibrary.simpleMessage("思考結果"),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("落子權轉移"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("超大 (140%)"),
    "update_now": MessageLookupByLibrary.simpleMessage("立即更新"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("立即使用"),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "值必須在 0 和 9 之間",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("非常小 (80%)"),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("聲音複製"),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage("歡迎使用 RWKV"),
    "white": MessageLookupByLibrary.simpleMessage("白方"),
    "white_score": MessageLookupByLibrary.simpleMessage("白方得分"),
    "white_wins": MessageLookupByLibrary.simpleMessage("白方獲勝！"),
    "you_are_now_using": m5,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "現在可以開始與 RWKV 聊天了",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("您可以錄製您的聲音，然後讓 RWKV 模仿它。"),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "您可以選擇角色進行聊天",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "您的聲音太短，請長按按鈕更久以獲取您的聲音。",
    ),
  };
}
