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

  static String m4(demoName) => "${demoName}へようこそ";

  static String m5(maxLength) => "会話名は${maxLength}文字を超えることはできません";

  static String m6(path) => "メッセージ履歴は以下のフォルダに保存されます:\n ${path}";

  static String m8(flag, nameCN, nameEN) =>
      "${flag} ${nameCN}(${nameEN})の音声を模倣";

  static String m9(fileName) => "${fileName}を模倣";

  static String m10(memUsed, memFree) => "使用メモリ：${memUsed}、残りメモリ：${memFree}";

  static String m15(modelName) => "現在、${modelName}を使用しています";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("について"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("以下に基づいて："),
    "all": MessageLookupByLibrary.simpleMessage("すべて"),
    "all_done": MessageLookupByLibrary.simpleMessage("すべて完了"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("すべてのプロンプト"),
    "appearance": MessageLookupByLibrary.simpleMessage("外観"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "アプリケーション内部テストグループ",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("アプリケーション言語"),
    "application_settings": MessageLookupByLibrary.simpleMessage("アプリケーション設定"),
    "apply": MessageLookupByLibrary.simpleMessage("適用"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage("このモデルを削除してもよろしいですか？"),
    "auto": MessageLookupByLibrary.simpleMessage("自動"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("チャットに戻る"),
    "black": MessageLookupByLibrary.simpleMessage("黒"),
    "black_score": MessageLookupByLibrary.simpleMessage("黒のスコア"),
    "black_wins": MessageLookupByLibrary.simpleMessage("黒の勝ち！"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "ボットメッセージが編集されました。新しいメッセージを送信できます。",
    ),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("生成できません"),
    "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("ダウンロードをキャンセル"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("今すぐ更新しない"),
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
    "chat_welcome_to_use": m4,
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage("使用するには、まずモデルをダウンロードする必要があります"),
    "chatting": MessageLookupByLibrary.simpleMessage("チャット中"),
    "chinese": MessageLookupByLibrary.simpleMessage("中国語"),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage(
      "プリセットキャラクターを選択",
    ),
    "clear": MessageLookupByLibrary.simpleMessage("クリア"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "ここをクリックして新しいモデルを選択",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "ここをクリックして新しいチャットを開始",
    ),
    "click_to_load_image": MessageLookupByLibrary.simpleMessage("画像をクリックしてロード"),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage(
      "モデルを選択するにはクリック",
    ),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "カラーテーマはシステムに従う",
    ),
    "completion_mode": MessageLookupByLibrary.simpleMessage("補完モード"),
    "confirm": MessageLookupByLibrary.simpleMessage("確認"),
    "continue_download": MessageLookupByLibrary.simpleMessage("ダウンロードを続行"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "より小さいモデルの使用を続行",
    ),
    "conversation_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "会話名は空にできません",
    ),
    "conversation_name_cannot_be_longer_than_30_characters": m5,
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("上のボタンをクリックして新しいセッションを作成"),
    "current_turn": MessageLookupByLibrary.simpleMessage("現在のターン"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage("カスタム難易度"),
    "dark_mode": MessageLookupByLibrary.simpleMessage("ダークモード"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage("ダークモードテーマ"),
    "decode": MessageLookupByLibrary.simpleMessage("デコード"),
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
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "download_all": MessageLookupByLibrary.simpleMessage("すべてダウンロード"),
    "download_app": MessageLookupByLibrary.simpleMessage("アプリをダウンロード"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage(
      "ブラウザからダウンロード",
    ),
    "download_missing": MessageLookupByLibrary.simpleMessage(
      "不足しているファイルをダウンロード",
    ),
    "download_model": MessageLookupByLibrary.simpleMessage("モデルをダウンロード"),
    "download_server_": MessageLookupByLibrary.simpleMessage(
      "ダウンロードサーバー（どれが速いか試してください）",
    ),
    "download_source": MessageLookupByLibrary.simpleMessage("ダウンロード元"),
    "downloading": MessageLookupByLibrary.simpleMessage("ダウンロード中"),
    "draw": MessageLookupByLibrary.simpleMessage("引き分け！"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage("自動ダンプメッセージ履歴"),
    "dump_see_files_alert_message": m6,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage(
      "アルゴリズム改善にご協力ください",
    ),
    "dump_started": MessageLookupByLibrary.simpleMessage("自動ダンプが開始されました"),
    "dump_stopped": MessageLookupByLibrary.simpleMessage("自動ダンプが停止しました"),
    "end": MessageLookupByLibrary.simpleMessage("終"),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage(
          "デバイスのメモリが十分であることを確認してください。そうでない場合、アプリケーションがクラッシュする可能性があります。",
        ),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("RWKVを探索"),
    "exploring": MessageLookupByLibrary.simpleMessage("探索中..."),
    "export_data": MessageLookupByLibrary.simpleMessage("データのエクスポート"),
    "extra_large": MessageLookupByLibrary.simpleMessage("特大 (130%)"),
    "feedback": MessageLookupByLibrary.simpleMessage("フィードバック"),
    "filter": MessageLookupByLibrary.simpleMessage(
      "こんにちは、この質問にはまだお答えできません。別の話題について話しましょう。",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("録音完了"),
    "follow_system": MessageLookupByLibrary.simpleMessage("システムに従う"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "Twitterでフォロー",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("フォント設定"),
    "font_size": MessageLookupByLibrary.simpleMessage("フォントサイズ"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("デフォルト (100%)"),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage("強制ダークモード"),
    "from_model": MessageLookupByLibrary.simpleMessage("モデルから: %s"),
    "game_over": MessageLookupByLibrary.simpleMessage("ゲームオーバー！"),
    "generate": MessageLookupByLibrary.simpleMessage("生成"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("世界で最も難しい数独を生成"),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "ランダムな数独パズルを生成",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("生成中..."),
    "hide_stack": MessageLookupByLibrary.simpleMessage("思考チェーンスタックを隠す"),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "長押しで録音、離して送信",
    ),
    "human": MessageLookupByLibrary.simpleMessage("人間"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage(
      "RWKVに言わせたいのは...",
    ),
    "imitate": m8,
    "imitate_fle": m9,
    "imitate_target": MessageLookupByLibrary.simpleMessage("使用"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage(
          "検索深度と検索幅の両方が2より大きい場合、インコンテキスト検索がアクティブになります",
        ),
    "inference_is_done": MessageLookupByLibrary.simpleMessage("🎉 推論完了"),
    "inference_is_running": MessageLookupByLibrary.simpleMessage("推論中"),
    "intonations": MessageLookupByLibrary.simpleMessage("イントネーション"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "RWKV v7 シリーズ大規模言語モデル（0.1B/0.4B/1.5B/2.9Bパラメータバージョンを含む）をぜひお試しください。モバイルデバイスに最適化されており、ロード後は完全にオフラインで動作し、サーバーとの通信は不要です。",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("無効な数独"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("無効な値"),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("あなたの番です〜"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "Discordサーバーに参加",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage("コミュニティに参加"),
    "just_watch_me": MessageLookupByLibrary.simpleMessage(
      "😎 私のパフォーマンスを見てください！",
    ),
    "large": MessageLookupByLibrary.simpleMessage("大 (120%)"),
    "lazy": MessageLookupByLibrary.simpleMessage("怠惰"),
    "license": MessageLookupByLibrary.simpleMessage("オープンソースライセンス"),
    "light_mode": MessageLookupByLibrary.simpleMessage("ライトモード"),
    "loading": MessageLookupByLibrary.simpleMessage("ロード中..."),
    "medium": MessageLookupByLibrary.simpleMessage("中 (110%)"),
    "memory_used": m10,
    "model_settings": MessageLookupByLibrary.simpleMessage("モデル設定"),
    "more": MessageLookupByLibrary.simpleMessage("その他"),
    "my_voice": MessageLookupByLibrary.simpleMessage("私の声"),
    "network_error": MessageLookupByLibrary.simpleMessage("ネットワークエラー"),
    "new_chat": MessageLookupByLibrary.simpleMessage("新しいチャット"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("新しいチャットを開始しました"),
    "new_game": MessageLookupByLibrary.simpleMessage("新しいゲーム"),
    "new_version_found": MessageLookupByLibrary.simpleMessage("新バージョンが見つかりました"),
    "no_cell_available": MessageLookupByLibrary.simpleMessage("置けるマスがありません"),
    "no_data": MessageLookupByLibrary.simpleMessage("データなし"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("数独なし"),
    "number": MessageLookupByLibrary.simpleMessage("数字"),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage(
          "または、RWKVにコピーさせるためにwavファイルを選択できます。",
        ),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "または、新しい空のチャットを開始できます",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV オセロ"),
    "output": MessageLookupByLibrary.simpleMessage("出力"),
    "overseas": MessageLookupByLibrary.simpleMessage("(海外)"),
    "pause": MessageLookupByLibrary.simpleMessage("一時停止"),
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
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "タスクの種類を選択してください",
    ),
    "please_select_an_image_from_the_following_options":
        MessageLookupByLibrary.simpleMessage("以下のオプションから画像を選択してください"),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "アプリケーション言語を選択してください",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage(
      "フォントサイズを選択してください",
    ),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "難易度を選択してください",
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
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("プリセット音声"),
    "prefer": MessageLookupByLibrary.simpleMessage("使用"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("中国語での推論を使用"),
    "prefill": MessageLookupByLibrary.simpleMessage("事前入力"),
    "prompt": MessageLookupByLibrary.simpleMessage("プロンプト"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQグループ1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQグループ2"),
    "quick_thinking": MessageLookupByLibrary.simpleMessage("高速思考"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage(
      "高速思考が有効になりました",
    ),
    "reason": MessageLookupByLibrary.simpleMessage("推論"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("推論モード"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("音声を録音中..."),
    "regenerate": MessageLookupByLibrary.simpleMessage("再生成"),
    "remaining": MessageLookupByLibrary.simpleMessage("残り時間："),
    "rename": MessageLookupByLibrary.simpleMessage("名前を変更"),
    "reselect_model": MessageLookupByLibrary.simpleMessage("モデルを再選択"),
    "reset": MessageLookupByLibrary.simpleMessage("リセット"),
    "resume": MessageLookupByLibrary.simpleMessage("再開"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV チャット"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV オセロ"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("QRコードをスキャン"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("検索幅"),
    "search_depth": MessageLookupByLibrary.simpleMessage("検索深度"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("モデルを選択"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("タスクの種類を選択"),
    "select_from_library": MessageLookupByLibrary.simpleMessage("ライブラリから選択"),
    "select_image": MessageLookupByLibrary.simpleMessage("画像を選択"),
    "select_new_image": MessageLookupByLibrary.simpleMessage("新しい画像を選択"),
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage(
      "RWKVにメッセージを送信",
    ),
    "server_error": MessageLookupByLibrary.simpleMessage("サーバーエラー"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("セッション構成"),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("グリッドの値を設定"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "share": MessageLookupByLibrary.simpleMessage("共有"),
    "share_chat": MessageLookupByLibrary.simpleMessage("チャットを共有"),
    "show_stack": MessageLookupByLibrary.simpleMessage("思考チェーンスタックを表示"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "少なくとも1.5Bモデルを選択することをお勧めします。より大きい2.9Bモデルの方が優れています。",
    ),
    "small": MessageLookupByLibrary.simpleMessage("小さい (90%)"),
    "speed": MessageLookupByLibrary.simpleMessage("ダウンロード速度："),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage("新しいチャットを開始"),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage("下のボタンをクリックして新しいチャットを開始"),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("ゲーム開始"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("チャットを開始"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("推論を開始"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "ストレージ権限が許可されていません",
    ),
    "str_model_selection_dialog_hint": MessageLookupByLibrary.simpleMessage(
      "少なくとも1.5Bモデルを選択することをお勧めします。より大きい2.9Bモデルの方が優れています。",
    ),
    "submit": MessageLookupByLibrary.simpleMessage("送信"),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("入門"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("エキスパート"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("普通"),
    "system_mode": MessageLookupByLibrary.simpleMessage("システムに従う"),
    "take_photo": MessageLookupByLibrary.simpleMessage("写真を撮る"),
    "technical_research_group": MessageLookupByLibrary.simpleMessage(
      "技術研究グループ",
    ),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage("数独が無効です"),
    "theme_dim": MessageLookupByLibrary.simpleMessage("暗い"),
    "theme_light": MessageLookupByLibrary.simpleMessage("明るい"),
    "theme_lights_out": MessageLookupByLibrary.simpleMessage("黒"),
    "then_you_can_start_to_chat_with_rwkv":
        MessageLookupByLibrary.simpleMessage("これでRWKVとのチャットを開始できます"),
    "thinking": MessageLookupByLibrary.simpleMessage("思考中..."),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("これは世界で最も難しい数独です"),
    "thought_result": MessageLookupByLibrary.simpleMessage("思考結果"),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("ターンの移行"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("超大 (140%)"),
    "update_now": MessageLookupByLibrary.simpleMessage("今すぐ更新"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("今すぐ使用"),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "値は0から9の間である必要があります",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("非常に小さい (80%)"),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("音声クローン"),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage("RWKVへようこそ"),
    "white": MessageLookupByLibrary.simpleMessage("白"),
    "white_score": MessageLookupByLibrary.simpleMessage("白のスコア"),
    "white_wins": MessageLookupByLibrary.simpleMessage("白の勝ち！"),
    "x_message_selected": MessageLookupByLibrary.simpleMessage(
      "%d件のメッセージが選択されました",
    ),
    "you_are_now_using": m15,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "これでRWKVとのチャットを開始できます",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("音声を録音して、RWKVにそれをコピーさせることができます。"),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "チャットする役割を選択できます",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "音声が短すぎます。ボタンを長く押して音声を録音してください。",
    ),
  };
}
