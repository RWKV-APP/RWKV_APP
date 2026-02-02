// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja locale. All the
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
  String get localeName => 'ja';

  static String m0(count) => "並列 × ${count}";

  static String m1(count) => "各推論で${count}件のメッセージが生成されます";

  static String m2(count) => "各推論で ${count} 件の結果を生成";

  static String m3(count) => "並列推論を実行中、同時に${count}件のメッセージを生成しています";

  static String m4(index) => "${index}番目のメッセージが選択されました";

  static String m5(demoName) => "${demoName}へようこそ";

  static String m6(maxLength) => "会話名は${maxLength}文字を超えることはできません";

  static String m7(length) => "ctx ${length}";

  static String m8(modelName) => "現在のモデル: ${modelName}";

  static String m9(current, total) => "現在の進捗: ${current}/${total}";

  static String m10(current, total) => "現在のテスト項目 (${current}/${total})";

  static String m11(path) => "メッセージ履歴は以下のフォルダに保存されます:\n ${path}";

  static String m12(successCount, failCount) =>
      "${successCount}個のファイルを移動、${failCount}個が失敗";

  static String m13(value) => "Frequency Penalty: ${value}";

  static String m14(port) => "HTTPサービス（ポート：${port}）";

  static String m15(flag, nameCN, nameEN) =>
      "${flag} ${nameCN}(${nameEN})の音声を模倣";

  static String m16(fileName) => "${fileName}を模倣";

  static String m17(count) => "インポート成功：${count} 個のファイルをインポートしました";

  static String m18(folderName) => "ローカルフォルダ：${folderName}";

  static String m19(memUsed, memFree) => "使用メモリ：${memUsed}、残りメモリ：${memFree}";

  static String m20(count) => "キューに ${count} 件のメッセージがあります";

  static String m21(text) => "モデル出力: ${text}";

  static String m22(socName) => "お使いのチップ ${socName} の NPU サポートはまだ利用できません";

  static String m23(takePhoto) =>
      "${takePhoto} をクリックしてください。RWKV が画像内のテキストを翻訳します。";

  static String m24(path) => "パス：${path}";

  static String m25(value) => "Penalty Decay: ${value}";

  static String m26(index) => "メッセージ ${index} に設定するサンプラーとペナルティパラメータを選択してください";

  static String m27(value) => "Presence Penalty: ${value}";

  static String m28(count) => "キュー内：${count}";

  static String m29(count) => "選択された ${count}";

  static String m30(text) => "ソーステキスト: ${text}";

  static String m31(text) => "ターゲットテキスト: ${text}";

  static String m32(value) => "Temperature: ${value}";

  static String m33(footer) => "推論${footer}-英語";

  static String m34(footer) => "推論${footer}-英語 長";

  static String m35(footer) => "推論${footer}-英語 短";

  static String m36(footer) => "推論${footer}-速い";

  static String m37(footer) => "推論${footer}-自動";

  static String m38(footer) => "推論${footer}-高";

  static String m39(footer) => "推論${footer}-オフ";

  static String m40(value) => "Top P: ${value}";

  static String m41(count) => "総テスト項目: ${count}";

  static String m42(port) => "WebSocketサービス（ポート：${port}）";

  static String m43(id) => "ウィンドウ ${id}";

  static String m44(count) => "${count}個のタブ";

  static String m45(modelName) => "現在、${modelName}を使用しています";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("について"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("以下に基づいて："),
    "accuracy": MessageLookupByLibrary.simpleMessage("精度"),
    "adapting_more_inference_chips": MessageLookupByLibrary.simpleMessage(
      "より多くの推論チップへの対応を継続しています。ご期待ください。",
    ),
    "add_local_folder": MessageLookupByLibrary.simpleMessage("ローカルフォルダを追加"),
    "advance_settings": MessageLookupByLibrary.simpleMessage("詳細設定"),
    "all": MessageLookupByLibrary.simpleMessage("すべて"),
    "all_done": MessageLookupByLibrary.simpleMessage("すべて完了"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("すべてのプロンプト"),
    "all_the_same": MessageLookupByLibrary.simpleMessage("すべて同じ"),
    "allow_background_downloads": MessageLookupByLibrary.simpleMessage(
      "バックグラウンドでのダウンロードを許可",
    ),
    "already_using_this_directory": MessageLookupByLibrary.simpleMessage(
      "既にこのディレクトリを使用しています",
    ),
    "analysing_result": MessageLookupByLibrary.simpleMessage("検索結果を分析中"),
    "app_is_already_up_to_date": MessageLookupByLibrary.simpleMessage(
      "アプリは既に最新です",
    ),
    "appearance": MessageLookupByLibrary.simpleMessage("外観"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "アプリケーション内部テストグループ",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("アプリケーション言語"),
    "application_mode": MessageLookupByLibrary.simpleMessage("アプリケーションモード"),
    "application_settings": MessageLookupByLibrary.simpleMessage("アプリケーション設定"),
    "apply": MessageLookupByLibrary.simpleMessage("適用"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage("このモデルを削除してもよろしいですか？"),
    "ask_me_anything": MessageLookupByLibrary.simpleMessage("何でも聞いてください..."),
    "assistant": MessageLookupByLibrary.simpleMessage("RWKV："),
    "auto": MessageLookupByLibrary.simpleMessage("自動"),
    "auto_detect": MessageLookupByLibrary.simpleMessage("自動検出"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("チャットに戻る"),
    "balanced": MessageLookupByLibrary.simpleMessage("バランス"),
    "batch_completion": MessageLookupByLibrary.simpleMessage("バッチ補完"),
    "batch_completion_settings": MessageLookupByLibrary.simpleMessage(
      "バッチ補完設定",
    ),
    "batch_inference": MessageLookupByLibrary.simpleMessage("並列推論"),
    "batch_inference_button": m0,
    "batch_inference_count": MessageLookupByLibrary.simpleMessage("並列推論数"),
    "batch_inference_count_detail": m1,
    "batch_inference_count_detail_2": m2,
    "batch_inference_detail": MessageLookupByLibrary.simpleMessage(
      "並列推論を有効にすると、RWKVは同時に複数の回答を生成できます",
    ),
    "batch_inference_enable_or_not": MessageLookupByLibrary.simpleMessage(
      "並列推論を有効または無効にする",
    ),
    "batch_inference_running": m3,
    "batch_inference_selected": m4,
    "batch_inference_settings": MessageLookupByLibrary.simpleMessage("並列推論設定"),
    "batch_inference_short": MessageLookupByLibrary.simpleMessage("並列"),
    "batch_inference_width": MessageLookupByLibrary.simpleMessage("メッセージ表示幅"),
    "batch_inference_width_2": MessageLookupByLibrary.simpleMessage("結果表示幅"),
    "batch_inference_width_detail": MessageLookupByLibrary.simpleMessage(
      "並列推論の各メッセージの幅",
    ),
    "batch_inference_width_detail_2": MessageLookupByLibrary.simpleMessage(
      "各結果の幅",
    ),
    "beginner": MessageLookupByLibrary.simpleMessage("初心者"),
    "below_are_your_local_folders": MessageLookupByLibrary.simpleMessage(
      "以下はローカルフォルダです",
    ),
    "benchmark": MessageLookupByLibrary.simpleMessage("ベンチマーク"),
    "benchmark_result": MessageLookupByLibrary.simpleMessage("ベンチマーク結果"),
    "black": MessageLookupByLibrary.simpleMessage("黒"),
    "black_score": MessageLookupByLibrary.simpleMessage("黒のスコア"),
    "black_wins": MessageLookupByLibrary.simpleMessage("黒の勝ち！"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "ボットメッセージが編集されました。新しいメッセージを送信できます。",
    ),
    "browser_status": MessageLookupByLibrary.simpleMessage("ブラウザのステータス"),
    "cached_translations_disk": MessageLookupByLibrary.simpleMessage(
      "キャッシュされた翻訳（ディスク）",
    ),
    "cached_translations_memory": MessageLookupByLibrary.simpleMessage(
      "キャッシュされた翻訳（メモリ）",
    ),
    "camera": MessageLookupByLibrary.simpleMessage("カメラ"),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("生成できません"),
    "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
    "cancel_all_selection": MessageLookupByLibrary.simpleMessage("すべて選択を解除"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("ダウンロードをキャンセル"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("今すぐ更新しない"),
    "change": MessageLookupByLibrary.simpleMessage("変更"),
    "change_selected_image": MessageLookupByLibrary.simpleMessage("画像を変更"),
    "chat": MessageLookupByLibrary.simpleMessage("チャット"),
    "chat_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "クリップボードにコピーされました",
    ),
    "chat_empty_message": MessageLookupByLibrary.simpleMessage(
      "メッセージ内容を入力してください",
    ),
    "chat_history": MessageLookupByLibrary.simpleMessage("チャット履歴"),
    "chat_mode": MessageLookupByLibrary.simpleMessage("チャットモード"),
    "chat_model_name": MessageLookupByLibrary.simpleMessage("モデル名"),
    "chat_please_select_a_model": MessageLookupByLibrary.simpleMessage(
      "モデルを選択してください",
    ),
    "chat_resume": MessageLookupByLibrary.simpleMessage("再開"),
    "chat_title": MessageLookupByLibrary.simpleMessage("RWKVチャット"),
    "chat_welcome_to_use": m5,
    "chat_with_rwkv_model": MessageLookupByLibrary.simpleMessage(
      "RWKVモデルとチャット",
    ),
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage("使用するには、まずモデルをダウンロードする必要があります"),
    "chatting": MessageLookupByLibrary.simpleMessage("チャット中"),
    "check_for_updates": MessageLookupByLibrary.simpleMessage("更新を確認"),
    "chinese": MessageLookupByLibrary.simpleMessage("中国語"),
    "chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "中国語思考モードテンプレート",
    ),
    "chinese_translation_result": MessageLookupByLibrary.simpleMessage(
      "中国語翻訳結果",
    ),
    "chinese_web_search_template": MessageLookupByLibrary.simpleMessage(
      "中国語ウェブ検索テンプレート",
    ),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage(
      "プリセットキャラクターを選択",
    ),
    "clear": MessageLookupByLibrary.simpleMessage("クリア"),
    "clear_memory_cache": MessageLookupByLibrary.simpleMessage("メモリキャッシュをクリア"),
    "clear_text": MessageLookupByLibrary.simpleMessage("テキストを消去"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "ここをクリックして新しいモデルを選択",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "ここをクリックして新しいチャットを開始",
    ),
    "click_plus_add_local_folder": MessageLookupByLibrary.simpleMessage(
      "+ をクリックしてローカルフォルダを追加。RWKV Chat がフォルダ内の .pth ファイルをスキャンし、読み込み可能な重みとして表示します",
    ),
    "click_plus_to_add_more_folders": MessageLookupByLibrary.simpleMessage(
      "+ をクリックしてローカルフォルダを追加",
    ),
    "click_to_load_image": MessageLookupByLibrary.simpleMessage("画像をクリックしてロード"),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage(
      "モデルを選択するにはクリック",
    ),
    "close": MessageLookupByLibrary.simpleMessage("閉じる"),
    "code_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "コードがクリップボードにコピーされました",
    ),
    "colon": MessageLookupByLibrary.simpleMessage("："),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "カラーテーマはシステムに従う",
    ),
    "completion": MessageLookupByLibrary.simpleMessage("補完"),
    "completion_mode": MessageLookupByLibrary.simpleMessage("補完モード"),
    "confirm": MessageLookupByLibrary.simpleMessage("確認"),
    "confirm_delete_file_message": MessageLookupByLibrary.simpleMessage(
      "このファイルはローカルディスクから完全に削除されます",
    ),
    "confirm_delete_file_title": MessageLookupByLibrary.simpleMessage(
      "このファイルを削除しますか？",
    ),
    "confirm_forget_location_message": MessageLookupByLibrary.simpleMessage(
      "忘れると、このフォルダはローカルフォルダ一覧に表示されなくなります",
    ),
    "confirm_forget_location_title": MessageLookupByLibrary.simpleMessage(
      "この場所を忘れますか？",
    ),
    "continue_download": MessageLookupByLibrary.simpleMessage("ダウンロードを続行"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "より小さいモデルの使用を続行",
    ),
    "conversation_management": MessageLookupByLibrary.simpleMessage("管理"),
    "conversation_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "会話名は空にできません",
    ),
    "conversation_name_cannot_be_longer_than_30_characters": m6,
    "conversations": MessageLookupByLibrary.simpleMessage("会話"),
    "copy_code": MessageLookupByLibrary.simpleMessage("コードをコピー"),
    "copy_text": MessageLookupByLibrary.simpleMessage("テキストをコピー"),
    "correct_count": MessageLookupByLibrary.simpleMessage("正解数"),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("上のボタンをクリックして新しいセッションを作成"),
    "created_at": MessageLookupByLibrary.simpleMessage("作成日時"),
    "creative_recommended": MessageLookupByLibrary.simpleMessage("クリエイティブ（推奨）"),
    "creative_recommended_short": MessageLookupByLibrary.simpleMessage(
      "クリエイティブ",
    ),
    "ctx_length_label": m7,
    "current_folder_has_no_local_models": MessageLookupByLibrary.simpleMessage(
      "このフォルダにローカルモデルはありません",
    ),
    "current_model": m8,
    "current_model_from_latest_json_not_pth":
        MessageLookupByLibrary.simpleMessage(
          "現在読み込んでいるのは latest.json の設定であり、ローカル .pth ファイルではありません",
        ),
    "current_progress": m9,
    "current_task_tab_id": MessageLookupByLibrary.simpleMessage("現在のタスクのタブID"),
    "current_task_text_length": MessageLookupByLibrary.simpleMessage(
      "現在のタスクのテキスト長",
    ),
    "current_task_url": MessageLookupByLibrary.simpleMessage("現在のタスクのURL"),
    "current_test_item": m10,
    "current_turn": MessageLookupByLibrary.simpleMessage("現在のターン"),
    "current_version": MessageLookupByLibrary.simpleMessage("現在のバージョン"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage("カスタム難易度"),
    "custom_directory_set": MessageLookupByLibrary.simpleMessage(
      "カスタムディレクトリを設定しました",
    ),
    "dark_mode": MessageLookupByLibrary.simpleMessage("ダークモード"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage("ダークモードテーマ"),
    "decode": MessageLookupByLibrary.simpleMessage("デコード"),
    "decode_param": MessageLookupByLibrary.simpleMessage("デコードパラメータ"),
    "decode_param_comprehensive": MessageLookupByLibrary.simpleMessage(
      "包括的（試す価値あり）",
    ),
    "decode_param_comprehensive_short": MessageLookupByLibrary.simpleMessage(
      "包括的",
    ),
    "decode_param_conservative": MessageLookupByLibrary.simpleMessage(
      "保守的（数学やコードに最適）",
    ),
    "decode_param_conservative_short": MessageLookupByLibrary.simpleMessage(
      "保守的",
    ),
    "decode_param_creative": MessageLookupByLibrary.simpleMessage(
      "クリエイティブ（執筆向き、繰り返し少）",
    ),
    "decode_param_creative_short": MessageLookupByLibrary.simpleMessage(
      "クリエイティブ",
    ),
    "decode_param_custom": MessageLookupByLibrary.simpleMessage("カスタム（手動設定）"),
    "decode_param_custom_short": MessageLookupByLibrary.simpleMessage("カスタム"),
    "decode_param_default_": MessageLookupByLibrary.simpleMessage(
      "デフォルト（デフォルト設定）",
    ),
    "decode_param_default_short": MessageLookupByLibrary.simpleMessage("デフォルト"),
    "decode_param_fixed": MessageLookupByLibrary.simpleMessage("固定（最も保守的）"),
    "decode_param_fixed_short": MessageLookupByLibrary.simpleMessage("固定"),
    "decode_param_select_message": MessageLookupByLibrary.simpleMessage(
      "デコードパラメータを通じて RWKV の出力スタイルを制御できます",
    ),
    "decode_param_select_title": MessageLookupByLibrary.simpleMessage(
      "デコードパラメータを選択してください",
    ),
    "decode_params_for_each_message": MessageLookupByLibrary.simpleMessage(
      "各メッセージのデコードパラメータ",
    ),
    "decode_params_for_each_message_detail":
        MessageLookupByLibrary.simpleMessage(
          "バッチ推論における各メッセージのデコードパラメータ。クリックして編集できます。",
        ),
    "deep_web_search": MessageLookupByLibrary.simpleMessage("ディープネットワーク検索"),
    "default_font": MessageLookupByLibrary.simpleMessage("デフォルト"),
    "delete": MessageLookupByLibrary.simpleMessage("削除"),
    "delete_all": MessageLookupByLibrary.simpleMessage("すべて削除"),
    "delete_conversation": MessageLookupByLibrary.simpleMessage("会話を削除"),
    "delete_conversation_message": MessageLookupByLibrary.simpleMessage(
      "会話を削除してもよろしいですか？",
    ),
    "difficulty": MessageLookupByLibrary.simpleMessage("難易度"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "難易度は0より大きくなければなりません",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "難易度は81より小さくなければなりません",
    ),
    "disabled": MessageLookupByLibrary.simpleMessage("無効"),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "dont_ask_again": MessageLookupByLibrary.simpleMessage("次回から表示しない"),
    "download_all": MessageLookupByLibrary.simpleMessage("すべてダウンロード"),
    "download_all_missing": MessageLookupByLibrary.simpleMessage(
      "不足しているファイルをすべてダウンロード",
    ),
    "download_app": MessageLookupByLibrary.simpleMessage("アプリをダウンロード"),
    "download_failed": MessageLookupByLibrary.simpleMessage("ダウンロードに失敗しました"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage(
      "ブラウザからダウンロード",
    ),
    "download_missing": MessageLookupByLibrary.simpleMessage(
      "不足しているファイルをダウンロード",
    ),
    "download_model": MessageLookupByLibrary.simpleMessage("モデルをダウンロード"),
    "download_now": MessageLookupByLibrary.simpleMessage("今すぐダウンロード"),
    "download_server_": MessageLookupByLibrary.simpleMessage(
      "ダウンロードサーバー（どれが速いか試してください）",
    ),
    "download_source": MessageLookupByLibrary.simpleMessage("ダウンロード元"),
    "downloading": MessageLookupByLibrary.simpleMessage("ダウンロード中"),
    "draw": MessageLookupByLibrary.simpleMessage("引き分け！"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage("自動ダンプメッセージ履歴"),
    "dump_see_files_alert_message": m11,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage(
      "アルゴリズム改善にご協力ください",
    ),
    "dump_started": MessageLookupByLibrary.simpleMessage("自動ダンプが開始されました"),
    "dump_stopped": MessageLookupByLibrary.simpleMessage("自動ダンプが停止しました"),
    "en_to_zh": MessageLookupByLibrary.simpleMessage("英->中"),
    "enabled": MessageLookupByLibrary.simpleMessage("有効"),
    "end": MessageLookupByLibrary.simpleMessage("終"),
    "english_translation_result": MessageLookupByLibrary.simpleMessage(
      "英語翻訳結果",
    ),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage(
          "デバイスのメモリが十分であることを確認してください。そうでない場合、アプリケーションがクラッシュする可能性があります。",
        ),
    "enter_text_to_translate": MessageLookupByLibrary.simpleMessage(
      "翻訳するテキストを入力...",
    ),
    "escape_characters_rendered": MessageLookupByLibrary.simpleMessage(
      "改行文字が表示されました",
    ),
    "expert": MessageLookupByLibrary.simpleMessage("専門家"),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("RWKVを探索"),
    "exploring": MessageLookupByLibrary.simpleMessage("探索中..."),
    "export_all_weight_files": MessageLookupByLibrary.simpleMessage(
      "すべての重みファイルをエクスポート",
    ),
    "export_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "ダウンロード済みのすべての重みファイルが個別のファイルとして選択したディレクトリにエクスポートされます。同じ名前のファイルはスキップされます。",
    ),
    "export_conversation_failed": MessageLookupByLibrary.simpleMessage(
      "会話のエクスポートに失敗しました",
    ),
    "export_conversation_to_txt": MessageLookupByLibrary.simpleMessage(
      "会話を.txtファイルにエクスポート",
    ),
    "export_data": MessageLookupByLibrary.simpleMessage("データのエクスポート"),
    "export_failed": MessageLookupByLibrary.simpleMessage("エクスポート失敗"),
    "export_success": MessageLookupByLibrary.simpleMessage("エクスポート成功"),
    "export_title": MessageLookupByLibrary.simpleMessage("会話のタイトル："),
    "export_weight_file": MessageLookupByLibrary.simpleMessage("重みファイルをエクスポート"),
    "extra_large": MessageLookupByLibrary.simpleMessage("特大 (130%)"),
    "failed_to_check_for_updates": MessageLookupByLibrary.simpleMessage(
      "更新の確認に失敗しました",
    ),
    "failed_to_create_directory": MessageLookupByLibrary.simpleMessage(
      "ディレクトリの作成に失敗しました",
    ),
    "feedback": MessageLookupByLibrary.simpleMessage("フィードバック"),
    "file_already_exists": MessageLookupByLibrary.simpleMessage("ファイルは既に存在します"),
    "file_not_found": MessageLookupByLibrary.simpleMessage("ファイルが見つかりません"),
    "file_not_supported": MessageLookupByLibrary.simpleMessage(
      "このファイルはまだサポートされていません。ファイル名が正しいか確認してください",
    ),
    "file_path_not_found": MessageLookupByLibrary.simpleMessage(
      "ファイルパスが見つかりません",
    ),
    "files": MessageLookupByLibrary.simpleMessage("ファイル"),
    "files_moved_with_failures": m12,
    "filter": MessageLookupByLibrary.simpleMessage(
      "こんにちは、この質問にはまだお答えできません。別の話題について話しましょう。",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("録音完了"),
    "folder_already_added": MessageLookupByLibrary.simpleMessage(
      "このフォルダは既に追加されています",
    ),
    "folder_not_accessible_check_permission":
        MessageLookupByLibrary.simpleMessage(
          "このフォルダにアクセスできません。フォルダの権限を確認してください",
        ),
    "folder_not_found_on_device": MessageLookupByLibrary.simpleMessage(
      "お使いのデバイスでこのフォルダが見つかりませんでした",
    ),
    "follow_system": MessageLookupByLibrary.simpleMessage("システムに従う"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "Twitterでフォロー",
    ),
    "font_preview_markdown_asset": MessageLookupByLibrary.simpleMessage(
      "assets/lib/font_preview/font_preview_ja.md",
    ),
    "font_preview_user_message": MessageLookupByLibrary.simpleMessage(
      "Hello! こんにちは！これはユーザーメッセージのプレビューです。",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("フォント設定"),
    "font_size": MessageLookupByLibrary.simpleMessage("フォントサイズ"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("デフォルト (100%)"),
    "font_size_follow_system": MessageLookupByLibrary.simpleMessage(
      "フォントサイズをシステムに従う",
    ),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage("強制ダークモード"),
    "forget_location_success": MessageLookupByLibrary.simpleMessage("場所を忘れました"),
    "forget_this_location": MessageLookupByLibrary.simpleMessage("この場所を忘れる"),
    "found_new_version_available": MessageLookupByLibrary.simpleMessage(
      "新しいバージョンが見つかりました",
    ),
    "frequency_penalty_with_value": m13,
    "from_model": MessageLookupByLibrary.simpleMessage("モデルから: %s"),
    "gallery": MessageLookupByLibrary.simpleMessage("ギャラリー"),
    "game_over": MessageLookupByLibrary.simpleMessage("ゲームオーバー！"),
    "generate": MessageLookupByLibrary.simpleMessage("生成"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("世界で最も難しい数独を生成"),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "ランダムな数独パズルを生成",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("生成中..."),
    "github_repository": MessageLookupByLibrary.simpleMessage("Githubリポジトリ"),
    "go_to_home_page": MessageLookupByLibrary.simpleMessage("ホームページへ"),
    "go_to_settings": MessageLookupByLibrary.simpleMessage("設定に移動"),
    "got_it": MessageLookupByLibrary.simpleMessage("了解"),
    "hello_ask_me_anything": MessageLookupByLibrary.simpleMessage(
      "こんにちは、\n何でも聞いてください...",
    ),
    "hide_stack": MessageLookupByLibrary.simpleMessage("思考チェーンスタックを隠す"),
    "hide_translations": MessageLookupByLibrary.simpleMessage("翻訳を非表示"),
    "hint_chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "デフォルトでは\'<think>好的\'を使用します。2025-09-21より前にリリースされたモデルでは、自動的に\'<think>嗯\'が使用されます",
    ),
    "hint_system_prompt": MessageLookupByLibrary.simpleMessage(
      "例：System: あなたは強力なRWKV大規模言語モデルで、常にユーザーの質問に辛抱強く答えます。",
    ),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "長押しで録音、離して送信",
    ),
    "home": MessageLookupByLibrary.simpleMessage("ホーム"),
    "http_service_port": m14,
    "human": MessageLookupByLibrary.simpleMessage("人間"),
    "hyphen": MessageLookupByLibrary.simpleMessage("-"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage(
      "RWKVに言わせたいのは...",
    ),
    "idle": MessageLookupByLibrary.simpleMessage("待機中"),
    "imitate": m15,
    "imitate_fle": m16,
    "imitate_target": MessageLookupByLibrary.simpleMessage("使用"),
    "import_all_weight_files": MessageLookupByLibrary.simpleMessage(
      "すべての重みファイルをインポート",
    ),
    "import_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "このアプリからエクスポートされたZIPファイルを選択してください。ZIPファイル内のすべての重みファイルがインポートされます。同じ名前のファイルが存在する場合、既存のファイルが上書きされます。",
    ),
    "import_all_weight_files_success": m17,
    "import_failed": MessageLookupByLibrary.simpleMessage("インポート失敗"),
    "import_success": MessageLookupByLibrary.simpleMessage("インポート成功"),
    "import_weight_file": MessageLookupByLibrary.simpleMessage("重みファイルをインポート"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage(
          "検索深度と検索幅の両方が2より大きい場合、インコンテキスト検索がアクティブになります",
        ),
    "inference_engine": MessageLookupByLibrary.simpleMessage("推論エンジン"),
    "inference_is_done": MessageLookupByLibrary.simpleMessage("🎉 推論完了"),
    "inference_is_running": MessageLookupByLibrary.simpleMessage("推論中"),
    "input_chinese_text_here": MessageLookupByLibrary.simpleMessage(
      "ここに中国語のテキストを入力",
    ),
    "input_english_text_here": MessageLookupByLibrary.simpleMessage(
      "ここに英語のテキストを入力",
    ),
    "intonations": MessageLookupByLibrary.simpleMessage("イントネーション"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "RWKV v7 シリーズ大規模言語モデル（0.1B/0.4B/1.5B/2.9Bパラメータバージョンを含む）をぜひお試しください。モバイルデバイスに最適化されており、ロード後は完全にオフラインで動作し、サーバーとの通信は不要です。",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("無効な数独"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("無効な値"),
    "invalid_zip_file": MessageLookupByLibrary.simpleMessage(
      "無効なZIPファイルまたはファイル形式が認識されません",
    ),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("あなたの番です〜"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "Discordサーバーに参加",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage("コミュニティに参加"),
    "just_watch_me": MessageLookupByLibrary.simpleMessage(
      "😎 私のパフォーマンスを見てください！",
    ),
    "lambada_test": MessageLookupByLibrary.simpleMessage("LAMBADA テスト"),
    "lan_server": MessageLookupByLibrary.simpleMessage("LANサーバー"),
    "large": MessageLookupByLibrary.simpleMessage("大 (120%)"),
    "latest_version": MessageLookupByLibrary.simpleMessage("最新バージョン"),
    "lazy": MessageLookupByLibrary.simpleMessage("怠惰"),
    "lazy_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "怠惰な思考モードテンプレート",
    ),
    "license": MessageLookupByLibrary.simpleMessage("オープンソースライセンス"),
    "life_span": MessageLookupByLibrary.simpleMessage("Life Span"),
    "light_mode": MessageLookupByLibrary.simpleMessage("ライトモード"),
    "line_break_rendered": MessageLookupByLibrary.simpleMessage("改行文字が表示されました"),
    "load_": MessageLookupByLibrary.simpleMessage("ロード"),
    "load_data": MessageLookupByLibrary.simpleMessage("データをロード"),
    "loaded": MessageLookupByLibrary.simpleMessage("ロード済み"),
    "loading": MessageLookupByLibrary.simpleMessage("ロード中..."),
    "local_folder_name": m18,
    "local_pth_files_section_title": MessageLookupByLibrary.simpleMessage(
      "ローカル .pth ファイル",
    ),
    "local_pth_option_files_in_config": MessageLookupByLibrary.simpleMessage(
      "設定ファイルの重み",
    ),
    "local_pth_option_local_pth_files": MessageLookupByLibrary.simpleMessage(
      "ローカル .pth ファイル",
    ),
    "local_pth_you_can_select": MessageLookupByLibrary.simpleMessage(
      "ローカルの .pth ファイルを選択して読み込めます",
    ),
    "medium": MessageLookupByLibrary.simpleMessage("中 (110%)"),
    "memory_used": m19,
    "message_content": MessageLookupByLibrary.simpleMessage("メッセージ内容"),
    "message_in_queue": m20,
    "mode": MessageLookupByLibrary.simpleMessage("モード"),
    "model": MessageLookupByLibrary.simpleMessage("モデル"),
    "model_loading": MessageLookupByLibrary.simpleMessage("モデルを読み込み中..."),
    "model_output": m21,
    "model_settings": MessageLookupByLibrary.simpleMessage("モデル設定"),
    "model_size_increased_please_open_a_new_conversation":
        MessageLookupByLibrary.simpleMessage(
          "モデルサイズが大きくなりました。会話の品質を向上させるために、新しい会話を開始してください",
        ),
    "monospace_font_setting": MessageLookupByLibrary.simpleMessage("等幅フォント設定"),
    "more": MessageLookupByLibrary.simpleMessage("その他"),
    "more_questions": MessageLookupByLibrary.simpleMessage("その他の質問"),
    "moving_files": MessageLookupByLibrary.simpleMessage("ファイルを移動中..."),
    "multi_thread": MessageLookupByLibrary.simpleMessage("マルチスレッド"),
    "my_voice": MessageLookupByLibrary.simpleMessage("私の声"),
    "neko": MessageLookupByLibrary.simpleMessage("ネコ"),
    "network_error": MessageLookupByLibrary.simpleMessage("ネットワークエラー"),
    "new_chat": MessageLookupByLibrary.simpleMessage("新しいチャット"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("新しいチャットを開始しました"),
    "new_chat_template": MessageLookupByLibrary.simpleMessage("新しいチャットテンプレート"),
    "new_chat_template_helper_text": MessageLookupByLibrary.simpleMessage(
      "これは新しい会話ごとに2つの改行で区切られて挿入されます。例：\nこんにちは、あなたは誰ですか？\n\nこんにちは、私はRWKVです。何かお手伝いできることはありますか？",
    ),
    "new_conversation": MessageLookupByLibrary.simpleMessage("新しい会話"),
    "new_game": MessageLookupByLibrary.simpleMessage("新しいゲーム"),
    "new_version_available": MessageLookupByLibrary.simpleMessage(
      "新しいバージョンが利用可能です",
    ),
    "new_version_found": MessageLookupByLibrary.simpleMessage("新バージョンが見つかりました"),
    "no_audio_file": MessageLookupByLibrary.simpleMessage("音声ファイルがありません"),
    "no_browser_windows_connected": MessageLookupByLibrary.simpleMessage(
      "接続されているブラウザウィンドウはありません",
    ),
    "no_cell_available": MessageLookupByLibrary.simpleMessage("置けるマスがありません"),
    "no_conversation_yet": MessageLookupByLibrary.simpleMessage("まだ会話はありません"),
    "no_conversations_yet": MessageLookupByLibrary.simpleMessage("まだ会話はありません"),
    "no_data": MessageLookupByLibrary.simpleMessage("データなし"),
    "no_files_in_zip": MessageLookupByLibrary.simpleMessage(
      "ZIPファイル内に有効な重みファイルが見つかりませんでした",
    ),
    "no_latest_version_info": MessageLookupByLibrary.simpleMessage(
      "最新バージョン情報がありません",
    ),
    "no_local_folders": MessageLookupByLibrary.simpleMessage(
      ".pth ファイルを含むローカルフォルダをまだ追加していません",
    ),
    "no_local_pth_loaded_yet": MessageLookupByLibrary.simpleMessage(
      "読み込み済みのローカル .pth ファイルはありません",
    ),
    "no_message_to_export": MessageLookupByLibrary.simpleMessage(
      "エクスポートするメッセージがありません",
    ),
    "no_model_selected": MessageLookupByLibrary.simpleMessage("モデルが選択されていません"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("数独なし"),
    "no_weight_files_guide_message": MessageLookupByLibrary.simpleMessage(
      "まだ重みファイルをダウンロードしていません。ホームページに移動してダウンロードし、アプリを体験してください。",
    ),
    "no_weight_files_guide_title": MessageLookupByLibrary.simpleMessage(
      "重みファイルがありません",
    ),
    "no_weight_files_to_export": MessageLookupByLibrary.simpleMessage(
      "エクスポートする重みファイルがありません",
    ),
    "not_all_the_same": MessageLookupByLibrary.simpleMessage("すべて同じではない"),
    "not_syncing": MessageLookupByLibrary.simpleMessage("非同期"),
    "npu_not_supported_title": m22,
    "number": MessageLookupByLibrary.simpleMessage("数字"),
    "nyan_nyan": MessageLookupByLibrary.simpleMessage("にゃん~~、にゃん~~"),
    "ocr_guide_text": m23,
    "ocr_title": MessageLookupByLibrary.simpleMessage("OCR"),
    "off": MessageLookupByLibrary.simpleMessage("オフ"),
    "offline_translator": MessageLookupByLibrary.simpleMessage("オフライン翻訳"),
    "offline_translator_detail": MessageLookupByLibrary.simpleMessage(
      "デバイス上でテキストを翻訳",
    ),
    "offline_translator_server": MessageLookupByLibrary.simpleMessage(
      "オフライン翻訳サーバー",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "open_containing_folder": MessageLookupByLibrary.simpleMessage(
      "保存先フォルダを開く",
    ),
    "open_database_folder": MessageLookupByLibrary.simpleMessage(
      "データベースフォルダを開く",
    ),
    "open_debug_log_panel": MessageLookupByLibrary.simpleMessage(
      "デバッグログパネルを開く",
    ),
    "open_folder": MessageLookupByLibrary.simpleMessage("フォルダを開く"),
    "open_state_panel": MessageLookupByLibrary.simpleMessage("状態パネルを開く"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage(
          "または、RWKVにコピーさせるためにwavファイルを選択できます。",
        ),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "または、新しい空のチャットを開始できます",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV オセロ"),
    "other_files": MessageLookupByLibrary.simpleMessage(
      "その他のファイル (これらのファイルは期限切れまたはサポートされなくなった重みファイルであり、RWKV Chat ではもう使用されていない可能性があります)",
    ),
    "output": MessageLookupByLibrary.simpleMessage("出力"),
    "overseas": MessageLookupByLibrary.simpleMessage("(海外)"),
    "overwrite": MessageLookupByLibrary.simpleMessage("上書き"),
    "overwrite_file_confirmation": MessageLookupByLibrary.simpleMessage(
      "ファイルは既に存在します。上書きしますか？",
    ),
    "parameter_description": MessageLookupByLibrary.simpleMessage("パラメータ説明"),
    "parameter_description_detail": MessageLookupByLibrary.simpleMessage(
      "Temperature: 出力のランダム性を制御します。高い値（例: 0.8）はより創造的でランダムに、低い値（例: 0.2）はより集中的で決定的になります。\n\nTop P: 出力の多様性を制御します。モデルは累積確率がTop Pに達するトークンのみを考慮します。低い値（例: 0.5）は低確率の単語を無視し、関連性を高めます。\n\nPresence Penalty: トークンがテキスト内に既に出現しているかどうかに基づいてペナルティを与えます。正の値は新しいトピックについて話す可能性を高めます。\n\nFrequency Penalty: テキスト内での出現頻度に基づいてペナルティを与えます。正の値は同じ行を逐語的に繰り返す可能性を減らします。\n\nPenalty Decay: 距離に応じたペナルティの減衰を制御します。",
    ),
    "path_label": m24,
    "pause": MessageLookupByLibrary.simpleMessage("一時停止"),
    "penalty_decay_with_value": m25,
    "performance_test": MessageLookupByLibrary.simpleMessage("パフォーマンステスト"),
    "performance_test_description": MessageLookupByLibrary.simpleMessage(
      "速度と精度をテスト",
    ),
    "perplexity": MessageLookupByLibrary.simpleMessage("困惑度"),
    "players": MessageLookupByLibrary.simpleMessage("プレイヤー"),
    "playing_partial_generated_audio": MessageLookupByLibrary.simpleMessage(
      "部分的に生成された音声を再生中",
    ),
    "please_check_the_result": MessageLookupByLibrary.simpleMessage(
      "結果を確認してください",
    ),
    "please_enter_a_number_0_means_empty": MessageLookupByLibrary.simpleMessage(
      "数字を入力してください。0は空を意味します。",
    ),
    "please_enter_conversation_name": MessageLookupByLibrary.simpleMessage(
      "会話名を入力してください",
    ),
    "please_enter_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "難易度を入力してください",
    ),
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage("マイクの使用許可を付与してください"),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage(
      "まずモデルをロードしてください",
    ),
    "please_manually_migrate_files": MessageLookupByLibrary.simpleMessage(
      "パスを更新しました。ファイルの移動が必要な場合は手動で行ってください。",
    ),
    "please_select_a_branch_to_continue_the_conversation":
        MessageLookupByLibrary.simpleMessage("会話を続けるにはブランチを選択してください"),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "タスクの種類を選択してください",
    ),
    "please_select_an_image_first": MessageLookupByLibrary.simpleMessage(
      "まず画像を選択してください",
    ),
    "please_select_an_image_from_the_following_options":
        MessageLookupByLibrary.simpleMessage("以下のオプションから画像を選択してください"),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "アプリケーション言語を選択してください",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage(
      "フォントサイズを選択してください",
    ),
    "please_select_model": MessageLookupByLibrary.simpleMessage("モデルを選択してください"),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "難易度を選択してください",
    ),
    "please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index":
        m26,
    "please_select_the_sampler_and_penalty_parameters_to_set_for_all_messages":
        MessageLookupByLibrary.simpleMessage(
          "すべてのメッセージに設定するサンプラーとペナルティパラメータを選択してください",
        ),
    "please_wait_for_it_to_finish": MessageLookupByLibrary.simpleMessage(
      "推論の完了を待ってください",
    ),
    "please_wait_for_the_model_to_finish_generating":
        MessageLookupByLibrary.simpleMessage("モデルの生成完了を待ってください"),
    "please_wait_for_the_model_to_generate":
        MessageLookupByLibrary.simpleMessage("モデルの生成を待ってください"),
    "please_wait_for_the_model_to_load": MessageLookupByLibrary.simpleMessage(
      "モデルのロードを待ってください",
    ),
    "power_user": MessageLookupByLibrary.simpleMessage("パワーユーザー"),
    "prebuilt": MessageLookupByLibrary.simpleMessage("プリセット"),
    "prebuilt_models_intro": MessageLookupByLibrary.simpleMessage(
      "以下は RWKV Chat が事前に量子化したモデルです",
    ),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("プリセット音声"),
    "prefer": MessageLookupByLibrary.simpleMessage("使用"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("中国語での推論を使用"),
    "prefill": MessageLookupByLibrary.simpleMessage("事前入力"),
    "presence_penalty_with_value": m27,
    "prompt": MessageLookupByLibrary.simpleMessage("プロンプト"),
    "prompt_template": MessageLookupByLibrary.simpleMessage("プロンプトテンプレート"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQグループ1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQグループ2"),
    "queued_x": m28,
    "quick_thinking": MessageLookupByLibrary.simpleMessage("高速思考"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage(
      "高速思考が有効になりました",
    ),
    "reached_bottom": MessageLookupByLibrary.simpleMessage("お楽しみに"),
    "real_time_update": MessageLookupByLibrary.simpleMessage("リアルタイム更新"),
    "reason": MessageLookupByLibrary.simpleMessage("推論"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("推論モード"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("音声を録音中..."),
    "reference_source": MessageLookupByLibrary.simpleMessage("参照元"),
    "refresh": MessageLookupByLibrary.simpleMessage("更新"),
    "refresh_complete": MessageLookupByLibrary.simpleMessage("更新完了"),
    "refreshed": MessageLookupByLibrary.simpleMessage("更新"),
    "regenerate": MessageLookupByLibrary.simpleMessage("再生成"),
    "remaining": MessageLookupByLibrary.simpleMessage("残り時間："),
    "rename": MessageLookupByLibrary.simpleMessage("名前を変更"),
    "report_an_issue_on_github": MessageLookupByLibrary.simpleMessage(
      "Githubで問題を報告",
    ),
    "reselect_model": MessageLookupByLibrary.simpleMessage("モデルを再選択"),
    "reset": MessageLookupByLibrary.simpleMessage("リセット"),
    "reset_to_default": MessageLookupByLibrary.simpleMessage("デフォルトに戻す"),
    "reset_to_default_directory": MessageLookupByLibrary.simpleMessage(
      "デフォルトディレクトリに戻しました",
    ),
    "restore_default": MessageLookupByLibrary.simpleMessage("デフォルトに戻す"),
    "result": MessageLookupByLibrary.simpleMessage("結果"),
    "resume": MessageLookupByLibrary.simpleMessage("再開"),
    "role_play": MessageLookupByLibrary.simpleMessage("ロールプレイ"),
    "role_play_intro": MessageLookupByLibrary.simpleMessage("お気に入りのキャラクターを演じる"),
    "runtime_log_panel": MessageLookupByLibrary.simpleMessage("実行ログパネル"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV チャット"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV オセロ"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("QRコードをスキャン"),
    "scanning_folder_for_pth": MessageLookupByLibrary.simpleMessage(
      "このフォルダ内の .pth ファイルをスキャン中",
    ),
    "screen_width": MessageLookupByLibrary.simpleMessage("画面幅"),
    "search": MessageLookupByLibrary.simpleMessage("検索"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("検索幅"),
    "search_depth": MessageLookupByLibrary.simpleMessage("検索深度"),
    "search_failed": MessageLookupByLibrary.simpleMessage("検索に失敗しました"),
    "searching": MessageLookupByLibrary.simpleMessage("検索中..."),
    "see": MessageLookupByLibrary.simpleMessage("画像Q&A"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("モデルを選択"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("タスクの種類を選択"),
    "select_all": MessageLookupByLibrary.simpleMessage("すべて選択"),
    "select_from_file": MessageLookupByLibrary.simpleMessage("画像ファイルを選択"),
    "select_from_library": MessageLookupByLibrary.simpleMessage("ライブラリから選択"),
    "select_image": MessageLookupByLibrary.simpleMessage("画像を選択"),
    "select_local_pth_file_button": MessageLookupByLibrary.simpleMessage(
      "ローカル .pth ファイルを選択",
    ),
    "select_model": MessageLookupByLibrary.simpleMessage("モデルを選択"),
    "select_new_image": MessageLookupByLibrary.simpleMessage("画像を選択"),
    "select_the_decode_parameters_to_set_all_to_for_index":
        MessageLookupByLibrary.simpleMessage(
          "以下からプリセットを選択するか、「カスタム」をタップして手動で設定してください",
        ),
    "select_weights_or_local_pth_hint": MessageLookupByLibrary.simpleMessage(
      "設定ファイルの重みまたはローカル .pth ファイルを選択",
    ),
    "selected_count": m29,
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage(
      "RWKVにメッセージを送信",
    ),
    "server_error": MessageLookupByLibrary.simpleMessage("サーバーエラー"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("セッション構成"),
    "set_all_batch_params": MessageLookupByLibrary.simpleMessage(
      "すべてのバッチパラメータを設定",
    ),
    "set_all_to_question_mark": MessageLookupByLibrary.simpleMessage(
      "すべて???に設定",
    ),
    "set_custom_directory": MessageLookupByLibrary.simpleMessage(
      "カスタムディレクトリを設定",
    ),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("グリッドの値を設定"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "share": MessageLookupByLibrary.simpleMessage("共有"),
    "share_chat": MessageLookupByLibrary.simpleMessage("チャットを共有"),
    "show_escape_characters": MessageLookupByLibrary.simpleMessage("改行文字を表示"),
    "show_prefill_log_only": MessageLookupByLibrary.simpleMessage(
      "Prefill ログのみ表示",
    ),
    "show_stack": MessageLookupByLibrary.simpleMessage("思考チェーンスタックを表示"),
    "show_translations": MessageLookupByLibrary.simpleMessage("翻訳を表示"),
    "single_thread": MessageLookupByLibrary.simpleMessage("シングルスレッド"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "少なくとも1.5Bモデルを選択することをお勧めします。より大きい2.9Bモデルの方が優れています。",
    ),
    "skip_this_version": MessageLookupByLibrary.simpleMessage("このバージョンをスキップ"),
    "small": MessageLookupByLibrary.simpleMessage("小さい (90%)"),
    "source_code": MessageLookupByLibrary.simpleMessage("ソースコード"),
    "source_text": m30,
    "speed": MessageLookupByLibrary.simpleMessage("ダウンロード速度："),
    "start": MessageLookupByLibrary.simpleMessage("開始"),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage("新しいチャットを開始"),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage("下のボタンをクリックして新しいチャットを開始"),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("ゲーム開始"),
    "start_download_updates_": MessageLookupByLibrary.simpleMessage(
      "アップデートのバックグラウンドダウンロードを開始...",
    ),
    "start_service": MessageLookupByLibrary.simpleMessage("サービスを開始"),
    "start_service_and_open_browser": MessageLookupByLibrary.simpleMessage(
      "サービスを開始し、サポートされているブラウザページを開いてください。",
    ),
    "start_test": MessageLookupByLibrary.simpleMessage("テスト開始"),
    "start_testing": MessageLookupByLibrary.simpleMessage("テストを開始"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("チャットを開始"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("推論を開始"),
    "starting": MessageLookupByLibrary.simpleMessage("開始中..."),
    "state_list": MessageLookupByLibrary.simpleMessage("State リスト"),
    "state_panel": MessageLookupByLibrary.simpleMessage("状態パネル"),
    "status": MessageLookupByLibrary.simpleMessage("ステータス"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "stop_service": MessageLookupByLibrary.simpleMessage("サービスを停止"),
    "stop_test": MessageLookupByLibrary.simpleMessage("テスト停止"),
    "stopping": MessageLookupByLibrary.simpleMessage("停止中..."),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "ストレージ権限が許可されていません",
    ),
    "str_downloading_info": MessageLookupByLibrary.simpleMessage(
      "ダウンロード %.1f% 速度 %.1fMB/s 残り %s",
    ),
    "str_model_selection_dialog_hint": MessageLookupByLibrary.simpleMessage(
      "少なくとも1.5Bモデルを選択することをお勧めします。より大きい2.9Bモデルの方が優れています。",
    ),
    "str_please_disable_battery_opt_": MessageLookupByLibrary.simpleMessage(
      "バックグラウンドでのダウンロードを許可するには、バッテリーの最適化を無効にしてください。そうしないと、他のアプリに切り替えたときにダウンロードが一時停止することがあります。",
    ),
    "str_please_select_app_mode_": MessageLookupByLibrary.simpleMessage(
      "AIとLLMの習熟度に応じてアプリモードを選択してください。",
    ),
    "style": MessageLookupByLibrary.simpleMessage("スタイル"),
    "submit": MessageLookupByLibrary.simpleMessage("送信"),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("入門"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("エキスパート"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("普通"),
    "suggest": MessageLookupByLibrary.simpleMessage("提案"),
    "switch_to_creative_mode_for_better_exp":
        MessageLookupByLibrary.simpleMessage(
          "より良い体験のために「クリエイティブモード」への切り替えをお勧めします",
        ),
    "syncing": MessageLookupByLibrary.simpleMessage("同期中"),
    "system_mode": MessageLookupByLibrary.simpleMessage("システムに従う"),
    "system_prompt": MessageLookupByLibrary.simpleMessage("システムプロンプト"),
    "take_photo": MessageLookupByLibrary.simpleMessage("写真を撮る"),
    "target_text": m31,
    "technical_research_group": MessageLookupByLibrary.simpleMessage(
      "技術研究グループ",
    ),
    "temperature_with_value": m32,
    "test_data": MessageLookupByLibrary.simpleMessage("テストデータ"),
    "test_result": MessageLookupByLibrary.simpleMessage("テスト結果"),
    "test_results": MessageLookupByLibrary.simpleMessage("テスト結果"),
    "testing": MessageLookupByLibrary.simpleMessage("テスト中..."),
    "text": MessageLookupByLibrary.simpleMessage("テキスト"),
    "text_completion_mode": MessageLookupByLibrary.simpleMessage("テキスト補完モード"),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage("数独が無効です"),
    "theme_dim": MessageLookupByLibrary.simpleMessage("暗い"),
    "theme_light": MessageLookupByLibrary.simpleMessage("明るい"),
    "theme_lights_out": MessageLookupByLibrary.simpleMessage("黒"),
    "then_you_can_start_to_chat_with_rwkv":
        MessageLookupByLibrary.simpleMessage("これでRWKVとのチャットを開始できます"),
    "think_button_mode_en": m33,
    "think_button_mode_en_long": m34,
    "think_button_mode_en_short": m35,
    "think_button_mode_fast": m36,
    "think_mode_selector_message": MessageLookupByLibrary.simpleMessage(
      "推論モードは、モデルの推論時のパフォーマンスに影響します",
    ),
    "think_mode_selector_title": MessageLookupByLibrary.simpleMessage(
      "推論モードを選択してください",
    ),
    "thinking": MessageLookupByLibrary.simpleMessage("思考中..."),
    "thinking_mode_alert_footer": MessageLookupByLibrary.simpleMessage("モード"),
    "thinking_mode_auto": m37,
    "thinking_mode_high": m38,
    "thinking_mode_off": m39,
    "thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "思考モードテンプレート",
    ),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("これは世界で最も難しい数独です"),
    "this_model_does_not_support_batch_inference":
        MessageLookupByLibrary.simpleMessage(
          "このモデルは並列推論をサポートしていません。「batch」タグのあるモデルを選択してください",
        ),
    "thought_result": MessageLookupByLibrary.simpleMessage("思考結果"),
    "top_p_with_value": m40,
    "total_count": MessageLookupByLibrary.simpleMessage("総数"),
    "total_disk_usage": MessageLookupByLibrary.simpleMessage("合計ディスク使用量"),
    "total_test_items": m41,
    "translate": MessageLookupByLibrary.simpleMessage("翻訳"),
    "translating": MessageLookupByLibrary.simpleMessage("翻訳中..."),
    "translation": MessageLookupByLibrary.simpleMessage("翻訳"),
    "translator_debug_info": MessageLookupByLibrary.simpleMessage("翻訳者デバッグ情報"),
    "tts": MessageLookupByLibrary.simpleMessage("テキスト読み上げ"),
    "tts_detail": MessageLookupByLibrary.simpleMessage("RWKVに音声を出力させる"),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("ターンの移行"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ui_font_setting": MessageLookupByLibrary.simpleMessage("UI フォント設定"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("超大 (140%)"),
    "unknown": MessageLookupByLibrary.simpleMessage("不明"),
    "unzipping": MessageLookupByLibrary.simpleMessage("展開中"),
    "update_now": MessageLookupByLibrary.simpleMessage("今すぐ更新"),
    "updated_at": MessageLookupByLibrary.simpleMessage("更新日時"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("今すぐ使用"),
    "user": MessageLookupByLibrary.simpleMessage("ユーザー："),
    "using_custom_directory": MessageLookupByLibrary.simpleMessage(
      "カスタムディレクトリを使用中",
    ),
    "using_default_directory": MessageLookupByLibrary.simpleMessage(
      "デフォルトディレクトリを使用中",
    ),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "値は0から9の間である必要があります",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("非常に小さい (80%)"),
    "visual_understanding_and_ocr": MessageLookupByLibrary.simpleMessage(
      "視覚理解とOCR",
    ),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("音声クローン"),
    "we_support_npu_socs": MessageLookupByLibrary.simpleMessage(
      "現在、以下の SoC チップの NPU に対応しています",
    ),
    "web_search": MessageLookupByLibrary.simpleMessage("ネットワーク検索"),
    "web_search_template": MessageLookupByLibrary.simpleMessage("ウェブ検索テンプレート"),
    "websocket_service_port": m42,
    "weights_mangement": MessageLookupByLibrary.simpleMessage("重みファイル管理"),
    "weights_saving_directory": MessageLookupByLibrary.simpleMessage(
      "重みファイル保存ディレクトリ",
    ),
    "welcome_to_rwkv_chat": MessageLookupByLibrary.simpleMessage(
      "RWKVチャットへようこそ",
    ),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage("RWKVへようこそ"),
    "what_is_pth_file_message": MessageLookupByLibrary.simpleMessage(
      ".pth ファイルはダウンロードサーバーを経由せず、ローカルファイルシステムから直接読み込む重みファイルです。\n\nPyTorch で訓練したモデルは通常 .pth ファイルとして保存されます。\n\nRWKV Chat は .pth ファイルの読み込みに対応しています。",
    ),
    "what_is_pth_file_title": MessageLookupByLibrary.simpleMessage(
      ".pth ファイルとは？",
    ),
    "white": MessageLookupByLibrary.simpleMessage("白"),
    "white_score": MessageLookupByLibrary.simpleMessage("白のスコア"),
    "white_wins": MessageLookupByLibrary.simpleMessage("白の勝ち！"),
    "window_id": m43,
    "world": MessageLookupByLibrary.simpleMessage("See"),
    "x_message_selected": MessageLookupByLibrary.simpleMessage(
      "%d件のメッセージが選択されました",
    ),
    "x_pages_found": MessageLookupByLibrary.simpleMessage("%dページ見つかりました"),
    "x_tabs": m44,
    "you_are_now_using": m45,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "これでRWKVとのチャットを開始できます",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("音声を録音して、RWKVにそれをコピーさせることができます。"),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "チャットする役割を選択できます",
    ),
    "your_device": MessageLookupByLibrary.simpleMessage("お使いのデバイス："),
    "your_voice_is_empty": MessageLookupByLibrary.simpleMessage(
      "音声データが空です。マイクを確認してください",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "音声が短すぎます。ボタンを長く押して音声を録音してください。",
    ),
    "zh_to_en": MessageLookupByLibrary.simpleMessage("中->英"),
  };
}
