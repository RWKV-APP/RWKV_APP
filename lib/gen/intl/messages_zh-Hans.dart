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

  static String m0(count) => "并行 × ${count}";

  static String m1(count) => "每次推理将生成 ${count} 条消息";

  static String m2(count) => "并行推理中，同时生成 ${count} 条消息";

  static String m3(index) => "已选择第 ${index} 条消息";

  static String m4(demoName) => "欢迎探索 ${demoName}";

  static String m5(maxLength) => "会话名称不能超过 ${maxLength} 个字符";

  static String m6(path) => "消息记录会存储在该文件夹下\n ${path}";

  static String m7(port) => "HTTP 服务 (端口: ${port})";

  static String m8(flag, nameCN, nameEN) =>
      "模仿 ${flag} ${nameCN}(${nameEN}) 的声音";

  static String m9(fileName) => "模仿 ${fileName}";

  static String m10(memUsed, memFree) => "已用内存：${memUsed}，剩余内存：${memFree}";

  static String m11(count) => "排队中: ${count}";

  static String m12(port) => "WebSocket 服务 (端口: ${port})";

  static String m13(id) => "窗口 ${id}";

  static String m14(count) => "${count} 个标签页";

  static String m15(modelName) => "您当前正在使用 ${modelName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Completion": MessageLookupByLibrary.simpleMessage("续写模式"),
    "about": MessageLookupByLibrary.simpleMessage("关于"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("根据: "),
    "advance_settings": MessageLookupByLibrary.simpleMessage("高级设置"),
    "all": MessageLookupByLibrary.simpleMessage("全部"),
    "all_done": MessageLookupByLibrary.simpleMessage("全部完成"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("全部 Prompt"),
    "allow_background_downloads": MessageLookupByLibrary.simpleMessage(
      "允许后台下载",
    ),
    "analysing_result": MessageLookupByLibrary.simpleMessage("正在分析搜索结果"),
    "app_is_already_up_to_date": MessageLookupByLibrary.simpleMessage(
      "已经是最新版本",
    ),
    "appearance": MessageLookupByLibrary.simpleMessage("外观"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "应用内测群",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("应用语言"),
    "application_mode": MessageLookupByLibrary.simpleMessage("应用模式"),
    "application_settings": MessageLookupByLibrary.simpleMessage("应用设置"),
    "apply": MessageLookupByLibrary.simpleMessage("应用"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage("确定要删除这个模型吗？"),
    "ask_me_anything": MessageLookupByLibrary.simpleMessage("随意向我提问..."),
    "assistant": MessageLookupByLibrary.simpleMessage("RWKV:"),
    "auto": MessageLookupByLibrary.simpleMessage("自动"),
    "auto_detect": MessageLookupByLibrary.simpleMessage("自动检测"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("返回聊天"),
    "balanced": MessageLookupByLibrary.simpleMessage("均衡"),
    "batch_inference": MessageLookupByLibrary.simpleMessage("并行推理"),
    "batch_inference_button": m0,
    "batch_inference_count": MessageLookupByLibrary.simpleMessage("并行推理数量"),
    "batch_inference_count_detail": m1,
    "batch_inference_detail": MessageLookupByLibrary.simpleMessage(
      "开启并行推理后，RWKV 可以同时生成多个答案",
    ),
    "batch_inference_enable_or_not": MessageLookupByLibrary.simpleMessage(
      "开启或关闭并行推理",
    ),
    "batch_inference_running": m2,
    "batch_inference_selected": m3,
    "batch_inference_settings": MessageLookupByLibrary.simpleMessage("并行推理设置"),
    "batch_inference_short": MessageLookupByLibrary.simpleMessage("并行"),
    "batch_inference_width": MessageLookupByLibrary.simpleMessage("消息显示宽度"),
    "batch_inference_width_detail": MessageLookupByLibrary.simpleMessage(
      "并行推理每条消息宽度",
    ),
    "beginner": MessageLookupByLibrary.simpleMessage("新手模式"),
    "benchmark": MessageLookupByLibrary.simpleMessage("基准测试"),
    "benchmark_result": MessageLookupByLibrary.simpleMessage("基准测试结果"),
    "black": MessageLookupByLibrary.simpleMessage("黑方"),
    "black_score": MessageLookupByLibrary.simpleMessage("黑方得分"),
    "black_wins": MessageLookupByLibrary.simpleMessage("黑方获胜！"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "机器人消息已编辑，现在可以发送新消息",
    ),
    "browser_status": MessageLookupByLibrary.simpleMessage("浏览器状态"),
    "cached_translations_disk": MessageLookupByLibrary.simpleMessage(
      "缓存的翻译 (磁盘)",
    ),
    "cached_translations_memory": MessageLookupByLibrary.simpleMessage(
      "缓存的翻译 (内存)",
    ),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("无法生成"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("取消下载"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("暂不更新"),
    "change": MessageLookupByLibrary.simpleMessage("更改"),
    "chat": MessageLookupByLibrary.simpleMessage("开始对话"),
    "chat_copied_to_clipboard": MessageLookupByLibrary.simpleMessage("已复制到剪贴板"),
    "chat_empty_message": MessageLookupByLibrary.simpleMessage("请输入消息内容"),
    "chat_history": MessageLookupByLibrary.simpleMessage("聊天记录"),
    "chat_mode": MessageLookupByLibrary.simpleMessage("对话模式"),
    "chat_model_name": MessageLookupByLibrary.simpleMessage("模型名称"),
    "chat_please_select_a_model": MessageLookupByLibrary.simpleMessage(
      "请选择一个模型",
    ),
    "chat_resume": MessageLookupByLibrary.simpleMessage("继续"),
    "chat_title": MessageLookupByLibrary.simpleMessage("RWKV Chat"),
    "chat_welcome_to_use": m4,
    "chat_with_rwkv_model": MessageLookupByLibrary.simpleMessage("与 RWKV 模型对话"),
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage("您需要先下载模型才能使用"),
    "chatting": MessageLookupByLibrary.simpleMessage("聊天中"),
    "check_for_updates": MessageLookupByLibrary.simpleMessage("检查更新"),
    "chinese": MessageLookupByLibrary.simpleMessage("中文"),
    "chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "中文思考模板",
    ),
    "chinese_translation_result": MessageLookupByLibrary.simpleMessage(
      "中文翻译结果",
    ),
    "chinese_web_search_template": MessageLookupByLibrary.simpleMessage(
      "中文联网搜索模板",
    ),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage("选择预设角色"),
    "clear": MessageLookupByLibrary.simpleMessage("清除"),
    "clear_memory_cache": MessageLookupByLibrary.simpleMessage("清除内存缓存"),
    "clear_text": MessageLookupByLibrary.simpleMessage("清除文本"),
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
    "completion_mode": MessageLookupByLibrary.simpleMessage("续写模式"),
    "comprehensive": MessageLookupByLibrary.simpleMessage("综合"),
    "confirm": MessageLookupByLibrary.simpleMessage("确认"),
    "conservative": MessageLookupByLibrary.simpleMessage("保守"),
    "continue_download": MessageLookupByLibrary.simpleMessage("继续下载"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "继续使用较小模型",
    ),
    "conversation_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "会话名称不能为空",
    ),
    "conversation_name_cannot_be_longer_than_30_characters": m5,
    "conversations": MessageLookupByLibrary.simpleMessage("会话"),
    "copy_text": MessageLookupByLibrary.simpleMessage("复制文本"),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("点击上方按钮创建新会话"),
    "created_at": MessageLookupByLibrary.simpleMessage("创建时间"),
    "creative": MessageLookupByLibrary.simpleMessage("创意"),
    "current_task_tab_id": MessageLookupByLibrary.simpleMessage("当前任务标签页 ID"),
    "current_task_text_length": MessageLookupByLibrary.simpleMessage(
      "当前任务文本长度",
    ),
    "current_task_url": MessageLookupByLibrary.simpleMessage("当前任务 URL"),
    "current_turn": MessageLookupByLibrary.simpleMessage("当前回合"),
    "custom": MessageLookupByLibrary.simpleMessage("自定义"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage("自定义难度"),
    "dark_mode": MessageLookupByLibrary.simpleMessage("深色模式"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage("深色模式主题"),
    "decode": MessageLookupByLibrary.simpleMessage("解码"),
    "decode_param": MessageLookupByLibrary.simpleMessage("解码参数"),
    "deep_web_search": MessageLookupByLibrary.simpleMessage("深度联网"),
    "default_": MessageLookupByLibrary.simpleMessage("默认"),
    "delete": MessageLookupByLibrary.simpleMessage("删除"),
    "delete_all": MessageLookupByLibrary.simpleMessage("全部删除"),
    "delete_conversation": MessageLookupByLibrary.simpleMessage("删除会话"),
    "delete_conversation_message": MessageLookupByLibrary.simpleMessage(
      "确定要删除会话吗？",
    ),
    "difficulty": MessageLookupByLibrary.simpleMessage("难度"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "难度必须大于 0",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "难度必须小于 81",
    ),
    "disabled": MessageLookupByLibrary.simpleMessage("关闭"),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "dont_ask_again": MessageLookupByLibrary.simpleMessage("不再询问"),
    "download_all": MessageLookupByLibrary.simpleMessage("下载全部"),
    "download_all_missing": MessageLookupByLibrary.simpleMessage("下载全部缺失文件"),
    "download_app": MessageLookupByLibrary.simpleMessage("下载App"),
    "download_failed": MessageLookupByLibrary.simpleMessage("下载失败"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage("从浏览器下载"),
    "download_missing": MessageLookupByLibrary.simpleMessage("下载缺失文件"),
    "download_model": MessageLookupByLibrary.simpleMessage("下载模型"),
    "download_server_": MessageLookupByLibrary.simpleMessage("下载服务器(请试试哪个快)"),
    "download_source": MessageLookupByLibrary.simpleMessage("下载源"),
    "downloading": MessageLookupByLibrary.simpleMessage("下载中"),
    "draw": MessageLookupByLibrary.simpleMessage("平局！"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage("自动 Dump 消息记录"),
    "dump_see_files_alert_message": m6,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage("协助我们改进算法"),
    "dump_started": MessageLookupByLibrary.simpleMessage("自动 dump 已开启"),
    "dump_stopped": MessageLookupByLibrary.simpleMessage("自动 dump 已关闭"),
    "enabled": MessageLookupByLibrary.simpleMessage("开启"),
    "end": MessageLookupByLibrary.simpleMessage("完"),
    "english_translation_result": MessageLookupByLibrary.simpleMessage(
      "英文翻译结果",
    ),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage("请确保设备内存充足，否则可能导致应用崩溃"),
    "enter_text_to_translate": MessageLookupByLibrary.simpleMessage(
      "输入要翻译的文本...",
    ),
    "expert": MessageLookupByLibrary.simpleMessage("专家模式"),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("探索RWKV"),
    "exploring": MessageLookupByLibrary.simpleMessage("探索中..."),
    "export_conversation_failed": MessageLookupByLibrary.simpleMessage(
      "导出会话失败",
    ),
    "export_conversation_to_txt": MessageLookupByLibrary.simpleMessage(
      "导出会话为 .txt 文件",
    ),
    "export_data": MessageLookupByLibrary.simpleMessage("导出数据"),
    "export_title": MessageLookupByLibrary.simpleMessage("会话标题:"),
    "extra_large": MessageLookupByLibrary.simpleMessage("特大 (130%)"),
    "feedback": MessageLookupByLibrary.simpleMessage("反馈问题"),
    "filter": MessageLookupByLibrary.simpleMessage(
      "你好，这个问题我暂时无法回答，让我们换个话题再聊聊吧。",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("录音完成"),
    "fixed": MessageLookupByLibrary.simpleMessage("固定"),
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
    "github_repository": MessageLookupByLibrary.simpleMessage("Github 仓库"),
    "go_to_settings": MessageLookupByLibrary.simpleMessage("去设置"),
    "hello_ask_me_anything": MessageLookupByLibrary.simpleMessage(
      "Hello, 请随意 \n向我提问...",
    ),
    "hide_stack": MessageLookupByLibrary.simpleMessage("隐藏思维链堆栈"),
    "hint_system_prompt": MessageLookupByLibrary.simpleMessage(
      "例子: System: 你是秦始皇，使用文言文，以居高临下的态度与人沟通.",
    ),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "按住录音，松开发送",
    ),
    "home": MessageLookupByLibrary.simpleMessage("主页"),
    "http_service_port": m7,
    "human": MessageLookupByLibrary.simpleMessage("人类"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage("我想让 RWKV 说..."),
    "idle": MessageLookupByLibrary.simpleMessage("空闲"),
    "imitate": m8,
    "imitate_fle": m9,
    "imitate_target": MessageLookupByLibrary.simpleMessage("使用"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage("当搜索深度和宽度都大于 2 时，将激活上下文搜索"),
    "inference_engine": MessageLookupByLibrary.simpleMessage("推理引擎"),
    "inference_is_done": MessageLookupByLibrary.simpleMessage("🎉 推理完成"),
    "inference_is_running": MessageLookupByLibrary.simpleMessage("推理中"),
    "input_chinese_text_here": MessageLookupByLibrary.simpleMessage("输入中文文本"),
    "input_english_text_here": MessageLookupByLibrary.simpleMessage("输入英文文本"),
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
    "lan_server": MessageLookupByLibrary.simpleMessage("局域网服务器"),
    "large": MessageLookupByLibrary.simpleMessage("大 (120%)"),
    "lazy": MessageLookupByLibrary.simpleMessage("懒"),
    "lazy_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "懒思考模板",
    ),
    "license": MessageLookupByLibrary.simpleMessage("开源许可证"),
    "light_mode": MessageLookupByLibrary.simpleMessage("浅色模式"),
    "load_": MessageLookupByLibrary.simpleMessage("加载"),
    "loaded": MessageLookupByLibrary.simpleMessage("已加载"),
    "loading": MessageLookupByLibrary.simpleMessage("加载中..."),
    "medium": MessageLookupByLibrary.simpleMessage("中 (110%)"),
    "memory_used": m10,
    "message_content": MessageLookupByLibrary.simpleMessage("消息内容"),
    "mode": MessageLookupByLibrary.simpleMessage("模式"),
    "model": MessageLookupByLibrary.simpleMessage("模型"),
    "model_loading": MessageLookupByLibrary.simpleMessage("模型加载中..."),
    "model_settings": MessageLookupByLibrary.simpleMessage("模型设置"),
    "more": MessageLookupByLibrary.simpleMessage("更多"),
    "more_questions": MessageLookupByLibrary.simpleMessage("更多问题"),
    "my_voice": MessageLookupByLibrary.simpleMessage("我的声音"),
    "neko": MessageLookupByLibrary.simpleMessage("Neko"),
    "network_error": MessageLookupByLibrary.simpleMessage("网络错误"),
    "new_chat": MessageLookupByLibrary.simpleMessage("新聊天"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("开始新聊天"),
    "new_chat_template": MessageLookupByLibrary.simpleMessage("新对话模板"),
    "new_chat_template_helper_text": MessageLookupByLibrary.simpleMessage(
      "每次新对话将插入此内容, 用两个换行分隔, 例子:\n你好，你是谁？\n\n你好，我是RWKV，有什么我可以帮助你的吗",
    ),
    "new_conversation": MessageLookupByLibrary.simpleMessage("开始新对话"),
    "new_game": MessageLookupByLibrary.simpleMessage("新游戏"),
    "new_version_found": MessageLookupByLibrary.simpleMessage("发现新版本"),
    "no_audio_file": MessageLookupByLibrary.simpleMessage("没有音频文件"),
    "no_browser_windows_connected": MessageLookupByLibrary.simpleMessage(
      "没有连接的浏览器窗口",
    ),
    "no_cell_available": MessageLookupByLibrary.simpleMessage("无子可下"),
    "no_conversation_yet": MessageLookupByLibrary.simpleMessage("目前还没有对话"),
    "no_conversations_yet": MessageLookupByLibrary.simpleMessage("暂时还没有任何对话"),
    "no_data": MessageLookupByLibrary.simpleMessage("无数据"),
    "no_message_to_export": MessageLookupByLibrary.simpleMessage("没有消息可导出"),
    "no_model_selected": MessageLookupByLibrary.simpleMessage("未选择模型"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("没有数独"),
    "number": MessageLookupByLibrary.simpleMessage("数字"),
    "nyan_nyan": MessageLookupByLibrary.simpleMessage("Nyan~~,Nyan~~"),
    "off": MessageLookupByLibrary.simpleMessage("关闭"),
    "offline_translator": MessageLookupByLibrary.simpleMessage("离线翻译"),
    "offline_translator_detail": MessageLookupByLibrary.simpleMessage("离线翻译文本"),
    "offline_translator_server": MessageLookupByLibrary.simpleMessage("线翻译服务器"),
    "ok": MessageLookupByLibrary.simpleMessage("确定"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("或者选择一个 wav 文件，让 RWKV 模仿它。"),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "或开始一个空白聊天",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "output": MessageLookupByLibrary.simpleMessage("输出"),
    "overseas": MessageLookupByLibrary.simpleMessage("(境外)"),
    "pause": MessageLookupByLibrary.simpleMessage("暂停"),
    "performance_test": MessageLookupByLibrary.simpleMessage("性能测试"),
    "players": MessageLookupByLibrary.simpleMessage("玩家"),
    "playing_partial_generated_audio": MessageLookupByLibrary.simpleMessage(
      "正在播放部分已生成的语音",
    ),
    "please_check_the_result": MessageLookupByLibrary.simpleMessage("请检查结果"),
    "please_enter_a_number_0_means_empty": MessageLookupByLibrary.simpleMessage(
      "请输入一个数字。0 表示空。",
    ),
    "please_enter_conversation_name": MessageLookupByLibrary.simpleMessage(
      "请输入会话名称",
    ),
    "please_enter_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "请输入难度",
    ),
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage("请授予使用麦克风的权限"),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage("请先加载模型"),
    "please_select_a_branch_to_continue_the_conversation":
        MessageLookupByLibrary.simpleMessage("请选择你喜欢的分支以进行接下来的对话"),
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
    "power_user": MessageLookupByLibrary.simpleMessage("高级模式"),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("预设声音"),
    "prefer": MessageLookupByLibrary.simpleMessage("使用"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("使用中文推理"),
    "prefill": MessageLookupByLibrary.simpleMessage("预填"),
    "prompt": MessageLookupByLibrary.simpleMessage("提示词"),
    "prompt_template": MessageLookupByLibrary.simpleMessage("Prompt 模板"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQ 群 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQ 群 2"),
    "queued_x": m11,
    "quick_thinking": MessageLookupByLibrary.simpleMessage("快思考"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage("快思考已经开启"),
    "reason": MessageLookupByLibrary.simpleMessage("推理"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("推理模式"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("正在录音..."),
    "reference_source": MessageLookupByLibrary.simpleMessage("参考源"),
    "regenerate": MessageLookupByLibrary.simpleMessage("重新生成"),
    "remaining": MessageLookupByLibrary.simpleMessage("剩余时间："),
    "rename": MessageLookupByLibrary.simpleMessage("重命名"),
    "report_an_issue_on_github": MessageLookupByLibrary.simpleMessage(
      "在 Github 上报告问题",
    ),
    "reselect_model": MessageLookupByLibrary.simpleMessage("重新选择模型"),
    "reset": MessageLookupByLibrary.simpleMessage("重置"),
    "result": MessageLookupByLibrary.simpleMessage("结果"),
    "resume": MessageLookupByLibrary.simpleMessage("恢复"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV 聊天"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("扫描二维码"),
    "screen_width": MessageLookupByLibrary.simpleMessage("屏幕宽度"),
    "search": MessageLookupByLibrary.simpleMessage("搜索"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("搜索宽度"),
    "search_depth": MessageLookupByLibrary.simpleMessage("搜索深度"),
    "search_failed": MessageLookupByLibrary.simpleMessage("搜索失败"),
    "searching": MessageLookupByLibrary.simpleMessage("搜索中..."),
    "select_a_model": MessageLookupByLibrary.simpleMessage("选择模型"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("选择任务类型"),
    "select_from_library": MessageLookupByLibrary.simpleMessage("从相册选择"),
    "select_image": MessageLookupByLibrary.simpleMessage("选择图片"),
    "select_model": MessageLookupByLibrary.simpleMessage("选择模型"),
    "select_new_image": MessageLookupByLibrary.simpleMessage("选择新图片"),
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage("发送消息给 RWKV"),
    "server_error": MessageLookupByLibrary.simpleMessage("服务器错误"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("会话配置"),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("设置网格值"),
    "settings": MessageLookupByLibrary.simpleMessage("设置"),
    "share": MessageLookupByLibrary.simpleMessage("分享"),
    "share_chat": MessageLookupByLibrary.simpleMessage("分享聊天"),
    "show_stack": MessageLookupByLibrary.simpleMessage("显示思维链堆栈"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "推荐至少选择 1.5B 模型，效果更好",
    ),
    "small": MessageLookupByLibrary.simpleMessage("小 (90%)"),
    "speed": MessageLookupByLibrary.simpleMessage("下载速度："),
    "start": MessageLookupByLibrary.simpleMessage("开始"),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage("开始新聊天"),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage("点击下方按钮开始新聊天"),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("开始对局"),
    "start_service": MessageLookupByLibrary.simpleMessage("启动服务"),
    "start_service_and_open_browser": MessageLookupByLibrary.simpleMessage(
      "启动服务并打开支持的浏览器页面。",
    ),
    "start_testing": MessageLookupByLibrary.simpleMessage("开始测试"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("开始聊天"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("开始推理"),
    "starting": MessageLookupByLibrary.simpleMessage("启动中..."),
    "status": MessageLookupByLibrary.simpleMessage("状态"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "stop_service": MessageLookupByLibrary.simpleMessage("停止服务"),
    "stopping": MessageLookupByLibrary.simpleMessage("停止中..."),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "存储权限未授予",
    ),
    "str_model_selection_dialog_hint": MessageLookupByLibrary.simpleMessage(
      "推荐至少选择1.5B模型，更大的2.9B模型更好",
    ),
    "str_please_disable_battery_opt_": MessageLookupByLibrary.simpleMessage(
      "请关闭电池优化已允许后台下载，否则切换到其他应用时下载可能会被暂停",
    ),
    "str_please_select_app_mode_": MessageLookupByLibrary.simpleMessage(
      "请根据你对 AI 和 LLM 的了解程度选择应用模式.",
    ),
    "submit": MessageLookupByLibrary.simpleMessage("提交"),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("入门"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("专家"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("普通"),
    "suggest": MessageLookupByLibrary.simpleMessage("推荐"),
    "system_mode": MessageLookupByLibrary.simpleMessage("跟随系统"),
    "system_prompt": MessageLookupByLibrary.simpleMessage("系统提示词"),
    "take_photo": MessageLookupByLibrary.simpleMessage("拍照"),
    "technical_research_group": MessageLookupByLibrary.simpleMessage("技术研发群"),
    "test_result": MessageLookupByLibrary.simpleMessage("测试结果"),
    "text_completion_mode": MessageLookupByLibrary.simpleMessage("文本补全模式"),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage("数独无效"),
    "theme_dim": MessageLookupByLibrary.simpleMessage("深色"),
    "theme_light": MessageLookupByLibrary.simpleMessage("浅色"),
    "theme_lights_out": MessageLookupByLibrary.simpleMessage("黑色"),
    "then_you_can_start_to_chat_with_rwkv":
        MessageLookupByLibrary.simpleMessage("然后您就可以开始与 RWKV 对话了"),
    "thinking": MessageLookupByLibrary.simpleMessage("思考中..."),
    "thinking_mode_auto": MessageLookupByLibrary.simpleMessage("推理: 中"),
    "thinking_mode_detail_auto": MessageLookupByLibrary.simpleMessage(
      "推理模式: 中",
    ),
    "thinking_mode_detail_high": MessageLookupByLibrary.simpleMessage(
      "推理模式: 高",
    ),
    "thinking_mode_detail_off": MessageLookupByLibrary.simpleMessage("推理模式: 关"),
    "thinking_mode_high": MessageLookupByLibrary.simpleMessage("推理: 高"),
    "thinking_mode_off": MessageLookupByLibrary.simpleMessage("推理: 关"),
    "thinking_mode_template": MessageLookupByLibrary.simpleMessage("思考模式模板"),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("这是世界上最难的数独"),
    "this_model_does_not_support_batch_inference":
        MessageLookupByLibrary.simpleMessage("这个模型不支持并行推理, 请选择带有 batch 标签的模型"),
    "thought_result": MessageLookupByLibrary.simpleMessage("思考结果"),
    "translate": MessageLookupByLibrary.simpleMessage("翻译"),
    "translating": MessageLookupByLibrary.simpleMessage("翻译中..."),
    "translation": MessageLookupByLibrary.simpleMessage("翻译结果"),
    "translator_debug_info": MessageLookupByLibrary.simpleMessage("翻译器调试信息"),
    "tts": MessageLookupByLibrary.simpleMessage("文本转语音"),
    "tts_detail": MessageLookupByLibrary.simpleMessage("让 RWKV 输出语音"),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("落子权转移"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("超大 (140%)"),
    "unknown": MessageLookupByLibrary.simpleMessage("未知"),
    "update_now": MessageLookupByLibrary.simpleMessage("立即更新"),
    "updated_at": MessageLookupByLibrary.simpleMessage("更新时间"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("立即使用"),
    "user": MessageLookupByLibrary.simpleMessage("用户:"),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "值必须在 0 和 9 之间",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("非常小 (80%)"),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("声音克隆"),
    "web_search": MessageLookupByLibrary.simpleMessage("联网"),
    "web_search_template": MessageLookupByLibrary.simpleMessage("联网搜索模板"),
    "websocket_service_port": m12,
    "welcome_to_rwkv_chat": MessageLookupByLibrary.simpleMessage(
      "欢迎探索 RWKV Chat",
    ),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage("欢迎使用 RWKV"),
    "white": MessageLookupByLibrary.simpleMessage("白方"),
    "white_score": MessageLookupByLibrary.simpleMessage("白方得分"),
    "white_wins": MessageLookupByLibrary.simpleMessage("白方获胜！"),
    "window_id": m13,
    "x_message_selected": MessageLookupByLibrary.simpleMessage("已选 %d 条消息"),
    "x_pages_found": MessageLookupByLibrary.simpleMessage("已找到 %d 个相关网页"),
    "x_tabs": m14,
    "you_are_now_using": m15,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "现在可以开始与 RWKV 聊天了",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("您可以录制您的声音，然后让 RWKV 模仿它。"),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "您可以选择角色进行聊天",
    ),
    "your_voice_is_empty": MessageLookupByLibrary.simpleMessage(
      "您的声音数据为空，请检查您的麦克风",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "您的声音太短，请长按按钮更久以获取您的声音。",
    ),
  };
}
