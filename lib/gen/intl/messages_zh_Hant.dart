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

  static String m0(count) => "並行 × ${count}";

  static String m1(count) => "每次推理將生成 ${count} 則訊息";

  static String m2(count) => "每次生成 ${count} 條結果";

  static String m3(count) => "並行推理中，同時生成 ${count} 則訊息";

  static String m4(index) => "已選擇第 ${index} 則訊息";

  static String m5(demoName) => "歡迎探索 ${demoName}";

  static String m6(maxLength) => "對話名稱不能超過${maxLength}個字元";

  static String m7(modelName) => "目前模型: ${modelName}";

  static String m8(current, total) => "目前進度: ${current}/${total}";

  static String m9(current, total) => "目前測試項 (${current}/${total})";

  static String m10(path) => "訊息記錄會儲存在該資料夾下\n ${path}";

  static String m11(
    scale,
    h1BaseSize,
    h2BaseSize,
    h3BaseSize,
    h4BaseSize,
    h5BaseSize,
    h6BaseSize,
    bodyBaseSize,
    h1Size,
    h2Size,
    h3Size,
    h4Size,
    h5Size,
    h6Size,
    bodySize,
  ) =>
      "# Markdown 語法全集測試 (H1)\n\n這是一個用於測試 **Markdown 解析器** 和 **CSS 樣式** 的標準測試檔案。\n\n## 1. 文字格式 (Typography)\n\n這裡是普通文字段落。測試中英文混排的表現：The quick brown fox jumps over the lazy dog. 敏捷的棕色狐狸跳過了懶惰的狗。\n\n* **粗體文字 (Bold)** 或 __另一種粗體__\n* *斜體文字 (Italic)* 或 _另一種斜體_\n* ***粗斜體文字 (Bold & Italic)***\n* ~~刪除線 (Strikethrough)~~\n* `行內程式碼 (Inline Code)`\n* [連結文字 (Link)](https://www.google.com)\n\n## 2. 標題層級 (Headings)\n\n# 一級標題 (H1, font size: ${h1BaseSize} * ${scale} = ${h1Size})\n\n## 二級標題 (H2, font size: ${h2BaseSize} * ${scale} = ${h2Size})\n\n### 三級標題 (H3, font size: ${h3BaseSize} * ${scale} = ${h3Size})\n\n#### 四級標題 (H4, font size: ${h4BaseSize} * ${scale} = ${h4Size})\n\n##### 五級標題 (H5, font size: ${h5BaseSize} * ${scale} = ${h5Size})\n\n###### 六級標題 (H6, font size: ${h6BaseSize} * ${scale} = ${h6Size})\n\n正文內容 (XX, font size: ${bodyBaseSize} * ${scale} = ${bodySize})\n\n## 3. 列表 (Lists)\n\n### 無序列表\n* 項目一\n* 項目二\n  * 子項目 A\n  * 子項目 B\n    * 以此類推\n\n### 有序列表\n1. 第一步\n2. 第二步\n3. 第三步\n   1. 子步驟 I\n   2. 子步驟 II\n\n### 任務列表 (Task List)\n- [x] 已完成的任務\n- [ ] 未完成的任務\n- [ ] 正在進行的任務\n\n## 4. 引用 (Blockquotes)\n\n> 這是一個一級引用。\n> > 這是一個巢狀的二級引用。\n> > 回到二級。\n> 回到一級引用。\n\n## 5. 程式碼區塊 (Code Blocks)\n\n### 基礎程式碼區塊 (Indented)\n\n    // 這是一個縮排程式碼區塊\n    console.log(\'Hello\');\n\n### 語法高亮 (Fenced with Syntax Highlighting)\n\n**JavaScript:**\n```javascript\nfunction helloWorld() {\n  const message = \"Hello, Markdown!\";\n  console.log(message);\n  return true;\n}```";

  static String m12(value) => "Frequency Penalty: ${value}";

  static String m13(port) => "HTTP 服務 (連接埠: ${port})";

  static String m14(flag, nameCN, nameEN) =>
      "模仿 ${flag} ${nameCN}(${nameEN}) 的聲音";

  static String m15(fileName) => "模仿 ${fileName}";

  static String m16(count) => "匯入成功：已匯入 ${count} 個檔案";

  static String m17(memUsed, memFree) => "已用記憶體：${memUsed}，剩餘記憶體：${memFree}";

  static String m18(text) => "模型輸出: ${text}";

  static String m19(socName) => "暫未支持您的芯片 ${socName} 的 NPU 加速";

  static String m20(takePhoto) => "點擊 ${takePhoto}。RWKV 將翻譯圖片中的文本。";

  static String m21(value) => "Penalty Decay: ${value}";

  static String m22(index) => "請選擇要為第 ${index} 條消息設定的取樣和懲罰參數";

  static String m23(value) => "Presence Penalty: ${value}";

  static String m24(count) => "排隊中: ${count}";

  static String m25(count) => "已選擇 ${count}";

  static String m26(text) => "來源文字: ${text}";

  static String m27(text) => "目標文字: ${text}";

  static String m28(value) => "Temperature: ${value}";

  static String m29(footer) => "推理${footer}: 英";

  static String m30(footer) => "推理${footer}: 英長";

  static String m31(footer) => "推理${footer}: 英短";

  static String m32(footer) => "推理${footer}: 快";

  static String m33(footer) => "推理${footer}: 中";

  static String m34(footer) => "推理${footer}: 高";

  static String m35(footer) => "推理${footer}: 關";

  static String m36(value) => "Top P: ${value}";

  static String m37(count) => "總測試項: ${count}";

  static String m38(port) => "WebSocket 服務 (連接埠: ${port})";

  static String m39(id) => "視窗 ${id}";

  static String m40(count) => "${count} 個分頁";

  static String m41(modelName) => "您目前正在使用 ${modelName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("關於"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("根據: "),
    "accuracy": MessageLookupByLibrary.simpleMessage("準確率"),
    "adapting_more_inference_chips": MessageLookupByLibrary.simpleMessage(
      "我們正在持續適配更多的推理芯片，敬請期待。",
    ),
    "advance_settings": MessageLookupByLibrary.simpleMessage("進階設定"),
    "all": MessageLookupByLibrary.simpleMessage("全部"),
    "all_done": MessageLookupByLibrary.simpleMessage("全部完成"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("全部 Prompt"),
    "all_the_same": MessageLookupByLibrary.simpleMessage("全部相同"),
    "allow_background_downloads": MessageLookupByLibrary.simpleMessage(
      "允許背景下載",
    ),
    "analysing_result": MessageLookupByLibrary.simpleMessage("正在分析搜尋結果"),
    "app_is_already_up_to_date": MessageLookupByLibrary.simpleMessage("已是最新版本"),
    "appearance": MessageLookupByLibrary.simpleMessage("外觀"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "應用程式內測群",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("應用語言"),
    "application_mode": MessageLookupByLibrary.simpleMessage("應用程式模式"),
    "application_settings": MessageLookupByLibrary.simpleMessage("應用程式設定"),
    "apply": MessageLookupByLibrary.simpleMessage("套用"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage("確定要刪除這個模型嗎？"),
    "ask_me_anything": MessageLookupByLibrary.simpleMessage("隨意向我提問..."),
    "assistant": MessageLookupByLibrary.simpleMessage("RWKV:"),
    "auto": MessageLookupByLibrary.simpleMessage("自動"),
    "auto_detect": MessageLookupByLibrary.simpleMessage("自動偵測"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("返回聊天"),
    "balanced": MessageLookupByLibrary.simpleMessage("均衡"),
    "batch_completion": MessageLookupByLibrary.simpleMessage("並行續寫"),
    "batch_completion_settings": MessageLookupByLibrary.simpleMessage("並行續寫設定"),
    "batch_inference": MessageLookupByLibrary.simpleMessage("並行推理"),
    "batch_inference_button": m0,
    "batch_inference_count": MessageLookupByLibrary.simpleMessage("並行推理數量"),
    "batch_inference_count_detail": m1,
    "batch_inference_count_detail_2": m2,
    "batch_inference_detail": MessageLookupByLibrary.simpleMessage(
      "開啟並行推理後，RWKV 可以同時生成多個答案",
    ),
    "batch_inference_enable_or_not": MessageLookupByLibrary.simpleMessage(
      "開啟或關閉並行推理",
    ),
    "batch_inference_running": m3,
    "batch_inference_selected": m4,
    "batch_inference_settings": MessageLookupByLibrary.simpleMessage("並行推理設定"),
    "batch_inference_short": MessageLookupByLibrary.simpleMessage("並行"),
    "batch_inference_width": MessageLookupByLibrary.simpleMessage("訊息顯示寬度"),
    "batch_inference_width_2": MessageLookupByLibrary.simpleMessage("結果顯示寬度"),
    "batch_inference_width_detail": MessageLookupByLibrary.simpleMessage(
      "並行推理每則訊息寬度",
    ),
    "batch_inference_width_detail_2": MessageLookupByLibrary.simpleMessage(
      "每條結果的寬度",
    ),
    "beginner": MessageLookupByLibrary.simpleMessage("新手模式"),
    "benchmark": MessageLookupByLibrary.simpleMessage("基準測試"),
    "benchmark_result": MessageLookupByLibrary.simpleMessage("基準測試結果"),
    "black": MessageLookupByLibrary.simpleMessage("黑方"),
    "black_score": MessageLookupByLibrary.simpleMessage("黑方得分"),
    "black_wins": MessageLookupByLibrary.simpleMessage("黑方獲勝！"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "機器人訊息已編輯，現在可以傳送新訊息",
    ),
    "browser_status": MessageLookupByLibrary.simpleMessage("瀏覽器狀態"),
    "cached_translations_disk": MessageLookupByLibrary.simpleMessage(
      "快取的翻譯 (磁碟)",
    ),
    "cached_translations_memory": MessageLookupByLibrary.simpleMessage(
      "快取的翻譯 (記憶體)",
    ),
    "camera": MessageLookupByLibrary.simpleMessage("相機"),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("無法產生"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "cancel_all_selection": MessageLookupByLibrary.simpleMessage("取消全選"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("取消下載"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("暫不更新"),
    "change": MessageLookupByLibrary.simpleMessage("變更"),
    "change_selected_image": MessageLookupByLibrary.simpleMessage("更換圖片"),
    "chat": MessageLookupByLibrary.simpleMessage("開始對話"),
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
    "chat_welcome_to_use": m5,
    "chat_with_rwkv_model": MessageLookupByLibrary.simpleMessage("與 RWKV 模型對話"),
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage("您需要先下載模型才能使用"),
    "chatting": MessageLookupByLibrary.simpleMessage("聊天中"),
    "check_for_updates": MessageLookupByLibrary.simpleMessage("檢查更新"),
    "chinese": MessageLookupByLibrary.simpleMessage("中文"),
    "chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "中文思考範本",
    ),
    "chinese_translation_result": MessageLookupByLibrary.simpleMessage(
      "中文翻譯結果",
    ),
    "chinese_web_search_template": MessageLookupByLibrary.simpleMessage(
      "中文網路搜尋範本",
    ),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage("選擇預設角色"),
    "clear": MessageLookupByLibrary.simpleMessage("清除"),
    "clear_memory_cache": MessageLookupByLibrary.simpleMessage("清除記憶體快取"),
    "clear_text": MessageLookupByLibrary.simpleMessage("清除文字"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "點擊此處選擇新模型",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "點擊此處開始新聊天",
    ),
    "click_to_load_image": MessageLookupByLibrary.simpleMessage("點擊載入圖片"),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage("點擊選擇模型"),
    "close": MessageLookupByLibrary.simpleMessage("關閉"),
    "code_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "代碼已複製到剪貼簿",
    ),
    "colon": MessageLookupByLibrary.simpleMessage("："),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "色彩模式跟隨系統",
    ),
    "completion": MessageLookupByLibrary.simpleMessage("續寫模式"),
    "completion_mode": MessageLookupByLibrary.simpleMessage("續寫模式"),
    "comprehensive": MessageLookupByLibrary.simpleMessage("綜合"),
    "confirm": MessageLookupByLibrary.simpleMessage("確認"),
    "conservative": MessageLookupByLibrary.simpleMessage("保守（適合數學和程式碼）"),
    "continue_download": MessageLookupByLibrary.simpleMessage("繼續下載"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "繼續使用較小模型",
    ),
    "conversation_management": MessageLookupByLibrary.simpleMessage("管理"),
    "conversation_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "對話名稱不能為空",
    ),
    "conversation_name_cannot_be_longer_than_30_characters": m6,
    "conversations": MessageLookupByLibrary.simpleMessage("對話"),
    "copy_code": MessageLookupByLibrary.simpleMessage("複製代碼"),
    "copy_text": MessageLookupByLibrary.simpleMessage("複製文字"),
    "correct_count": MessageLookupByLibrary.simpleMessage("正確數"),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("點擊上方按鈕建立新會話"),
    "created_at": MessageLookupByLibrary.simpleMessage("建立時間"),
    "creative": MessageLookupByLibrary.simpleMessage("創意"),
    "current_model": m7,
    "current_progress": m8,
    "current_task_tab_id": MessageLookupByLibrary.simpleMessage("目前任務分頁 ID"),
    "current_task_text_length": MessageLookupByLibrary.simpleMessage(
      "目前任務文字長度",
    ),
    "current_task_url": MessageLookupByLibrary.simpleMessage("目前任務 URL"),
    "current_test_item": m9,
    "current_turn": MessageLookupByLibrary.simpleMessage("目前回合"),
    "custom": MessageLookupByLibrary.simpleMessage("自訂"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage("自定義難度"),
    "dark_mode": MessageLookupByLibrary.simpleMessage("深色模式"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage("深色模式主題"),
    "decode": MessageLookupByLibrary.simpleMessage("解碼"),
    "decode_param": MessageLookupByLibrary.simpleMessage("解碼參數"),
    "decode_params_for_each_message": MessageLookupByLibrary.simpleMessage(
      "每條訊息的解碼參數",
    ),
    "decode_params_for_each_message_detail":
        MessageLookupByLibrary.simpleMessage("批量推理中每條訊息的解碼參數。點擊編輯每條訊息的解碼參數。"),
    "deep_web_search": MessageLookupByLibrary.simpleMessage("深度網路搜尋"),
    "default_": MessageLookupByLibrary.simpleMessage("預設"),
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
    "disabled": MessageLookupByLibrary.simpleMessage("關閉"),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "dont_ask_again": MessageLookupByLibrary.simpleMessage("不再詢問"),
    "download_all": MessageLookupByLibrary.simpleMessage("下載全部"),
    "download_all_missing": MessageLookupByLibrary.simpleMessage("下載全部缺失檔案"),
    "download_app": MessageLookupByLibrary.simpleMessage("下載App"),
    "download_failed": MessageLookupByLibrary.simpleMessage("下載失敗"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage("從瀏覽器下載"),
    "download_missing": MessageLookupByLibrary.simpleMessage("下載缺失檔案"),
    "download_model": MessageLookupByLibrary.simpleMessage("下載模型"),
    "download_server_": MessageLookupByLibrary.simpleMessage("下載伺服器(請試試哪個快)"),
    "download_source": MessageLookupByLibrary.simpleMessage("下載來源"),
    "downloading": MessageLookupByLibrary.simpleMessage("下載中"),
    "draw": MessageLookupByLibrary.simpleMessage("平局！"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage("自動 Dump 訊息記錄"),
    "dump_see_files_alert_message": m10,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage(
      "協助我們改進演算法",
    ),
    "dump_started": MessageLookupByLibrary.simpleMessage("自動 dump 已開啟"),
    "dump_stopped": MessageLookupByLibrary.simpleMessage("自動 dump 已關閉"),
    "en_to_zh": MessageLookupByLibrary.simpleMessage("英->中"),
    "enabled": MessageLookupByLibrary.simpleMessage("開啟"),
    "end": MessageLookupByLibrary.simpleMessage("完"),
    "english_translation_result": MessageLookupByLibrary.simpleMessage(
      "英文翻譯結果",
    ),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage("請確保裝置記憶體充足，否則可能導致應用程式崩潰"),
    "enter_text_to_translate": MessageLookupByLibrary.simpleMessage(
      "輸入要翻譯的文字...",
    ),
    "escape_characters_rendered": MessageLookupByLibrary.simpleMessage(
      "已渲染換行符",
    ),
    "expert": MessageLookupByLibrary.simpleMessage("專家模式"),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("探索RWKV"),
    "exploring": MessageLookupByLibrary.simpleMessage("探索中..."),
    "export_all_weight_files": MessageLookupByLibrary.simpleMessage("匯出全部權重檔案"),
    "export_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "所有已下載的權重檔案將作為單獨檔案匯出到所選目錄。同名檔案將被跳過。",
    ),
    "export_conversation_failed": MessageLookupByLibrary.simpleMessage(
      "匯出對話失敗",
    ),
    "export_conversation_to_txt": MessageLookupByLibrary.simpleMessage(
      "將對話匯出為 .txt 檔案",
    ),
    "export_data": MessageLookupByLibrary.simpleMessage("匯出資料"),
    "export_failed": MessageLookupByLibrary.simpleMessage("匯出失敗"),
    "export_success": MessageLookupByLibrary.simpleMessage("匯出成功"),
    "export_title": MessageLookupByLibrary.simpleMessage("對話標題:"),
    "export_weight_file": MessageLookupByLibrary.simpleMessage("匯出權重檔案"),
    "extra_large": MessageLookupByLibrary.simpleMessage("特大 (130%)"),
    "feedback": MessageLookupByLibrary.simpleMessage("回饋問題"),
    "file_already_exists": MessageLookupByLibrary.simpleMessage("檔案已存在"),
    "file_not_found": MessageLookupByLibrary.simpleMessage("檔案未找到"),
    "file_not_supported": MessageLookupByLibrary.simpleMessage(
      "目前檔案尚未支援，請檢查檔案名稱是否正確",
    ),
    "file_path_not_found": MessageLookupByLibrary.simpleMessage("檔案路徑未找到"),
    "files": MessageLookupByLibrary.simpleMessage("個檔案"),
    "filter": MessageLookupByLibrary.simpleMessage(
      "你好，這個問題我暫時無法回答，讓我們換個話題再聊聊吧。",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("錄音完成"),
    "fixed": MessageLookupByLibrary.simpleMessage("固定"),
    "follow_system": MessageLookupByLibrary.simpleMessage("跟隨系統"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "在 Twitter 上追蹤我們",
    ),
    "font_preview_bot_message": m11,
    "font_preview_user_message": MessageLookupByLibrary.simpleMessage(
      "Hello! 你好！這是使用者訊息的預覽。",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("字體設定"),
    "font_size": MessageLookupByLibrary.simpleMessage("字體大小"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("預設 (100%)"),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage("強制使用深色模式"),
    "frequency_penalty_with_value": m12,
    "from_model": MessageLookupByLibrary.simpleMessage("來自模型: %s"),
    "gallery": MessageLookupByLibrary.simpleMessage("相冊"),
    "game_over": MessageLookupByLibrary.simpleMessage("遊戲結束！"),
    "generate": MessageLookupByLibrary.simpleMessage("產生"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("產生世界上最難的數獨"),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "產生隨機數獨",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("產生中..."),
    "github_repository": MessageLookupByLibrary.simpleMessage("Github 倉庫"),
    "go_to_home_page": MessageLookupByLibrary.simpleMessage("前往首頁"),
    "go_to_settings": MessageLookupByLibrary.simpleMessage("前往設定"),
    "got_it": MessageLookupByLibrary.simpleMessage("我知道了"),
    "hello_ask_me_anything": MessageLookupByLibrary.simpleMessage(
      "Hello, 請隨意 \n向我提問...",
    ),
    "hide_stack": MessageLookupByLibrary.simpleMessage("隱藏思維鏈堆疊"),
    "hide_translations": MessageLookupByLibrary.simpleMessage("隱藏翻譯"),
    "hint_chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "預設使用 \'<think>好的\', 在 2025-09-21 前發佈的模型中, 會自動使用 \'<think>嗯\'",
    ),
    "hint_system_prompt": MessageLookupByLibrary.simpleMessage(
      "例子: System: 你是秦始皇，使用文言文，以居高臨下的態度與人溝通。",
    ),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "按住錄音，鬆開發送",
    ),
    "home": MessageLookupByLibrary.simpleMessage("主頁"),
    "http_service_port": m13,
    "human": MessageLookupByLibrary.simpleMessage("人類"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage("我想讓 RWKV 說..."),
    "idle": MessageLookupByLibrary.simpleMessage("閒置"),
    "imitate": m14,
    "imitate_fle": m15,
    "imitate_target": MessageLookupByLibrary.simpleMessage("使用"),
    "import_all_weight_files": MessageLookupByLibrary.simpleMessage("匯入全部權重檔案"),
    "import_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "選擇從此應用匯出的 ZIP 檔案。ZIP 檔案中的所有權重檔案將被匯入。如果檔案名稱相同，現有檔案將被覆蓋。",
    ),
    "import_all_weight_files_success": m16,
    "import_failed": MessageLookupByLibrary.simpleMessage("匯入失敗"),
    "import_success": MessageLookupByLibrary.simpleMessage("匯入成功"),
    "import_weight_file": MessageLookupByLibrary.simpleMessage("匯入權重檔案"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage("當搜尋深度和寬度都大於 2 時，將啟用上下文搜尋"),
    "inference_engine": MessageLookupByLibrary.simpleMessage("推理引擎"),
    "inference_is_done": MessageLookupByLibrary.simpleMessage("🎉 推理完成"),
    "inference_is_running": MessageLookupByLibrary.simpleMessage("推理中"),
    "input_chinese_text_here": MessageLookupByLibrary.simpleMessage("輸入中文文字"),
    "input_english_text_here": MessageLookupByLibrary.simpleMessage("輸入英文文字"),
    "intonations": MessageLookupByLibrary.simpleMessage("語氣詞"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "歡迎探索 RWKV v7 系列大語言模型，包含 0.1B/0.4B/1.5B/2.9B 參數版本，專為行動裝置優化，載入後可完全離線執行，無需伺服器通訊",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("無效數獨"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("無效值"),
    "invalid_zip_file": MessageLookupByLibrary.simpleMessage(
      "無效的 ZIP 檔案或檔案格式無法識別",
    ),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("輪到你了~"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "加入我們的 Discord 伺服器",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage("加入社群"),
    "just_watch_me": MessageLookupByLibrary.simpleMessage("😎 看我表演！"),
    "lambada_test": MessageLookupByLibrary.simpleMessage("LAMBADA 測試"),
    "lan_server": MessageLookupByLibrary.simpleMessage("區域網路伺服器"),
    "large": MessageLookupByLibrary.simpleMessage("大 (120%)"),
    "lazy": MessageLookupByLibrary.simpleMessage("懶"),
    "lazy_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "懶人思考範本",
    ),
    "license": MessageLookupByLibrary.simpleMessage("開源許可證"),
    "life_span": MessageLookupByLibrary.simpleMessage("Life Span"),
    "light_mode": MessageLookupByLibrary.simpleMessage("淺色模式"),
    "line_break_rendered": MessageLookupByLibrary.simpleMessage("已渲染換行"),
    "load_": MessageLookupByLibrary.simpleMessage("載入"),
    "load_data": MessageLookupByLibrary.simpleMessage("載入資料"),
    "loaded": MessageLookupByLibrary.simpleMessage("已載入"),
    "loading": MessageLookupByLibrary.simpleMessage("載入中..."),
    "medium": MessageLookupByLibrary.simpleMessage("中 (110%)"),
    "memory_used": m17,
    "message_content": MessageLookupByLibrary.simpleMessage("訊息內容"),
    "mode": MessageLookupByLibrary.simpleMessage("模式"),
    "model": MessageLookupByLibrary.simpleMessage("模型"),
    "model_loading": MessageLookupByLibrary.simpleMessage("模型載入中..."),
    "model_output": m18,
    "model_settings": MessageLookupByLibrary.simpleMessage("模型設定"),
    "model_size_increased_please_open_a_new_conversation":
        MessageLookupByLibrary.simpleMessage("模型大小增加，請開啟一個新的對話，以提升對話品質"),
    "more": MessageLookupByLibrary.simpleMessage("更多"),
    "more_questions": MessageLookupByLibrary.simpleMessage("更多問題"),
    "multi_thread": MessageLookupByLibrary.simpleMessage("多執行緒"),
    "my_voice": MessageLookupByLibrary.simpleMessage("我的聲音"),
    "neko": MessageLookupByLibrary.simpleMessage("Neko"),
    "network_error": MessageLookupByLibrary.simpleMessage("網路錯誤"),
    "new_chat": MessageLookupByLibrary.simpleMessage("新聊天"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("開始新聊天"),
    "new_chat_template": MessageLookupByLibrary.simpleMessage("新對話範本"),
    "new_chat_template_helper_text": MessageLookupByLibrary.simpleMessage(
      "每次新對話將插入此內容，用兩個換行分隔，例如：\n你好，你是誰？\n\n你好，我是RWKV，有什麼可以幫助你的嗎",
    ),
    "new_conversation": MessageLookupByLibrary.simpleMessage("開始新對話"),
    "new_game": MessageLookupByLibrary.simpleMessage("新遊戲"),
    "new_version_found": MessageLookupByLibrary.simpleMessage("發現新版本"),
    "no_audio_file": MessageLookupByLibrary.simpleMessage("沒有音訊檔案"),
    "no_browser_windows_connected": MessageLookupByLibrary.simpleMessage(
      "沒有連接的瀏覽器視窗",
    ),
    "no_cell_available": MessageLookupByLibrary.simpleMessage("無子可下"),
    "no_conversation_yet": MessageLookupByLibrary.simpleMessage("目前還沒有對話"),
    "no_conversations_yet": MessageLookupByLibrary.simpleMessage("暫時還沒有任何對話"),
    "no_data": MessageLookupByLibrary.simpleMessage("無資料"),
    "no_files_in_zip": MessageLookupByLibrary.simpleMessage(
      "ZIP 檔案中未找到有效的權重檔案",
    ),
    "no_message_to_export": MessageLookupByLibrary.simpleMessage("沒有可匯出的訊息"),
    "no_model_selected": MessageLookupByLibrary.simpleMessage("未選擇模型"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("沒有數獨"),
    "no_weight_files_guide_message": MessageLookupByLibrary.simpleMessage(
      "您還沒有下載任何權重檔案。前往首頁下載並體驗應用。",
    ),
    "no_weight_files_guide_title": MessageLookupByLibrary.simpleMessage(
      "暫無權重檔案",
    ),
    "no_weight_files_to_export": MessageLookupByLibrary.simpleMessage(
      "沒有可匯出的權重檔案",
    ),
    "not_all_the_same": MessageLookupByLibrary.simpleMessage("不完全相同"),
    "not_syncing": MessageLookupByLibrary.simpleMessage("未同步"),
    "npu_not_supported_title": m19,
    "number": MessageLookupByLibrary.simpleMessage("數字"),
    "nyan_nyan": MessageLookupByLibrary.simpleMessage("Nyan~~,Nyan~~"),
    "ocr_guide_text": m20,
    "ocr_title": MessageLookupByLibrary.simpleMessage("OCR"),
    "off": MessageLookupByLibrary.simpleMessage("關閉"),
    "offline_translator": MessageLookupByLibrary.simpleMessage("離線翻譯"),
    "offline_translator_detail": MessageLookupByLibrary.simpleMessage("離線翻譯文字"),
    "offline_translator_server": MessageLookupByLibrary.simpleMessage(
      "離線翻譯伺服器",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("確定"),
    "open_database_folder": MessageLookupByLibrary.simpleMessage("開啟資料庫資料夾"),
    "open_debug_log_panel": MessageLookupByLibrary.simpleMessage("打開調試日誌面板"),
    "open_state_panel": MessageLookupByLibrary.simpleMessage("打開狀態面板"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("或者選擇一個 wav 檔案，讓 RWKV 模仿它。"),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "或開始一個空白聊天",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "other_files": MessageLookupByLibrary.simpleMessage(
      "其他檔案 (這些檔案可能是已經過期或不再支援的權重 RWKV Chat 無需再使用它們)",
    ),
    "output": MessageLookupByLibrary.simpleMessage("輸出"),
    "overseas": MessageLookupByLibrary.simpleMessage("(境外)"),
    "overwrite": MessageLookupByLibrary.simpleMessage("覆蓋"),
    "overwrite_file_confirmation": MessageLookupByLibrary.simpleMessage(
      "檔案已存在，是否要覆蓋？",
    ),
    "parameter_description": MessageLookupByLibrary.simpleMessage("參數說明"),
    "parameter_description_detail": MessageLookupByLibrary.simpleMessage(
      "Temperature: 控制輸出的隨機性。較高的值（如 0.8）使輸出更具創意和隨機性；較低的值（如 0.2）使輸出更集中和確定。\n\nTop P: 控制輸出的多樣性。模型僅考慮累積機率達到 Top P 的 token。較低的值（如 0.5）會忽略低機率的詞，使輸出更相關。\n\nPresence Penalty: 根據 token 是否已在文字中出現來懲罰它們。正值會增加模型談論新主題的可能性。\n\nFrequency Penalty: 根據 token 在文字中出現的頻率來懲罰它們。正值會減少模型逐字重複同一行的可能性。\n\nPenalty Decay: 控制懲罰隨距離的衰減程度。",
    ),
    "pause": MessageLookupByLibrary.simpleMessage("暫停"),
    "penalty_decay_with_value": m21,
    "performance_test": MessageLookupByLibrary.simpleMessage("效能測試"),
    "performance_test_description": MessageLookupByLibrary.simpleMessage(
      "測試速度和準確率",
    ),
    "perplexity": MessageLookupByLibrary.simpleMessage("困惑度"),
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
    "please_select_a_branch_to_continue_the_conversation":
        MessageLookupByLibrary.simpleMessage("請選擇您喜歡的分支以進行接下來的對話"),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "請選擇任務類型",
    ),
    "please_select_an_image_first": MessageLookupByLibrary.simpleMessage(
      "請先選擇一個圖片",
    ),
    "please_select_an_image_from_the_following_options":
        MessageLookupByLibrary.simpleMessage("請從以下選項中選擇一個圖片"),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "請選擇應用程式語言",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage("請選擇字體大小"),
    "please_select_model": MessageLookupByLibrary.simpleMessage("請選擇模型"),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "請選擇難度",
    ),
    "please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index":
        m22,
    "please_select_the_sampler_and_penalty_parameters_to_set_for_all_messages":
        MessageLookupByLibrary.simpleMessage("請選擇要為所有消息設定的取樣和懲罰參數"),
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
    "power_user": MessageLookupByLibrary.simpleMessage("進階模式"),
    "prebuilt": MessageLookupByLibrary.simpleMessage("預設"),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("預設聲音"),
    "prefer": MessageLookupByLibrary.simpleMessage("使用"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("使用中文推理"),
    "prefill": MessageLookupByLibrary.simpleMessage("預填"),
    "presence_penalty_with_value": m23,
    "prompt": MessageLookupByLibrary.simpleMessage("提示詞"),
    "prompt_template": MessageLookupByLibrary.simpleMessage("Prompt 範本"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQ 群 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQ 群 2"),
    "queued_x": m24,
    "quick_thinking": MessageLookupByLibrary.simpleMessage("快思考"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage("快思考已經開啟"),
    "reached_bottom": MessageLookupByLibrary.simpleMessage("敬請期待"),
    "real_time_update": MessageLookupByLibrary.simpleMessage("即時更新"),
    "reason": MessageLookupByLibrary.simpleMessage("推理"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("推理模式"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("正在錄音..."),
    "reference_source": MessageLookupByLibrary.simpleMessage("參考來源"),
    "refresh": MessageLookupByLibrary.simpleMessage("刷新"),
    "refreshed": MessageLookupByLibrary.simpleMessage("已刷新"),
    "regenerate": MessageLookupByLibrary.simpleMessage("重新產生"),
    "remaining": MessageLookupByLibrary.simpleMessage("剩餘時間："),
    "rename": MessageLookupByLibrary.simpleMessage("重新命名"),
    "report_an_issue_on_github": MessageLookupByLibrary.simpleMessage(
      "在 Github 上回報問題",
    ),
    "reselect_model": MessageLookupByLibrary.simpleMessage("重新選擇模型"),
    "reset": MessageLookupByLibrary.simpleMessage("重設"),
    "result": MessageLookupByLibrary.simpleMessage("結果"),
    "resume": MessageLookupByLibrary.simpleMessage("恢復"),
    "role_play": MessageLookupByLibrary.simpleMessage("角色扮演"),
    "role_play_intro": MessageLookupByLibrary.simpleMessage("扮演你喜歡的角色"),
    "runtime_log_panel": MessageLookupByLibrary.simpleMessage("運行日誌面板"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV 聊天"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "save": MessageLookupByLibrary.simpleMessage("儲存"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("掃描二維碼"),
    "screen_width": MessageLookupByLibrary.simpleMessage("螢幕寬度"),
    "search": MessageLookupByLibrary.simpleMessage("搜尋"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("搜尋寬度"),
    "search_depth": MessageLookupByLibrary.simpleMessage("搜尋深度"),
    "search_failed": MessageLookupByLibrary.simpleMessage("搜尋失敗"),
    "searching": MessageLookupByLibrary.simpleMessage("搜尋中..."),
    "see": MessageLookupByLibrary.simpleMessage("圖像問答"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("選擇模型"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("選擇任務類型"),
    "select_all": MessageLookupByLibrary.simpleMessage("全選"),
    "select_from_file": MessageLookupByLibrary.simpleMessage("選擇圖片檔案"),
    "select_from_library": MessageLookupByLibrary.simpleMessage("從相簿選擇"),
    "select_image": MessageLookupByLibrary.simpleMessage("選擇圖片"),
    "select_model": MessageLookupByLibrary.simpleMessage("選擇模型"),
    "select_new_image": MessageLookupByLibrary.simpleMessage("選擇圖片"),
    "select_the_decode_parameters_to_set_all_to_for_index":
        MessageLookupByLibrary.simpleMessage("請從下方選擇預設參數，或點擊「自定義」進行手動配置"),
    "selected_count": m25,
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage("傳送訊息給 RWKV"),
    "server_error": MessageLookupByLibrary.simpleMessage("伺服器錯誤"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("會話組態"),
    "set_all_batch_params": MessageLookupByLibrary.simpleMessage("設置全部批量參數"),
    "set_all_to_question_mark": MessageLookupByLibrary.simpleMessage(
      "全部設定為 ???",
    ),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("設定網格值"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "share": MessageLookupByLibrary.simpleMessage("分享"),
    "share_chat": MessageLookupByLibrary.simpleMessage("分享聊天"),
    "show_escape_characters": MessageLookupByLibrary.simpleMessage("換行符顯示"),
    "show_prefill_log_only": MessageLookupByLibrary.simpleMessage(
      "僅顯示 Prefill 日誌",
    ),
    "show_stack": MessageLookupByLibrary.simpleMessage("顯示思維鏈堆疊"),
    "show_translations": MessageLookupByLibrary.simpleMessage("顯示翻譯"),
    "single_thread": MessageLookupByLibrary.simpleMessage("單執行緒"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "推薦至少選擇 1.5B 模型，效果更好",
    ),
    "small": MessageLookupByLibrary.simpleMessage("小 (90%)"),
    "source_code": MessageLookupByLibrary.simpleMessage("原始碼"),
    "source_text": m26,
    "speed": MessageLookupByLibrary.simpleMessage("下載速度："),
    "start": MessageLookupByLibrary.simpleMessage("開始"),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage("開始新聊天"),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage("點擊下方按鈕開始新聊天"),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("開始對局"),
    "start_download_updates_": MessageLookupByLibrary.simpleMessage(
      "開始後台下載更新...",
    ),
    "start_service": MessageLookupByLibrary.simpleMessage("啟動服務"),
    "start_service_and_open_browser": MessageLookupByLibrary.simpleMessage(
      "啟動服務並開啟支援的瀏覽器頁面。",
    ),
    "start_test": MessageLookupByLibrary.simpleMessage("開始測試"),
    "start_testing": MessageLookupByLibrary.simpleMessage("開始測試"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("開始聊天"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("開始推理"),
    "starting": MessageLookupByLibrary.simpleMessage("啟動中..."),
    "state_list": MessageLookupByLibrary.simpleMessage("State 列表"),
    "state_panel": MessageLookupByLibrary.simpleMessage("狀態面板"),
    "status": MessageLookupByLibrary.simpleMessage("狀態"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "stop_service": MessageLookupByLibrary.simpleMessage("停止服務"),
    "stop_test": MessageLookupByLibrary.simpleMessage("停止測試"),
    "stopping": MessageLookupByLibrary.simpleMessage("停止中..."),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "儲存權限未授予",
    ),
    "str_downloading_info": MessageLookupByLibrary.simpleMessage(
      "下載 %.1f% 速度 %.1fMB/s 剩餘 %s",
    ),
    "str_model_selection_dialog_hint": MessageLookupByLibrary.simpleMessage(
      "推薦至少選擇1.5B模型，更大的2.9B模型更好",
    ),
    "str_please_disable_battery_opt_": MessageLookupByLibrary.simpleMessage(
      "請關閉電池優化以允許背景下載，否則切換到其他應用程式時下載可能會被暫停",
    ),
    "str_please_select_app_mode_": MessageLookupByLibrary.simpleMessage(
      "請根據您對 AI 和 LLM 的了解程度選擇應用程式模式。",
    ),
    "submit": MessageLookupByLibrary.simpleMessage("提交"),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("入門"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("專家"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("普通"),
    "suggest": MessageLookupByLibrary.simpleMessage("推薦"),
    "switch_to_creative_mode_for_better_exp":
        MessageLookupByLibrary.simpleMessage("建議選擇 “創意模式”, 以便獲得更好的體驗"),
    "syncing": MessageLookupByLibrary.simpleMessage("同步中"),
    "system_mode": MessageLookupByLibrary.simpleMessage("跟隨系統"),
    "system_prompt": MessageLookupByLibrary.simpleMessage("系統提示詞"),
    "take_photo": MessageLookupByLibrary.simpleMessage("拍照"),
    "target_text": m27,
    "technical_research_group": MessageLookupByLibrary.simpleMessage("技術研發群"),
    "temperature_with_value": m28,
    "test_data": MessageLookupByLibrary.simpleMessage("測試資料"),
    "test_result": MessageLookupByLibrary.simpleMessage("測試結果"),
    "test_results": MessageLookupByLibrary.simpleMessage("測試結果"),
    "testing": MessageLookupByLibrary.simpleMessage("測試中..."),
    "text": MessageLookupByLibrary.simpleMessage("文字"),
    "text_completion_mode": MessageLookupByLibrary.simpleMessage("文字補全模式"),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage("數獨無效"),
    "theme_dim": MessageLookupByLibrary.simpleMessage("深色"),
    "theme_light": MessageLookupByLibrary.simpleMessage("淺色"),
    "theme_lights_out": MessageLookupByLibrary.simpleMessage("黑色"),
    "then_you_can_start_to_chat_with_rwkv":
        MessageLookupByLibrary.simpleMessage("然後您就可以開始與 RWKV 對話了"),
    "think_button_mode_en": m29,
    "think_button_mode_en_long": m30,
    "think_button_mode_en_short": m31,
    "think_button_mode_fast": m32,
    "think_mode_selector_message": MessageLookupByLibrary.simpleMessage(
      "推理模式會影響模型在推理時的表現",
    ),
    "think_mode_selector_title": MessageLookupByLibrary.simpleMessage(
      "請選擇推理模式",
    ),
    "thinking": MessageLookupByLibrary.simpleMessage("思考中..."),
    "thinking_mode_alert_footer": MessageLookupByLibrary.simpleMessage("模式"),
    "thinking_mode_auto": m33,
    "thinking_mode_high": m34,
    "thinking_mode_off": m35,
    "thinking_mode_template": MessageLookupByLibrary.simpleMessage("思考模式範本"),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("這是世界上最難的數獨"),
    "this_model_does_not_support_batch_inference":
        MessageLookupByLibrary.simpleMessage("此模型不支援並行推理，請選擇帶有 batch 標籤的模型"),
    "thought_result": MessageLookupByLibrary.simpleMessage("思考結果"),
    "top_p_with_value": m36,
    "total_count": MessageLookupByLibrary.simpleMessage("總數"),
    "total_disk_usage": MessageLookupByLibrary.simpleMessage("總磁碟使用量"),
    "total_test_items": m37,
    "translate": MessageLookupByLibrary.simpleMessage("翻譯"),
    "translating": MessageLookupByLibrary.simpleMessage("翻譯中..."),
    "translation": MessageLookupByLibrary.simpleMessage("翻譯結果"),
    "translator_debug_info": MessageLookupByLibrary.simpleMessage("翻譯器偵錯資訊"),
    "tts": MessageLookupByLibrary.simpleMessage("文字轉語音"),
    "tts_detail": MessageLookupByLibrary.simpleMessage("讓 RWKV 輸出語音"),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("落子權轉移"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("超大 (140%)"),
    "unknown": MessageLookupByLibrary.simpleMessage("未知"),
    "unzipping": MessageLookupByLibrary.simpleMessage("解壓中"),
    "update_now": MessageLookupByLibrary.simpleMessage("立即更新"),
    "updated_at": MessageLookupByLibrary.simpleMessage("更新時間"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("立即使用"),
    "user": MessageLookupByLibrary.simpleMessage("使用者:"),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "值必須在 0 和 9 之間",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("非常小 (80%)"),
    "visual_understanding_and_ocr": MessageLookupByLibrary.simpleMessage(
      "視覺理解與 OCR",
    ),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("聲音複製"),
    "web_search": MessageLookupByLibrary.simpleMessage("網路搜尋"),
    "web_search_template": MessageLookupByLibrary.simpleMessage("網路搜尋範本"),
    "websocket_service_port": m38,
    "weights_mangement": MessageLookupByLibrary.simpleMessage("權重檔案管理"),
    "weights_saving_directory": MessageLookupByLibrary.simpleMessage(
      "權重文件保存目錄",
    ),
    "welcome_to_rwkv_chat": MessageLookupByLibrary.simpleMessage(
      "歡迎探索 RWKV Chat",
    ),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage("歡迎使用 RWKV"),
    "white": MessageLookupByLibrary.simpleMessage("白方"),
    "white_score": MessageLookupByLibrary.simpleMessage("白方得分"),
    "white_wins": MessageLookupByLibrary.simpleMessage("白方獲勝！"),
    "window_id": m39,
    "world": MessageLookupByLibrary.simpleMessage("See"),
    "x_message_selected": MessageLookupByLibrary.simpleMessage("已選 %d 條訊息"),
    "x_pages_found": MessageLookupByLibrary.simpleMessage("已找到 %d 個相關網頁"),
    "x_tabs": m40,
    "you_are_now_using": m41,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "現在可以開始與 RWKV 聊天了",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("您可以錄製您的聲音，然後讓 RWKV 模仿它。"),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "您可以選擇角色進行聊天",
    ),
    "your_voice_is_empty": MessageLookupByLibrary.simpleMessage(
      "您的聲音資料為空，請檢查您的麥克風",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "您的聲音太短，請長按按鈕更久以獲取您的聲音。",
    ),
    "zh_to_en": MessageLookupByLibrary.simpleMessage("中->英"),
  };
}
