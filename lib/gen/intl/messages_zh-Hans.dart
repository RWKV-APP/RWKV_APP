// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_Hans locale. All the
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
  String get localeName => 'zh_Hans';

  static String m0(demoName) => "欢迎探索 ${demoName}";

  static String m1(path) => "消息记录会存储在该文件夹下\n ${path}";

  static String m2(flag, nameCN, nameEN) =>
      "模仿 ${flag} ${nameCN}(${nameEN}) 的声音";

  static String m3(fileName) => "模仿 ${fileName}";

  static String m4(memUsed, memFree) => "已用内存：${memUsed}，剩余内存：${memFree}";

  static String m5(modelName) => "您当前正在使用 ${modelName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("关于"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("根据: "),
    "all": MessageLookupByLibrary.simpleMessage("全部"),
    "all_done": MessageLookupByLibrary.simpleMessage("全部完成"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("全部 Prompt"),
    "appearance": MessageLookupByLibrary.simpleMessage("外观"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "应用内测群",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("应用语言"),
    "application_settings": MessageLookupByLibrary.simpleMessage("应用设置"),
    "apply": MessageLookupByLibrary.simpleMessage("应用"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage("确定要删除这个模型吗？"),
    "auto": MessageLookupByLibrary.simpleMessage("自动"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("返回聊天"),
    "black": MessageLookupByLibrary.simpleMessage("黑方"),
    "black_score": MessageLookupByLibrary.simpleMessage("黑方得分"),
    "black_wins": MessageLookupByLibrary.simpleMessage("黑方获胜！"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "机器人消息已编辑，现在可以发送新消息",
    ),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("无法生成"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("取消下载"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("暂不更新"),
    "chat_copied_to_clipboard": MessageLookupByLibrary.simpleMessage("已复制到剪贴板"),
    "chat_empty_message": MessageLookupByLibrary.simpleMessage("请输入消息内容"),
    "chat_model_name": MessageLookupByLibrary.simpleMessage("模型名称"),
    "chat_please_select_a_model": MessageLookupByLibrary.simpleMessage(
      "请选择一个模型",
    ),
    "chat_resume": MessageLookupByLibrary.simpleMessage("继续"),
    "chat_title": MessageLookupByLibrary.simpleMessage("RWKV Chat"),
    "chat_welcome_to_use": m0,
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage("您需要先下载模型才能使用"),
    "chatting": MessageLookupByLibrary.simpleMessage("聊天中"),
    "chinese": MessageLookupByLibrary.simpleMessage("中文"),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage("选择预设角色"),
    "clear": MessageLookupByLibrary.simpleMessage("清除"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "点击此处选择新模型",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "点击此处开始新聊天",
    ),
    "click_to_load_image": MessageLookupByLibrary.simpleMessage("点击加载图片"),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage("点击选择模型"),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "色彩模式跟随系统",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("确认"),
    "continue_download": MessageLookupByLibrary.simpleMessage("继续下载"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "继续使用较小模型",
    ),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("点击上方按钮创建新会话"),
    "current_turn": MessageLookupByLibrary.simpleMessage("当前回合"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage("自定义难度"),
    "dark_mode": MessageLookupByLibrary.simpleMessage("深色模式"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage("深色模式主题"),
    "decode": MessageLookupByLibrary.simpleMessage("解码"),
    "delete": MessageLookupByLibrary.simpleMessage("删除"),
    "delete_all": MessageLookupByLibrary.simpleMessage("全部删除"),
    "difficulty": MessageLookupByLibrary.simpleMessage("难度"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "难度必须大于 0",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "难度必须小于 81",
    ),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "download_all": MessageLookupByLibrary.simpleMessage("下载全部"),
    "download_app": MessageLookupByLibrary.simpleMessage("下载App"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage("从浏览器下载"),
    "download_missing": MessageLookupByLibrary.simpleMessage("下载缺失文件"),
    "download_model": MessageLookupByLibrary.simpleMessage("下载模型"),
    "download_server_": MessageLookupByLibrary.simpleMessage("下载服务器(请试试哪个快)"),
    "download_source": MessageLookupByLibrary.simpleMessage("下载源"),
    "downloading": MessageLookupByLibrary.simpleMessage("下载中"),
    "draw": MessageLookupByLibrary.simpleMessage("平局！"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage("自动 Dump 消息记录"),
    "dump_see_files_alert_message": m1,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage("协助我们改进算法"),
    "dump_started": MessageLookupByLibrary.simpleMessage("自动 dump 已开启"),
    "dump_stopped": MessageLookupByLibrary.simpleMessage("自动 dump 已关闭"),
    "end": MessageLookupByLibrary.simpleMessage("完"),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage("请确保设备内存充足，否则可能导致应用崩溃"),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("探索RWKV"),
    "exploring": MessageLookupByLibrary.simpleMessage("探索中..."),
    "extra_large": MessageLookupByLibrary.simpleMessage("特大 (130%)"),
    "feedback": MessageLookupByLibrary.simpleMessage("反馈问题"),
    "filter": MessageLookupByLibrary.simpleMessage(
      "你好，这个问题我暂时无法回答，让我们换个话题再聊聊吧。",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("录音完成"),
    "follow_system": MessageLookupByLibrary.simpleMessage("跟随系统"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "在 Twitter 上关注我们",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("字体设置"),
    "font_size": MessageLookupByLibrary.simpleMessage("字体大小"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("默认 (100%)"),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage("强制使用深色模式"),
    "from_model": MessageLookupByLibrary.simpleMessage("来自模型: %s"),
    "game_over": MessageLookupByLibrary.simpleMessage("游戏结束！"),
    "generate": MessageLookupByLibrary.simpleMessage("生成"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("生成世界上最难的数独"),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "生成随机数独",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("生成中..."),
    "hide_stack": MessageLookupByLibrary.simpleMessage("隐藏思维链堆栈"),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "按住录音，松开发送",
    ),
    "human": MessageLookupByLibrary.simpleMessage("人类"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage("我想让 RWKV 说..."),
    "imitate": m2,
    "imitate_fle": m3,
    "imitate_target": MessageLookupByLibrary.simpleMessage("使用"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage("当搜索深度和宽度都大于 2 时，将激活上下文搜索"),
    "inference_is_done": MessageLookupByLibrary.simpleMessage("🎉 推理完成"),
    "inference_is_running": MessageLookupByLibrary.simpleMessage("推理中"),
    "intonations": MessageLookupByLibrary.simpleMessage("语气词"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "欢迎探索 RWKV v7 系列大语言模型，包含 0.1B/0.4B/1.5B/2.9B 参数版本，专为移动设备优化，加载后可完全离线运行，无需服务器通信",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("无效数独"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("无效值"),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("轮到你了~"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "加入我们的 Discord 服务器",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage("加入社区"),
    "just_watch_me": MessageLookupByLibrary.simpleMessage("😎 看我表演！"),
    "large": MessageLookupByLibrary.simpleMessage("大 (120%)"),
    "lazy": MessageLookupByLibrary.simpleMessage("懒"),
    "license": MessageLookupByLibrary.simpleMessage("开源许可证"),
    "light_mode": MessageLookupByLibrary.simpleMessage("浅色模式"),
    "loading": MessageLookupByLibrary.simpleMessage("加载中..."),
    "medium": MessageLookupByLibrary.simpleMessage("中 (110%)"),
    "memory_used": m4,
    "model_settings": MessageLookupByLibrary.simpleMessage("模型设置"),
    "my_voice": MessageLookupByLibrary.simpleMessage("我的声音"),
    "network_error": MessageLookupByLibrary.simpleMessage("网络错误"),
    "new_chat": MessageLookupByLibrary.simpleMessage("新聊天"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("开始新聊天"),
    "new_game": MessageLookupByLibrary.simpleMessage("新游戏"),
    "new_version_found": MessageLookupByLibrary.simpleMessage("发现新版本"),
    "no_cell_available": MessageLookupByLibrary.simpleMessage("无子可下"),
    "no_data": MessageLookupByLibrary.simpleMessage("无数据"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("没有数独"),
    "number": MessageLookupByLibrary.simpleMessage("数字"),
    "ok": MessageLookupByLibrary.simpleMessage("确定"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("或者选择一个 wav 文件，让 RWKV 模仿它。"),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "或开始一个空白聊天",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "overseas": MessageLookupByLibrary.simpleMessage("(境外)"),
    "players": MessageLookupByLibrary.simpleMessage("玩家"),
    "playing_partial_generated_audio": MessageLookupByLibrary.simpleMessage(
      "正在播放部分已生成的语音",
    ),
    "please_check_the_result": MessageLookupByLibrary.simpleMessage("请检查结果"),
    "please_enter_a_number_0_means_empty": MessageLookupByLibrary.simpleMessage(
      "请输入一个数字。0 表示空。",
    ),
    "please_enter_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "请输入难度",
    ),
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage("请授予使用麦克风的权限"),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage("请先加载模型"),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "请选择任务类型",
    ),
    "please_select_an_image_from_the_following_options":
        MessageLookupByLibrary.simpleMessage("请从以下选项中选择一个图片"),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "请选择应用语言",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage("请选择字体大小"),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "请选择难度",
    ),
    "please_wait_for_it_to_finish": MessageLookupByLibrary.simpleMessage(
      "请等待推理完成",
    ),
    "please_wait_for_the_model_to_finish_generating":
        MessageLookupByLibrary.simpleMessage("请等待模型生成完成"),
    "please_wait_for_the_model_to_generate":
        MessageLookupByLibrary.simpleMessage("请等待模型生成"),
    "please_wait_for_the_model_to_load": MessageLookupByLibrary.simpleMessage(
      "请等待模型加载",
    ),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("预设声音"),
    "prefer": MessageLookupByLibrary.simpleMessage("使用"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("使用中文推理"),
    "prefill": MessageLookupByLibrary.simpleMessage("预填"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQ 群 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQ 群 2"),
    "quick_thinking": MessageLookupByLibrary.simpleMessage("快思考"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage("快思考已经开启"),
    "reason": MessageLookupByLibrary.simpleMessage("推理"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("推理模式"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("正在录音..."),
    "remaining": MessageLookupByLibrary.simpleMessage("剩余时间："),
    "reselect_model": MessageLookupByLibrary.simpleMessage("重新选择模型"),
    "reset": MessageLookupByLibrary.simpleMessage("重置"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV 聊天"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("扫描二维码"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("搜索宽度"),
    "search_depth": MessageLookupByLibrary.simpleMessage("搜索深度"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("选择模型"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("选择任务类型"),
    "select_from_library": MessageLookupByLibrary.simpleMessage("从相册选择"),
    "select_image": MessageLookupByLibrary.simpleMessage("选择图片"),
    "select_new_image": MessageLookupByLibrary.simpleMessage("选择新图片"),
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage("发送消息给 RWKV"),
    "server_error": MessageLookupByLibrary.simpleMessage("服务器错误"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("会话配置"),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("设置网格值"),
    "share": MessageLookupByLibrary.simpleMessage("分享"),
    "share_chat": MessageLookupByLibrary.simpleMessage("分享聊天"),
    "show_stack": MessageLookupByLibrary.simpleMessage("显示思维链堆栈"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "推荐至少选择 1.5B 模型，效果更好",
    ),
    "small": MessageLookupByLibrary.simpleMessage("小 (90%)"),
    "speed": MessageLookupByLibrary.simpleMessage("下载速度："),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage("开始新聊天"),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage("点击下方按钮开始新聊天"),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("开始对局"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("开始聊天"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("开始推理"),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "存储权限未授予",
    ),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("入门"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("专家"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("普通"),
    "system_mode": MessageLookupByLibrary.simpleMessage("跟随系统"),
    "take_photo": MessageLookupByLibrary.simpleMessage("拍照"),
    "technical_research_group": MessageLookupByLibrary.simpleMessage("技术研发群"),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage("数独无效"),
    "theme_dim": MessageLookupByLibrary.simpleMessage("深色"),
    "theme_light": MessageLookupByLibrary.simpleMessage("浅色"),
    "theme_lights_out": MessageLookupByLibrary.simpleMessage("黑色"),
    "then_you_can_start_to_chat_with_rwkv":
        MessageLookupByLibrary.simpleMessage("然后您就可以开始与 RWKV 对话了"),
    "thinking": MessageLookupByLibrary.simpleMessage("思考中..."),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("这是世界上最难的数独"),
    "thought_result": MessageLookupByLibrary.simpleMessage("思考结果"),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("落子权转移"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("超大 (140%)"),
    "update_now": MessageLookupByLibrary.simpleMessage("立即更新"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("立即使用"),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "值必须在 0 和 9 之间",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("非常小 (80%)"),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("声音克隆"),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage("欢迎使用 RWKV"),
    "white": MessageLookupByLibrary.simpleMessage("白方"),
    "white_score": MessageLookupByLibrary.simpleMessage("白方得分"),
    "white_wins": MessageLookupByLibrary.simpleMessage("白方获胜！"),
    "x_message_selected": MessageLookupByLibrary.simpleMessage("已选 %d 条消息"),
    "you_are_now_using": m5,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "现在可以开始与 RWKV 聊天了",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("您可以录制您的声音，然后让 RWKV 模仿它。"),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "您可以选择角色进行聊天",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "您的声音太短，请长按按钮更久以获取您的声音。",
    ),
  };
}
