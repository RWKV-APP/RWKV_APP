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

  /// `{count} 条消息正在队列中`
  String message_in_queue(Object count) {
    return Intl.message(
      '$count 条消息正在队列中',
      name: 'message_in_queue',
      desc: '',
      args: [count],
    );
  }

  /// `-`
  String get hyphen {
    return Intl.message('-', name: 'hyphen', desc: '', args: []);
  }

  /// `风格`
  String get style {
    return Intl.message('风格', name: 'style', desc: '', args: []);
  }

  /// `管理`
  String get conversation_management {
    return Intl.message(
      '管理',
      name: 'conversation_management',
      desc: '',
      args: [],
    );
  }

  /// `权重文件保存目录`
  String get weights_saving_directory {
    return Intl.message(
      '权重文件保存目录',
      name: 'weights_saving_directory',
      desc: '',
      args: [],
    );
  }

  /// `解压中`
  String get unzipping {
    return Intl.message('解压中', name: 'unzipping', desc: '', args: []);
  }

  /// `我知道了`
  String get got_it {
    return Intl.message('我知道了', name: 'got_it', desc: '', args: []);
  }

  /// `预设`
  String get prebuilt {
    return Intl.message('预设', name: 'prebuilt', desc: '', args: []);
  }

  /// `：`
  String get colon {
    return Intl.message('：', name: 'colon', desc: '', args: []);
  }

  /// `设置全部批量参数`
  String get set_all_batch_params {
    return Intl.message(
      '设置全部批量参数',
      name: 'set_all_batch_params',
      desc: '',
      args: [],
    );
  }

  /// `See`
  String get world {
    return Intl.message('See', name: 'world', desc: '', args: []);
  }

  /// `图像问答`
  String get see {
    return Intl.message('图像问答', name: 'see', desc: '', args: []);
  }

  /// `视觉理解与 OCR`
  String get visual_understanding_and_ocr {
    return Intl.message(
      '视觉理解与 OCR',
      name: 'visual_understanding_and_ocr',
      desc: '',
      args: [],
    );
  }

  /// `请先选择一个图片`
  String get please_select_an_image_first {
    return Intl.message(
      '请先选择一个图片',
      name: 'please_select_an_image_first',
      desc: '',
      args: [],
    );
  }

  /// `更换图片`
  String get change_selected_image {
    return Intl.message(
      '更换图片',
      name: 'change_selected_image',
      desc: '',
      args: [],
    );
  }

  /// `直接渲染换行`
  String get render_newline_directly {
    return Intl.message(
      '直接渲染换行',
      name: 'render_newline_directly',
      desc: '',
      args: [],
    );
  }

  /// `已渲染换行`
  String get line_break_rendered {
    return Intl.message(
      '已渲染换行',
      name: 'line_break_rendered',
      desc: '',
      args: [],
    );
  }

  /// `已渲染换行符`
  String get escape_characters_rendered {
    return Intl.message(
      '已渲染换行符',
      name: 'escape_characters_rendered',
      desc: '',
      args: [],
    );
  }

  /// `渲染空格符号`
  String get render_space_symbol {
    return Intl.message(
      '渲染空格符号',
      name: 'render_space_symbol',
      desc: '',
      args: [],
    );
  }

  /// `已渲染空格`
  String get space_rendered {
    return Intl.message('已渲染空格', name: 'space_rendered', desc: '', args: []);
  }

  /// `已渲染空格符号`
  String get space_symbols_rendered {
    return Intl.message(
      '已渲染空格符号',
      name: 'space_symbols_rendered',
      desc: '',
      args: [],
    );
  }

  /// `空格符设置`
  String get space_symbol_settings {
    return Intl.message(
      '空格符设置',
      name: 'space_symbol_settings',
      desc: '',
      args: [],
    );
  }

  /// `换行符设置`
  String get line_break_symbol_settings {
    return Intl.message(
      '换行符设置',
      name: 'line_break_symbol_settings',
      desc: '',
      args: [],
    );
  }

  /// `空格符样式`
  String get space_symbol_style {
    return Intl.message(
      '空格符样式',
      name: 'space_symbol_style',
      desc: '',
      args: [],
    );
  }

  /// `文本颜色`
  String get text_color {
    return Intl.message('文本颜色', name: 'text_color', desc: '', args: []);
  }

  /// `背景颜色`
  String get background_color {
    return Intl.message('背景颜色', name: 'background_color', desc: '', args: []);
  }

  /// `预览`
  String get preview {
    return Intl.message('预览', name: 'preview', desc: '', args: []);
  }

  /// `仅显示 Prefill 日志`
  String get show_prefill_log_only {
    return Intl.message(
      '仅显示 Prefill 日志',
      name: 'show_prefill_log_only',
      desc: '',
      args: [],
    );
  }

  /// `文本`
  String get text {
    return Intl.message('文本', name: 'text', desc: '', args: []);
  }

  /// `Life Span`
  String get life_span {
    return Intl.message('Life Span', name: 'life_span', desc: '', args: []);
  }

  /// `小于 0.01 GB`
  String get less_than_01_gb {
    return Intl.message(
      '小于 0.01 GB',
      name: 'less_than_01_gb',
      desc: '',
      args: [],
    );
  }

  /// `状态面板`
  String get state_panel {
    return Intl.message('状态面板', name: 'state_panel', desc: '', args: []);
  }

  /// `打开状态面板`
  String get open_state_panel {
    return Intl.message('打开状态面板', name: 'open_state_panel', desc: '', args: []);
  }

  /// `已刷新`
  String get refreshed {
    return Intl.message('已刷新', name: 'refreshed', desc: '', args: []);
  }

  /// `刷新`
  String get refresh {
    return Intl.message('刷新', name: 'refresh', desc: '', args: []);
  }

  /// `关闭`
  String get close {
    return Intl.message('关闭', name: 'close', desc: '', args: []);
  }

  /// `运行日志面板`
  String get runtime_log_panel {
    return Intl.message(
      '运行日志面板',
      name: 'runtime_log_panel',
      desc: '',
      args: [],
    );
  }

  /// `打开调试日志面板`
  String get open_debug_log_panel {
    return Intl.message(
      '打开调试日志面板',
      name: 'open_debug_log_panel',
      desc: '',
      args: [],
    );
  }

  /// `已选择 {count}`
  String selected_count(Object count) {
    return Intl.message(
      '已选择 $count',
      name: 'selected_count',
      desc: '',
      args: [count],
    );
  }

  /// `全选`
  String get select_all {
    return Intl.message('全选', name: 'select_all', desc: '', args: []);
  }

  /// `取消全选`
  String get cancel_all_selection {
    return Intl.message(
      '取消全选',
      name: 'cancel_all_selection',
      desc: '',
      args: [],
    );
  }

  /// `权重文件管理`
  String get weights_mangement {
    return Intl.message(
      '权重文件管理',
      name: 'weights_mangement',
      desc: '',
      args: [],
    );
  }

  /// `存储空间占用量`
  String get total_disk_usage {
    return Intl.message(
      '存储空间占用量',
      name: 'total_disk_usage',
      desc: '',
      args: [],
    );
  }

  /// `模式`
  String get thinking_mode_alert_footer {
    return Intl.message(
      '模式',
      name: 'thinking_mode_alert_footer',
      desc: '',
      args: [],
    );
  }

  /// `请选择推理模式`
  String get think_mode_selector_title {
    return Intl.message(
      '请选择推理模式',
      name: 'think_mode_selector_title',
      desc: '',
      args: [],
    );
  }

  /// `推理模式会影响模型在推理时的表现`
  String get think_mode_selector_message {
    return Intl.message(
      '推理模式会影响模型在推理时的表现',
      name: 'think_mode_selector_message',
      desc: '',
      args: [],
    );
  }

  /// `推荐至少选择【推理-快】`
  String get think_mode_selector_recommendation {
    return Intl.message(
      '推荐至少选择【推理-快】',
      name: 'think_mode_selector_recommendation',
      desc: '',
      args: [],
    );
  }

  /// `推理{footer}-快`
  String think_button_mode_fast(Object footer) {
    return Intl.message(
      '推理$footer-快',
      name: 'think_button_mode_fast',
      desc: '',
      args: [footer],
    );
  }

  /// `推理{footer}-英`
  String think_button_mode_en(Object footer) {
    return Intl.message(
      '推理$footer-英',
      name: 'think_button_mode_en',
      desc: '',
      args: [footer],
    );
  }

  /// `推理{footer}-英短`
  String think_button_mode_en_short(Object footer) {
    return Intl.message(
      '推理$footer-英短',
      name: 'think_button_mode_en_short',
      desc: '',
      args: [footer],
    );
  }

  /// `推理{footer}-英长`
  String think_button_mode_en_long(Object footer) {
    return Intl.message(
      '推理$footer-英长',
      name: 'think_button_mode_en_long',
      desc: '',
      args: [footer],
    );
  }

  /// `默认使用 '<think>好的', 在 2025-09-21 前发布的模型中, 会自动使用 '<think>嗯'`
  String get hint_chinese_thinking_mode_template {
    return Intl.message(
      '默认使用 \'<think>好的\', 在 2025-09-21 前发布的模型中, 会自动使用 \'<think>嗯\'',
      name: 'hint_chinese_thinking_mode_template',
      desc: '',
      args: [],
    );
  }

  /// `模型大小增加，请打开一个新的对话, 以提升对话质量`
  String get model_size_increased_please_open_a_new_conversation {
    return Intl.message(
      '模型大小增加，请打开一个新的对话, 以提升对话质量',
      name: 'model_size_increased_please_open_a_new_conversation',
      desc: '',
      args: [],
    );
  }

  /// `并行`
  String get batch_inference_short {
    return Intl.message(
      '并行',
      name: 'batch_inference_short',
      desc: '',
      args: [],
    );
  }

  /// `您的声音数据为空，请检查您的麦克风`
  String get your_voice_is_empty {
    return Intl.message(
      '您的声音数据为空，请检查您的麦克风',
      name: 'your_voice_is_empty',
      desc: '',
      args: [],
    );
  }

  /// `选择 RWKV 要模仿的声音`
  String get tts_voice_source_sheet_title {
    return Intl.message(
      '选择 RWKV 要模仿的声音',
      name: 'tts_voice_source_sheet_title',
      desc: '',
      args: [],
    );
  }

  /// `在下列的不同方式中选择录入声音的方式`
  String get tts_voice_source_sheet_subtitle {
    return Intl.message(
      '在下列的不同方式中选择录入声音的方式',
      name: 'tts_voice_source_sheet_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `预设声音`
  String get tts_voice_source_preset_title {
    return Intl.message(
      '预设声音',
      name: 'tts_voice_source_preset_title',
      desc: '',
      args: [],
    );
  }

  /// `在 RWKV 内置的预设声音中选择`
  String get tts_voice_source_preset_subtitle {
    return Intl.message(
      '在 RWKV 内置的预设声音中选择',
      name: 'tts_voice_source_preset_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `我的声音`
  String get tts_voice_source_my_voice_title {
    return Intl.message(
      '我的声音',
      name: 'tts_voice_source_my_voice_title',
      desc: '',
      args: [],
    );
  }

  /// `录制我的声音，让 RWKV 模仿它`
  String get tts_voice_source_my_voice_subtitle {
    return Intl.message(
      '录制我的声音，让 RWKV 模仿它',
      name: 'tts_voice_source_my_voice_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `声音文件`
  String get tts_voice_source_file_title {
    return Intl.message(
      '声音文件',
      name: 'tts_voice_source_file_title',
      desc: '',
      args: [],
    );
  }

  /// `选择一个 WAV 文件让 RWKV 模仿它`
  String get tts_voice_source_file_subtitle {
    return Intl.message(
      '选择一个 WAV 文件让 RWKV 模仿它',
      name: 'tts_voice_source_file_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `使用下方文件的声音来生成语音`
  String get tts_voice_source_file_panel_hint {
    return Intl.message(
      '使用下方文件的声音来生成语音',
      name: 'tts_voice_source_file_panel_hint',
      desc: '',
      args: [],
    );
  }

  /// `并行推理中，同时生成 {count} 条消息`
  String batch_inference_running(Object count) {
    return Intl.message(
      '并行推理中，同时生成 $count 条消息',
      name: 'batch_inference_running',
      desc: '',
      args: [count],
    );
  }

  /// `已选择第 {index} 条消息`
  String batch_inference_selected(Object index) {
    return Intl.message(
      '已选择第 $index 条消息',
      name: 'batch_inference_selected',
      desc: '',
      args: [index],
    );
  }

  /// `这个模型不支持并行推理, 请选择带有 batch 标签的模型`
  String get this_model_does_not_support_batch_inference {
    return Intl.message(
      '这个模型不支持并行推理, 请选择带有 batch 标签的模型',
      name: 'this_model_does_not_support_batch_inference',
      desc: '',
      args: [],
    );
  }

  /// `开启`
  String get enabled {
    return Intl.message('开启', name: 'enabled', desc: '', args: []);
  }

  /// `关闭`
  String get disabled {
    return Intl.message('关闭', name: 'disabled', desc: '', args: []);
  }

  /// `请选择你喜欢的分支以进行接下来的对话`
  String get please_select_a_branch_to_continue_the_conversation {
    return Intl.message(
      '请选择你喜欢的分支以进行接下来的对话',
      name: 'please_select_a_branch_to_continue_the_conversation',
      desc: '',
      args: [],
    );
  }

  /// `已经是第一条消息了`
  String get branch_switcher_tooltip_first {
    return Intl.message(
      '已经是第一条消息了',
      name: 'branch_switcher_tooltip_first',
      desc: '',
      args: [],
    );
  }

  /// `上一条消息`
  String get branch_switcher_tooltip_prev {
    return Intl.message(
      '上一条消息',
      name: 'branch_switcher_tooltip_prev',
      desc: '',
      args: [],
    );
  }

  /// `已经是最后一条消息了`
  String get branch_switcher_tooltip_last {
    return Intl.message(
      '已经是最后一条消息了',
      name: 'branch_switcher_tooltip_last',
      desc: '',
      args: [],
    );
  }

  /// `下一条消息`
  String get branch_switcher_tooltip_next {
    return Intl.message(
      '下一条消息',
      name: 'branch_switcher_tooltip_next',
      desc: '',
      args: [],
    );
  }

  /// `已切换分支`
  String get user_message_branch_switched {
    return Intl.message(
      '已切换分支',
      name: 'user_message_branch_switched',
      desc: '',
      args: [],
    );
  }

  /// `消息操作`
  String get user_message_actions_panel_title {
    return Intl.message(
      '消息操作',
      name: 'user_message_actions_panel_title',
      desc: '',
      args: [],
    );
  }

  /// `当前消息暂无可用操作`
  String get user_message_actions_panel_empty {
    return Intl.message(
      '当前消息暂无可用操作',
      name: 'user_message_actions_panel_empty',
      desc: '',
      args: [],
    );
  }

  /// `切换分支`
  String get user_message_actions_panel_switch_branch_title {
    return Intl.message(
      '切换分支',
      name: 'user_message_actions_panel_switch_branch_title',
      desc: '',
      args: [],
    );
  }

  /// `通过上一条 / 下一条切换相邻分支`
  String get user_message_actions_panel_switch_branch_subtitle {
    return Intl.message(
      '通过上一条 / 下一条切换相邻分支',
      name: 'user_message_actions_panel_switch_branch_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `删除当前消息`
  String get delete_current_branch {
    return Intl.message(
      '删除当前消息',
      name: 'delete_current_branch',
      desc: '',
      args: [],
    );
  }

  /// `删除当前消息`
  String get delete_branch_title {
    return Intl.message(
      '删除当前消息',
      name: 'delete_branch_title',
      desc: '',
      args: [],
    );
  }

  /// `这是危险操作：将永久删除当前消息及其所有子节点，并同步删除数据库中的相关记录。该操作不可恢复，是否继续？`
  String get delete_branch_confirmation_message {
    return Intl.message(
      '这是危险操作：将永久删除当前消息及其所有子节点，并同步删除数据库中的相关记录。该操作不可恢复，是否继续？',
      name: 'delete_branch_confirmation_message',
      desc: '',
      args: [],
    );
  }

  /// `屏幕宽度`
  String get screen_width {
    return Intl.message('屏幕宽度', name: 'screen_width', desc: '', args: []);
  }

  /// `并行 × {count}`
  String batch_inference_button(Object count) {
    return Intl.message(
      '并行 × $count',
      name: 'batch_inference_button',
      desc: '',
      args: [count],
    );
  }

  /// `并行推理`
  String get batch_inference {
    return Intl.message('并行推理', name: 'batch_inference', desc: '', args: []);
  }

  /// `开启并行推理后，RWKV 可以同时生成多个答案`
  String get batch_inference_detail {
    return Intl.message(
      '开启并行推理后，RWKV 可以同时生成多个答案',
      name: 'batch_inference_detail',
      desc: '',
      args: [],
    );
  }

  /// `开启或关闭并行推理`
  String get batch_inference_enable_or_not {
    return Intl.message(
      '开启或关闭并行推理',
      name: 'batch_inference_enable_or_not',
      desc: '',
      args: [],
    );
  }

  /// `并行推理设置`
  String get batch_inference_settings {
    return Intl.message(
      '并行推理设置',
      name: 'batch_inference_settings',
      desc: '',
      args: [],
    );
  }

  /// `并行推理数量`
  String get batch_inference_count {
    return Intl.message(
      '并行推理数量',
      name: 'batch_inference_count',
      desc: '',
      args: [],
    );
  }

  /// `每次推理将生成 {count} 条消息`
  String batch_inference_count_detail(Object count) {
    return Intl.message(
      '每次推理将生成 $count 条消息',
      name: 'batch_inference_count_detail',
      desc: '',
      args: [count],
    );
  }

  /// `单线程`
  String get single_thread {
    return Intl.message('单线程', name: 'single_thread', desc: '', args: []);
  }

  /// `多线程`
  String get multi_thread {
    return Intl.message('多线程', name: 'multi_thread', desc: '', args: []);
  }

  /// `消息显示宽度`
  String get batch_inference_width {
    return Intl.message(
      '消息显示宽度',
      name: 'batch_inference_width',
      desc: '',
      args: [],
    );
  }

  /// `并行推理每条消息宽度`
  String get batch_inference_width_detail {
    return Intl.message(
      '并行推理每条消息宽度',
      name: 'batch_inference_width_detail',
      desc: '',
      args: [],
    );
  }

  /// `推理{footer}-关`
  String thinking_mode_off(Object footer) {
    return Intl.message(
      '推理$footer-关',
      name: 'thinking_mode_off',
      desc: '',
      args: [footer],
    );
  }

  /// `推理{footer}-中`
  String thinking_mode_auto(Object footer) {
    return Intl.message(
      '推理$footer-中',
      name: 'thinking_mode_auto',
      desc: '',
      args: [footer],
    );
  }

  /// `推理{footer}-高`
  String thinking_mode_high(Object footer) {
    return Intl.message(
      '推理$footer-高',
      name: 'thinking_mode_high',
      desc: '',
      args: [footer],
    );
  }

  /// `下载全部缺失文件`
  String get download_all_missing {
    return Intl.message(
      '下载全部缺失文件',
      name: 'download_all_missing',
      desc: '',
      args: [],
    );
  }

  /// `文本转语音`
  String get tts {
    return Intl.message('文本转语音', name: 'tts', desc: '', args: []);
  }

  /// `让 RWKV 输出语音`
  String get tts_detail {
    return Intl.message('让 RWKV 输出语音', name: 'tts_detail', desc: '', args: []);
  }

  /// `离线翻译服务器`
  String get offline_translator_server {
    return Intl.message(
      '离线翻译服务器',
      name: 'offline_translator_server',
      desc: '',
      args: [],
    );
  }

  /// `离线翻译`
  String get offline_translator {
    return Intl.message('离线翻译', name: 'offline_translator', desc: '', args: []);
  }

  /// `离线翻译文本`
  String get offline_translator_detail {
    return Intl.message(
      '离线翻译文本',
      name: 'offline_translator_detail',
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

  /// `会话名称不能超过 {maxLength} 个字符`
  String conversation_name_cannot_be_longer_than_30_characters(
    Object maxLength,
  ) {
    return Intl.message(
      '会话名称不能超过 $maxLength 个字符',
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

  /// `代码已复制到剪贴板`
  String get code_copied_to_clipboard {
    return Intl.message(
      '代码已复制到剪贴板',
      name: 'code_copied_to_clipboard',
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

  /// `加载{percent}%`
  String loading_progress_percent(Object percent) {
    return Intl.message(
      '加载$percent%',
      name: 'loading_progress_percent',
      desc: '',
      args: [percent],
    );
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

  /// `新版本可用`
  String get new_version_available {
    return Intl.message(
      '新版本可用',
      name: 'new_version_available',
      desc: '',
      args: [],
    );
  }

  /// `发现新版本可用`
  String get found_new_version_available {
    return Intl.message(
      '发现新版本可用',
      name: 'found_new_version_available',
      desc: '',
      args: [],
    );
  }

  /// `没有最新版本信息`
  String get no_latest_version_info {
    return Intl.message(
      '没有最新版本信息',
      name: 'no_latest_version_info',
      desc: '',
      args: [],
    );
  }

  /// `暂不更新`
  String get cancel_update {
    return Intl.message('暂不更新', name: 'cancel_update', desc: '', args: []);
  }

  /// `立即更新`
  String get update_now {
    return Intl.message('立即更新', name: 'update_now', desc: '', args: []);
  }

  /// `立即下载`
  String get download_now {
    return Intl.message('立即下载', name: 'download_now', desc: '', args: []);
  }

  /// `跳过此版本`
  String get skip_this_version {
    return Intl.message('跳过此版本', name: 'skip_this_version', desc: '', args: []);
  }

  /// `最新版本`
  String get latest_version {
    return Intl.message('最新版本', name: 'latest_version', desc: '', args: []);
  }

  /// `当前版本`
  String get current_version {
    return Intl.message('当前版本', name: 'current_version', desc: '', args: []);
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

  /// `字体大小跟随系统`
  String get font_size_follow_system {
    return Intl.message(
      '字体大小跟随系统',
      name: 'font_size_follow_system',
      desc: '',
      args: [],
    );
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

  /// `UI 字体设置`
  String get ui_font_setting {
    return Intl.message('UI 字体设置', name: 'ui_font_setting', desc: '', args: []);
  }

  /// `等宽字体设置`
  String get monospace_font_setting {
    return Intl.message(
      '等宽字体设置',
      name: 'monospace_font_setting',
      desc: '',
      args: [],
    );
  }

  /// `默认`
  String get default_font {
    return Intl.message('默认', name: 'default_font', desc: '', args: []);
  }

  /// `恢复默认`
  String get restore_default {
    return Intl.message('恢复默认', name: 'restore_default', desc: '', args: []);
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

  /// `预填充`
  String get prefill {
    return Intl.message('预填充', name: 'prefill', desc: '', args: []);
  }

  /// `预填充进度 {percent}`
  String prefill_progress_percent(Object percent) {
    return Intl.message(
      '预填充进度 $percent',
      name: 'prefill_progress_percent',
      desc: '',
      args: [percent],
    );
  }

  /// `解码`
  String get decode {
    return Intl.message('解码', name: 'decode', desc: '', args: []);
  }

  /// `单条消息 Token 数量`
  String get message_token_count {
    return Intl.message(
      '单条消息 Token 数量',
      name: 'message_token_count',
      desc: '',
      args: [],
    );
  }

  /// `当前对话 Token 数量`
  String get conversation_token_count {
    return Intl.message(
      '当前对话 Token 数量',
      name: 'conversation_token_count',
      desc: '',
      args: [],
    );
  }

  /// `建议开启新对话`
  String get conversation_token_limit_hint_short {
    return Intl.message(
      '建议开启新对话',
      name: 'conversation_token_limit_hint_short',
      desc: '',
      args: [],
    );
  }

  /// `当前对话已超过 8,000 tokens，建议开启新对话`
  String get conversation_token_limit_recommend_new_chat {
    return Intl.message(
      '当前对话已超过 8,000 tokens，建议开启新对话',
      name: 'conversation_token_limit_recommend_new_chat',
      desc: '',
      args: [],
    );
  }

  /// `预填充速度（tokens 每秒）`
  String get prefill_speed_tokens_per_second {
    return Intl.message(
      '预填充速度（tokens 每秒）',
      name: 'prefill_speed_tokens_per_second',
      desc: '',
      args: [],
    );
  }

  /// `解码速度（tokens 每秒）`
  String get decode_speed_tokens_per_second {
    return Intl.message(
      '解码速度（tokens 每秒）',
      name: 'decode_speed_tokens_per_second',
      desc: '',
      args: [],
    );
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

  /// `选择图片文件`
  String get select_from_file {
    return Intl.message('选择图片文件', name: 'select_from_file', desc: '', args: []);
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

  /// `选择图片`
  String get select_new_image {
    return Intl.message('选择图片', name: 'select_new_image', desc: '', args: []);
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

  /// `模型输出: {text}`
  String model_output(Object text) {
    return Intl.message(
      '模型输出: $text',
      name: 'model_output',
      desc: '',
      args: [text],
    );
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

  /// `源代码`
  String get source_code {
    return Intl.message('源代码', name: 'source_code', desc: '', args: []);
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
  String get completion {
    return Intl.message('续写模式', name: 'completion', desc: '', args: []);
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

  /// `检查更新失败`
  String get failed_to_check_for_updates {
    return Intl.message(
      '检查更新失败',
      name: 'failed_to_check_for_updates',
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

  /// `输入英文文本`
  String get input_english_text_here {
    return Intl.message(
      '输入英文文本',
      name: 'input_english_text_here',
      desc: '',
      args: [],
    );
  }

  /// `输入中文文本`
  String get input_chinese_text_here {
    return Intl.message(
      '输入中文文本',
      name: 'input_chinese_text_here',
      desc: '',
      args: [],
    );
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

  /// `中文翻译结果`
  String get chinese_translation_result {
    return Intl.message(
      '中文翻译结果',
      name: 'chinese_translation_result',
      desc: '',
      args: [],
    );
  }

  /// `英文翻译结果`
  String get english_translation_result {
    return Intl.message(
      '英文翻译结果',
      name: 'english_translation_result',
      desc: '',
      args: [],
    );
  }

  /// `复制文本`
  String get copy_text {
    return Intl.message('复制文本', name: 'copy_text', desc: '', args: []);
  }

  /// `复制代码`
  String get copy_code {
    return Intl.message('复制代码', name: 'copy_code', desc: '', args: []);
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

  /// `编辑`
  String get edit {
    return Intl.message('编辑', name: 'edit', desc: '', args: []);
  }

  /// `编辑中`
  String get editing {
    return Intl.message('编辑中', name: 'editing', desc: '', args: []);
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

  /// `例子: System: 你是秦始皇，使用文言文，以居高临下的态度与人沟通.`
  String get hint_system_prompt {
    return Intl.message(
      '例子: System: 你是秦始皇，使用文言文，以居高临下的态度与人沟通.',
      name: 'hint_system_prompt',
      desc: '',
      args: [],
    );
  }

  /// `加载`
  String get load_ {
    return Intl.message('加载', name: 'load_', desc: '', args: []);
  }

  /// `已加载`
  String get loaded {
    return Intl.message('已加载', name: 'loaded', desc: '', args: []);
  }

  /// `基准测试`
  String get benchmark {
    return Intl.message('基准测试', name: 'benchmark', desc: '', args: []);
  }

  /// `选择模型`
  String get select_model {
    return Intl.message('选择模型', name: 'select_model', desc: '', args: []);
  }

  /// `开始`
  String get start {
    return Intl.message('开始', name: 'start', desc: '', args: []);
  }

  /// `开始测试`
  String get start_testing {
    return Intl.message('开始测试', name: 'start_testing', desc: '', args: []);
  }

  /// `结果`
  String get result {
    return Intl.message('结果', name: 'result', desc: '', args: []);
  }

  /// `测试结果`
  String get test_result {
    return Intl.message('测试结果', name: 'test_result', desc: '', args: []);
  }

  /// `基准测试结果`
  String get benchmark_result {
    return Intl.message('基准测试结果', name: 'benchmark_result', desc: '', args: []);
  }

  /// `性能测试`
  String get performance_test {
    return Intl.message('性能测试', name: 'performance_test', desc: '', args: []);
  }

  /// `解码参数`
  String get decode_param {
    return Intl.message('解码参数', name: 'decode_param', desc: '', args: []);
  }

  /// `固定（最保守）`
  String get decode_param_fixed {
    return Intl.message(
      '固定（最保守）',
      name: 'decode_param_fixed',
      desc: '',
      args: [],
    );
  }

  /// `固定`
  String get decode_param_fixed_short {
    return Intl.message(
      '固定',
      name: 'decode_param_fixed_short',
      desc: '',
      args: [],
    );
  }

  /// `创意（适合写作，减少重复）`
  String get decode_param_creative {
    return Intl.message(
      '创意（适合写作，减少重复）',
      name: 'decode_param_creative',
      desc: '',
      args: [],
    );
  }

  /// `创意`
  String get decode_param_creative_short {
    return Intl.message(
      '创意',
      name: 'decode_param_creative_short',
      desc: '',
      args: [],
    );
  }

  /// `创意 (推荐)`
  String get creative_recommended {
    return Intl.message(
      '创意 (推荐)',
      name: 'creative_recommended',
      desc: '',
      args: [],
    );
  }

  /// `创意`
  String get creative_recommended_short {
    return Intl.message(
      '创意',
      name: 'creative_recommended_short',
      desc: '',
      args: [],
    );
  }

  /// `保守（适合数学和代码）`
  String get decode_param_conservative {
    return Intl.message(
      '保守（适合数学和代码）',
      name: 'decode_param_conservative',
      desc: '',
      args: [],
    );
  }

  /// `保守`
  String get decode_param_conservative_short {
    return Intl.message(
      '保守',
      name: 'decode_param_conservative_short',
      desc: '',
      args: [],
    );
  }

  /// `默认（默认参数）`
  String get decode_param_default_ {
    return Intl.message(
      '默认（默认参数）',
      name: 'decode_param_default_',
      desc: '',
      args: [],
    );
  }

  /// `默认`
  String get decode_param_default_short {
    return Intl.message(
      '默认',
      name: 'decode_param_default_short',
      desc: '',
      args: [],
    );
  }

  /// `均衡`
  String get balanced {
    return Intl.message('均衡', name: 'balanced', desc: '', args: []);
  }

  /// `自定义（自己设定）`
  String get decode_param_custom {
    return Intl.message(
      '自定义（自己设定）',
      name: 'decode_param_custom',
      desc: '',
      args: [],
    );
  }

  /// `自定义`
  String get decode_param_custom_short {
    return Intl.message(
      '自定义',
      name: 'decode_param_custom_short',
      desc: '',
      args: [],
    );
  }

  /// `模式`
  String get mode {
    return Intl.message('模式', name: 'mode', desc: '', args: []);
  }

  /// `推荐`
  String get suggest {
    return Intl.message('推荐', name: 'suggest', desc: '', args: []);
  }

  /// `综合（也值得试试）`
  String get decode_param_comprehensive {
    return Intl.message(
      '综合（也值得试试）',
      name: 'decode_param_comprehensive',
      desc: '',
      args: [],
    );
  }

  /// `综合`
  String get decode_param_comprehensive_short {
    return Intl.message(
      '综合',
      name: 'decode_param_comprehensive_short',
      desc: '',
      args: [],
    );
  }

  /// `请选择解码参数`
  String get decode_param_select_title {
    return Intl.message(
      '请选择解码参数',
      name: 'decode_param_select_title',
      desc: '',
      args: [],
    );
  }

  /// `我们可以通过解码参数控制 RWKV 的输出风格`
  String get decode_param_select_message {
    return Intl.message(
      '我们可以通过解码参数控制 RWKV 的输出风格',
      name: 'decode_param_select_message',
      desc: '',
      args: [],
    );
  }

  /// `下载%.1f% 速度%.1fMB/s 剩余%s`
  String get str_downloading_info {
    return Intl.message(
      '下载%.1f% 速度%.1fMB/s 剩余%s',
      name: 'str_downloading_info',
      desc: '',
      args: [],
    );
  }

  /// `State 列表`
  String get state_list {
    return Intl.message('State 列表', name: 'state_list', desc: '', args: []);
  }

  /// `角色扮演`
  String get role_play {
    return Intl.message('角色扮演', name: 'role_play', desc: '', args: []);
  }

  /// `扮演你喜欢的角色`
  String get role_play_intro {
    return Intl.message(
      '扮演你喜欢的角色',
      name: 'role_play_intro',
      desc: '',
      args: [],
    );
  }

  /// `并行续写`
  String get batch_completion {
    return Intl.message('并行续写', name: 'batch_completion', desc: '', args: []);
  }

  /// `并行续写设置`
  String get batch_completion_settings {
    return Intl.message(
      '并行续写设置',
      name: 'batch_completion_settings',
      desc: '',
      args: [],
    );
  }

  /// `结果显示宽度`
  String get batch_inference_width_2 {
    return Intl.message(
      '结果显示宽度',
      name: 'batch_inference_width_2',
      desc: '',
      args: [],
    );
  }

  /// `每次生成 {count} 条结果`
  String batch_inference_count_detail_2(Object count) {
    return Intl.message(
      '每次生成 $count 条结果',
      name: 'batch_inference_count_detail_2',
      desc: '',
      args: [count],
    );
  }

  /// `每条结果的宽度`
  String get batch_inference_width_detail_2 {
    return Intl.message(
      '每条结果的宽度',
      name: 'batch_inference_width_detail_2',
      desc: '',
      args: [],
    );
  }

  /// `LAMBADA 测试`
  String get lambada_test {
    return Intl.message('LAMBADA 测试', name: 'lambada_test', desc: '', args: []);
  }

  /// `测试中...`
  String get testing {
    return Intl.message('测试中...', name: 'testing', desc: '', args: []);
  }

  /// `开始测试`
  String get start_test {
    return Intl.message('开始测试', name: 'start_test', desc: '', args: []);
  }

  /// `停止测试`
  String get stop_test {
    return Intl.message('停止测试', name: 'stop_test', desc: '', args: []);
  }

  /// `加载数据`
  String get load_data {
    return Intl.message('加载数据', name: 'load_data', desc: '', args: []);
  }

  /// `当前模型: {modelName}`
  String current_model(Object modelName) {
    return Intl.message(
      '当前模型: $modelName',
      name: 'current_model',
      desc: '',
      args: [modelName],
    );
  }

  /// `请选择模型`
  String get please_select_model {
    return Intl.message(
      '请选择模型',
      name: 'please_select_model',
      desc: '',
      args: [],
    );
  }

  /// `测试数据`
  String get test_data {
    return Intl.message('测试数据', name: 'test_data', desc: '', args: []);
  }

  /// `总测试项: {count}`
  String total_test_items(Object count) {
    return Intl.message(
      '总测试项: $count',
      name: 'total_test_items',
      desc: '',
      args: [count],
    );
  }

  /// `当前进度: {current}/{total}`
  String current_progress(Object current, Object total) {
    return Intl.message(
      '当前进度: $current/$total',
      name: 'current_progress',
      desc: '',
      args: [current, total],
    );
  }

  /// `测试结果`
  String get test_results {
    return Intl.message('测试结果', name: 'test_results', desc: '', args: []);
  }

  /// `实时更新`
  String get real_time_update {
    return Intl.message('实时更新', name: 'real_time_update', desc: '', args: []);
  }

  /// `准确率`
  String get accuracy {
    return Intl.message('准确率', name: 'accuracy', desc: '', args: []);
  }

  /// `困惑度`
  String get perplexity {
    return Intl.message('困惑度', name: 'perplexity', desc: '', args: []);
  }

  /// `正确数`
  String get correct_count {
    return Intl.message('正确数', name: 'correct_count', desc: '', args: []);
  }

  /// `总数`
  String get total_count {
    return Intl.message('总数', name: 'total_count', desc: '', args: []);
  }

  /// `当前测试项 ({current}/{total})`
  String current_test_item(Object current, Object total) {
    return Intl.message(
      '当前测试项 ($current/$total)',
      name: 'current_test_item',
      desc: '',
      args: [current, total],
    );
  }

  /// `源文本: {text}`
  String source_text(Object text) {
    return Intl.message(
      '源文本: $text',
      name: 'source_text',
      desc: '',
      args: [text],
    );
  }

  /// `目标文本: {text}`
  String target_text(Object text) {
    return Intl.message(
      '目标文本: $text',
      name: 'target_text',
      desc: '',
      args: [text],
    );
  }

  /// `测试速度和准确率`
  String get performance_test_description {
    return Intl.message(
      '测试速度和准确率',
      name: 'performance_test_description',
      desc: '',
      args: [],
    );
  }

  /// `开始后台下载更新...`
  String get start_download_updates_ {
    return Intl.message(
      '开始后台下载更新...',
      name: 'start_download_updates_',
      desc: '',
      args: [],
    );
  }

  /// `解码参数建议选择 “创意”, 以便获得更好的体验`
  String get switch_to_creative_mode_for_better_exp {
    return Intl.message(
      '解码参数建议选择 “创意”, 以便获得更好的体验',
      name: 'switch_to_creative_mode_for_better_exp',
      desc: '',
      args: [],
    );
  }

  /// `参数说明`
  String get parameter_description {
    return Intl.message(
      '参数说明',
      name: 'parameter_description',
      desc: '',
      args: [],
    );
  }

  /// `Temperature: 控制输出的随机性。较高的值（如 0.8）使输出更具创意和随机性；较低的值（如 0.2）使输出更集中和确定。\n\nTop P: 控制输出的多样性。模型仅考虑累积概率达到 Top P 的 token。较低的值（如 0.5）会忽略低概率的词，使输出更相关。\n\nPresence Penalty: 根据 token 是否已在文本中出现来惩罚它们。正值会增加模型谈论新主题的可能性。\n\nFrequency Penalty: 根据 token 在文本中出现的频率来惩罚它们。正值会减少模型逐字重复同一行的可能性。\n\nPenalty Decay: 控制惩罚随距离的衰减程度。`
  String get parameter_description_detail {
    return Intl.message(
      'Temperature: 控制输出的随机性。较高的值（如 0.8）使输出更具创意和随机性；较低的值（如 0.2）使输出更集中和确定。\n\nTop P: 控制输出的多样性。模型仅考虑累积概率达到 Top P 的 token。较低的值（如 0.5）会忽略低概率的词，使输出更相关。\n\nPresence Penalty: 根据 token 是否已在文本中出现来惩罚它们。正值会增加模型谈论新主题的可能性。\n\nFrequency Penalty: 根据 token 在文本中出现的频率来惩罚它们。正值会减少模型逐字重复同一行的可能性。\n\nPenalty Decay: 控制惩罚随距离的衰减程度。',
      name: 'parameter_description_detail',
      desc: '',
      args: [],
    );
  }

  /// `每条消息的解码参数`
  String get decode_params_for_each_message {
    return Intl.message(
      '每条消息的解码参数',
      name: 'decode_params_for_each_message',
      desc: '',
      args: [],
    );
  }

  /// `批量推理中每条消息的解码参数。点击编辑每条消息的解码参数。`
  String get decode_params_for_each_message_detail {
    return Intl.message(
      '批量推理中每条消息的解码参数。点击编辑每条消息的解码参数。',
      name: 'decode_params_for_each_message_detail',
      desc: '',
      args: [],
    );
  }

  /// `全部相同`
  String get all_the_same {
    return Intl.message('全部相同', name: 'all_the_same', desc: '', args: []);
  }

  /// `不完全相同`
  String get not_all_the_same {
    return Intl.message('不完全相同', name: 'not_all_the_same', desc: '', args: []);
  }

  /// `同步中`
  String get syncing {
    return Intl.message('同步中', name: 'syncing', desc: '', args: []);
  }

  /// `未同步`
  String get not_syncing {
    return Intl.message('未同步', name: 'not_syncing', desc: '', args: []);
  }

  /// `全部设置为 ???`
  String get set_all_to_question_mark {
    return Intl.message(
      '全部设置为 ???',
      name: 'set_all_to_question_mark',
      desc: '',
      args: [],
    );
  }

  /// `请选择要为第 {index} 条消息设置的采样和惩罚参数`
  String
  please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index(
    Object index,
  ) {
    return Intl.message(
      '请选择要为第 $index 条消息设置的采样和惩罚参数',
      name:
          'please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index',
      desc: '',
      args: [index],
    );
  }

  /// `请选择要为所有消息设置的采样和惩罚参数`
  String
  get please_select_the_sampler_and_penalty_parameters_to_set_for_all_messages {
    return Intl.message(
      '请选择要为所有消息设置的采样和惩罚参数',
      name:
          'please_select_the_sampler_and_penalty_parameters_to_set_for_all_messages',
      desc: '',
      args: [],
    );
  }

  /// `请从下方选择预设参数，或点击“自定义”进行手动配置`
  String get select_the_decode_parameters_to_set_all_to_for_index {
    return Intl.message(
      '请从下方选择预设参数，或点击“自定义”进行手动配置',
      name: 'select_the_decode_parameters_to_set_all_to_for_index',
      desc: '',
      args: [],
    );
  }

  /// `Temperature: {value}`
  String temperature_with_value(Object value) {
    return Intl.message(
      'Temperature: $value',
      name: 'temperature_with_value',
      desc: '',
      args: [value],
    );
  }

  /// `Top P: {value}`
  String top_p_with_value(Object value) {
    return Intl.message(
      'Top P: $value',
      name: 'top_p_with_value',
      desc: '',
      args: [value],
    );
  }

  /// `Presence Penalty: {value}`
  String presence_penalty_with_value(Object value) {
    return Intl.message(
      'Presence Penalty: $value',
      name: 'presence_penalty_with_value',
      desc: '',
      args: [value],
    );
  }

  /// `Frequency Penalty: {value}`
  String frequency_penalty_with_value(Object value) {
    return Intl.message(
      'Frequency Penalty: $value',
      name: 'frequency_penalty_with_value',
      desc: '',
      args: [value],
    );
  }

  /// `Penalty Decay: {value}`
  String penalty_decay_with_value(Object value) {
    return Intl.message(
      'Penalty Decay: $value',
      name: 'penalty_decay_with_value',
      desc: '',
      args: [value],
    );
  }

  /// `Hello! 你好！这是用户消息的预览。`
  String get font_preview_user_message {
    return Intl.message(
      'Hello! 你好！这是用户消息的预览。',
      name: 'font_preview_user_message',
      desc: '',
      args: [],
    );
  }

  /// `assets/lib/font_preview/font_preview_zh_Hans.md`
  String get font_preview_markdown_asset {
    return Intl.message(
      'assets/lib/font_preview/font_preview_zh_Hans.md',
      name: 'font_preview_markdown_asset',
      desc: '',
      args: [],
    );
  }

  /// `日期`
  String get tag_date {
    return Intl.message('日期', name: 'tag_date', desc: '', args: []);
  }

  /// `时间`
  String get tag_time {
    return Intl.message('时间', name: 'tag_time', desc: '', args: []);
  }

  /// `星期`
  String get tag_day_of_week {
    return Intl.message('星期', name: 'tag_day_of_week', desc: '', args: []);
  }

  /// `OCR`
  String get ocr_title {
    return Intl.message('OCR', name: 'ocr_title', desc: '', args: []);
  }

  /// `隐藏翻译`
  String get hide_translations {
    return Intl.message('隐藏翻译', name: 'hide_translations', desc: '', args: []);
  }

  /// `显示翻译`
  String get show_translations {
    return Intl.message('显示翻译', name: 'show_translations', desc: '', args: []);
  }

  /// `英->中`
  String get en_to_zh {
    return Intl.message('英->中', name: 'en_to_zh', desc: '', args: []);
  }

  /// `中->英`
  String get zh_to_en {
    return Intl.message('中->英', name: 'zh_to_en', desc: '', args: []);
  }

  /// `相机`
  String get camera {
    return Intl.message('相机', name: 'camera', desc: '', args: []);
  }

  /// `相册`
  String get gallery {
    return Intl.message('相册', name: 'gallery', desc: '', args: []);
  }

  /// `点击 {takePhoto}。RWKV 将翻译图片中的文本。`
  String ocr_guide_text(Object takePhoto) {
    return Intl.message(
      '点击 $takePhoto。RWKV 将翻译图片中的文本。',
      name: 'ocr_guide_text',
      desc: '',
      args: [takePhoto],
    );
  }

  /// `输入要续写的段落`
  String get enter_text_to_expand {
    return Intl.message(
      '输入要续写的段落',
      name: 'enter_text_to_expand',
      desc: '',
      args: [],
    );
  }

  /// `续写`
  String get continue2 {
    return Intl.message('续写', name: 'continue2', desc: '', args: []);
  }

  /// `请先输入要续写的段落`
  String get please_entry_some_text_to_continue {
    return Intl.message(
      '请先输入要续写的段落',
      name: 'please_entry_some_text_to_continue',
      desc: '',
      args: [],
    );
  }

  /// `敬请期待`
  String get reached_bottom {
    return Intl.message('敬请期待', name: 'reached_bottom', desc: '', args: []);
  }

  /// `打开数据库文件夹`
  String get open_database_folder {
    return Intl.message(
      '打开数据库文件夹',
      name: 'open_database_folder',
      desc: '',
      args: [],
    );
  }

  /// `暂未支持您的芯片 {socName} 的 NPU 加速`
  String npu_not_supported_title(Object socName) {
    return Intl.message(
      '暂未支持您的芯片 $socName 的 NPU 加速',
      name: 'npu_not_supported_title',
      desc: '',
      args: [socName],
    );
  }

  /// `我们正在持续适配更多的推理芯片，敬请期待。`
  String get adapting_more_inference_chips {
    return Intl.message(
      '我们正在持续适配更多的推理芯片，敬请期待。',
      name: 'adapting_more_inference_chips',
      desc: '',
      args: [],
    );
  }

  /// `其他文件 (这些文件可能是已经过期或不再支持的权重 RWKV Chat 无需再使用它们)`
  String get other_files {
    return Intl.message(
      '其他文件 (这些文件可能是已经过期或不再支持的权重 RWKV Chat 无需再使用它们)',
      name: 'other_files',
      desc: '',
      args: [],
    );
  }

  /// `MLX/CoreML 缓存`
  String get mlx_cache {
    return Intl.message('MLX/CoreML 缓存', name: 'mlx_cache', desc: '', args: []);
  }

  /// `删除 MLX/CoreML 缓存可释放磁盘空间，但下次加载对应的 MLX/CoreML 模型会更慢。`
  String get mlx_cache_notice {
    return Intl.message(
      '删除 MLX/CoreML 缓存可释放磁盘空间，但下次加载对应的 MLX/CoreML 模型会更慢。',
      name: 'mlx_cache_notice',
      desc: '',
      args: [],
    );
  }

  /// `确定要删除这个 MLX/CoreML 缓存吗？`
  String get delete_mlx_cache_confirmation {
    return Intl.message(
      '确定要删除这个 MLX/CoreML 缓存吗？',
      name: 'delete_mlx_cache_confirmation',
      desc: '',
      args: [],
    );
  }

  /// `导入权重文件`
  String get import_weight_file {
    return Intl.message(
      '导入权重文件',
      name: 'import_weight_file',
      desc: '',
      args: [],
    );
  }

  /// `导入成功`
  String get import_success {
    return Intl.message('导入成功', name: 'import_success', desc: '', args: []);
  }

  /// `导入失败`
  String get import_failed {
    return Intl.message('导入失败', name: 'import_failed', desc: '', args: []);
  }

  /// `文件路径未找到`
  String get file_path_not_found {
    return Intl.message(
      '文件路径未找到',
      name: 'file_path_not_found',
      desc: '',
      args: [],
    );
  }

  /// `文件未找到`
  String get file_not_found {
    return Intl.message('文件未找到', name: 'file_not_found', desc: '', args: []);
  }

  /// `当前文件尚未支持，请检查文件名是否正确`
  String get file_not_supported {
    return Intl.message(
      '当前文件尚未支持，请检查文件名是否正确',
      name: 'file_not_supported',
      desc: '',
      args: [],
    );
  }

  /// `文件已存在`
  String get file_already_exists {
    return Intl.message(
      '文件已存在',
      name: 'file_already_exists',
      desc: '',
      args: [],
    );
  }

  /// `文件已存在，是否要覆盖？`
  String get overwrite_file_confirmation {
    return Intl.message(
      '文件已存在，是否要覆盖？',
      name: 'overwrite_file_confirmation',
      desc: '',
      args: [],
    );
  }

  /// `覆盖`
  String get overwrite {
    return Intl.message('覆盖', name: 'overwrite', desc: '', args: []);
  }

  /// `导出权重文件`
  String get export_weight_file {
    return Intl.message(
      '导出权重文件',
      name: 'export_weight_file',
      desc: '',
      args: [],
    );
  }

  /// `导出全部权重文件`
  String get export_all_weight_files {
    return Intl.message(
      '导出全部权重文件',
      name: 'export_all_weight_files',
      desc: '',
      args: [],
    );
  }

  /// `导出成功`
  String get export_success {
    return Intl.message('导出成功', name: 'export_success', desc: '', args: []);
  }

  /// `导出失败`
  String get export_failed {
    return Intl.message('导出失败', name: 'export_failed', desc: '', args: []);
  }

  /// `个文件`
  String get files {
    return Intl.message('个文件', name: 'files', desc: '', args: []);
  }

  /// `没有可导出的权重文件`
  String get no_weight_files_to_export {
    return Intl.message(
      '没有可导出的权重文件',
      name: 'no_weight_files_to_export',
      desc: '',
      args: [],
    );
  }

  /// `所有已下载的权重文件将作为单独文件导出到所选目录。同名文件将被跳过。`
  String get export_all_weight_files_description {
    return Intl.message(
      '所有已下载的权重文件将作为单独文件导出到所选目录。同名文件将被跳过。',
      name: 'export_all_weight_files_description',
      desc: '',
      args: [],
    );
  }

  /// `暂无权重文件`
  String get no_weight_files_guide_title {
    return Intl.message(
      '暂无权重文件',
      name: 'no_weight_files_guide_title',
      desc: '',
      args: [],
    );
  }

  /// `您还没有下载任何权重文件。前往首页下载并体验应用。`
  String get no_weight_files_guide_message {
    return Intl.message(
      '您还没有下载任何权重文件。前往首页下载并体验应用。',
      name: 'no_weight_files_guide_message',
      desc: '',
      args: [],
    );
  }

  /// `前往首页`
  String get go_to_home_page {
    return Intl.message('前往首页', name: 'go_to_home_page', desc: '', args: []);
  }

  /// `导入全部权重文件`
  String get import_all_weight_files {
    return Intl.message(
      '导入全部权重文件',
      name: 'import_all_weight_files',
      desc: '',
      args: [],
    );
  }

  /// `选择从此应用导出的 ZIP 文件。ZIP 文件中的所有权重文件将被导入。如果文件名相同，现有文件将被覆盖。`
  String get import_all_weight_files_description {
    return Intl.message(
      '选择从此应用导出的 ZIP 文件。ZIP 文件中的所有权重文件将被导入。如果文件名相同，现有文件将被覆盖。',
      name: 'import_all_weight_files_description',
      desc: '',
      args: [],
    );
  }

  /// `导入成功：已导入 {count} 个文件`
  String import_all_weight_files_success(Object count) {
    return Intl.message(
      '导入成功：已导入 $count 个文件',
      name: 'import_all_weight_files_success',
      desc: '',
      args: [count],
    );
  }

  /// `无效的 ZIP 文件或文件格式无法识别`
  String get invalid_zip_file {
    return Intl.message(
      '无效的 ZIP 文件或文件格式无法识别',
      name: 'invalid_zip_file',
      desc: '',
      args: [],
    );
  }

  /// `ZIP 文件中未找到有效的权重文件`
  String get no_files_in_zip {
    return Intl.message(
      'ZIP 文件中未找到有效的权重文件',
      name: 'no_files_in_zip',
      desc: '',
      args: [],
    );
  }

  /// `当前加载的是 latest.json 中的配置，不是本地 .pth 文件`
  String get current_model_from_latest_json_not_pth {
    return Intl.message(
      '当前加载的是 latest.json 中的配置，不是本地 .pth 文件',
      name: 'current_model_from_latest_json_not_pth',
      desc: '',
      args: [],
    );
  }

  /// `暂无已加载的本地 .pth 文件`
  String get no_local_pth_loaded_yet {
    return Intl.message(
      '暂无已加载的本地 .pth 文件',
      name: 'no_local_pth_loaded_yet',
      desc: '',
      args: [],
    );
  }

  /// `ctx {length}`
  String ctx_length_label(Object length) {
    return Intl.message(
      'ctx $length',
      name: 'ctx_length_label',
      desc: '',
      args: [length],
    );
  }

  /// `配置文件中的权重`
  String get local_pth_option_files_in_config {
    return Intl.message(
      '配置文件中的权重',
      name: 'local_pth_option_files_in_config',
      desc: '',
      args: [],
    );
  }

  /// `本地 .pth 文件`
  String get local_pth_option_local_pth_files {
    return Intl.message(
      '本地 .pth 文件',
      name: 'local_pth_option_local_pth_files',
      desc: '',
      args: [],
    );
  }

  /// `选择配置文件中的权重或者本地 .pth 文件`
  String get select_weights_or_local_pth_hint {
    return Intl.message(
      '选择配置文件中的权重或者本地 .pth 文件',
      name: 'select_weights_or_local_pth_hint',
      desc: '',
      args: [],
    );
  }

  /// `本地 .pth 文件`
  String get local_pth_files_section_title {
    return Intl.message(
      '本地 .pth 文件',
      name: 'local_pth_files_section_title',
      desc: '',
      args: [],
    );
  }

  /// `你可以选择本地的 .pth 文件进行加载`
  String get local_pth_you_can_select {
    return Intl.message(
      '你可以选择本地的 .pth 文件进行加载',
      name: 'local_pth_you_can_select',
      desc: '',
      args: [],
    );
  }

  /// `什么是 .pth 文件？`
  String get what_is_pth_file_title {
    return Intl.message(
      '什么是 .pth 文件？',
      name: 'what_is_pth_file_title',
      desc: '',
      args: [],
    );
  }

  /// `.pth 文件是直接从本地文件系统中加载的权重文件，不需要通过下载服务器下载。\n\n通常通过 Pytorch 训练的模型会保存为 .pth 文件。\n\nRWKV Chat 支持加载 .pth 文件。`
  String get what_is_pth_file_message {
    return Intl.message(
      '.pth 文件是直接从本地文件系统中加载的权重文件，不需要通过下载服务器下载。\n\n通常通过 Pytorch 训练的模型会保存为 .pth 文件。\n\nRWKV Chat 支持加载 .pth 文件。',
      name: 'what_is_pth_file_message',
      desc: '',
      args: [],
    );
  }

  /// `选择本地 .pth 文件`
  String get select_local_pth_file_button {
    return Intl.message(
      '选择本地 .pth 文件',
      name: 'select_local_pth_file_button',
      desc: '',
      args: [],
    );
  }

  /// `打开所在文件夹`
  String get open_containing_folder {
    return Intl.message(
      '打开所在文件夹',
      name: 'open_containing_folder',
      desc: '',
      args: [],
    );
  }

  /// `该文件夹已添加`
  String get folder_already_added {
    return Intl.message(
      '该文件夹已添加',
      name: 'folder_already_added',
      desc: '',
      args: [],
    );
  }

  /// `确定要忘记该位置吗？`
  String get confirm_forget_location_title {
    return Intl.message(
      '确定要忘记该位置吗？',
      name: 'confirm_forget_location_title',
      desc: '',
      args: [],
    );
  }

  /// `忘记该位置后，该文件夹将不再显示在本地文件夹列表中`
  String get confirm_forget_location_message {
    return Intl.message(
      '忘记该位置后，该文件夹将不再显示在本地文件夹列表中',
      name: 'confirm_forget_location_message',
      desc: '',
      args: [],
    );
  }

  /// `忘记该位置成功`
  String get forget_location_success {
    return Intl.message(
      '忘记该位置成功',
      name: 'forget_location_success',
      desc: '',
      args: [],
    );
  }

  /// `刷新完成`
  String get refresh_complete {
    return Intl.message('刷新完成', name: 'refresh_complete', desc: '', args: []);
  }

  /// `确定要删除该文件吗？`
  String get confirm_delete_file_title {
    return Intl.message(
      '确定要删除该文件吗？',
      name: 'confirm_delete_file_title',
      desc: '',
      args: [],
    );
  }

  /// `该文件将在您的本地硬盘中被永久删除`
  String get confirm_delete_file_message {
    return Intl.message(
      '该文件将在您的本地硬盘中被永久删除',
      name: 'confirm_delete_file_message',
      desc: '',
      args: [],
    );
  }

  /// `您的设备：`
  String get your_device {
    return Intl.message('您的设备：', name: 'your_device', desc: '', args: []);
  }

  /// `我们目前支持以下 SoC 芯片中的 NPU：`
  String get we_support_npu_socs {
    return Intl.message(
      '我们目前支持以下 SoC 芯片中的 NPU：',
      name: 'we_support_npu_socs',
      desc: '',
      args: [],
    );
  }

  /// `以下是 RWKV Chat 预先量化好的模型`
  String get prebuilt_models_intro {
    return Intl.message(
      '以下是 RWKV Chat 预先量化好的模型',
      name: 'prebuilt_models_intro',
      desc: '',
      args: [],
    );
  }

  /// `下面是您本地的文件夹`
  String get below_are_your_local_folders {
    return Intl.message(
      '下面是您本地的文件夹',
      name: 'below_are_your_local_folders',
      desc: '',
      args: [],
    );
  }

  /// `点击 + 号添加更多本地文件夹`
  String get click_plus_to_add_more_folders {
    return Intl.message(
      '点击 + 号添加更多本地文件夹',
      name: 'click_plus_to_add_more_folders',
      desc: '',
      args: [],
    );
  }

  /// `添加本地文件夹`
  String get add_local_folder {
    return Intl.message(
      '添加本地文件夹',
      name: 'add_local_folder',
      desc: '',
      args: [],
    );
  }

  /// `你还没有添加包含有 .pth 文件的本地文件夹`
  String get no_local_folders {
    return Intl.message(
      '你还没有添加包含有 .pth 文件的本地文件夹',
      name: 'no_local_folders',
      desc: '',
      args: [],
    );
  }

  /// `点击 + 添加本地文件夹, RWKV Chat 会扫描该文件夹下的 .pth 文件, 并将其作为可加载的权重`
  String get click_plus_add_local_folder {
    return Intl.message(
      '点击 + 添加本地文件夹, RWKV Chat 会扫描该文件夹下的 .pth 文件, 并将其作为可加载的权重',
      name: 'click_plus_add_local_folder',
      desc: '',
      args: [],
    );
  }

  /// `打开文件夹`
  String get open_folder {
    return Intl.message('打开文件夹', name: 'open_folder', desc: '', args: []);
  }

  /// `忘记该位置`
  String get forget_this_location {
    return Intl.message(
      '忘记该位置',
      name: 'forget_this_location',
      desc: '',
      args: [],
    );
  }

  /// `正在扫描该文件夹中的 .pth 文件`
  String get scanning_folder_for_pth {
    return Intl.message(
      '正在扫描该文件夹中的 .pth 文件',
      name: 'scanning_folder_for_pth',
      desc: '',
      args: [],
    );
  }

  /// `当前文件夹没有本地模型`
  String get current_folder_has_no_local_models {
    return Intl.message(
      '当前文件夹没有本地模型',
      name: 'current_folder_has_no_local_models',
      desc: '',
      args: [],
    );
  }

  /// `未在您的电脑上发现该文件夹`
  String get folder_not_found_on_device {
    return Intl.message(
      '未在您的电脑上发现该文件夹',
      name: 'folder_not_found_on_device',
      desc: '',
      args: [],
    );
  }

  /// `该文件夹无法访问，请检查文件夹权限`
  String get folder_not_accessible_check_permission {
    return Intl.message(
      '该文件夹无法访问，请检查文件夹权限',
      name: 'folder_not_accessible_check_permission',
      desc: '',
      args: [],
    );
  }

  /// `路径：{path}`
  String path_label(Object path) {
    return Intl.message('路径：$path', name: 'path_label', desc: '', args: [path]);
  }

  /// `本地文件夹：{folderName}`
  String local_folder_name(Object folderName) {
    return Intl.message(
      '本地文件夹：$folderName',
      name: 'local_folder_name',
      desc: '',
      args: [folderName],
    );
  }

  /// `自定义目录已设置`
  String get custom_directory_set {
    return Intl.message(
      '自定义目录已设置',
      name: 'custom_directory_set',
      desc: '',
      args: [],
    );
  }

  /// `已恢复默认目录`
  String get reset_to_default_directory {
    return Intl.message(
      '已恢复默认目录',
      name: 'reset_to_default_directory',
      desc: '',
      args: [],
    );
  }

  /// `创建目录失败`
  String get failed_to_create_directory {
    return Intl.message(
      '创建目录失败',
      name: 'failed_to_create_directory',
      desc: '',
      args: [],
    );
  }

  /// `设置自定义目录`
  String get set_custom_directory {
    return Intl.message(
      '设置自定义目录',
      name: 'set_custom_directory',
      desc: '',
      args: [],
    );
  }

  /// `恢复默认`
  String get reset_to_default {
    return Intl.message('恢复默认', name: 'reset_to_default', desc: '', args: []);
  }

  /// `正在使用自定义目录`
  String get using_custom_directory {
    return Intl.message(
      '正在使用自定义目录',
      name: 'using_custom_directory',
      desc: '',
      args: [],
    );
  }

  /// `正在使用默认目录`
  String get using_default_directory {
    return Intl.message(
      '正在使用默认目录',
      name: 'using_default_directory',
      desc: '',
      args: [],
    );
  }

  /// `正在移动文件...`
  String get moving_files {
    return Intl.message('正在移动文件...', name: 'moving_files', desc: '', args: []);
  }

  /// `已在使用此目录`
  String get already_using_this_directory {
    return Intl.message(
      '已在使用此目录',
      name: 'already_using_this_directory',
      desc: '',
      args: [],
    );
  }

  /// `{successCount} 个文件已移动，{failCount} 个失败`
  String files_moved_with_failures(Object successCount, Object failCount) {
    return Intl.message(
      '$successCount 个文件已移动，$failCount 个失败',
      name: 'files_moved_with_failures',
      desc: '',
      args: [successCount, failCount],
    );
  }

  /// `路径已更新，如需迁移文件请手动选择并移动。`
  String get please_manually_migrate_files {
    return Intl.message(
      '路径已更新，如需迁移文件请手动选择并移动。',
      name: 'please_manually_migrate_files',
      desc: '',
      args: [],
    );
  }

  /// `当前操作系统({os})不支持打开文件夹的操作。`
  String open_folder_unsupported_on_platform(Object os) {
    return Intl.message(
      '当前操作系统($os)不支持打开文件夹的操作。',
      name: 'open_folder_unsupported_on_platform',
      desc: '',
      args: [os],
    );
  }

  /// `删除完成`
  String get delete_finished {
    return Intl.message('删除完成', name: 'delete_finished', desc: '', args: []);
  }

  /// `删除文件失败：{error}`
  String failed_to_delete_file(Object error) {
    return Intl.message(
      '删除文件失败：$error',
      name: 'failed_to_delete_file',
      desc: '',
      args: [error],
    );
  }

  /// `文件夹路径为空。`
  String get open_folder_path_is_null {
    return Intl.message(
      '文件夹路径为空。',
      name: 'open_folder_path_is_null',
      desc: '',
      args: [],
    );
  }

  /// `文件夹不存在，正在创建空文件夹。`
  String get open_folder_creating_empty {
    return Intl.message(
      '文件夹不存在，正在创建空文件夹。',
      name: 'open_folder_creating_empty',
      desc: '',
      args: [],
    );
  }

  /// `空文件夹创建成功。`
  String get open_folder_created_success {
    return Intl.message(
      '空文件夹创建成功。',
      name: 'open_folder_created_success',
      desc: '',
      args: [],
    );
  }

  /// `空文件夹创建失败：{error}`
  String open_folder_create_failed(Object error) {
    return Intl.message(
      '空文件夹创建失败：$error',
      name: 'open_folder_create_failed',
      desc: '',
      args: [error],
    );
  }

  /// `升级 iOS 18+ 可使用这款权重，更快更省电`
  String get model_item_ios18_weight_hint {
    return Intl.message(
      '升级 iOS 18+ 可使用这款权重，更快更省电',
      name: 'model_item_ios18_weight_hint',
      desc: '',
      args: [],
    );
  }

  /// `TTS 正在运行，请等待其完成`
  String get tts_is_running_please_wait {
    return Intl.message(
      'TTS 正在运行，请等待其完成',
      name: 'tts_is_running_please_wait',
      desc: '',
      args: [],
    );
  }

  /// `请选择一个预设声音或录制您的声音`
  String get please_select_a_spk_or_a_wav_file {
    return Intl.message(
      '请选择一个预设声音或录制您的声音',
      name: 'please_select_a_spk_or_a_wav_file',
      desc: '',
      args: [],
    );
  }

  /// `请输入文本以生成语音`
  String get please_enter_text_to_generate_tts {
    return Intl.message(
      '请输入文本以生成语音',
      name: 'please_enter_text_to_generate_tts',
      desc: '',
      args: [],
    );
  }

  /// `检测到架构不匹配：当前应用 Build Architecture 为 {buildArchitecture}，但 Windows Operating System 为 {operatingSystemArchitecture}。请前往官方下载页下载匹配版本：{url}`
  String windows_architecture_mismatch_warning(
    Object buildArchitecture,
    Object operatingSystemArchitecture,
    Object url,
  ) {
    return Intl.message(
      '检测到架构不匹配：当前应用 Build Architecture 为 $buildArchitecture，但 Windows Operating System 为 $operatingSystemArchitecture。请前往官方下载页下载匹配版本：$url',
      name: 'windows_architecture_mismatch_warning',
      desc: '',
      args: [buildArchitecture, operatingSystemArchitecture, url],
    );
  }

  /// `架构不匹配`
  String get windows_architecture_mismatch_dialog_title {
    return Intl.message(
      '架构不匹配',
      name: 'windows_architecture_mismatch_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `当前应用 Build Architecture 为 {buildArchitecture}，但 Windows Operating System 为 {operatingSystemArchitecture}。\n\n请前往官方下载页下载匹配架构的可执行文件：\n{url}`
  String windows_architecture_mismatch_dialog_message(
    Object buildArchitecture,
    Object operatingSystemArchitecture,
    Object url,
  ) {
    return Intl.message(
      '当前应用 Build Architecture 为 $buildArchitecture，但 Windows Operating System 为 $operatingSystemArchitecture。\n\n请前往官方下载页下载匹配架构的可执行文件：\n$url',
      name: 'windows_architecture_mismatch_dialog_message',
      desc: '',
      args: [buildArchitecture, operatingSystemArchitecture, url],
    );
  }

  /// `打开官方下载页`
  String get open_official_download_page {
    return Intl.message(
      '打开官方下载页',
      name: 'open_official_download_page',
      desc: '',
      args: [],
    );
  }

  /// `模仿`
  String get mimic {
    return Intl.message('模仿', name: 'mimic', desc: '', args: []);
  }

  /// `提问`
  String get ask {
    return Intl.message('提问', name: 'ask', desc: '', args: []);
  }

  /// `RWKV 帮你问`
  String get question_generator {
    return Intl.message(
      'RWKV 帮你问',
      name: 'question_generator',
      desc: '',
      args: [],
    );
  }

  /// `不知道怎么开口更合适？让 RWKV 先帮你想一个吧。`
  String get question_generator_mock_description {
    return Intl.message(
      '不知道怎么开口更合适？让 RWKV 先帮你想一个吧。',
      name: 'question_generator_mock_description',
      desc: '',
      args: [],
    );
  }

  /// `一时想不到怎么问？让 RWKV 多帮你想几个问题吧。`
  String get question_generator_mock_batch_description {
    return Intl.message(
      '一时想不到怎么问？让 RWKV 多帮你想几个问题吧。',
      name: 'question_generator_mock_batch_description',
      desc: '',
      args: [],
    );
  }

  /// `选好上面的问题开头后，点一下生成，RWKV 会先帮你想一个可以直接提问的问题。`
  String get question_generator_empty_chat_hint {
    return Intl.message(
      '选好上面的问题开头后，点一下生成，RWKV 会先帮你想一个可以直接提问的问题。',
      name: 'question_generator_empty_chat_hint',
      desc: '',
      args: [],
    );
  }

  /// `选好上面的问题开头后，点一下生成，RWKV 会先帮你想几个可以直接提问的问题。`
  String get question_generator_empty_chat_batch_hint {
    return Intl.message(
      '选好上面的问题开头后，点一下生成，RWKV 会先帮你想几个可以直接提问的问题。',
      name: 'question_generator_empty_chat_batch_hint',
      desc: '',
      args: [],
    );
  }

  /// `点一下生成，RWKV 会顺着你选好的开头，帮你想出最多 {count} 个问题。`
  String question_generator_tap_generate_hint(Object count) {
    return Intl.message(
      '点一下生成，RWKV 会顺着你选好的开头，帮你想出最多 $count 个问题。',
      name: 'question_generator_tap_generate_hint',
      desc: '',
      args: [count],
    );
  }

  /// `切换语言后，上面可选的问题开头也会一起变化。挑一个顺手的开头，再让 RWKV 接着往下想就好。`
  String get question_generator_language_switched_hint {
    return Intl.message(
      '切换语言后，上面可选的问题开头也会一起变化。挑一个顺手的开头，再让 RWKV 接着往下想就好。',
      name: 'question_generator_language_switched_hint',
      desc: '',
      args: [],
    );
  }

  /// `点一点不同的问题开头，RWKV 会顺着这个开头继续帮你生成问题。你也可以直接改下面的输入框，写一个更符合你想法的开头。`
  String get question_generator_prefix_guide {
    return Intl.message(
      '点一点不同的问题开头，RWKV 会顺着这个开头继续帮你生成问题。你也可以直接改下面的输入框，写一个更符合你想法的开头。',
      name: 'question_generator_prefix_guide',
      desc: '',
      args: [],
    );
  }

  /// `问题前缀`
  String get question_generator_prefixes {
    return Intl.message(
      '问题前缀',
      name: 'question_generator_prefixes',
      desc: '',
      args: [],
    );
  }

  /// `生成数量`
  String get question_generator_count {
    return Intl.message(
      '生成数量',
      name: 'question_generator_count',
      desc: '',
      args: [],
    );
  }

  /// `在这里写下你想要的问题开头...`
  String get question_generator_prefix_input_placeholder {
    return Intl.message(
      '在这里写下你想要的问题开头...',
      name: 'question_generator_prefix_input_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `如果留空，RWKV 会根据上下文生成问题`
  String get question_generator_context_prefix_input_placeholder {
    return Intl.message(
      '如果留空，RWKV 会根据上下文生成问题',
      name: 'question_generator_context_prefix_input_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `请先输入一个问题前缀`
  String get question_generator_prefix_required {
    return Intl.message(
      '请先输入一个问题前缀',
      name: 'question_generator_prefix_required',
      desc: '',
      args: [],
    );
  }

  /// `点击已生成的问题，即可粘贴到对话输入框。`
  String get question_generator_question_action_guide {
    return Intl.message(
      '点击已生成的问题，即可粘贴到对话输入框。',
      name: 'question_generator_question_action_guide',
      desc: '',
      args: [],
    );
  }

  /// `我想让 RWKV 以这种语言提问...`
  String get question_language {
    return Intl.message(
      '我想让 RWKV 以这种语言提问...',
      name: 'question_language',
      desc: '',
      args: [],
    );
  }

  /// `前缀组`
  String get prefix_bank {
    return Intl.message('前缀组', name: 'prefix_bank', desc: '', args: []);
  }

  /// `前缀示例`
  String get prefix_examples {
    return Intl.message('前缀示例', name: 'prefix_examples', desc: '', args: []);
  }

  /// `生成的问题`
  String get generated_questions {
    return Intl.message(
      '生成的问题',
      name: 'generated_questions',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get english {
    return Intl.message('English', name: 'english', desc: '', args: []);
  }

  /// `日本語`
  String get japanese {
    return Intl.message('日本語', name: 'japanese', desc: '', args: []);
  }

  /// `한국어`
  String get korean {
    return Intl.message('한국어', name: 'korean', desc: '', args: []);
  }

  /// `Русский`
  String get russian {
    return Intl.message('Русский', name: 'russian', desc: '', args: []);
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
      Locale.fromSubtags(languageCode: 'ru'),
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
