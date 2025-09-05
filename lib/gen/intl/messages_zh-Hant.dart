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

  static String m2(demoName) => "歡迎探索 ${demoName}";

  static String m3(maxLength) => "對話名稱不能超過${maxLength}個字元";

  static String m4(path) => "訊息記錄會儲存在該資料夾下\n ${path}";

  static String m6(flag, nameCN, nameEN) =>
      "模仿 ${flag} ${nameCN}(${nameEN}) 的聲音";

  static String m7(fileName) => "模仿 ${fileName}";

  static String m8(memUsed, memFree) => "已用記憶體：${memUsed}，剩餘記憶體：${memFree}";

  static String m13(modelName) => "您目前正在使用 ${modelName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("關於"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("根據: "),
    "all": MessageLookupByLibrary.simpleMessage("全部"),
    "all_done": MessageLookupByLibrary.simpleMessage("全部完成"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("全部 Prompt"),
    "appearance": MessageLookupByLibrary.simpleMessage("外觀"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "應用程式內測群",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("應用程式語言"),
    "application_settings": MessageLookupByLibrary.simpleMessage("應用程式設定"),
    "apply": MessageLookupByLibrary.simpleMessage("套用"),
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
    "can_not_generate": MessageLookupByLibrary.simpleMessage("無法產生"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("取消下載"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("暫不更新"),
    "chat_copied_to_clipboard": MessageLookupByLibrary.simpleMessage("已複製到剪貼簿"),
    "chat_empty_message": MessageLookupByLibrary.simpleMessage("請輸入訊息內容"),
    "chat_history": MessageLookupByLibrary.simpleMessage("聊天記錄"),
    "chat_mode": MessageLookupByLibrary.simpleMessage("對話模式"),
    "chat_model_name": MessageLookupByLibrary.simpleMessage("模型名稱"),
    "chat_please_select_a_model": MessageLookupByLibrary.simpleMessage(
      "請選擇一個模型",
    ),
    "chat_resume": MessageLookupByLibrary.simpleMessage("繼續"),
    "chat_title": MessageLookupByLibrary.simpleMessage("RWKV 聊天"),
    "chat_welcome_to_use": m2,
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
    "click_to_load_image": MessageLookupByLibrary.simpleMessage("點擊載入圖片"),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage("點擊選擇模型"),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "色彩模式跟隨系統",
    ),
    "completion_mode": MessageLookupByLibrary.simpleMessage("續寫模式"),
    "confirm": MessageLookupByLibrary.simpleMessage("確認"),
    "continue_download": MessageLookupByLibrary.simpleMessage("繼續下載"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "繼續使用較小模型",
    ),
    "conversation_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "對話名稱不能為空",
    ),
    "conversation_name_cannot_be_longer_than_30_characters": m3,
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("點擊上方按鈕建立新會話"),
    "current_turn": MessageLookupByLibrary.simpleMessage("目前回合"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage("自定義難度"),
    "dark_mode": MessageLookupByLibrary.simpleMessage("深色模式"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage("深色模式主題"),
    "decode": MessageLookupByLibrary.simpleMessage("解碼"),
    "delete": MessageLookupByLibrary.simpleMessage("刪除"),
    "delete_all": MessageLookupByLibrary.simpleMessage("全部刪除"),
    "delete_conversation": MessageLookupByLibrary.simpleMessage("刪除對話"),
    "delete_conversation_message": MessageLookupByLibrary.simpleMessage(
      "確定要刪除對話嗎？",
    ),
    "difficulty": MessageLookupByLibrary.simpleMessage("難度"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "難度必須大於 0",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "難度必須小於 81",
    ),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "download_all": MessageLookupByLibrary.simpleMessage("下載全部"),
    "download_app": MessageLookupByLibrary.simpleMessage("下載App"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage("從瀏覽器下載"),
    "download_missing": MessageLookupByLibrary.simpleMessage("下載缺失檔案"),
    "download_model": MessageLookupByLibrary.simpleMessage("下載模型"),
    "download_server_": MessageLookupByLibrary.simpleMessage("下載伺服器(請試試哪個快)"),
    "download_source": MessageLookupByLibrary.simpleMessage("下載來源"),
    "downloading": MessageLookupByLibrary.simpleMessage("下載中"),
    "draw": MessageLookupByLibrary.simpleMessage("平局！"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage("自動 Dump 訊息記錄"),
    "dump_see_files_alert_message": m4,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage(
      "協助我們改進演算法",
    ),
    "dump_started": MessageLookupByLibrary.simpleMessage("自動 dump 已開啟"),
    "dump_stopped": MessageLookupByLibrary.simpleMessage("自動 dump 已關閉"),
    "end": MessageLookupByLibrary.simpleMessage("完"),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage("請確保裝置記憶體充足，否則可能導致應用程式崩潰"),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("探索RWKV"),
    "exploring": MessageLookupByLibrary.simpleMessage("探索中..."),
    "export_data": MessageLookupByLibrary.simpleMessage("匯出資料"),
    "extra_large": MessageLookupByLibrary.simpleMessage("特大 (130%)"),
    "feedback": MessageLookupByLibrary.simpleMessage("回饋問題"),
    "filter": MessageLookupByLibrary.simpleMessage(
      "你好，這個問題我暫時無法回答，讓我們換個話題再聊聊吧。",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("錄音完成"),
    "follow_system": MessageLookupByLibrary.simpleMessage("跟隨系統"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "在 Twitter 上追蹤我們",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("字體設定"),
    "font_size": MessageLookupByLibrary.simpleMessage("字體大小"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("預設 (100%)"),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage("強制使用深色模式"),
    "from_model": MessageLookupByLibrary.simpleMessage("來自模型: %s"),
    "game_over": MessageLookupByLibrary.simpleMessage("遊戲結束！"),
    "generate": MessageLookupByLibrary.simpleMessage("產生"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("產生世界上最難的數獨"),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "產生隨機數獨",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("產生中..."),
    "hide_stack": MessageLookupByLibrary.simpleMessage("隱藏思維鏈堆疊"),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "按住錄音，鬆開發送",
    ),
    "human": MessageLookupByLibrary.simpleMessage("人類"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage("我想讓 RWKV 說..."),
    "imitate": m6,
    "imitate_fle": m7,
    "imitate_target": MessageLookupByLibrary.simpleMessage("使用"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage("當搜尋深度和寬度都大於 2 時，將啟用上下文搜尋"),
    "inference_is_done": MessageLookupByLibrary.simpleMessage("🎉 推理完成"),
    "inference_is_running": MessageLookupByLibrary.simpleMessage("推理中"),
    "intonations": MessageLookupByLibrary.simpleMessage("語氣詞"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "歡迎探索 RWKV v7 系列大語言模型，包含 0.1B/0.4B/1.5B/2.9B 參數版本，專為行動裝置優化，載入後可完全離線執行，無需伺服器通訊",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("無效數獨"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("無效值"),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("輪到你了~"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "加入我們的 Discord 伺服器",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage("加入社群"),
    "just_watch_me": MessageLookupByLibrary.simpleMessage("😎 看我表演！"),
    "large": MessageLookupByLibrary.simpleMessage("大 (120%)"),
    "lazy": MessageLookupByLibrary.simpleMessage("懶"),
    "license": MessageLookupByLibrary.simpleMessage("開源許可證"),
    "light_mode": MessageLookupByLibrary.simpleMessage("淺色模式"),
    "loading": MessageLookupByLibrary.simpleMessage("載入中..."),
    "medium": MessageLookupByLibrary.simpleMessage("中 (110%)"),
    "memory_used": m8,
    "model_settings": MessageLookupByLibrary.simpleMessage("模型設定"),
    "more": MessageLookupByLibrary.simpleMessage("更多"),
    "my_voice": MessageLookupByLibrary.simpleMessage("我的聲音"),
    "network_error": MessageLookupByLibrary.simpleMessage("網路錯誤"),
    "new_chat": MessageLookupByLibrary.simpleMessage("新聊天"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("開始新聊天"),
    "new_game": MessageLookupByLibrary.simpleMessage("新遊戲"),
    "new_version_found": MessageLookupByLibrary.simpleMessage("發現新版本"),
    "no_cell_available": MessageLookupByLibrary.simpleMessage("無子可下"),
    "no_data": MessageLookupByLibrary.simpleMessage("無資料"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("沒有數獨"),
    "number": MessageLookupByLibrary.simpleMessage("數字"),
    "ok": MessageLookupByLibrary.simpleMessage("確定"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("或者選擇一個 wav 檔案，讓 RWKV 模仿它。"),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "或開始一個空白聊天",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "output": MessageLookupByLibrary.simpleMessage("輸出"),
    "overseas": MessageLookupByLibrary.simpleMessage("(境外)"),
    "pause": MessageLookupByLibrary.simpleMessage("暫停"),
    "players": MessageLookupByLibrary.simpleMessage("玩家"),
    "playing_partial_generated_audio": MessageLookupByLibrary.simpleMessage(
      "正在播放部分已產生的語音",
    ),
    "please_check_the_result": MessageLookupByLibrary.simpleMessage("請檢查結果"),
    "please_enter_a_number_0_means_empty": MessageLookupByLibrary.simpleMessage(
      "請輸入一個數字。0 表示空。",
    ),
    "please_enter_conversation_name": MessageLookupByLibrary.simpleMessage(
      "請輸入對話名稱",
    ),
    "please_enter_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "請輸入難度",
    ),
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage("請授予使用麥克風的權限"),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage("請先載入模型"),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "請選擇任務類型",
    ),
    "please_select_an_image_from_the_following_options":
        MessageLookupByLibrary.simpleMessage("請從以下選項中選擇一個圖片"),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "請選擇應用程式語言",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage("請選擇字體大小"),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "請選擇難度",
    ),
    "please_wait_for_it_to_finish": MessageLookupByLibrary.simpleMessage(
      "請等待推理完成",
    ),
    "please_wait_for_the_model_to_finish_generating":
        MessageLookupByLibrary.simpleMessage("請等待模型產生完成"),
    "please_wait_for_the_model_to_generate":
        MessageLookupByLibrary.simpleMessage("請等待模型產生"),
    "please_wait_for_the_model_to_load": MessageLookupByLibrary.simpleMessage(
      "請等待模型載入",
    ),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("預設聲音"),
    "prefer": MessageLookupByLibrary.simpleMessage("使用"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("使用中文推理"),
    "prefill": MessageLookupByLibrary.simpleMessage("預填"),
    "prompt": MessageLookupByLibrary.simpleMessage("提示詞"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQ 群 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQ 群 2"),
    "quick_thinking": MessageLookupByLibrary.simpleMessage("快思考"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage("快思考已經開啟"),
    "reason": MessageLookupByLibrary.simpleMessage("推理"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("推理模式"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("正在錄音..."),
    "regenerate": MessageLookupByLibrary.simpleMessage("重新產生"),
    "remaining": MessageLookupByLibrary.simpleMessage("剩餘時間："),
    "rename": MessageLookupByLibrary.simpleMessage("重新命名"),
    "reselect_model": MessageLookupByLibrary.simpleMessage("重新選擇模型"),
    "reset": MessageLookupByLibrary.simpleMessage("重設"),
    "resume": MessageLookupByLibrary.simpleMessage("恢復"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV 聊天"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "save": MessageLookupByLibrary.simpleMessage("儲存"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("掃描QR碼"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("搜尋寬度"),
    "search_depth": MessageLookupByLibrary.simpleMessage("搜尋深度"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("選擇模型"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("選擇任務類型"),
    "select_from_library": MessageLookupByLibrary.simpleMessage("從相簿選擇"),
    "select_image": MessageLookupByLibrary.simpleMessage("選擇圖片"),
    "select_new_image": MessageLookupByLibrary.simpleMessage("選擇新圖片"),
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage("傳送訊息給 RWKV"),
    "server_error": MessageLookupByLibrary.simpleMessage("伺服器錯誤"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("會話組態"),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("設定網格值"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "share": MessageLookupByLibrary.simpleMessage("分享"),
    "share_chat": MessageLookupByLibrary.simpleMessage("分享聊天"),
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
    "start_to_inference": MessageLookupByLibrary.simpleMessage("開始推理"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "儲存權限未授予",
    ),
    "str_model_selection_dialog_hint": MessageLookupByLibrary.simpleMessage(
      "推薦至少選擇1.5B模型，更大的2.9B模型更好",
    ),
    "submit": MessageLookupByLibrary.simpleMessage("提交"),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("入門"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("專家"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("普通"),
    "system_mode": MessageLookupByLibrary.simpleMessage("跟隨系統"),
    "take_photo": MessageLookupByLibrary.simpleMessage("拍照"),
    "technical_research_group": MessageLookupByLibrary.simpleMessage("技術研發群"),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage("數獨無效"),
    "theme_dim": MessageLookupByLibrary.simpleMessage("深色"),
    "theme_light": MessageLookupByLibrary.simpleMessage("淺色"),
    "theme_lights_out": MessageLookupByLibrary.simpleMessage("黑色"),
    "then_you_can_start_to_chat_with_rwkv":
        MessageLookupByLibrary.simpleMessage("然後您就可以開始與 RWKV 對話了"),
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
    "x_message_selected": MessageLookupByLibrary.simpleMessage("已選 %d 條訊息"),
    "you_are_now_using": m13,
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
