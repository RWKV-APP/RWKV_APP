// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `RWKV 离线翻译服务器`
  String get rwkv_offline_translator_server {
    return Intl.message(
      'RWKV 离线翻译服务器',
      name: 'rwkv_offline_translator_server',
      desc: '',
      args: [],
    );
  }

  /// `RWKV 离线翻译`
  String get rwkv_offline_translator {
    return Intl.message(
      'RWKV 离线翻译',
      name: 'rwkv_offline_translator',
      desc: '',
      args: [],
    );
  }

  /// `没有音频文件`
  String get no_audio_file {
    return Intl.message('没有音频文件', name: 'no_audio_file', desc: '', args: []);
  }

  /// `Github 仓库`
  String get github_repository {
    return Intl.message(
      'Github 仓库',
      name: 'github_repository',
      desc: '',
      args: [],
    );
  }

  /// `在 Github 上报告问题`
  String get report_an_issue_on_github {
    return Intl.message(
      '在 Github 上报告问题',
      name: 'report_an_issue_on_github',
      desc: '',
      args: [],
    );
  }

  /// `没有消息可导出`
  String get no_message_to_export {
    return Intl.message(
      '没有消息可导出',
      name: 'no_message_to_export',
      desc: '',
      args: [],
    );
  }

  /// `导出会话为 .txt 文件`
  String get export_conversation_to_txt {
    return Intl.message(
      '导出会话为 .txt 文件',
      name: 'export_conversation_to_txt',
      desc: '',
      args: [],
    );
  }

  /// `创建时间`
  String get created_at {
    return Intl.message('创建时间', name: 'created_at', desc: '', args: []);
  }

  /// `更新时间`
  String get updated_at {
    return Intl.message('更新时间', name: 'updated_at', desc: '', args: []);
  }

  /// `消息内容`
  String get message_content {
    return Intl.message('消息内容', name: 'message_content', desc: '', args: []);
  }

  /// `会话标题:`
  String get export_title {
    return Intl.message('会话标题:', name: 'export_title', desc: '', args: []);
  }

  /// `用户:`
  String get user {
    return Intl.message('用户:', name: 'user', desc: '', args: []);
  }

  /// `RWKV:`
  String get assistant {
    return Intl.message('RWKV:', name: 'assistant', desc: '', args: []);
  }

  /// `导出会话失败`
  String get export_conversation_failed {
    return Intl.message(
      '导出会话失败',
      name: 'export_conversation_failed',
      desc: '',
      args: [],
    );
  }

  /// `未知`
  String get unknown {
    return Intl.message('未知', name: 'unknown', desc: '', args: []);
  }

  /// `重命名`
  String get rename {
    return Intl.message('重命名', name: 'rename', desc: '', args: []);
  }

  /// `请输入会话名称`
  String get please_enter_conversation_name {
    return Intl.message(
      '请输入会话名称',
      name: 'please_enter_conversation_name',
      desc: '',
      args: [],
    );
  }

  /// `会话名称不能为空`
  String get conversation_name_cannot_be_empty {
    return Intl.message(
      '会话名称不能为空',
      name: 'conversation_name_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `会话名称不能超过{maxLength}个字符`
  String conversation_name_cannot_be_longer_than_30_characters(
    Object maxLength,
  ) {
    return Intl.message(
      '会话名称不能超过$maxLength个字符',
      name: 'conversation_name_cannot_be_longer_than_30_characters',
      desc: '',
      args: [maxLength],
    );
  }

  /// `删除会话`
  String get delete_conversation {
    return Intl.message(
      '删除会话',
      name: 'delete_conversation',
      desc: '',
      args: [],
    );
  }

  /// `确定要删除会话吗？`
  String get delete_conversation_message {
    return Intl.message(
      '确定要删除会话吗？',
      name: 'delete_conversation_message',
      desc: '',
      args: [],
    );
  }

  /// `导出数据`
  String get export_data {
    return Intl.message('导出数据', name: 'export_data', desc: '', args: []);
  }

  /// `RWKV Chat`
  String get chat_title {
    return Intl.message('RWKV Chat', name: 'chat_title', desc: '', args: []);
  }

  /// `RWKV 黑白棋`
  String get othello_title {
    return Intl.message('RWKV 黑白棋', name: 'othello_title', desc: '', args: []);
  }

  /// `发送消息给 RWKV`
  String get send_message_to_rwkv {
    return Intl.message(
      '发送消息给 RWKV',
      name: 'send_message_to_rwkv',
      desc: '',
      args: [],
    );
  }

  /// `已复制到剪贴板`
  String get chat_copied_to_clipboard {
    return Intl.message(
      '已复制到剪贴板',
      name: 'chat_copied_to_clipboard',
      desc: '',
      args: [],
    );
  }

  /// `请输入消息内容`
  String get chat_empty_message {
    return Intl.message(
      '请输入消息内容',
      name: 'chat_empty_message',
      desc: '',
      args: [],
    );
  }

  /// `欢迎探索 {demoName}`
  String chat_welcome_to_use(Object demoName) {
    return Intl.message(
      '欢迎探索 $demoName',
      name: 'chat_welcome_to_use',
      desc: '',
      args: [demoName],
    );
  }

  /// `请选择一个模型`
  String get chat_please_select_a_model {
    return Intl.message(
      '请选择一个模型',
      name: 'chat_please_select_a_model',
      desc: '',
      args: [],
    );
  }

  /// `您需要先下载模型才能使用`
  String get chat_you_need_download_model_if_you_want_to_use_it {
    return Intl.message(
      '您需要先下载模型才能使用',
      name: 'chat_you_need_download_model_if_you_want_to_use_it',
      desc: '',
      args: [],
    );
  }

  /// `下载模型`
  String get download_model {
    return Intl.message('下载模型', name: 'download_model', desc: '', args: []);
  }

  /// `立即使用`
  String get use_it_now {
    return Intl.message('立即使用', name: 'use_it_now', desc: '', args: []);
  }

  /// `选择预设角色`
  String get choose_prebuilt_character {
    return Intl.message(
      '选择预设角色',
      name: 'choose_prebuilt_character',
      desc: '',
      args: [],
    );
  }

  /// `开始聊天`
  String get start_to_chat {
    return Intl.message('开始聊天', name: 'start_to_chat', desc: '', args: []);
  }

  /// `模型名称`
  String get chat_model_name {
    return Intl.message('模型名称', name: 'chat_model_name', desc: '', args: []);
  }

  /// `foo bar`
  String get foo_bar {
    return Intl.message('foo bar', name: 'foo_bar', desc: '', args: []);
  }

  /// `聊天中`
  String get chatting {
    return Intl.message('聊天中', name: 'chatting', desc: '', args: []);
  }

  /// `欢迎使用 RWKV`
  String get welcome_to_use_rwkv {
    return Intl.message(
      '欢迎使用 RWKV',
      name: 'welcome_to_use_rwkv',
      desc: '',
      args: [],
    );
  }

  /// `RWKV 黑白棋`
  String get rwkv_othello {
    return Intl.message('RWKV 黑白棋', name: 'rwkv_othello', desc: '', args: []);
  }

  /// `RWKV 聊天`
  String get rwkv_chat {
    return Intl.message('RWKV 聊天', name: 'rwkv_chat', desc: '', args: []);
  }

  /// `点击下方按钮开始新聊天`
  String get start_a_new_chat_by_clicking_the_button_below {
    return Intl.message(
      '点击下方按钮开始新聊天',
      name: 'start_a_new_chat_by_clicking_the_button_below',
      desc: '',
      args: [],
    );
  }

  /// `欢迎探索 RWKV v7 系列大语言模型，包含 0.1B/0.4B/1.5B/2.9B 参数版本，专为移动设备优化，加载后可完全离线运行，无需服务器通信`
  String get intro {
    return Intl.message(
      '欢迎探索 RWKV v7 系列大语言模型，包含 0.1B/0.4B/1.5B/2.9B 参数版本，专为移动设备优化，加载后可完全离线运行，无需服务器通信',
      name: 'intro',
      desc: '',
      args: [],
    );
  }

  /// `选择模型`
  String get select_a_model {
    return Intl.message('选择模型', name: 'select_a_model', desc: '', args: []);
  }

  /// `您当前正在使用 {modelName}`
  String you_are_now_using(Object modelName) {
    return Intl.message(
      '您当前正在使用 $modelName',
      name: 'you_are_now_using',
      desc: '',
      args: [modelName],
    );
  }

  /// `点击此处开始新聊天`
  String get click_here_to_start_a_new_chat {
    return Intl.message(
      '点击此处开始新聊天',
      name: 'click_here_to_start_a_new_chat',
      desc: '',
      args: [],
    );
  }

  /// `点击此处选择新模型`
  String get click_here_to_select_a_new_model {
    return Intl.message(
      '点击此处选择新模型',
      name: 'click_here_to_select_a_new_model',
      desc: '',
      args: [],
    );
  }

  /// `请确保设备内存充足，否则可能导致应用崩溃`
  String get ensure_you_have_enough_memory_to_load_the_model {
    return Intl.message(
      '请确保设备内存充足，否则可能导致应用崩溃',
      name: 'ensure_you_have_enough_memory_to_load_the_model',
      desc: '',
      args: [],
    );
  }

  /// `已用内存：{memUsed}，剩余内存：{memFree}`
  String memory_used(Object memUsed, Object memFree) {
    return Intl.message(
      '已用内存：$memUsed，剩余内存：$memFree',
      name: 'memory_used',
      desc: '',
      args: [memUsed, memFree],
    );
  }

  /// `您可以选择角色进行聊天`
  String get you_can_select_a_role_to_chat {
    return Intl.message(
      '您可以选择角色进行聊天',
      name: 'you_can_select_a_role_to_chat',
      desc: '',
      args: [],
    );
  }

  /// `新聊天`
  String get new_chat {
    return Intl.message('新聊天', name: 'new_chat', desc: '', args: []);
  }

  /// `或开始一个空白聊天`
  String get or_you_can_start_a_new_empty_chat {
    return Intl.message(
      '或开始一个空白聊天',
      name: 'or_you_can_start_a_new_empty_chat',
      desc: '',
      args: [],
    );
  }

  /// `开始新聊天`
  String get start_a_new_chat {
    return Intl.message('开始新聊天', name: 'start_a_new_chat', desc: '', args: []);
  }

  /// `现在可以开始与 RWKV 聊天了`
  String get you_can_now_start_to_chat_with_rwkv {
    return Intl.message(
      '现在可以开始与 RWKV 聊天了',
      name: 'you_can_now_start_to_chat_with_rwkv',
      desc: '',
      args: [],
    );
  }

  /// `机器人消息已编辑，现在可以发送新消息`
  String get bot_message_edited {
    return Intl.message(
      '机器人消息已编辑，现在可以发送新消息',
      name: 'bot_message_edited',
      desc: '',
      args: [],
    );
  }

  /// `下载源`
  String get download_source {
    return Intl.message('下载源', name: 'download_source', desc: '', args: []);
  }

  /// `选择任务类型`
  String get select_a_world_type {
    return Intl.message(
      '选择任务类型',
      name: 'select_a_world_type',
      desc: '',
      args: [],
    );
  }

  /// `请选择任务类型`
  String get please_select_a_world_type {
    return Intl.message(
      '请选择任务类型',
      name: 'please_select_a_world_type',
      desc: '',
      args: [],
    );
  }

  /// `加载中...`
  String get loading {
    return Intl.message('加载中...', name: 'loading', desc: '', args: []);
  }

  /// `取消`
  String get cancel {
    return Intl.message('取消', name: 'cancel', desc: '', args: []);
  }

  /// `会话配置`
  String get session_configuration {
    return Intl.message(
      '会话配置',
      name: 'session_configuration',
      desc: '',
      args: [],
    );
  }

  /// `应用`
  String get apply {
    return Intl.message('应用', name: 'apply', desc: '', args: []);
  }

  /// `重置`
  String get reset {
    return Intl.message('重置', name: 'reset', desc: '', args: []);
  }

  /// `自动`
  String get auto {
    return Intl.message('自动', name: 'auto', desc: '', args: []);
  }

  /// `点击上方按钮创建新会话`
  String get create_a_new_one_by_clicking_the_button_above {
    return Intl.message(
      '点击上方按钮创建新会话',
      name: 'create_a_new_one_by_clicking_the_button_above',
      desc: '',
      args: [],
    );
  }

  /// `下载速度：`
  String get speed {
    return Intl.message('下载速度：', name: 'speed', desc: '', args: []);
  }

  /// `剩余时间：`
  String get remaining {
    return Intl.message('剩余时间：', name: 'remaining', desc: '', args: []);
  }

  /// `使用中文推理`
  String get prefer_chinese {
    return Intl.message('使用中文推理', name: 'prefer_chinese', desc: '', args: []);
  }

  /// `推理模式`
  String get reasoning_enabled {
    return Intl.message('推理模式', name: 'reasoning_enabled', desc: '', args: []);
  }

  /// `请等待模型加载`
  String get please_wait_for_the_model_to_load {
    return Intl.message(
      '请等待模型加载',
      name: 'please_wait_for_the_model_to_load',
      desc: '',
      args: [],
    );
  }

  /// `请等待模型生成完成`
  String get please_wait_for_the_model_to_finish_generating {
    return Intl.message(
      '请等待模型生成完成',
      name: 'please_wait_for_the_model_to_finish_generating',
      desc: '',
      args: [],
    );
  }

  /// `推理`
  String get reason {
    return Intl.message('推理', name: 'reason', desc: '', args: []);
  }

  /// `点击选择模型`
  String get click_to_select_model {
    return Intl.message(
      '点击选择模型',
      name: 'click_to_select_model',
      desc: '',
      args: [],
    );
  }

  /// `确定要删除这个模型吗？`
  String get are_you_sure_you_want_to_delete_this_model {
    return Intl.message(
      '确定要删除这个模型吗？',
      name: 'are_you_sure_you_want_to_delete_this_model',
      desc: '',
      args: [],
    );
  }

  /// `删除`
  String get delete {
    return Intl.message('删除', name: 'delete', desc: '', args: []);
  }

  /// `使用`
  String get prefer {
    return Intl.message('使用', name: 'prefer', desc: '', args: []);
  }

  /// `中文`
  String get chinese {
    return Intl.message('中文', name: 'chinese', desc: '', args: []);
  }

  /// `思考中...`
  String get thinking {
    return Intl.message('思考中...', name: 'thinking', desc: '', args: []);
  }

  /// `思考结果`
  String get thought_result {
    return Intl.message('思考结果', name: 'thought_result', desc: '', args: []);
  }

  /// `继续`
  String get chat_resume {
    return Intl.message('继续', name: 'chat_resume', desc: '', args: []);
  }

  /// `网络错误`
  String get network_error {
    return Intl.message('网络错误', name: 'network_error', desc: '', args: []);
  }

  /// `服务器错误`
  String get server_error {
    return Intl.message('服务器错误', name: 'server_error', desc: '', args: []);
  }

  /// `发现新版本`
  String get new_version_found {
    return Intl.message('发现新版本', name: 'new_version_found', desc: '', args: []);
  }

  /// `暂不更新`
  String get cancel_update {
    return Intl.message('暂不更新', name: 'cancel_update', desc: '', args: []);
  }

  /// `立即更新`
  String get update_now {
    return Intl.message('立即更新', name: 'update_now', desc: '', args: []);
  }

  /// `返回聊天`
  String get back_to_chat {
    return Intl.message('返回聊天', name: 'back_to_chat', desc: '', args: []);
  }

  /// `全部删除`
  String get delete_all {
    return Intl.message('全部删除', name: 'delete_all', desc: '', args: []);
  }

  /// `下载缺失文件`
  String get download_missing {
    return Intl.message('下载缺失文件', name: 'download_missing', desc: '', args: []);
  }

  /// `探索中...`
  String get exploring {
    return Intl.message('探索中...', name: 'exploring', desc: '', args: []);
  }

  /// `我想让 RWKV 说...`
  String get i_want_rwkv_to_say {
    return Intl.message(
      '我想让 RWKV 说...',
      name: 'i_want_rwkv_to_say',
      desc: '',
      args: [],
    );
  }

  /// `声音克隆`
  String get voice_cloning {
    return Intl.message('声音克隆', name: 'voice_cloning', desc: '', args: []);
  }

  /// `预设声音`
  String get prebuilt_voices {
    return Intl.message('预设声音', name: 'prebuilt_voices', desc: '', args: []);
  }

  /// `语气词`
  String get intonations {
    return Intl.message('语气词', name: 'intonations', desc: '', args: []);
  }

  /// `跟随系统`
  String get follow_system {
    return Intl.message('跟随系统', name: 'follow_system', desc: '', args: []);
  }

  /// `应用语言`
  String get application_language {
    return Intl.message(
      '应用语言',
      name: 'application_language',
      desc: '',
      args: [],
    );
  }

  /// `请选择应用语言`
  String get please_select_application_language {
    return Intl.message(
      '请选择应用语言',
      name: 'please_select_application_language',
      desc: '',
      args: [],
    );
  }

  /// `请选择字体大小`
  String get please_select_font_size {
    return Intl.message(
      '请选择字体大小',
      name: 'please_select_font_size',
      desc: '',
      args: [],
    );
  }

  /// `字体大小`
  String get font_size {
    return Intl.message('字体大小', name: 'font_size', desc: '', args: []);
  }

  /// `字体设置`
  String get font_setting {
    return Intl.message('字体设置', name: 'font_setting', desc: '', args: []);
  }

  /// `非常小 (80%)`
  String get very_small {
    return Intl.message('非常小 (80%)', name: 'very_small', desc: '', args: []);
  }

  /// `小 (90%)`
  String get small {
    return Intl.message('小 (90%)', name: 'small', desc: '', args: []);
  }

  /// `默认 (100%)`
  String get font_size_default {
    return Intl.message(
      '默认 (100%)',
      name: 'font_size_default',
      desc: '',
      args: [],
    );
  }

  /// `中 (110%)`
  String get medium {
    return Intl.message('中 (110%)', name: 'medium', desc: '', args: []);
  }

  /// `大 (120%)`
  String get large {
    return Intl.message('大 (120%)', name: 'large', desc: '', args: []);
  }

  /// `特大 (130%)`
  String get extra_large {
    return Intl.message('特大 (130%)', name: 'extra_large', desc: '', args: []);
  }

  /// `超大 (140%)`
  String get ultra_large {
    return Intl.message('超大 (140%)', name: 'ultra_large', desc: '', args: []);
  }

  /// `反馈问题`
  String get feedback {
    return Intl.message('反馈问题', name: 'feedback', desc: '', args: []);
  }

  /// `开源许可证`
  String get license {
    return Intl.message('开源许可证', name: 'license', desc: '', args: []);
  }

  /// `应用设置`
  String get application_settings {
    return Intl.message(
      '应用设置',
      name: 'application_settings',
      desc: '',
      args: [],
    );
  }

  /// `加入社区`
  String get join_the_community {
    return Intl.message('加入社区', name: 'join_the_community', desc: '', args: []);
  }

  /// `关于`
  String get about {
    return Intl.message('关于', name: 'about', desc: '', args: []);
  }

  /// `使用`
  String get imitate_target {
    return Intl.message('使用', name: 'imitate_target', desc: '', args: []);
  }

  /// `你好，这个问题我暂时无法回答，让我们换个话题再聊聊吧。`
  String get filter {
    return Intl.message(
      '你好，这个问题我暂时无法回答，让我们换个话题再聊聊吧。',
      name: 'filter',
      desc: '',
      args: [],
    );
  }

  /// `游戏结束！`
  String get game_over {
    return Intl.message('游戏结束！', name: 'game_over', desc: '', args: []);
  }

  /// `黑方获胜！`
  String get black_wins {
    return Intl.message('黑方获胜！', name: 'black_wins', desc: '', args: []);
  }

  /// `白方获胜！`
  String get white_wins {
    return Intl.message('白方获胜！', name: 'white_wins', desc: '', args: []);
  }

  /// `平局！`
  String get draw {
    return Intl.message('平局！', name: 'draw', desc: '', args: []);
  }

  /// `黑方得分`
  String get black_score {
    return Intl.message('黑方得分', name: 'black_score', desc: '', args: []);
  }

  /// `白方得分`
  String get white_score {
    return Intl.message('白方得分', name: 'white_score', desc: '', args: []);
  }

  /// `搜索深度`
  String get search_depth {
    return Intl.message('搜索深度', name: 'search_depth', desc: '', args: []);
  }

  /// `搜索宽度`
  String get search_breadth {
    return Intl.message('搜索宽度', name: 'search_breadth', desc: '', args: []);
  }

  /// `白方`
  String get white {
    return Intl.message('白方', name: 'white', desc: '', args: []);
  }

  /// `黑方`
  String get black {
    return Intl.message('黑方', name: 'black', desc: '', args: []);
  }

  /// `人类`
  String get human {
    return Intl.message('人类', name: 'human', desc: '', args: []);
  }

  /// `玩家`
  String get players {
    return Intl.message('玩家', name: 'players', desc: '', args: []);
  }

  /// `模型设置`
  String get model_settings {
    return Intl.message('模型设置', name: 'model_settings', desc: '', args: []);
  }

  /// `当搜索深度和宽度都大于 2 时，将激活上下文搜索`
  String
  get in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2 {
    return Intl.message(
      '当搜索深度和宽度都大于 2 时，将激活上下文搜索',
      name:
          'in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2',
      desc: '',
      args: [],
    );
  }

  /// `新游戏`
  String get new_game {
    return Intl.message('新游戏', name: 'new_game', desc: '', args: []);
  }

  /// `RWKV`
  String get rwkv {
    return Intl.message('RWKV', name: 'rwkv', desc: '', args: []);
  }

  /// `预填`
  String get prefill {
    return Intl.message('预填', name: 'prefill', desc: '', args: []);
  }

  /// `解码`
  String get decode {
    return Intl.message('解码', name: 'decode', desc: '', args: []);
  }

  /// `当前回合`
  String get current_turn {
    return Intl.message('当前回合', name: 'current_turn', desc: '', args: []);
  }

  /// `开始对局`
  String get start_a_new_game {
    return Intl.message('开始对局', name: 'start_a_new_game', desc: '', args: []);
  }

  /// `请等待模型生成`
  String get please_wait_for_the_model_to_generate {
    return Intl.message(
      '请等待模型生成',
      name: 'please_wait_for_the_model_to_generate',
      desc: '',
      args: [],
    );
  }

  /// `取消下载`
  String get cancel_download {
    return Intl.message('取消下载', name: 'cancel_download', desc: '', args: []);
  }

  /// `继续下载`
  String get continue_download {
    return Intl.message('继续下载', name: 'continue_download', desc: '', args: []);
  }

  /// `生成`
  String get generate {
    return Intl.message('生成', name: 'generate', desc: '', args: []);
  }

  /// `推理中`
  String get inference_is_running {
    return Intl.message(
      '推理中',
      name: 'inference_is_running',
      desc: '',
      args: [],
    );
  }

  /// `请等待推理完成`
  String get please_wait_for_it_to_finish {
    return Intl.message(
      '请等待推理完成',
      name: 'please_wait_for_it_to_finish',
      desc: '',
      args: [],
    );
  }

  /// `😎 看我表演！`
  String get just_watch_me {
    return Intl.message('😎 看我表演！', name: 'just_watch_me', desc: '', args: []);
  }

  /// `这是世界上最难的数独`
  String get this_is_the_hardest_sudoku_in_the_world {
    return Intl.message(
      '这是世界上最难的数独',
      name: 'this_is_the_hardest_sudoku_in_the_world',
      desc: '',
      args: [],
    );
  }

  /// `轮到你了~`
  String get its_your_turn {
    return Intl.message('轮到你了~', name: 'its_your_turn', desc: '', args: []);
  }

  /// `生成世界上最难的数独`
  String get generate_hardest_sudoku_in_the_world {
    return Intl.message(
      '生成世界上最难的数独',
      name: 'generate_hardest_sudoku_in_the_world',
      desc: '',
      args: [],
    );
  }

  /// `开始推理`
  String get start_to_inference {
    return Intl.message('开始推理', name: 'start_to_inference', desc: '', args: []);
  }

  /// `没有数独`
  String get no_puzzle {
    return Intl.message('没有数独', name: 'no_puzzle', desc: '', args: []);
  }

  /// `隐藏思维链堆栈`
  String get hide_stack {
    return Intl.message('隐藏思维链堆栈', name: 'hide_stack', desc: '', args: []);
  }

  /// `显示思维链堆栈`
  String get show_stack {
    return Intl.message('显示思维链堆栈', name: 'show_stack', desc: '', args: []);
  }

  /// `清除`
  String get clear {
    return Intl.message('清除', name: 'clear', desc: '', args: []);
  }

  /// `设置网格值`
  String get set_the_value_of_grid {
    return Intl.message(
      '设置网格值',
      name: 'set_the_value_of_grid',
      desc: '',
      args: [],
    );
  }

  /// `请输入一个数字。0 表示空。`
  String get please_enter_a_number_0_means_empty {
    return Intl.message(
      '请输入一个数字。0 表示空。',
      name: 'please_enter_a_number_0_means_empty',
      desc: '',
      args: [],
    );
  }

  /// `无效值`
  String get invalid_value {
    return Intl.message('无效值', name: 'invalid_value', desc: '', args: []);
  }

  /// `值必须在 0 和 9 之间`
  String get value_must_be_between_0_and_9 {
    return Intl.message(
      '值必须在 0 和 9 之间',
      name: 'value_must_be_between_0_and_9',
      desc: '',
      args: [],
    );
  }

  /// `无效数独`
  String get invalid_puzzle {
    return Intl.message('无效数独', name: 'invalid_puzzle', desc: '', args: []);
  }

  /// `数独无效`
  String get the_puzzle_is_not_valid {
    return Intl.message(
      '数独无效',
      name: 'the_puzzle_is_not_valid',
      desc: '',
      args: [],
    );
  }

  /// `难度`
  String get difficulty {
    return Intl.message('难度', name: 'difficulty', desc: '', args: []);
  }

  /// `无法生成`
  String get can_not_generate {
    return Intl.message('无法生成', name: 'can_not_generate', desc: '', args: []);
  }

  /// `难度必须大于 0`
  String get difficulty_must_be_greater_than_0 {
    return Intl.message(
      '难度必须大于 0',
      name: 'difficulty_must_be_greater_than_0',
      desc: '',
      args: [],
    );
  }

  /// `生成随机数独`
  String get generate_random_sudoku_puzzle {
    return Intl.message(
      '生成随机数独',
      name: 'generate_random_sudoku_puzzle',
      desc: '',
      args: [],
    );
  }

  /// `请选择难度`
  String get please_select_the_difficulty {
    return Intl.message(
      '请选择难度',
      name: 'please_select_the_difficulty',
      desc: '',
      args: [],
    );
  }

  /// `难度必须小于 81`
  String get difficulty_must_be_less_than_81 {
    return Intl.message(
      '难度必须小于 81',
      name: 'difficulty_must_be_less_than_81',
      desc: '',
      args: [],
    );
  }

  /// `数字`
  String get number {
    return Intl.message('数字', name: 'number', desc: '', args: []);
  }

  /// `确定`
  String get ok {
    return Intl.message('确定', name: 'ok', desc: '', args: []);
  }

  /// `根据: `
  String get according_to_the_following_audio_file {
    return Intl.message(
      '根据: ',
      name: 'according_to_the_following_audio_file',
      desc: '',
      args: [],
    );
  }

  /// `QQ 群 1`
  String get qq_group_1 {
    return Intl.message('QQ 群 1', name: 'qq_group_1', desc: '', args: []);
  }

  /// `QQ 群 2`
  String get qq_group_2 {
    return Intl.message('QQ 群 2', name: 'qq_group_2', desc: '', args: []);
  }

  /// `Discord`
  String get discord {
    return Intl.message('Discord', name: 'discord', desc: '', args: []);
  }

  /// `Twitter`
  String get twitter {
    return Intl.message('Twitter', name: 'twitter', desc: '', args: []);
  }

  /// `应用内测群`
  String get application_internal_test_group {
    return Intl.message(
      '应用内测群',
      name: 'application_internal_test_group',
      desc: '',
      args: [],
    );
  }

  /// `技术研发群`
  String get technical_research_group {
    return Intl.message(
      '技术研发群',
      name: 'technical_research_group',
      desc: '',
      args: [],
    );
  }

  /// `加入我们的 Discord 服务器`
  String get join_our_discord_server {
    return Intl.message(
      '加入我们的 Discord 服务器',
      name: 'join_our_discord_server',
      desc: '',
      args: [],
    );
  }

  /// `在 Twitter 上关注我们`
  String get follow_us_on_twitter {
    return Intl.message(
      '在 Twitter 上关注我们',
      name: 'follow_us_on_twitter',
      desc: '',
      args: [],
    );
  }

  /// `请先加载模型`
  String get please_load_model_first {
    return Intl.message(
      '请先加载模型',
      name: 'please_load_model_first',
      desc: '',
      args: [],
    );
  }

  /// `🎉 推理完成`
  String get inference_is_done {
    return Intl.message(
      '🎉 推理完成',
      name: 'inference_is_done',
      desc: '',
      args: [],
    );
  }

  /// `请检查结果`
  String get please_check_the_result {
    return Intl.message(
      '请检查结果',
      name: 'please_check_the_result',
      desc: '',
      args: [],
    );
  }

  /// `生成中...`
  String get generating {
    return Intl.message('生成中...', name: 'generating', desc: '', args: []);
  }

  /// `全部完成`
  String get all_done {
    return Intl.message('全部完成', name: 'all_done', desc: '', args: []);
  }

  /// `正在播放部分已生成的语音`
  String get playing_partial_generated_audio {
    return Intl.message(
      '正在播放部分已生成的语音',
      name: 'playing_partial_generated_audio',
      desc: '',
      args: [],
    );
  }

  /// `无子可下`
  String get no_cell_available {
    return Intl.message('无子可下', name: 'no_cell_available', desc: '', args: []);
  }

  /// `落子权转移`
  String get turn_transfer {
    return Intl.message('落子权转移', name: 'turn_transfer', desc: '', args: []);
  }

  /// `继续使用较小模型`
  String get continue_using_smaller_model {
    return Intl.message(
      '继续使用较小模型',
      name: 'continue_using_smaller_model',
      desc: '',
      args: [],
    );
  }

  /// `重新选择模型`
  String get reselect_model {
    return Intl.message('重新选择模型', name: 'reselect_model', desc: '', args: []);
  }

  /// `推荐至少选择 1.5B 模型，效果更好`
  String get size_recommendation {
    return Intl.message(
      '推荐至少选择 1.5B 模型，效果更好',
      name: 'size_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `您可以录制您的声音，然后让 RWKV 模仿它。`
  String get you_can_record_your_voice_and_let_rwkv_to_copy_it {
    return Intl.message(
      '您可以录制您的声音，然后让 RWKV 模仿它。',
      name: 'you_can_record_your_voice_and_let_rwkv_to_copy_it',
      desc: '',
      args: [],
    );
  }

  /// `或者选择一个 wav 文件，让 RWKV 模仿它。`
  String get or_select_a_wav_file_to_let_rwkv_to_copy_it {
    return Intl.message(
      '或者选择一个 wav 文件，让 RWKV 模仿它。',
      name: 'or_select_a_wav_file_to_let_rwkv_to_copy_it',
      desc: '',
      args: [],
    );
  }

  /// `按住录音，松开发送`
  String get hold_to_record_release_to_send {
    return Intl.message(
      '按住录音，松开发送',
      name: 'hold_to_record_release_to_send',
      desc: '',
      args: [],
    );
  }

  /// `正在录音...`
  String get recording_your_voice {
    return Intl.message(
      '正在录音...',
      name: 'recording_your_voice',
      desc: '',
      args: [],
    );
  }

  /// `录音完成`
  String get finish_recording {
    return Intl.message('录音完成', name: 'finish_recording', desc: '', args: []);
  }

  /// `请授予使用麦克风的权限`
  String get please_grant_permission_to_use_microphone {
    return Intl.message(
      '请授予使用麦克风的权限',
      name: 'please_grant_permission_to_use_microphone',
      desc: '',
      args: [],
    );
  }

  /// `您的声音太短，请长按按钮更久以获取您的声音。`
  String get your_voice_is_too_short {
    return Intl.message(
      '您的声音太短，请长按按钮更久以获取您的声音。',
      name: 'your_voice_is_too_short',
      desc: '',
      args: [],
    );
  }

  /// `我的声音`
  String get my_voice {
    return Intl.message('我的声音', name: 'my_voice', desc: '', args: []);
  }

  /// `下载全部`
  String get download_all {
    return Intl.message('下载全部', name: 'download_all', desc: '', args: []);
  }

  /// `开始新聊天`
  String get new_chat_started {
    return Intl.message('开始新聊天', name: 'new_chat_started', desc: '', args: []);
  }

  /// `模仿 {flag} {nameCN}({nameEN}) 的声音`
  String imitate(Object flag, Object nameCN, Object nameEN) {
    return Intl.message(
      '模仿 $flag $nameCN($nameEN) 的声音',
      name: 'imitate',
      desc: '',
      args: [flag, nameCN, nameEN],
    );
  }

  /// `模仿 {fileName}`
  String imitate_fle(Object fileName) {
    return Intl.message(
      '模仿 $fileName',
      name: 'imitate_fle',
      desc: '',
      args: [fileName],
    );
  }

  /// `选择图片`
  String get select_image {
    return Intl.message('选择图片', name: 'select_image', desc: '', args: []);
  }

  /// `从相册选择`
  String get select_from_library {
    return Intl.message(
      '从相册选择',
      name: 'select_from_library',
      desc: '',
      args: [],
    );
  }

  /// `拍照`
  String get take_photo {
    return Intl.message('拍照', name: 'take_photo', desc: '', args: []);
  }

  /// `请从以下选项中选择一个图片`
  String get please_select_an_image_from_the_following_options {
    return Intl.message(
      '请从以下选项中选择一个图片',
      name: 'please_select_an_image_from_the_following_options',
      desc: '',
      args: [],
    );
  }

  /// `点击加载图片`
  String get click_to_load_image {
    return Intl.message(
      '点击加载图片',
      name: 'click_to_load_image',
      desc: '',
      args: [],
    );
  }

  /// `然后您就可以开始与 RWKV 对话了`
  String get then_you_can_start_to_chat_with_rwkv {
    return Intl.message(
      '然后您就可以开始与 RWKV 对话了',
      name: 'then_you_can_start_to_chat_with_rwkv',
      desc: '',
      args: [],
    );
  }

  /// `选择新图片`
  String get select_new_image {
    return Intl.message('选择新图片', name: 'select_new_image', desc: '', args: []);
  }

  /// `存储权限未授予`
  String get storage_permission_not_granted {
    return Intl.message(
      '存储权限未授予',
      name: 'storage_permission_not_granted',
      desc: '',
      args: [],
    );
  }

  /// `自动 dump 已开启`
  String get dump_started {
    return Intl.message(
      '自动 dump 已开启',
      name: 'dump_started',
      desc: '',
      args: [],
    );
  }

  /// `自动 dump 已关闭`
  String get dump_stopped {
    return Intl.message(
      '自动 dump 已关闭',
      name: 'dump_stopped',
      desc: '',
      args: [],
    );
  }

  /// `自动 Dump 消息记录`
  String get dump_see_files {
    return Intl.message(
      '自动 Dump 消息记录',
      name: 'dump_see_files',
      desc: '',
      args: [],
    );
  }

  /// `协助我们改进算法`
  String get dump_see_files_subtitle {
    return Intl.message(
      '协助我们改进算法',
      name: 'dump_see_files_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `消息记录会存储在该文件夹下\n {path}`
  String dump_see_files_alert_message(Object path) {
    return Intl.message(
      '消息记录会存储在该文件夹下\n $path',
      name: 'dump_see_files_alert_message',
      desc: '',
      args: [path],
    );
  }

  /// `全部`
  String get all {
    return Intl.message('全部', name: 'all', desc: '', args: []);
  }

  /// `全部 Prompt`
  String get all_prompt {
    return Intl.message('全部 Prompt', name: 'all_prompt', desc: '', args: []);
  }

  /// `无数据`
  String get no_data {
    return Intl.message('无数据', name: 'no_data', desc: '', args: []);
  }

  /// `分享聊天`
  String get share_chat {
    return Intl.message('分享聊天', name: 'share_chat', desc: '', args: []);
  }

  /// `快思考`
  String get quick_thinking {
    return Intl.message('快思考', name: 'quick_thinking', desc: '', args: []);
  }

  /// `快思考已经开启`
  String get quick_thinking_enabled {
    return Intl.message(
      '快思考已经开启',
      name: 'quick_thinking_enabled',
      desc: '',
      args: [],
    );
  }

  /// `从浏览器下载`
  String get download_from_browser {
    return Intl.message(
      '从浏览器下载',
      name: 'download_from_browser',
      desc: '',
      args: [],
    );
  }

  /// `下载中`
  String get downloading {
    return Intl.message('下载中', name: 'downloading', desc: '', args: []);
  }

  /// `下载服务器(请试试哪个快)`
  String get download_server_ {
    return Intl.message(
      '下载服务器(请试试哪个快)',
      name: 'download_server_',
      desc: '',
      args: [],
    );
  }

  /// `(境外)`
  String get overseas {
    return Intl.message('(境外)', name: 'overseas', desc: '', args: []);
  }

  /// `已选 %d 条消息`
  String get x_message_selected {
    return Intl.message(
      '已选 %d 条消息',
      name: 'x_message_selected',
      desc: '',
      args: [],
    );
  }

  /// `外观`
  String get appearance {
    return Intl.message('外观', name: 'appearance', desc: '', args: []);
  }

  /// `深色模式`
  String get dark_mode {
    return Intl.message('深色模式', name: 'dark_mode', desc: '', args: []);
  }

  /// `强制使用深色模式`
  String get force_dark_mode {
    return Intl.message(
      '强制使用深色模式',
      name: 'force_dark_mode',
      desc: '',
      args: [],
    );
  }

  /// `浅色模式`
  String get light_mode {
    return Intl.message('浅色模式', name: 'light_mode', desc: '', args: []);
  }

  /// `跟随系统`
  String get system_mode {
    return Intl.message('跟随系统', name: 'system_mode', desc: '', args: []);
  }

  /// `色彩模式跟随系统`
  String get color_theme_follow_system {
    return Intl.message(
      '色彩模式跟随系统',
      name: 'color_theme_follow_system',
      desc: '',
      args: [],
    );
  }

  /// `深色模式主题`
  String get dark_mode_theme {
    return Intl.message('深色模式主题', name: 'dark_mode_theme', desc: '', args: []);
  }

  /// `深色`
  String get theme_dim {
    return Intl.message('深色', name: 'theme_dim', desc: '', args: []);
  }

  /// `黑色`
  String get theme_lights_out {
    return Intl.message('黑色', name: 'theme_lights_out', desc: '', args: []);
  }

  /// `浅色`
  String get theme_light {
    return Intl.message('浅色', name: 'theme_light', desc: '', args: []);
  }

  /// `懒`
  String get lazy {
    return Intl.message('懒', name: 'lazy', desc: '', args: []);
  }

  /// `入门`
  String get sudoku_easy {
    return Intl.message('入门', name: 'sudoku_easy', desc: '', args: []);
  }

  /// `普通`
  String get sudoku_medium {
    return Intl.message('普通', name: 'sudoku_medium', desc: '', args: []);
  }

  /// `专家`
  String get sudoku_hard {
    return Intl.message('专家', name: 'sudoku_hard', desc: '', args: []);
  }

  /// `自定义难度`
  String get custom_difficulty {
    return Intl.message('自定义难度', name: 'custom_difficulty', desc: '', args: []);
  }

  /// `请输入难度`
  String get please_enter_the_difficulty {
    return Intl.message(
      '请输入难度',
      name: 'please_enter_the_difficulty',
      desc: '',
      args: [],
    );
  }

  /// `分享`
  String get share {
    return Intl.message('分享', name: 'share', desc: '', args: []);
  }

  /// `保存`
  String get save {
    return Intl.message('保存', name: 'save', desc: '', args: []);
  }

  /// `确认`
  String get confirm {
    return Intl.message('确认', name: 'confirm', desc: '', args: []);
  }

  /// `扫描二维码`
  String get scan_qrcode {
    return Intl.message('扫描二维码', name: 'scan_qrcode', desc: '', args: []);
  }

  /// `下载App`
  String get download_app {
    return Intl.message('下载App', name: 'download_app', desc: '', args: []);
  }

  /// `完`
  String get end {
    return Intl.message('完', name: 'end', desc: '', args: []);
  }

  /// `来自模型: %s`
  String get from_model {
    return Intl.message('来自模型: %s', name: 'from_model', desc: '', args: []);
  }

  /// `探索RWKV`
  String get explore_rwkv {
    return Intl.message('探索RWKV', name: 'explore_rwkv', desc: '', args: []);
  }

  /// `续写模式`
  String get completion_mode {
    return Intl.message('续写模式', name: 'completion_mode', desc: '', args: []);
  }

  /// `对话模式`
  String get chat_mode {
    return Intl.message('对话模式', name: 'chat_mode', desc: '', args: []);
  }

  /// `提示词`
  String get prompt {
    return Intl.message('提示词', name: 'prompt', desc: '', args: []);
  }

  /// `输出`
  String get output {
    return Intl.message('输出', name: 'output', desc: '', args: []);
  }

  /// `提交`
  String get submit {
    return Intl.message('提交', name: 'submit', desc: '', args: []);
  }

  /// `重新生成`
  String get regenerate {
    return Intl.message('重新生成', name: 'regenerate', desc: '', args: []);
  }

  /// `恢复`
  String get resume {
    return Intl.message('恢复', name: 'resume', desc: '', args: []);
  }

  /// `停止`
  String get stop {
    return Intl.message('停止', name: 'stop', desc: '', args: []);
  }

  /// `暂停`
  String get pause {
    return Intl.message('暂停', name: 'pause', desc: '', args: []);
  }

  /// `更多`
  String get more {
    return Intl.message('更多', name: 'more', desc: '', args: []);
  }

  /// `推荐至少选择1.5B模型，更大的2.9B模型更好`
  String get str_model_selection_dialog_hint {
    return Intl.message(
      '推荐至少选择1.5B模型，更大的2.9B模型更好',
      name: 'str_model_selection_dialog_hint',
      desc: '',
      args: [],
    );
  }

  /// `设置`
  String get settings {
    return Intl.message('设置', name: 'settings', desc: '', args: []);
  }

  /// `聊天记录`
  String get chat_history {
    return Intl.message('聊天记录', name: 'chat_history', desc: '', args: []);
  }

  /// `搜索`
  String get search {
    return Intl.message('搜索', name: 'search', desc: '', args: []);
  }

  /// `参考源`
  String get reference_source {
    return Intl.message('参考源', name: 'reference_source', desc: '', args: []);
  }

  /// `正在分析搜索结果`
  String get analysing_result {
    return Intl.message(
      '正在分析搜索结果',
      name: 'analysing_result',
      desc: '',
      args: [],
    );
  }

  /// `已找到 %d 个相关网页`
  String get x_pages_found {
    return Intl.message(
      '已找到 %d 个相关网页',
      name: 'x_pages_found',
      desc: '',
      args: [],
    );
  }

  /// `关闭`
  String get off {
    return Intl.message('关闭', name: 'off', desc: '', args: []);
  }

  /// `联网`
  String get web_search {
    return Intl.message('联网', name: 'web_search', desc: '', args: []);
  }

  /// `深度联网`
  String get deep_web_search {
    return Intl.message('深度联网', name: 'deep_web_search', desc: '', args: []);
  }

  /// `下载失败`
  String get download_failed {
    return Intl.message('下载失败', name: 'download_failed', desc: '', args: []);
  }

  /// `允许后台下载`
  String get allow_background_downloads {
    return Intl.message(
      '允许后台下载',
      name: 'allow_background_downloads',
      desc: '',
      args: [],
    );
  }

  /// `请关闭电池优化已允许后台下载，否则切换到其他应用时下载可能会被暂停`
  String get str_please_disable_battery_opt_ {
    return Intl.message(
      '请关闭电池优化已允许后台下载，否则切换到其他应用时下载可能会被暂停',
      name: 'str_please_disable_battery_opt_',
      desc: '',
      args: [],
    );
  }

  /// `去设置`
  String get go_to_settings {
    return Intl.message('去设置', name: 'go_to_settings', desc: '', args: []);
  }

  /// `不再询问`
  String get dont_ask_again {
    return Intl.message('不再询问', name: 'dont_ask_again', desc: '', args: []);
  }

  /// `搜索中...`
  String get searching {
    return Intl.message('搜索中...', name: 'searching', desc: '', args: []);
  }

  /// `搜索失败`
  String get search_failed {
    return Intl.message('搜索失败', name: 'search_failed', desc: '', args: []);
  }

  /// `欢迎探索 RWKV Chat`
  String get welcome_to_rwkv_chat {
    return Intl.message(
      '欢迎探索 RWKV Chat',
      name: 'welcome_to_rwkv_chat',
      desc: '',
      args: [],
    );
  }

  /// `开始对话`
  String get chat {
    return Intl.message('开始对话', name: 'chat', desc: '', args: []);
  }

  /// `Neko`
  String get neko {
    return Intl.message('Neko', name: 'neko', desc: '', args: []);
  }

  /// `续写模式`
  String get Completion {
    return Intl.message('续写模式', name: 'Completion', desc: '', args: []);
  }

  /// `与 RWKV 模型对话`
  String get chat_with_rwkv_model {
    return Intl.message(
      '与 RWKV 模型对话',
      name: 'chat_with_rwkv_model',
      desc: '',
      args: [],
    );
  }

  /// `文本补全模式`
  String get text_completion_mode {
    return Intl.message(
      '文本补全模式',
      name: 'text_completion_mode',
      desc: '',
      args: [],
    );
  }

  /// `主页`
  String get home {
    return Intl.message('主页', name: 'home', desc: '', args: []);
  }

  /// `会话`
  String get conversations {
    return Intl.message('会话', name: 'conversations', desc: '', args: []);
  }

  /// `Hello, 请随意 \n向我提问...`
  String get hello_ask_me_anything {
    return Intl.message(
      'Hello, 请随意 \n向我提问...',
      name: 'hello_ask_me_anything',
      desc: '',
      args: [],
    );
  }

  /// `目前还没有对话`
  String get no_conversation_yet {
    return Intl.message(
      '目前还没有对话',
      name: 'no_conversation_yet',
      desc: '',
      args: [],
    );
  }

  /// `Nyan~~,Nyan~~`
  String get nyan_nyan {
    return Intl.message('Nyan~~,Nyan~~', name: 'nyan_nyan', desc: '', args: []);
  }

  /// `随意向我提问...`
  String get ask_me_anything {
    return Intl.message(
      '随意向我提问...',
      name: 'ask_me_anything',
      desc: '',
      args: [],
    );
  }

  /// `应用模式`
  String get application_mode {
    return Intl.message('应用模式', name: 'application_mode', desc: '', args: []);
  }

  /// `请根据你对 AI 和 LLM 的了解程度选择应用模式.`
  String get str_please_select_app_mode_ {
    return Intl.message(
      '请根据你对 AI 和 LLM 的了解程度选择应用模式.',
      name: 'str_please_select_app_mode_',
      desc: '',
      args: [],
    );
  }

  /// `新手模式`
  String get beginner {
    return Intl.message('新手模式', name: 'beginner', desc: '', args: []);
  }

  /// `高级模式`
  String get power_user {
    return Intl.message('高级模式', name: 'power_user', desc: '', args: []);
  }

  /// `专家模式`
  String get expert {
    return Intl.message('专家模式', name: 'expert', desc: '', args: []);
  }

  /// `更多问题`
  String get more_questions {
    return Intl.message('更多问题', name: 'more_questions', desc: '', args: []);
  }

  /// `模型加载中...`
  String get model_loading {
    return Intl.message('模型加载中...', name: 'model_loading', desc: '', args: []);
  }

  /// `暂时还没有任何对话`
  String get no_conversations_yet {
    return Intl.message(
      '暂时还没有任何对话',
      name: 'no_conversations_yet',
      desc: '',
      args: [],
    );
  }

  /// `开始新对话`
  String get new_conversation {
    return Intl.message('开始新对话', name: 'new_conversation', desc: '', args: []);
  }

  /// `高级设置`
  String get advance_settings {
    return Intl.message('高级设置', name: 'advance_settings', desc: '', args: []);
  }

  /// `Prompt 模板`
  String get prompt_template {
    return Intl.message(
      'Prompt 模板',
      name: 'prompt_template',
      desc: '',
      args: [],
    );
  }

  /// `系统提示词`
  String get system_prompt {
    return Intl.message('系统提示词', name: 'system_prompt', desc: '', args: []);
  }

  /// `联网搜索模板`
  String get web_search_template {
    return Intl.message(
      '联网搜索模板',
      name: 'web_search_template',
      desc: '',
      args: [],
    );
  }

  /// `中文联网搜索模板`
  String get chinese_web_search_template {
    return Intl.message(
      '中文联网搜索模板',
      name: 'chinese_web_search_template',
      desc: '',
      args: [],
    );
  }

  /// `思考模式模板`
  String get thinking_mode_template {
    return Intl.message(
      '思考模式模板',
      name: 'thinking_mode_template',
      desc: '',
      args: [],
    );
  }

  /// `中文思考模板`
  String get chinese_thinking_mode_template {
    return Intl.message(
      '中文思考模板',
      name: 'chinese_thinking_mode_template',
      desc: '',
      args: [],
    );
  }

  /// `懒思考模板`
  String get lazy_thinking_mode_template {
    return Intl.message(
      '懒思考模板',
      name: 'lazy_thinking_mode_template',
      desc: '',
      args: [],
    );
  }

  /// `新对话模板`
  String get new_chat_template {
    return Intl.message('新对话模板', name: 'new_chat_template', desc: '', args: []);
  }

  /// `每次新对话将插入此内容, 用两个换行分隔, 例子:\n你好，你是谁？\n\n你好，我是RWKV，有什么我可以帮助你的吗`
  String get new_chat_template_helper_text {
    return Intl.message(
      '每次新对话将插入此内容, 用两个换行分隔, 例子:\n你好，你是谁？\n\n你好，我是RWKV，有什么我可以帮助你的吗',
      name: 'new_chat_template_helper_text',
      desc: '',
      args: [],
    );
  }

  /// `检查更新`
  String get check_for_updates {
    return Intl.message('检查更新', name: 'check_for_updates', desc: '', args: []);
  }

  /// `已经是最新版本`
  String get app_is_already_up_to_date {
    return Intl.message(
      '已经是最新版本',
      name: 'app_is_already_up_to_date',
      desc: '',
      args: [],
    );
  }

  /// `翻译`
  String get translate {
    return Intl.message('翻译', name: 'translate', desc: '', args: []);
  }

  /// `自动检测`
  String get auto_detect {
    return Intl.message('自动检测', name: 'auto_detect', desc: '', args: []);
  }

  /// `清除文本`
  String get clear_text {
    return Intl.message('清除文本', name: 'clear_text', desc: '', args: []);
  }

  /// `输入要翻译的文本...`
  String get enter_text_to_translate {
    return Intl.message(
      '输入要翻译的文本...',
      name: 'enter_text_to_translate',
      desc: '',
      args: [],
    );
  }

  /// `翻译结果`
  String get translation {
    return Intl.message('翻译结果', name: 'translation', desc: '', args: []);
  }

  /// `复制文本`
  String get copy_text {
    return Intl.message('复制文本', name: 'copy_text', desc: '', args: []);
  }

  /// `推理引擎`
  String get inference_engine {
    return Intl.message('推理引擎', name: 'inference_engine', desc: '', args: []);
  }

  /// `模型`
  String get model {
    return Intl.message('模型', name: 'model', desc: '', args: []);
  }

  /// `未选择模型`
  String get no_model_selected {
    return Intl.message('未选择模型', name: 'no_model_selected', desc: '', args: []);
  }

  /// `更改`
  String get change {
    return Intl.message('更改', name: 'change', desc: '', args: []);
  }

  /// `状态`
  String get status {
    return Intl.message('状态', name: 'status', desc: '', args: []);
  }

  /// `翻译中...`
  String get translating {
    return Intl.message('翻译中...', name: 'translating', desc: '', args: []);
  }

  /// `空闲`
  String get idle {
    return Intl.message('空闲', name: 'idle', desc: '', args: []);
  }

  /// `启动中...`
  String get starting {
    return Intl.message('启动中...', name: 'starting', desc: '', args: []);
  }

  /// `停止服务`
  String get stop_service {
    return Intl.message('停止服务', name: 'stop_service', desc: '', args: []);
  }

  /// `停止中...`
  String get stopping {
    return Intl.message('停止中...', name: 'stopping', desc: '', args: []);
  }

  /// `启动服务`
  String get start_service {
    return Intl.message('启动服务', name: 'start_service', desc: '', args: []);
  }

  /// `局域网服务器`
  String get lan_server {
    return Intl.message('局域网服务器', name: 'lan_server', desc: '', args: []);
  }

  /// `HTTP 服务 (端口: {port})`
  String http_service_port(Object port) {
    return Intl.message(
      'HTTP 服务 (端口: $port)',
      name: 'http_service_port',
      desc: '',
      args: [port],
    );
  }

  /// `WebSocket 服务 (端口: {port})`
  String websocket_service_port(Object port) {
    return Intl.message(
      'WebSocket 服务 (端口: $port)',
      name: 'websocket_service_port',
      desc: '',
      args: [port],
    );
  }

  /// `浏览器状态`
  String get browser_status {
    return Intl.message('浏览器状态', name: 'browser_status', desc: '', args: []);
  }

  /// `没有连接的浏览器窗口`
  String get no_browser_windows_connected {
    return Intl.message(
      '没有连接的浏览器窗口',
      name: 'no_browser_windows_connected',
      desc: '',
      args: [],
    );
  }

  /// `启动服务并打开支持的浏览器页面。`
  String get start_service_and_open_browser {
    return Intl.message(
      '启动服务并打开支持的浏览器页面。',
      name: 'start_service_and_open_browser',
      desc: '',
      args: [],
    );
  }

  /// `窗口 {id}`
  String window_id(Object id) {
    return Intl.message('窗口 $id', name: 'window_id', desc: '', args: [id]);
  }

  /// `{count} 个标签页`
  String x_tabs(Object count) {
    return Intl.message('$count 个标签页', name: 'x_tabs', desc: '', args: [count]);
  }

  /// `排队中: {count}`
  String queued_x(Object count) {
    return Intl.message(
      '排队中: $count',
      name: 'queued_x',
      desc: '',
      args: [count],
    );
  }

  /// `翻译器调试信息`
  String get translator_debug_info {
    return Intl.message(
      '翻译器调试信息',
      name: 'translator_debug_info',
      desc: '',
      args: [],
    );
  }

  /// `缓存的翻译 (内存)`
  String get cached_translations_memory {
    return Intl.message(
      '缓存的翻译 (内存)',
      name: 'cached_translations_memory',
      desc: '',
      args: [],
    );
  }

  /// `缓存的翻译 (磁盘)`
  String get cached_translations_disk {
    return Intl.message(
      '缓存的翻译 (磁盘)',
      name: 'cached_translations_disk',
      desc: '',
      args: [],
    );
  }

  /// `当前任务文本长度`
  String get current_task_text_length {
    return Intl.message(
      '当前任务文本长度',
      name: 'current_task_text_length',
      desc: '',
      args: [],
    );
  }

  /// `当前任务 URL`
  String get current_task_url {
    return Intl.message(
      '当前任务 URL',
      name: 'current_task_url',
      desc: '',
      args: [],
    );
  }

  /// `当前任务标签页 ID`
  String get current_task_tab_id {
    return Intl.message(
      '当前任务标签页 ID',
      name: 'current_task_tab_id',
      desc: '',
      args: [],
    );
  }

  /// `清除内存缓存`
  String get clear_memory_cache {
    return Intl.message(
      '清除内存缓存',
      name: 'clear_memory_cache',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'ko'),
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
