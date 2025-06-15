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

  static String m0(demoName) => "${demoName} へようこそ";

  static String m2(flag, nameCN, nameEN) =>
      "${flag} ${nameCN}(${nameEN}) の声を模倣";

  static String m4(memUsed, memFree) => "使用済みメモリ：${memUsed}、空きメモリ：${memFree}";

  static String m5(modelName) => "現在 ${modelName} を使用しています";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("について"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("に基づいています："),
    "all_done": MessageLookupByLibrary.simpleMessage("すべて完了"),
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
      "ボットメッセージが編集されました。新しいメッセージを送信できます",
    ),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("生成できません"),
    "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("ダウンロードをキャンセル"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("今は更新しない"),
    "chat_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "クリップボードにコピーしました",
    ),
    "chat_empty_message": MessageLookupByLibrary.simpleMessage(
      "メッセージを入力してください",
    ),
    "chat_model_name": MessageLookupByLibrary.simpleMessage("モデル名"),
    "chat_please_select_a_model": MessageLookupByLibrary.simpleMessage(
      "モデルを選択してください",
    ),
    "chat_resume": MessageLookupByLibrary.simpleMessage("再開"),
    "chat_title": MessageLookupByLibrary.simpleMessage("RWKV チャット"),
    "chat_welcome_to_use": m0,
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage("使用するにはモデルをダウンロードする必要があります"),
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
    "click_to_select_model": MessageLookupByLibrary.simpleMessage(
      "クリックしてモデルを選択",
    ),
    "continue_download": MessageLookupByLibrary.simpleMessage("ダウンロードを続行"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "より小さなモデルを使い続ける",
    ),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("上記のボタンをクリックして新しいセッションを作成"),
    "current_turn": MessageLookupByLibrary.simpleMessage("現在のターン"),
    "decode": MessageLookupByLibrary.simpleMessage("デコード"),
    "delete": MessageLookupByLibrary.simpleMessage("削除"),
    "delete_all": MessageLookupByLibrary.simpleMessage("すべて削除"),
    "difficulty": MessageLookupByLibrary.simpleMessage("難易度"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "難易度は0より大きくなければなりません",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "難易度は81未満でなければなりません",
    ),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "download_all": MessageLookupByLibrary.simpleMessage("すべてダウンロード"),
    "download_missing": MessageLookupByLibrary.simpleMessage("不足ファイルをダウンロード"),
    "download_model": MessageLookupByLibrary.simpleMessage("モデルをダウンロード"),
    "download_source": MessageLookupByLibrary.simpleMessage("ダウンロード元"),
    "draw": MessageLookupByLibrary.simpleMessage("引き分け！"),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage(
          "デバイスに十分なメモリがあることを確認してください。そうでない場合、アプリケーションがクラッシュする可能性があります",
        ),
    "exploring": MessageLookupByLibrary.simpleMessage("探索中..."),
    "extra_large": MessageLookupByLibrary.simpleMessage("特大 (130%)"),
    "feedback": MessageLookupByLibrary.simpleMessage("フィードバック"),
    "filter": MessageLookupByLibrary.simpleMessage(
      "申し訳ありませんが、この質問には現在お答えできません。別の話題について話しましょう。",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("録音完了"),
    "follow_system": MessageLookupByLibrary.simpleMessage("システムに従う"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "Twitterでフォローする",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("フォント設定"),
    "font_size": MessageLookupByLibrary.simpleMessage("フォントサイズ"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("デフォルト (100%)"),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "game_over": MessageLookupByLibrary.simpleMessage("ゲームオーバー！"),
    "generate": MessageLookupByLibrary.simpleMessage("生成"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("世界で最も難しい数独を生成"),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "ランダムな数独パズルを生成",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("生成中..."),
    "hide_stack": MessageLookupByLibrary.simpleMessage("思考スタックを非表示"),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "録音するには長押し、送信するには離す",
    ),
    "human": MessageLookupByLibrary.simpleMessage("人間"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage(
      "RWKV に言わせたいことは...",
    ),
    "imitate": m2,
    "imitate_target": MessageLookupByLibrary.simpleMessage("使用"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage(
          "探索深度と幅が両方とも2より大きい場合、インコンテキスト検索が有効になります",
        ),
    "inference_is_done": MessageLookupByLibrary.simpleMessage("🎉 推論完了"),
    "inference_is_running": MessageLookupByLibrary.simpleMessage("推論中"),
    "intonations": MessageLookupByLibrary.simpleMessage("イントネーション"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "RWKV v7 シリーズ大規模言語モデルを探索しましょう。0.1B/0.4B/1.5B/2.9B パラメータバージョンがあり、モバイルデバイス向けに最適化されています。ロード後は完全にオフラインで実行でき、サーバー通信は不要です。",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("無効な数独"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("無効な値"),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("あなたの番です～"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "Discordサーバーに参加する",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage("コミュニティに参加"),
    "just_watch_me": MessageLookupByLibrary.simpleMessage(
      "😎 私のパフォーマンスを見てください！",
    ),
    "large": MessageLookupByLibrary.simpleMessage("大きい (120%)"),
    "license": MessageLookupByLibrary.simpleMessage("オープンソースライセンス"),
    "loading": MessageLookupByLibrary.simpleMessage("ロード中..."),
    "medium": MessageLookupByLibrary.simpleMessage("中 (110%)"),
    "memory_used": m4,
    "model_settings": MessageLookupByLibrary.simpleMessage("モデル設定"),
    "my_voice": MessageLookupByLibrary.simpleMessage("私の声"),
    "network_error": MessageLookupByLibrary.simpleMessage("ネットワークエラー"),
    "new_chat": MessageLookupByLibrary.simpleMessage("新しいチャット"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("新しいチャットを開始しました"),
    "new_game": MessageLookupByLibrary.simpleMessage("新しいゲーム"),
    "new_version_found": MessageLookupByLibrary.simpleMessage(
      "新しいバージョンが見つかりました",
    ),
    "no_cell_available": MessageLookupByLibrary.simpleMessage("置ける駒がありません"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("数独がありません"),
    "number": MessageLookupByLibrary.simpleMessage("数字"),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage(
          "または、wavファイルを選択してRWKVにそれを模倣させることができます。",
        ),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "または、新しい空白のチャットを開始",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV オセロ"),
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
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage("マイクの使用許可を与えてください"),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage(
      "まずモデルをロードしてください",
    ),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "ワールドタイプを選択してください",
    ),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "アプリケーション言語を選択してください",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage(
      "フォントサイズを選択してください",
    ),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "難易度を入力してください",
    ),
    "please_wait_for_it_to_finish": MessageLookupByLibrary.simpleMessage(
      "完了するまでお待ちください",
    ),
    "please_wait_for_the_model_to_finish_generating":
        MessageLookupByLibrary.simpleMessage("モデルが生成を完了するまでお待ちください"),
    "please_wait_for_the_model_to_generate":
        MessageLookupByLibrary.simpleMessage("モデルの生成を待機してください"),
    "please_wait_for_the_model_to_load": MessageLookupByLibrary.simpleMessage(
      "モデルのロードを待機してください",
    ),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("プリセット音声"),
    "prefer": MessageLookupByLibrary.simpleMessage("使用"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("中国語推論を優先"),
    "prefill": MessageLookupByLibrary.simpleMessage("プリフィル"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQグループ1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQグループ2"),
    "reason": MessageLookupByLibrary.simpleMessage("推論"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("推論モード"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("音声を録音中..."),
    "remaining": MessageLookupByLibrary.simpleMessage("残り時間："),
    "reselect_model": MessageLookupByLibrary.simpleMessage("モデルを再選択"),
    "reset": MessageLookupByLibrary.simpleMessage("リセット"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV チャット"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV オセロ"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("探索幅"),
    "search_depth": MessageLookupByLibrary.simpleMessage("探索深度"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("モデルを選択"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("ワールドタイプを選択"),
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage(
      "RWKV にメッセージを送信",
    ),
    "server_error": MessageLookupByLibrary.simpleMessage("サーバーエラー"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("セッション設定"),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("グリッドの値を設定"),
    "show_stack": MessageLookupByLibrary.simpleMessage("思考スタックを表示"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "より良い結果を得るためには、少なくとも1.5Bモデルを選択することをお勧めします",
    ),
    "small": MessageLookupByLibrary.simpleMessage("小さい (90%)"),
    "speed": MessageLookupByLibrary.simpleMessage("ダウンロード速度："),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage("新しいチャットを開始"),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage("下のボタンをクリックして新しいチャットを開始"),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("対局を開始"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("チャットを開始"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("推論を開始"),
    "technical_research_group": MessageLookupByLibrary.simpleMessage(
      "技術研究グループ",
    ),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage("数独が無効です"),
    "thinking": MessageLookupByLibrary.simpleMessage("思考中..."),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("これは世界で最も難しい数独です"),
    "thought_result": MessageLookupByLibrary.simpleMessage("思考結果"),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("ターンの移行"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("超特大 (140%)"),
    "update_now": MessageLookupByLibrary.simpleMessage("今すぐ更新"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("今すぐ使用"),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "値は0から9の間である必要があります",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("非常に小さい (80%)"),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("音声クローン"),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage("RWKV へようこそ"),
    "white": MessageLookupByLibrary.simpleMessage("白"),
    "white_score": MessageLookupByLibrary.simpleMessage("白のスコア"),
    "white_wins": MessageLookupByLibrary.simpleMessage("白の勝ち！"),
    "you_are_now_using": m5,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "RWKV とチャットを開始できます",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("あなたの声を録音し、RWKVにそれを模倣させることができます。"),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "チャットする役割を選択できます",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "あなたの声が短すぎます。声を録音するためにもっと長くボタンを長押ししてください。",
    ),
  };
}
