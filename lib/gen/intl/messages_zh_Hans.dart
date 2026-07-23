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

  static String m0(completed, total, passed, failed, invalid) =>
      "已完成 ${completed}/${total} · 通过 ${passed} · 失败 ${failed} · 无效 ${invalid}";

  static String m1(current, total, name) =>
      "正在运行 ${current}/${total} · ${name}";

  static String m2(tools) => "工具：${tools}";

  static String m3(turn, title) => "第 ${turn} 轮 · ${title}";

  static String m4(dlls) =>
      "缺少运行时 DLL：${dlls}\n请使用完整的 Albatross bundle，并确保 lib 文件夹与程序在同一目录下";

  static String m5(error) => "错误: ${error}";

  static String m6(error) => "API 服务器启动失败: ${error}";

  static String m7(port) => "API 服务器已在端口 ${port} 启动";

  static String m8(count) => "并行 × ${count}";

  static String m9(count) => "每次推理将生成 ${count} 条消息";

  static String m10(count) => "每次生成 ${count} 条结果";

  static String m11(count) => "并行推理：${count} 条输出";

  static String m12(index) => "已选择第 ${index} 条输出";

  static String m13(batch) => "Batch ${batch}";

  static String m14(first, last, count) =>
      "Batch ${first}-${last}（共 ${count} 次）";

  static String m15(batch) => "Batch ${batch}";

  static String m16(count) => "最高支持 Batch ${count}";

  static String m17(batch, current, total) =>
      "Batch ${batch} · ${current}/${total}";

  static String m18(current, total, speed) =>
      "${current}/${total} · ${speed} t/s";

  static String m19(speed) => "Decode 峰值: ${speed} t/s";

  static String m20(progress, speed) => "${progress}% · ${speed} t/s";

  static String m21(prefillSpeed, decodeSpeed) =>
      "Prefill ${prefillSpeed} t/s · Decode ${decodeSpeed} t/s";

  static String m22(current, total, phase) => "${current}/${total} · ${phase}";

  static String m23(demoName) => "欢迎探索 ${demoName}";

  static String m24(maxLength) => "会话名称不能超过 ${maxLength} 个字符";

  static String m25(length) => "ctx ${length}";

  static String m26(modelName) => "当前模型: ${modelName}";

  static String m27(current, total) => "当前进度: ${current}/${total}";

  static String m28(current, total) => "当前测试项 (${current}/${total})";

  static String m29(count) => "确定要删除 ${count} 个会话吗？";

  static String m30(path) => "消息记录会存储在该文件夹下\n ${path}";

  static String m31(error) => "删除文件失败：${error}";

  static String m32(successCount, failCount) =>
      "${successCount} 个文件已移动，${failCount} 个失败";

  static String m33(value) => "Frequency Penalty: ${value}";

  static String m34(port) => "HTTP 服务 (端口: ${port})";

  static String m35(flag, nameCN, nameEN) =>
      "模仿 ${flag} ${nameCN}(${nameEN}) 的声音";

  static String m36(fileName) => "模仿 ${fileName}";

  static String m37(count) => "导入成功：已导入 ${count} 个文件";

  static String m38(commitId) => "推理引擎版本：${commitId}";

  static String m39(percent) => "加载${percent}%";

  static String m40(folderName) => "本地文件夹：${folderName}";

  static String m41(memUsed, memFree) => "已用内存：${memUsed}，剩余内存：${memFree}";

  static String m42(count) => "${count} 条消息正在队列中";

  static String m43(text) => "模型输出: ${text}";

  static String m44(socName) => "暂未支持您的芯片 ${socName} 的 NPU 加速";

  static String m45(takePhoto) => "点击 ${takePhoto}。RWKV 将翻译图片中的文本。";

  static String m46(error) => "空文件夹创建失败：${error}";

  static String m47(os) => "当前操作系统(${os})不支持打开文件夹的操作。";

  static String m48(path) => "路径：${path}";

  static String m49(value) => "Penalty Decay: ${value}";

  static String m50(index) => "请选择要为第 ${index} 条消息设置的采样和惩罚参数";

  static String m51(percent) => "预填充进度 ${percent}";

  static String m52(value) => "Presence Penalty: ${value}";

  static String m53(count) => "点一下生成，RWKV 会顺着你选好的开头，帮你想出最多 ${count} 个问题。";

  static String m54(count) => "排队中: ${count}";

  static String m55(count) => "当前模型不支持 ${count} 种表达风格";

  static String m56(count) => "同时回答 ${count} 个随机问题";

  static String m57(count) => "预制问题不足，无法发起 ${count} 个随机问题";

  static String m58(count) => "已选择 ${count}";

  static String m59(text) => "源文本: ${text}";

  static String m60(text) => "目标文本: ${text}";

  static String m61(value) => "Temperature: ${value}";

  static String m62(footer) => "推理${footer}-英";

  static String m63(footer) => "推理${footer}-英长";

  static String m64(footer) => "推理${footer}-英短";

  static String m65(footer) => "推理${footer}-快";

  static String m66(footer) => "推理${footer}-中";

  static String m67(footer) => "推理${footer}-高";

  static String m68(footer) => "推理${footer}-傻";

  static String m69(value) => "Top P: ${value}";

  static String m70(count) => "总测试项: ${count}";

  static String m71(model) => "官方云端 ${model}";

  static String m72(error) => "Web Demo 失败：${error}";

  static String m73(count, backend) => "${count} 个页面 · ${backend}";

  static String m74(index) => "网页 ${index}";

  static String m75(label) => "${label} 源代码";

  static String m76(tokens, bytes) => "${tokens} tokens，${bytes} bytes";

  static String m77(port) => "WebSocket 服务 (端口: ${port})";

  static String m78(id) => "窗口 ${id}";

  static String m79(buildArchitecture, operatingSystemArchitecture, url) =>
      "当前应用 Build Architecture 为 ${buildArchitecture}，但 Windows Operating System 为 ${operatingSystemArchitecture}。\n\n请前往官方下载页下载匹配架构的可执行文件：\n${url}";

  static String m80(buildArchitecture, operatingSystemArchitecture, url) =>
      "检测到架构不匹配：当前应用 Build Architecture 为 ${buildArchitecture}，但 Windows Operating System 为 ${operatingSystemArchitecture}。请前往官方下载页下载匹配版本：${url}";

  static String m81(count) => "${count} 个标签页";

  static String m82(modelName) => "您当前正在使用 ${modelName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("关于"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("根据: "),
    "accuracy": MessageLookupByLibrary.simpleMessage("准确率"),
    "adapting_more_inference_chips": MessageLookupByLibrary.simpleMessage(
      "我们正在持续适配更多的推理芯片，敬请期待。",
    ),
    "add_local_folder": MessageLookupByLibrary.simpleMessage("添加本地文件夹"),
    "advance_settings": MessageLookupByLibrary.simpleMessage("高级设置"),
    "agent_eval_active_model_unknown": MessageLookupByLibrary.simpleMessage(
      "Agent 能力评测无法识别当前聊天模型",
    ),
    "agent_eval_assisted_pass": MessageLookupByLibrary.simpleMessage("辅助后通过"),
    "agent_eval_case": MessageLookupByLibrary.simpleMessage("用例"),
    "agent_eval_completed": m0,
    "agent_eval_export": MessageLookupByLibrary.simpleMessage("导出报告"),
    "agent_eval_export_title": MessageLookupByLibrary.simpleMessage(
      "导出 Agent 能力评测报告",
    ),
    "agent_eval_fail": MessageLookupByLibrary.simpleMessage("失败"),
    "agent_eval_invalid": MessageLookupByLibrary.simpleMessage("无效"),
    "agent_eval_mode": MessageLookupByLibrary.simpleMessage("评分模式"),
    "agent_eval_mode_assisted": MessageLookupByLibrary.simpleMessage("辅助"),
    "agent_eval_mode_assisted_description":
        MessageLookupByLibrary.simpleMessage("允许带审计记录的宿主修复，用于诊断，同时报告严格分和辅助分。"),
    "agent_eval_mode_strict": MessageLookupByLibrary.simpleMessage("严格"),
    "agent_eval_mode_strict_description": MessageLookupByLibrary.simpleMessage(
      "按模型原始行为评分。宿主修复、类型转换、截断或强制工具调用都会导致严格评分失败。",
    ),
    "agent_eval_no_report": MessageLookupByLibrary.simpleMessage(
      "尚无可用的 Agent 能力评测报告",
    ),
    "agent_eval_repeats": MessageLookupByLibrary.simpleMessage("重复次数"),
    "agent_eval_run_all": MessageLookupByLibrary.simpleMessage("运行全部"),
    "agent_eval_running": m1,
    "agent_eval_sandbox_description": MessageLookupByLibrary.simpleMessage(
      "评测文件仅保存在内存中。文件执行、测试、AWK、权限和定时任务均为确定性模拟。Lua 在可终止的独立 Isolate 中运行，限时 2 秒，无法访问网络、宿主文件、系统命令、模块或调试 API。这里提供进程隔离，不提供严格的内存配额。",
    ),
    "agent_eval_sandbox_title": MessageLookupByLibrary.simpleMessage("受限评测沙箱"),
    "agent_eval_strict_pass": MessageLookupByLibrary.simpleMessage("通过"),
    "agent_eval_tools": m2,
    "agent_eval_turn": m3,
    "agent_test": MessageLookupByLibrary.simpleMessage("Agent 能力评测"),
    "albatross_backend_unsupported": MessageLookupByLibrary.simpleMessage(
      "当前 Albatross 后端暂不支持此功能",
    ),
    "albatross_binary": MessageLookupByLibrary.simpleMessage("程序"),
    "albatross_binary_compile_hint": MessageLookupByLibrary.simpleMessage(
      "Binary 可能需要根据你的机器环境自行编译。我们推荐你使用本地 AI Agent 编译对应的 Binary。",
    ),
    "albatross_binary_config_missing": MessageLookupByLibrary.simpleMessage(
      "缺少 Albatross 程序下载配置",
    ),
    "albatross_binary_required": MessageLookupByLibrary.simpleMessage(
      "请先选择 Albatross 程序",
    ),
    "albatross_binary_tokenizer_source": MessageLookupByLibrary.simpleMessage(
      "Binary 和 Tokenizer 来源",
    ),
    "albatross_chat": MessageLookupByLibrary.simpleMessage("Albatross Chat"),
    "albatross_chat_description": MessageLookupByLibrary.simpleMessage(
      "使用本地 Albatross CUDA 后端聊天",
    ),
    "albatross_checking_service": MessageLookupByLibrary.simpleMessage("检查中"),
    "albatross_compatibility_ok": MessageLookupByLibrary.simpleMessage(
      "CUDA 后端可用",
    ),
    "albatross_compatibility_warning": MessageLookupByLibrary.simpleMessage(
      "未确认 CUDA 兼容性",
    ),
    "albatross_connected": MessageLookupByLibrary.simpleMessage(
      "已连接 Albatross",
    ),
    "albatross_connecting": MessageLookupByLibrary.simpleMessage("连接中"),
    "albatross_copy_all_logs": MessageLookupByLibrary.simpleMessage("复制全部日志"),
    "albatross_cuda_not_detected": MessageLookupByLibrary.simpleMessage(
      "暂未检测到 CUDA 信息",
    ),
    "albatross_download_binary": MessageLookupByLibrary.simpleMessage("下载程序"),
    "albatross_download_tokenizer": MessageLookupByLibrary.simpleMessage(
      "下载词表",
    ),
    "albatross_drop_files": MessageLookupByLibrary.simpleMessage(
      "拖入 exe、PTH、词表或模型文件夹",
    ),
    "albatross_early_stage_notice": MessageLookupByLibrary.simpleMessage(
      "Albatross 目前处于非常早期的迭代开发阶段。页面展示与可用功能会持续调整，部分平台暂时仅提供配置、查看和日志等辅助能力。",
    ),
    "albatross_endpoint": MessageLookupByLibrary.simpleMessage("服务地址"),
    "albatross_enter_chat": MessageLookupByLibrary.simpleMessage("进入聊天"),
    "albatross_exit_code": MessageLookupByLibrary.simpleMessage("退出码"),
    "albatross_export_logs_txt": MessageLookupByLibrary.simpleMessage(
      "导出日志为 .txt",
    ),
    "albatross_external_service": MessageLookupByLibrary.simpleMessage("外部服务"),
    "albatross_host": MessageLookupByLibrary.simpleMessage("Host"),
    "albatross_last_error": MessageLookupByLibrary.simpleMessage("最近错误"),
    "albatross_launch_command": MessageLookupByLibrary.simpleMessage("启动命令"),
    "albatross_launch_config": MessageLookupByLibrary.simpleMessage("启动配置"),
    "albatross_launch_config_hint": MessageLookupByLibrary.simpleMessage(
      "Host 和端口会用于连接本地 Albatross 服务，运行中不可修改",
    ),
    "albatross_launched_by_app": MessageLookupByLibrary.simpleMessage(
      "由 RWKV Chat 启动",
    ),
    "albatross_missing_runtime_dlls": m4,
    "albatross_model": MessageLookupByLibrary.simpleMessage("模型"),
    "albatross_model_management": MessageLookupByLibrary.simpleMessage(
      "PTH 模型",
    ),
    "albatross_model_required": MessageLookupByLibrary.simpleMessage(
      "请先选择 PTH 模型",
    ),
    "albatross_no_downloaded_pth": MessageLookupByLibrary.simpleMessage(
      "没有已下载的 PTH 模型",
    ),
    "albatross_no_logs": MessageLookupByLibrary.simpleMessage("暂无日志"),
    "albatross_no_pth_candidates": MessageLookupByLibrary.simpleMessage(
      "暂无可用 PTH 模型，可选择本地 PTH 文件",
    ),
    "albatross_not_connected": MessageLookupByLibrary.simpleMessage(
      "未连接 Albatross",
    ),
    "albatross_not_selected": MessageLookupByLibrary.simpleMessage("未选择"),
    "albatross_open_resource_failed": MessageLookupByLibrary.simpleMessage(
      "无法打开资源链接",
    ),
    "albatross_parameter_hint": MessageLookupByLibrary.simpleMessage(
      "Albatross 当前沿用聊天页的采样参数",
    ),
    "albatross_parameters": MessageLookupByLibrary.simpleMessage("运行参数"),
    "albatross_pick_binary": MessageLookupByLibrary.simpleMessage("选择程序"),
    "albatross_pick_model_folder": MessageLookupByLibrary.simpleMessage(
      "选择模型文件夹",
    ),
    "albatross_pick_pth": MessageLookupByLibrary.simpleMessage("选择 PTH"),
    "albatross_pick_tokenizer": MessageLookupByLibrary.simpleMessage("选择词表"),
    "albatross_port": MessageLookupByLibrary.simpleMessage("端口"),
    "albatross_preflight_failed": MessageLookupByLibrary.simpleMessage(
      "请检查已高亮的 Albatross 设置区域",
    ),
    "albatross_probe_service": MessageLookupByLibrary.simpleMessage("检查服务"),
    "albatross_pth_source": MessageLookupByLibrary.simpleMessage("PTH 文件来源"),
    "albatross_refresh_cuda_info": MessageLookupByLibrary.simpleMessage(
      "刷新 CUDA 信息",
    ),
    "albatross_restart_runtime": MessageLookupByLibrary.simpleMessage(
      "重启 Runtime",
    ),
    "albatross_runtime_assets": MessageLookupByLibrary.simpleMessage(
      "Runtime、词表与 PTH 模型",
    ),
    "albatross_runtime_assets_hint": MessageLookupByLibrary.simpleMessage(
      "请从本地选择程序、词表和 PTH 模型",
    ),
    "albatross_runtime_logs": MessageLookupByLibrary.simpleMessage("运行日志"),
    "albatross_runtime_management": MessageLookupByLibrary.simpleMessage(
      "Runtime 管理",
    ),
    "albatross_select_downloaded_pth": MessageLookupByLibrary.simpleMessage(
      "选择已下载 PTH",
    ),
    "albatross_select_this_model": MessageLookupByLibrary.simpleMessage(
      "选择此模型",
    ),
    "albatross_selected_model": MessageLookupByLibrary.simpleMessage("已选择"),
    "albatross_service_not_running": MessageLookupByLibrary.simpleMessage(
      "Albatross 服务未运行",
    ),
    "albatross_start_chat": MessageLookupByLibrary.simpleMessage("启动并进入聊天"),
    "albatross_stop_runtime": MessageLookupByLibrary.simpleMessage(
      "停止 Runtime",
    ),
    "albatross_system_info": MessageLookupByLibrary.simpleMessage("当前电脑"),
    "albatross_tokenizer": MessageLookupByLibrary.simpleMessage("词表"),
    "albatross_tokenizer_config_missing": MessageLookupByLibrary.simpleMessage(
      "缺少 Albatross 词表下载配置",
    ),
    "albatross_tokenizer_required": MessageLookupByLibrary.simpleMessage(
      "请先选择词表",
    ),
    "albatross_use_downloaded_pth": MessageLookupByLibrary.simpleMessage(
      "使用已下载 PTH",
    ),
    "all": MessageLookupByLibrary.simpleMessage("全部"),
    "all_done": MessageLookupByLibrary.simpleMessage("全部完成"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("全部提示词"),
    "all_the_same": MessageLookupByLibrary.simpleMessage("全部相同"),
    "allow_background_downloads": MessageLookupByLibrary.simpleMessage(
      "允许后台下载",
    ),
    "already_using_this_directory": MessageLookupByLibrary.simpleMessage(
      "已在使用此目录",
    ),
    "analysing_result": MessageLookupByLibrary.simpleMessage("正在分析搜索结果"),
    "api_server": MessageLookupByLibrary.simpleMessage("API 服务器"),
    "api_server_active_request_no": MessageLookupByLibrary.simpleMessage(
      "当前请求: 无",
    ),
    "api_server_active_request_stopped": MessageLookupByLibrary.simpleMessage(
      "已停止当前请求",
    ),
    "api_server_active_request_yes": MessageLookupByLibrary.simpleMessage(
      "当前请求: 有",
    ),
    "api_server_android_foreground_hint": MessageLookupByLibrary.simpleMessage(
      "请保持 App 在前台，并让电脑与手机连接同一 Wi-Fi",
    ),
    "api_server_chat_empty_hint": MessageLookupByLibrary.simpleMessage(
      "发送一条消息来测试 API",
    ),
    "api_server_chat_error": m5,
    "api_server_chat_input_hint": MessageLookupByLibrary.simpleMessage(
      "输入消息...",
    ),
    "api_server_chat_test": MessageLookupByLibrary.simpleMessage("对话测试"),
    "api_server_curl_hint": MessageLookupByLibrary.simpleMessage("使用示例"),
    "api_server_description": MessageLookupByLibrary.simpleMessage(
      "启动 OpenAI 兼容的本地服务器",
    ),
    "api_server_docs": MessageLookupByLibrary.simpleMessage("API 文档"),
    "api_server_failed_to_start": m6,
    "api_server_logs": MessageLookupByLibrary.simpleMessage("请求日志"),
    "api_server_no_active_request": MessageLookupByLibrary.simpleMessage(
      "当前没有进行中的请求",
    ),
    "api_server_no_lan_address": MessageLookupByLibrary.simpleMessage(
      "未检测到可供电脑访问的局域网地址",
    ),
    "api_server_no_model": MessageLookupByLibrary.simpleMessage("未加载模型"),
    "api_server_open_dashboard": MessageLookupByLibrary.simpleMessage("打开控制面板"),
    "api_server_port": MessageLookupByLibrary.simpleMessage("端口"),
    "api_server_request_count": MessageLookupByLibrary.simpleMessage("请求数"),
    "api_server_running": MessageLookupByLibrary.simpleMessage("服务器运行中"),
    "api_server_select_model_first": MessageLookupByLibrary.simpleMessage(
      "请先选择一个聊天模型",
    ),
    "api_server_send": MessageLookupByLibrary.simpleMessage("发送"),
    "api_server_start": MessageLookupByLibrary.simpleMessage("启动服务器"),
    "api_server_started_on_port": m7,
    "api_server_starting": MessageLookupByLibrary.simpleMessage("服务器启动中"),
    "api_server_stop": MessageLookupByLibrary.simpleMessage("停止服务器"),
    "api_server_stopped": MessageLookupByLibrary.simpleMessage("服务器已停止"),
    "api_server_url": MessageLookupByLibrary.simpleMessage("服务器地址"),
    "app_is_already_up_to_date": MessageLookupByLibrary.simpleMessage(
      "已经是最新版本",
    ),
    "appearance": MessageLookupByLibrary.simpleMessage("外观"),
    "appearance_mode": MessageLookupByLibrary.simpleMessage("外观模式"),
    "application_cache_cleared": MessageLookupByLibrary.simpleMessage(
      "缓存已清除，重启应用后完全生效",
    ),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "应用内测群",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("应用语言"),
    "application_mode": MessageLookupByLibrary.simpleMessage("应用模式"),
    "application_settings": MessageLookupByLibrary.simpleMessage("应用设置"),
    "apply": MessageLookupByLibrary.simpleMessage("应用"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage("确定要删除这个模型吗？"),
    "ask": MessageLookupByLibrary.simpleMessage("提问"),
    "ask_me_anything": MessageLookupByLibrary.simpleMessage("随意向我提问..."),
    "assistant": MessageLookupByLibrary.simpleMessage("RWKV:"),
    "auto": MessageLookupByLibrary.simpleMessage("自动"),
    "auto_detect": MessageLookupByLibrary.simpleMessage("自动检测"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("返回聊天"),
    "background_color": MessageLookupByLibrary.simpleMessage("背景颜色"),
    "balanced": MessageLookupByLibrary.simpleMessage("均衡"),
    "batch_completion": MessageLookupByLibrary.simpleMessage("并行续写"),
    "batch_completion_settings": MessageLookupByLibrary.simpleMessage("并行续写设置"),
    "batch_inference": MessageLookupByLibrary.simpleMessage("并行推理"),
    "batch_inference_button": m8,
    "batch_inference_count": MessageLookupByLibrary.simpleMessage("并行推理数量"),
    "batch_inference_count_detail": m9,
    "batch_inference_count_detail_2": m10,
    "batch_inference_detail": MessageLookupByLibrary.simpleMessage(
      "开启并行推理后，RWKV 可以同时生成多个答案",
    ),
    "batch_inference_enable_or_not": MessageLookupByLibrary.simpleMessage(
      "开启或关闭并行推理",
    ),
    "batch_inference_running": m11,
    "batch_inference_selected": m12,
    "batch_inference_settings": MessageLookupByLibrary.simpleMessage("并行推理设置"),
    "batch_inference_short": MessageLookupByLibrary.simpleMessage("并行"),
    "batch_inference_width": MessageLookupByLibrary.simpleMessage("消息显示宽度"),
    "batch_inference_width_2": MessageLookupByLibrary.simpleMessage("结果显示宽度"),
    "batch_inference_width_detail": MessageLookupByLibrary.simpleMessage(
      "并行推理每条消息宽度",
    ),
    "batch_inference_width_detail_2": MessageLookupByLibrary.simpleMessage(
      "每条结果的宽度",
    ),
    "beginner": MessageLookupByLibrary.simpleMessage("新手模式"),
    "below_are_your_local_folders": MessageLookupByLibrary.simpleMessage(
      "下面是您本地的文件夹",
    ),
    "benchmark": MessageLookupByLibrary.simpleMessage("基准测试"),
    "benchmark_batch": m13,
    "benchmark_batch_not_supported_by_model":
        MessageLookupByLibrary.simpleMessage("模型不支持"),
    "benchmark_batch_plan_range": m14,
    "benchmark_batch_plan_single": MessageLookupByLibrary.simpleMessage(
      "Batch 1",
    ),
    "benchmark_batch_result": m15,
    "benchmark_batch_supported_up_to": m16,
    "benchmark_batch_waiting_for_backend": MessageLookupByLibrary.simpleMessage(
      "等待后端能力信息",
    ),
    "benchmark_best_bw": MessageLookupByLibrary.simpleMessage("最佳带宽"),
    "benchmark_best_decode": MessageLookupByLibrary.simpleMessage("最佳 Decode"),
    "benchmark_best_decode_per_batch": MessageLookupByLibrary.simpleMessage(
      "最佳 Decode / Batch",
    ),
    "benchmark_best_flops": MessageLookupByLibrary.simpleMessage("最佳 FLOPS"),
    "benchmark_current": MessageLookupByLibrary.simpleMessage("当前测试"),
    "benchmark_current_batch": m17,
    "benchmark_decode_per_batch": MessageLookupByLibrary.simpleMessage(
      "Decode / Batch",
    ),
    "benchmark_decode_progress_speed": m18,
    "benchmark_info_app_version": MessageLookupByLibrary.simpleMessage("应用版本"),
    "benchmark_info_backend": MessageLookupByLibrary.simpleMessage("后端"),
    "benchmark_info_build_mode": MessageLookupByLibrary.simpleMessage("构建模式"),
    "benchmark_info_cpu_name": MessageLookupByLibrary.simpleMessage("CPU"),
    "benchmark_info_device_model": MessageLookupByLibrary.simpleMessage("设备型号"),
    "benchmark_info_file_size": MessageLookupByLibrary.simpleMessage("文件大小"),
    "benchmark_info_gpu_name": MessageLookupByLibrary.simpleMessage("GPU"),
    "benchmark_info_os": MessageLookupByLibrary.simpleMessage("操作系统"),
    "benchmark_info_os_version": MessageLookupByLibrary.simpleMessage("系统版本"),
    "benchmark_info_soc_brand": MessageLookupByLibrary.simpleMessage("SoC 品牌"),
    "benchmark_info_soc_name": MessageLookupByLibrary.simpleMessage("SoC 名称"),
    "benchmark_info_total_memory": MessageLookupByLibrary.simpleMessage("总内存"),
    "benchmark_info_total_vram": MessageLookupByLibrary.simpleMessage("总显存"),
    "benchmark_peak_decode": m19,
    "benchmark_plan": MessageLookupByLibrary.simpleMessage("测试计划"),
    "benchmark_progress": MessageLookupByLibrary.simpleMessage("基准测试进度"),
    "benchmark_progress_speed": m20,
    "benchmark_result": MessageLookupByLibrary.simpleMessage("基准测试结果"),
    "benchmark_result_speed_line": m21,
    "benchmark_run": MessageLookupByLibrary.simpleMessage("轮次"),
    "benchmark_run_status": m22,
    "benchmark_support": MessageLookupByLibrary.simpleMessage("支持情况"),
    "benchmark_total_decode": MessageLookupByLibrary.simpleMessage("总 Decode"),
    "black": MessageLookupByLibrary.simpleMessage("黑方"),
    "black_score": MessageLookupByLibrary.simpleMessage("黑方得分"),
    "black_wins": MessageLookupByLibrary.simpleMessage("黑方获胜！"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "机器人消息已编辑，现在可以发送新消息",
    ),
    "branch_switcher_tooltip_first": MessageLookupByLibrary.simpleMessage(
      "已经是第一条消息了",
    ),
    "branch_switcher_tooltip_last": MessageLookupByLibrary.simpleMessage(
      "已经是最后一条消息了",
    ),
    "branch_switcher_tooltip_next": MessageLookupByLibrary.simpleMessage(
      "下一条消息",
    ),
    "branch_switcher_tooltip_prev": MessageLookupByLibrary.simpleMessage(
      "上一条消息",
    ),
    "browser_status": MessageLookupByLibrary.simpleMessage("浏览器状态"),
    "cached_translations_disk": MessageLookupByLibrary.simpleMessage(
      "缓存的翻译 (磁盘)",
    ),
    "cached_translations_memory": MessageLookupByLibrary.simpleMessage(
      "缓存的翻译 (内存)",
    ),
    "camera": MessageLookupByLibrary.simpleMessage("相机"),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("无法生成"),
    "cancel": MessageLookupByLibrary.simpleMessage("取消"),
    "cancel_all_selection": MessageLookupByLibrary.simpleMessage("取消全选"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("取消下载"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("暂不更新"),
    "change": MessageLookupByLibrary.simpleMessage("更改"),
    "change_selected_image": MessageLookupByLibrary.simpleMessage("更换图片"),
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
    "chat_welcome_to_use": m23,
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
    "clear_application_cache": MessageLookupByLibrary.simpleMessage("清除缓存"),
    "clear_application_cache_confirmation":
        MessageLookupByLibrary.simpleMessage(
          "确定要清除应用偏好和本地配置缓存吗？聊天记录、导出文件和权重文件不会被删除。自定义模型目录会保留。",
        ),
    "clear_memory_cache": MessageLookupByLibrary.simpleMessage("清除内存缓存"),
    "clear_text": MessageLookupByLibrary.simpleMessage("清除文本"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "点击此处选择新模型",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "点击此处开始新聊天",
    ),
    "click_plus_add_local_folder": MessageLookupByLibrary.simpleMessage(
      "点击 + 添加本地文件夹，RWKV Chat 会扫描该文件夹下的 .pth 文件和 RWKV .gguf 文件，并将其作为可加载的权重",
    ),
    "click_plus_to_add_more_folders": MessageLookupByLibrary.simpleMessage(
      "点击 + 号添加更多本地文件夹",
    ),
    "click_to_load_image": MessageLookupByLibrary.simpleMessage("点击加载图片"),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage("点击选择模型"),
    "close": MessageLookupByLibrary.simpleMessage("关闭"),
    "code_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "代码已复制到剪贴板",
    ),
    "colon": MessageLookupByLibrary.simpleMessage("："),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "色彩模式跟随系统",
    ),
    "completion": MessageLookupByLibrary.simpleMessage("续写模式"),
    "completion_mode": MessageLookupByLibrary.simpleMessage("续写模式"),
    "confirm": MessageLookupByLibrary.simpleMessage("确认"),
    "confirm_delete_file_message": MessageLookupByLibrary.simpleMessage(
      "该文件将在您的本地硬盘中被永久删除",
    ),
    "confirm_delete_file_title": MessageLookupByLibrary.simpleMessage(
      "确定要删除该文件吗？",
    ),
    "confirm_forget_location_message": MessageLookupByLibrary.simpleMessage(
      "忘记该位置后，该文件夹将不再显示在本地文件夹列表中",
    ),
    "confirm_forget_location_title": MessageLookupByLibrary.simpleMessage(
      "确定要忘记该位置吗？",
    ),
    "continue2": MessageLookupByLibrary.simpleMessage("续写"),
    "continue_download": MessageLookupByLibrary.simpleMessage("继续下载"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "继续使用较小模型",
    ),
    "conversation_management": MessageLookupByLibrary.simpleMessage("管理"),
    "conversation_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "会话名称不能为空",
    ),
    "conversation_name_cannot_be_longer_than_30_characters": m24,
    "conversation_token_count": MessageLookupByLibrary.simpleMessage(
      "当前对话 Token 数量",
    ),
    "conversation_token_limit_hint_short": MessageLookupByLibrary.simpleMessage(
      "建议开启新对话",
    ),
    "conversation_token_limit_recommend_new_chat":
        MessageLookupByLibrary.simpleMessage("当前对话已超过 8,000 tokens，建议开启新对话"),
    "conversations": MessageLookupByLibrary.simpleMessage("会话"),
    "copy_code": MessageLookupByLibrary.simpleMessage("复制代码"),
    "copy_text": MessageLookupByLibrary.simpleMessage("复制文本"),
    "correct_count": MessageLookupByLibrary.simpleMessage("正确数"),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("点击上方按钮创建新会话"),
    "created_at": MessageLookupByLibrary.simpleMessage("创建时间"),
    "creative_recommended": MessageLookupByLibrary.simpleMessage("创意 (推荐)"),
    "creative_recommended_short": MessageLookupByLibrary.simpleMessage("创意"),
    "ctx_length_label": m25,
    "current_folder_has_no_local_models": MessageLookupByLibrary.simpleMessage(
      "当前文件夹没有可用于 Chat 的本地模型",
    ),
    "current_model": m26,
    "current_model_from_latest_json_not_pth":
        MessageLookupByLibrary.simpleMessage("当前模型来自 latest.json 配置，未加载本地模型文件"),
    "current_progress": m27,
    "current_task_tab_id": MessageLookupByLibrary.simpleMessage("当前任务标签页 ID"),
    "current_task_text_length": MessageLookupByLibrary.simpleMessage(
      "当前任务文本长度",
    ),
    "current_task_url": MessageLookupByLibrary.simpleMessage("当前任务 URL"),
    "current_test_item": m28,
    "current_turn": MessageLookupByLibrary.simpleMessage("当前回合"),
    "current_version": MessageLookupByLibrary.simpleMessage("当前版本"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage("自定义难度"),
    "custom_directory_set": MessageLookupByLibrary.simpleMessage("自定义目录已设置"),
    "dark_mode": MessageLookupByLibrary.simpleMessage("深色模式"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage("深色模式主题"),
    "decode": MessageLookupByLibrary.simpleMessage("解码"),
    "decode_param": MessageLookupByLibrary.simpleMessage("解码参数"),
    "decode_param_comprehensive": MessageLookupByLibrary.simpleMessage(
      "综合（也值得试试）",
    ),
    "decode_param_comprehensive_short": MessageLookupByLibrary.simpleMessage(
      "综合",
    ),
    "decode_param_conservative": MessageLookupByLibrary.simpleMessage(
      "保守（适合数学和代码）",
    ),
    "decode_param_conservative_short": MessageLookupByLibrary.simpleMessage(
      "保守",
    ),
    "decode_param_creative": MessageLookupByLibrary.simpleMessage(
      "创意（适合写作，减少重复）",
    ),
    "decode_param_creative_short": MessageLookupByLibrary.simpleMessage("创意"),
    "decode_param_custom": MessageLookupByLibrary.simpleMessage("自定义（自己设定）"),
    "decode_param_custom_short": MessageLookupByLibrary.simpleMessage("自定义"),
    "decode_param_default_": MessageLookupByLibrary.simpleMessage("默认（默认参数）"),
    "decode_param_default_short": MessageLookupByLibrary.simpleMessage("默认"),
    "decode_param_fixed": MessageLookupByLibrary.simpleMessage("固定（最保守）"),
    "decode_param_fixed_short": MessageLookupByLibrary.simpleMessage("固定"),
    "decode_param_fixed_warning": MessageLookupByLibrary.simpleMessage(
      "固定模式会让模型输出非常保守，缺乏多样性。请确认这符合你的意图。",
    ),
    "decode_param_select_message": MessageLookupByLibrary.simpleMessage(
      "我们可以通过解码参数控制 RWKV 的输出风格",
    ),
    "decode_param_select_title": MessageLookupByLibrary.simpleMessage(
      "请选择解码参数",
    ),
    "decode_params_for_each_message": MessageLookupByLibrary.simpleMessage(
      "每条消息的解码参数",
    ),
    "decode_params_for_each_message_detail":
        MessageLookupByLibrary.simpleMessage("批量推理中每条消息的解码参数。点击编辑每条消息的解码参数。"),
    "decode_speed_tokens_per_second": MessageLookupByLibrary.simpleMessage(
      "解码速度（tokens 每秒）",
    ),
    "default_font": MessageLookupByLibrary.simpleMessage("默认"),
    "delete": MessageLookupByLibrary.simpleMessage("删除"),
    "delete_all": MessageLookupByLibrary.simpleMessage("全部删除"),
    "delete_branch_confirmation_message": MessageLookupByLibrary.simpleMessage(
      "这是危险操作：将永久删除当前消息及其所有子节点，并同步删除数据库中的相关记录。该操作不可恢复，是否继续？",
    ),
    "delete_branch_title": MessageLookupByLibrary.simpleMessage("删除当前消息"),
    "delete_conversation": MessageLookupByLibrary.simpleMessage("删除会话"),
    "delete_conversation_message": MessageLookupByLibrary.simpleMessage(
      "确定要删除会话吗？",
    ),
    "delete_conversations_failed": MessageLookupByLibrary.simpleMessage(
      "删除会话失败",
    ),
    "delete_conversations_message": m29,
    "delete_current_branch": MessageLookupByLibrary.simpleMessage("删除当前消息"),
    "delete_finished": MessageLookupByLibrary.simpleMessage("删除完成"),
    "delete_mlx_cache_confirmation": MessageLookupByLibrary.simpleMessage(
      "确定要删除这个 MLX/CoreML 缓存吗？",
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
    "display": MessageLookupByLibrary.simpleMessage("显示设置"),
    "dont_ask_again": MessageLookupByLibrary.simpleMessage("不再询问"),
    "download_all": MessageLookupByLibrary.simpleMessage("下载全部"),
    "download_all_missing": MessageLookupByLibrary.simpleMessage("下载全部缺失文件"),
    "download_app": MessageLookupByLibrary.simpleMessage("下载App"),
    "download_failed": MessageLookupByLibrary.simpleMessage("下载失败"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage("从浏览器下载"),
    "download_missing": MessageLookupByLibrary.simpleMessage("下载缺失文件"),
    "download_model": MessageLookupByLibrary.simpleMessage("下载模型"),
    "download_now": MessageLookupByLibrary.simpleMessage("立即下载"),
    "download_server_": MessageLookupByLibrary.simpleMessage("下载服务器(请试试哪个快)"),
    "download_source": MessageLookupByLibrary.simpleMessage("下载源"),
    "downloading": MessageLookupByLibrary.simpleMessage("下载中"),
    "drag_local_model_file_to_add_folder": MessageLookupByLibrary.simpleMessage(
      "也可以把 .pth 文件、RWKV .gguf 文件或文件夹拖到这里，应用会把对应文件夹加入扫描路径",
    ),
    "draw": MessageLookupByLibrary.simpleMessage("平局！"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage("自动 Dump 消息记录"),
    "dump_see_files_alert_message": m30,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage("协助我们改进算法"),
    "dump_started": MessageLookupByLibrary.simpleMessage("自动 dump 已开启"),
    "dump_stopped": MessageLookupByLibrary.simpleMessage("自动 dump 已关闭"),
    "edit": MessageLookupByLibrary.simpleMessage("编辑"),
    "edit_original_question": MessageLookupByLibrary.simpleMessage("修改原问题"),
    "editing": MessageLookupByLibrary.simpleMessage("编辑中"),
    "en_to_zh": MessageLookupByLibrary.simpleMessage("英->中"),
    "enable_system_proxy": MessageLookupByLibrary.simpleMessage("启用系统代理"),
    "enabled": MessageLookupByLibrary.simpleMessage("开启"),
    "end": MessageLookupByLibrary.simpleMessage("完"),
    "english": MessageLookupByLibrary.simpleMessage("English"),
    "english_translation_result": MessageLookupByLibrary.simpleMessage(
      "英文翻译结果",
    ),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage("请确保设备内存充足，否则可能导致应用崩溃"),
    "enter_text_to_expand": MessageLookupByLibrary.simpleMessage("输入要续写的段落"),
    "enter_text_to_translate": MessageLookupByLibrary.simpleMessage(
      "输入要翻译的文本...",
    ),
    "escape_characters_rendered": MessageLookupByLibrary.simpleMessage(
      "已渲染换行符",
    ),
    "exit_editing": MessageLookupByLibrary.simpleMessage("退出编辑"),
    "experimental_features": MessageLookupByLibrary.simpleMessage("实验性功能"),
    "experimental_features_description": MessageLookupByLibrary.simpleMessage(
      "这些功能仍在测试，体验和行为可能会调整。",
    ),
    "expert": MessageLookupByLibrary.simpleMessage("专家模式"),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("探索RWKV"),
    "exploring": MessageLookupByLibrary.simpleMessage("探索中..."),
    "export_all_weight_files": MessageLookupByLibrary.simpleMessage("导出全部权重文件"),
    "export_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "所有已下载的权重文件将作为单独文件导出到所选目录。同名文件将被跳过。",
    ),
    "export_conversation_failed": MessageLookupByLibrary.simpleMessage(
      "导出会话失败",
    ),
    "export_conversation_to_txt": MessageLookupByLibrary.simpleMessage(
      "导出会话为 .txt 文件",
    ),
    "export_data": MessageLookupByLibrary.simpleMessage("导出数据"),
    "export_debug_panels_to_txt": MessageLookupByLibrary.simpleMessage(
      "导出调试面板为 .txt",
    ),
    "export_failed": MessageLookupByLibrary.simpleMessage("导出失败"),
    "export_markdown_archive": MessageLookupByLibrary.simpleMessage(
      "导出 Markdown 归档",
    ),
    "export_sqlite_database": MessageLookupByLibrary.simpleMessage(
      "导出 SQLite 数据库",
    ),
    "export_success": MessageLookupByLibrary.simpleMessage("导出成功"),
    "export_title": MessageLookupByLibrary.simpleMessage("会话标题:"),
    "export_weight_file": MessageLookupByLibrary.simpleMessage("导出权重文件"),
    "extra_large": MessageLookupByLibrary.simpleMessage("特大 (130%)"),
    "failed_to_check_for_updates": MessageLookupByLibrary.simpleMessage(
      "检查更新失败",
    ),
    "failed_to_create_directory": MessageLookupByLibrary.simpleMessage(
      "创建目录失败",
    ),
    "failed_to_delete_file": m31,
    "fake_batch_inference_benchmark": MessageLookupByLibrary.simpleMessage(
      "并行推理 UI Benchmark",
    ),
    "feedback": MessageLookupByLibrary.simpleMessage("反馈问题"),
    "file_already_exists": MessageLookupByLibrary.simpleMessage("文件已存在"),
    "file_not_found": MessageLookupByLibrary.simpleMessage("文件未找到"),
    "file_not_supported": MessageLookupByLibrary.simpleMessage(
      "当前文件尚未支持，请检查文件名是否正确",
    ),
    "file_path_not_found": MessageLookupByLibrary.simpleMessage("文件路径未找到"),
    "files": MessageLookupByLibrary.simpleMessage("个文件"),
    "files_moved_with_failures": m32,
    "filter": MessageLookupByLibrary.simpleMessage(
      "你好，这个问题我暂时无法回答，让我们换个话题再聊聊吧。",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("录音完成"),
    "folder_already_added": MessageLookupByLibrary.simpleMessage("该文件夹已添加"),
    "folder_not_accessible_check_permission":
        MessageLookupByLibrary.simpleMessage("该文件夹无法访问，请检查文件夹权限"),
    "folder_not_found_on_device": MessageLookupByLibrary.simpleMessage(
      "未在您的电脑上发现该文件夹",
    ),
    "follow_system": MessageLookupByLibrary.simpleMessage("跟随系统"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "在 Twitter 上关注我们",
    ),
    "font_preview_markdown_asset": MessageLookupByLibrary.simpleMessage(
      "assets/lib/font_preview/font_preview_zh_Hans.md",
    ),
    "font_preview_user_message": MessageLookupByLibrary.simpleMessage(
      "Hello! 你好！这是用户消息的预览。\n第二行会跟着你调节的行距一起变化。",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("字体设置"),
    "font_size": MessageLookupByLibrary.simpleMessage("字体大小"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("默认 (100%)"),
    "font_size_follow_system": MessageLookupByLibrary.simpleMessage("字体大小跟随系统"),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage("强制使用深色模式"),
    "forget_location_success": MessageLookupByLibrary.simpleMessage("忘记该位置成功"),
    "forget_this_location": MessageLookupByLibrary.simpleMessage("忘记该位置"),
    "found_new_version_available": MessageLookupByLibrary.simpleMessage(
      "发现新版本可用",
    ),
    "frequency_penalty_with_value": m33,
    "from_model": MessageLookupByLibrary.simpleMessage("来自模型: %s"),
    "gallery": MessageLookupByLibrary.simpleMessage("相册"),
    "game_over": MessageLookupByLibrary.simpleMessage("游戏结束！"),
    "generate": MessageLookupByLibrary.simpleMessage("生成"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("生成世界上最难的数独"),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "生成随机数独",
    ),
    "generated_questions": MessageLookupByLibrary.simpleMessage("生成的问题"),
    "generating": MessageLookupByLibrary.simpleMessage("生成中..."),
    "github_repository": MessageLookupByLibrary.simpleMessage("Github 仓库"),
    "go_to_home_page": MessageLookupByLibrary.simpleMessage("前往首页"),
    "go_to_settings": MessageLookupByLibrary.simpleMessage("去设置"),
    "got_it": MessageLookupByLibrary.simpleMessage("我知道了"),
    "hello_ask_me_anything": MessageLookupByLibrary.simpleMessage(
      "Hello, 请随意 \n向我提问...",
    ),
    "hide_stack": MessageLookupByLibrary.simpleMessage("隐藏思维链堆栈"),
    "hide_translations": MessageLookupByLibrary.simpleMessage("隐藏翻译"),
    "hint_chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "默认使用 \'<think>好的\', 在 2025-09-21 前发布的模型中, 会自动使用 \'<think>嗯\'",
    ),
    "hint_system_prompt": MessageLookupByLibrary.simpleMessage(
      "例子: System: 你是秦始皇，使用文言文，以居高临下的态度与人沟通.",
    ),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "按住录音，松开发送",
    ),
    "home": MessageLookupByLibrary.simpleMessage("主页"),
    "http_service_port": m34,
    "human": MessageLookupByLibrary.simpleMessage("人类"),
    "hyphen": MessageLookupByLibrary.simpleMessage("-"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage("我想让 RWKV 说..."),
    "idle": MessageLookupByLibrary.simpleMessage("空闲"),
    "imitate": m35,
    "imitate_fle": m36,
    "imitate_target": MessageLookupByLibrary.simpleMessage("使用"),
    "import_all_weight_files": MessageLookupByLibrary.simpleMessage("导入全部权重文件"),
    "import_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "选择从此应用导出的 ZIP 文件。ZIP 文件中的所有权重文件将被导入。如果文件名相同，现有文件将被覆盖。",
    ),
    "import_all_weight_files_success": m37,
    "import_failed": MessageLookupByLibrary.simpleMessage("导入失败"),
    "import_success": MessageLookupByLibrary.simpleMessage("导入成功"),
    "import_weight_file": MessageLookupByLibrary.simpleMessage("导入权重文件"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage("当搜索深度和宽度都大于 2 时，将激活上下文搜索"),
    "inference_engine": MessageLookupByLibrary.simpleMessage("推理引擎"),
    "inference_engine_version": m38,
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
    "invalid_zip_file": MessageLookupByLibrary.simpleMessage(
      "无效的 ZIP 文件或文件格式无法识别",
    ),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("轮到你了~"),
    "japanese": MessageLookupByLibrary.simpleMessage("日本語"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "加入我们的 Discord 服务器",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage("加入社区"),
    "just_watch_me": MessageLookupByLibrary.simpleMessage("😎 看我表演！"),
    "korean": MessageLookupByLibrary.simpleMessage("한국어"),
    "lambada_test": MessageLookupByLibrary.simpleMessage("LAMBADA 测试"),
    "lan_server": MessageLookupByLibrary.simpleMessage("局域网服务器"),
    "large": MessageLookupByLibrary.simpleMessage("大 (120%)"),
    "latest_version": MessageLookupByLibrary.simpleMessage("最新版本"),
    "lazy": MessageLookupByLibrary.simpleMessage("懒"),
    "lazy_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "懒思考模板",
    ),
    "less_than_01_gb": MessageLookupByLibrary.simpleMessage("小于 0.01 GB"),
    "license": MessageLookupByLibrary.simpleMessage("开源许可证"),
    "life_span": MessageLookupByLibrary.simpleMessage("Life Span"),
    "light_mode": MessageLookupByLibrary.simpleMessage("浅色模式"),
    "line_break_rendered": MessageLookupByLibrary.simpleMessage("已渲染换行"),
    "line_break_symbol_settings": MessageLookupByLibrary.simpleMessage("换行符设置"),
    "load_": MessageLookupByLibrary.simpleMessage("加载"),
    "load_data": MessageLookupByLibrary.simpleMessage("加载数据"),
    "loaded": MessageLookupByLibrary.simpleMessage("已加载"),
    "loading": MessageLookupByLibrary.simpleMessage("加载中..."),
    "loading_progress_percent": m39,
    "local_folder_name": m40,
    "local_pth_files_section_title": MessageLookupByLibrary.simpleMessage(
      "本地模型文件",
    ),
    "local_pth_option_files_in_config": MessageLookupByLibrary.simpleMessage(
      "配置文件中的权重",
    ),
    "local_pth_option_local_pth_files": MessageLookupByLibrary.simpleMessage(
      "本地模型文件",
    ),
    "local_pth_you_can_select": MessageLookupByLibrary.simpleMessage(
      "你可以选择本地 .pth 文件或 RWKV .gguf 文件进行加载",
    ),
    "medium": MessageLookupByLibrary.simpleMessage("中 (110%)"),
    "memory_used": m41,
    "message_content": MessageLookupByLibrary.simpleMessage("消息内容"),
    "message_in_queue": m42,
    "message_line_height": MessageLookupByLibrary.simpleMessage("消息行距"),
    "message_line_height_default_hint": MessageLookupByLibrary.simpleMessage(
      "默认会使用字体和渲染器本身的行高，不是固定 1.0x。这里的自定义范围是 1.0x 到 2.0x。",
    ),
    "message_token_count": MessageLookupByLibrary.simpleMessage(
      "单条消息 Token 数量",
    ),
    "mimic": MessageLookupByLibrary.simpleMessage("模仿"),
    "mlx_cache": MessageLookupByLibrary.simpleMessage("MLX/CoreML 缓存"),
    "mlx_cache_notice": MessageLookupByLibrary.simpleMessage(
      "删除 MLX/CoreML 缓存可释放磁盘空间，但下次加载对应的 MLX/CoreML 模型会更慢。",
    ),
    "mode": MessageLookupByLibrary.simpleMessage("模式"),
    "model": MessageLookupByLibrary.simpleMessage("模型"),
    "model_item_ios18_weight_hint": MessageLookupByLibrary.simpleMessage(
      "升级 iOS 18+ 可使用这款权重，更快更省电",
    ),
    "model_loading": MessageLookupByLibrary.simpleMessage("模型加载中..."),
    "model_output": m43,
    "model_settings": MessageLookupByLibrary.simpleMessage("模型设置"),
    "model_size_increased_please_open_a_new_conversation":
        MessageLookupByLibrary.simpleMessage("模型大小增加，请打开一个新的对话, 以提升对话质量"),
    "monospace_font_setting": MessageLookupByLibrary.simpleMessage("等宽字体设置"),
    "more": MessageLookupByLibrary.simpleMessage("更多"),
    "more_questions": MessageLookupByLibrary.simpleMessage("更多问题"),
    "moving_files": MessageLookupByLibrary.simpleMessage("正在移动文件..."),
    "multi_question_continue": MessageLookupByLibrary.simpleMessage("继续对话"),
    "multi_question_entry_detail": MessageLookupByLibrary.simpleMessage(
      "同时提问多个问题，并行获取回答",
    ),
    "multi_question_input_hint": MessageLookupByLibrary.simpleMessage(
      "输入你的问题...",
    ),
    "multi_question_no_answer": MessageLookupByLibrary.simpleMessage("暂无回答"),
    "multi_question_send_all": MessageLookupByLibrary.simpleMessage("全部发送"),
    "multi_question_title": MessageLookupByLibrary.simpleMessage("多问题并行"),
    "multi_thread": MessageLookupByLibrary.simpleMessage("多线程"),
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
    "new_version_available": MessageLookupByLibrary.simpleMessage("新版本可用"),
    "new_version_found": MessageLookupByLibrary.simpleMessage("发现新版本"),
    "no_audio_file": MessageLookupByLibrary.simpleMessage("没有音频文件"),
    "no_browser_windows_connected": MessageLookupByLibrary.simpleMessage(
      "没有连接的浏览器窗口",
    ),
    "no_cell_available": MessageLookupByLibrary.simpleMessage("无子可下"),
    "no_conversation_yet": MessageLookupByLibrary.simpleMessage("目前还没有对话"),
    "no_conversations_yet": MessageLookupByLibrary.simpleMessage("暂时还没有任何对话"),
    "no_data": MessageLookupByLibrary.simpleMessage("无数据"),
    "no_files_in_zip": MessageLookupByLibrary.simpleMessage(
      "ZIP 文件中未找到有效的权重文件",
    ),
    "no_latest_version_info": MessageLookupByLibrary.simpleMessage("没有最新版本信息"),
    "no_local_folders": MessageLookupByLibrary.simpleMessage(
      "你还没有添加包含模型文件的本地文件夹",
    ),
    "no_local_pth_loaded_yet": MessageLookupByLibrary.simpleMessage(
      "暂无已加载的本地模型文件",
    ),
    "no_message_to_export": MessageLookupByLibrary.simpleMessage("没有消息可导出"),
    "no_model_selected": MessageLookupByLibrary.simpleMessage("未选择模型"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("没有数独"),
    "no_weight_files_guide_message": MessageLookupByLibrary.simpleMessage(
      "您还没有下载任何权重文件。前往首页下载并体验应用。",
    ),
    "no_weight_files_guide_title": MessageLookupByLibrary.simpleMessage(
      "暂无权重文件",
    ),
    "no_weight_files_to_export": MessageLookupByLibrary.simpleMessage(
      "没有可导出的权重文件",
    ),
    "not_all_the_same": MessageLookupByLibrary.simpleMessage("不完全相同"),
    "not_syncing": MessageLookupByLibrary.simpleMessage("未同步"),
    "npu_not_supported_title": m44,
    "npu_recommendation_divider": MessageLookupByLibrary.simpleMessage(
      "推荐选择上方 NPU 模型",
    ),
    "number": MessageLookupByLibrary.simpleMessage("数字"),
    "nyan_nyan": MessageLookupByLibrary.simpleMessage("Nyan~~,Nyan~~"),
    "ocr_guide_text": m45,
    "ocr_title": MessageLookupByLibrary.simpleMessage("OCR"),
    "off": MessageLookupByLibrary.simpleMessage("关闭"),
    "offline_translator": MessageLookupByLibrary.simpleMessage("离线翻译"),
    "offline_translator_detail": MessageLookupByLibrary.simpleMessage("离线翻译文本"),
    "offline_translator_server": MessageLookupByLibrary.simpleMessage(
      "离线翻译服务器",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("确定"),
    "open_containing_folder": MessageLookupByLibrary.simpleMessage("打开所在文件夹"),
    "open_database_folder": MessageLookupByLibrary.simpleMessage("打开数据库文件夹"),
    "open_debug_log_panel": MessageLookupByLibrary.simpleMessage("打开调试日志面板"),
    "open_folder": MessageLookupByLibrary.simpleMessage("打开文件夹"),
    "open_folder_create_failed": m46,
    "open_folder_created_success": MessageLookupByLibrary.simpleMessage(
      "空文件夹创建成功。",
    ),
    "open_folder_creating_empty": MessageLookupByLibrary.simpleMessage(
      "文件夹不存在，正在创建空文件夹。",
    ),
    "open_folder_path_is_null": MessageLookupByLibrary.simpleMessage(
      "文件夹路径为空。",
    ),
    "open_folder_unsupported_on_platform": m47,
    "open_official_download_page": MessageLookupByLibrary.simpleMessage(
      "打开官方下载页",
    ),
    "open_state_panel": MessageLookupByLibrary.simpleMessage("打开状态面板"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("或者选择一个 wav 文件，让 RWKV 模仿它。"),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "或开始一个空白聊天",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "other_files": MessageLookupByLibrary.simpleMessage(
      "其他文件 (这些文件可能是已经过期或不再支持的权重 RWKV Chat 无需再使用它们)",
    ),
    "other_settings": MessageLookupByLibrary.simpleMessage("其他设置"),
    "output": MessageLookupByLibrary.simpleMessage("输出"),
    "overseas": MessageLookupByLibrary.simpleMessage("(境外)"),
    "overwrite": MessageLookupByLibrary.simpleMessage("覆盖"),
    "overwrite_file_confirmation": MessageLookupByLibrary.simpleMessage(
      "文件已存在，是否要覆盖？",
    ),
    "parameter_description": MessageLookupByLibrary.simpleMessage("参数说明"),
    "parameter_description_detail": MessageLookupByLibrary.simpleMessage(
      "Temperature: 控制输出的随机性。较高的值（如 0.8）使输出更具创意和随机性；较低的值（如 0.2）使输出更集中和确定。\n\nTop P: 控制输出的多样性。模型仅考虑累积概率达到 Top P 的 token。较低的值（如 0.5）会忽略低概率的词，使输出更相关。\n\nPresence Penalty: 根据 token 是否已在文本中出现来惩罚它们。正值会增加模型谈论新主题的可能性。\n\nFrequency Penalty: 根据 token 在文本中出现的频率来惩罚它们。正值会减少模型逐字重复同一行的可能性。\n\nPenalty Decay: 控制惩罚随距离的衰减程度。",
    ),
    "path_label": m48,
    "pause": MessageLookupByLibrary.simpleMessage("暂停"),
    "paused_reply_edit_hint": MessageLookupByLibrary.simpleMessage(
      "回答已暂停。如果刚才的问题需要调整，修改原问题后重新生成会更准确。",
    ),
    "paused_reply_guidance_feature": MessageLookupByLibrary.simpleMessage(
      "暂停回答后的提问修正提示",
    ),
    "paused_reply_guidance_feature_description":
        MessageLookupByLibrary.simpleMessage("回答暂停后，提示修改原问题并重新生成。"),
    "penalty_decay_with_value": m49,
    "performance_test": MessageLookupByLibrary.simpleMessage("性能测试"),
    "performance_test_description": MessageLookupByLibrary.simpleMessage(
      "测试速度和准确率",
    ),
    "perplexity": MessageLookupByLibrary.simpleMessage("困惑度"),
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
    "please_enter_text_to_generate_tts": MessageLookupByLibrary.simpleMessage(
      "请输入文本以生成语音",
    ),
    "please_enter_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "请输入难度",
    ),
    "please_entry_some_text_to_continue": MessageLookupByLibrary.simpleMessage(
      "请先输入要续写的段落",
    ),
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage("请授予使用麦克风的权限"),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage("请先加载模型"),
    "please_manually_migrate_files": MessageLookupByLibrary.simpleMessage(
      "路径已更新，如需迁移文件请手动选择并移动。",
    ),
    "please_select_a_branch_to_continue_the_conversation":
        MessageLookupByLibrary.simpleMessage("请选择你喜欢的分支以进行接下来的对话"),
    "please_select_a_spk_or_a_wav_file": MessageLookupByLibrary.simpleMessage(
      "请选择一个预设声音或录制您的声音",
    ),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "请选择任务类型",
    ),
    "please_select_an_image_first": MessageLookupByLibrary.simpleMessage(
      "请先选择一个图片",
    ),
    "please_select_an_image_from_the_following_options":
        MessageLookupByLibrary.simpleMessage("请从以下选项中选择一个图片"),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "请选择应用语言",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage("请选择字体大小"),
    "please_select_model": MessageLookupByLibrary.simpleMessage("请选择模型"),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "请选择难度",
    ),
    "please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index":
        m50,
    "please_select_the_sampler_and_penalty_parameters_to_set_for_all_messages":
        MessageLookupByLibrary.simpleMessage("请选择要为所有消息设置的采样和惩罚参数"),
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
    "prebuilt": MessageLookupByLibrary.simpleMessage("预设"),
    "prebuilt_models_intro": MessageLookupByLibrary.simpleMessage(
      "以下是 RWKV Chat 预先量化好的模型",
    ),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("预设声音"),
    "prefer": MessageLookupByLibrary.simpleMessage("使用"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("使用中文推理"),
    "prefill": MessageLookupByLibrary.simpleMessage("预填充"),
    "prefill_progress_percent": m51,
    "prefill_speed_tokens_per_second": MessageLookupByLibrary.simpleMessage(
      "预填充速度（tokens 每秒）",
    ),
    "prefix_bank": MessageLookupByLibrary.simpleMessage("前缀组"),
    "prefix_examples": MessageLookupByLibrary.simpleMessage("前缀示例"),
    "presence_penalty_with_value": m52,
    "preview": MessageLookupByLibrary.simpleMessage("预览"),
    "processing_image": MessageLookupByLibrary.simpleMessage("正在处理图片..."),
    "prompt": MessageLookupByLibrary.simpleMessage("提示词"),
    "prompt_template": MessageLookupByLibrary.simpleMessage("Prompt 模板"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQ 群 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQ 群 2"),
    "quantization": MessageLookupByLibrary.simpleMessage("量化"),
    "question": MessageLookupByLibrary.simpleMessage("问题"),
    "question_generator": MessageLookupByLibrary.simpleMessage("RWKV 帮你问"),
    "question_generator_context_prefix_input_placeholder":
        MessageLookupByLibrary.simpleMessage("如果留空，RWKV 会根据上下文生成问题"),
    "question_generator_count": MessageLookupByLibrary.simpleMessage("生成数量"),
    "question_generator_empty_chat_batch_hint":
        MessageLookupByLibrary.simpleMessage(
          "选好上面的问题开头后，点一下生成，RWKV 会先帮你想几个可以直接提问的问题。",
        ),
    "question_generator_empty_chat_hint": MessageLookupByLibrary.simpleMessage(
      "选好上面的问题开头后，点一下生成，RWKV 会先帮你想一个可以直接提问的问题。",
    ),
    "question_generator_language_switched_hint":
        MessageLookupByLibrary.simpleMessage(
          "切换语言后，上面可选的问题开头也会一起变化。挑一个顺手的开头，再让 RWKV 接着往下想就好。",
        ),
    "question_generator_mock_batch_description":
        MessageLookupByLibrary.simpleMessage("一时想不到怎么问？让 RWKV 多帮你想几个问题吧。"),
    "question_generator_mock_description": MessageLookupByLibrary.simpleMessage(
      "不知道怎么开口更合适？让 RWKV 先帮你想一个吧。",
    ),
    "question_generator_prefix_guide": MessageLookupByLibrary.simpleMessage(
      "点一点不同的问题开头，RWKV 会顺着这个开头继续帮你生成问题。你也可以直接改下面的输入框，写一个更符合你想法的开头。",
    ),
    "question_generator_prefix_input_placeholder":
        MessageLookupByLibrary.simpleMessage("在这里写下你想要的问题开头..."),
    "question_generator_prefix_required": MessageLookupByLibrary.simpleMessage(
      "请先输入一个问题前缀",
    ),
    "question_generator_prefixes": MessageLookupByLibrary.simpleMessage("问题前缀"),
    "question_generator_question_action_guide":
        MessageLookupByLibrary.simpleMessage("点击已生成的问题，即可粘贴到对话输入框。"),
    "question_generator_tap_generate_hint": m53,
    "question_language": MessageLookupByLibrary.simpleMessage(
      "我想让 RWKV 以这种语言提问...",
    ),
    "queued_x": m54,
    "quick_thinking": MessageLookupByLibrary.simpleMessage("快思考"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage("快思考已经开启"),
    "reached_bottom": MessageLookupByLibrary.simpleMessage("敬请期待"),
    "real_time_update": MessageLookupByLibrary.simpleMessage("实时更新"),
    "reason": MessageLookupByLibrary.simpleMessage("推理"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("推理模式"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("正在录音..."),
    "reference_source": MessageLookupByLibrary.simpleMessage("参考源"),
    "refresh": MessageLookupByLibrary.simpleMessage("刷新"),
    "refresh_complete": MessageLookupByLibrary.simpleMessage("刷新完成"),
    "refreshed": MessageLookupByLibrary.simpleMessage("已刷新"),
    "regenerate": MessageLookupByLibrary.simpleMessage("重新生成"),
    "remaining": MessageLookupByLibrary.simpleMessage("剩余时间："),
    "rename": MessageLookupByLibrary.simpleMessage("重命名"),
    "render_newline_directly": MessageLookupByLibrary.simpleMessage("直接渲染换行"),
    "render_space_symbol": MessageLookupByLibrary.simpleMessage("渲染空格符号"),
    "report_an_issue_on_github": MessageLookupByLibrary.simpleMessage(
      "在 Github 上报告问题",
    ),
    "reselect_model": MessageLookupByLibrary.simpleMessage("重新选择模型"),
    "reset": MessageLookupByLibrary.simpleMessage("重置"),
    "reset_to_default": MessageLookupByLibrary.simpleMessage("恢复默认"),
    "reset_to_default_directory": MessageLookupByLibrary.simpleMessage(
      "已恢复默认目录",
    ),
    "response_style": MessageLookupByLibrary.simpleMessage("回答方式"),
    "response_style_auto_switched_to_jin": MessageLookupByLibrary.simpleMessage(
      "已自动切换为「今」风格",
    ),
    "response_style_batch_not_supported": m55,
    "response_style_button": MessageLookupByLibrary.simpleMessage("风格"),
    "response_style_keep_one": MessageLookupByLibrary.simpleMessage(
      "至少保留一种表达风格",
    ),
    "response_style_many": MessageLookupByLibrary.simpleMessage("多种风格"),
    "response_style_random_questions": m56,
    "response_style_random_questions_not_enough": m57,
    "response_style_route_en": MessageLookupByLibrary.simpleMessage("英文回答"),
    "response_style_route_en_detail": MessageLookupByLibrary.simpleMessage(
      "最终回答仅使用英文",
    ),
    "response_style_route_gu": MessageLookupByLibrary.simpleMessage("古"),
    "response_style_route_gu_detail": MessageLookupByLibrary.simpleMessage(
      "使用文言文回答",
    ),
    "response_style_route_ja_detail": MessageLookupByLibrary.simpleMessage(
      "用日语直接回答",
    ),
    "response_style_route_jin": MessageLookupByLibrary.simpleMessage("今"),
    "response_style_route_jin_detail": MessageLookupByLibrary.simpleMessage(
      "自然、直接",
    ),
    "response_style_route_mao": MessageLookupByLibrary.simpleMessage("猫"),
    "response_style_route_mao_detail": MessageLookupByLibrary.simpleMessage(
      "模仿猫猫的预期回答",
    ),
    "response_style_route_yue_detail": MessageLookupByLibrary.simpleMessage(
      "使用粤语回答",
    ),
    "restore_default": MessageLookupByLibrary.simpleMessage("恢复默认"),
    "result": MessageLookupByLibrary.simpleMessage("结果"),
    "resume": MessageLookupByLibrary.simpleMessage("恢复"),
    "role_play": MessageLookupByLibrary.simpleMessage("角色扮演"),
    "role_play_intro": MessageLookupByLibrary.simpleMessage("扮演你喜欢的角色"),
    "runtime_log_panel": MessageLookupByLibrary.simpleMessage("运行日志面板"),
    "russian": MessageLookupByLibrary.simpleMessage("Русский"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV 聊天"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV 黑白棋"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("扫描二维码"),
    "scanning_folder_for_pth": MessageLookupByLibrary.simpleMessage(
      "正在扫描该文件夹中的 .pth 文件和 RWKV .gguf 文件",
    ),
    "screen_orientation": MessageLookupByLibrary.simpleMessage("屏幕方向"),
    "screen_rotation": MessageLookupByLibrary.simpleMessage("屏幕旋转"),
    "screen_rotation_subtitle": MessageLookupByLibrary.simpleMessage(
      "允许竖屏和横屏布局",
    ),
    "screen_width": MessageLookupByLibrary.simpleMessage("屏幕宽度"),
    "search": MessageLookupByLibrary.simpleMessage("搜索"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("搜索宽度"),
    "search_depth": MessageLookupByLibrary.simpleMessage("搜索深度"),
    "search_failed": MessageLookupByLibrary.simpleMessage("搜索失败"),
    "searching": MessageLookupByLibrary.simpleMessage("搜索中..."),
    "see": MessageLookupByLibrary.simpleMessage("图像问答"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("选择模型"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("选择任务类型"),
    "select_all": MessageLookupByLibrary.simpleMessage("全选"),
    "select_from_file": MessageLookupByLibrary.simpleMessage("选择图片文件"),
    "select_from_library": MessageLookupByLibrary.simpleMessage("从相册选择"),
    "select_image": MessageLookupByLibrary.simpleMessage("选择图片"),
    "select_local_pth_file_button": MessageLookupByLibrary.simpleMessage(
      "选择本地模型文件",
    ),
    "select_model": MessageLookupByLibrary.simpleMessage("选择模型"),
    "select_new_image": MessageLookupByLibrary.simpleMessage("选择图片"),
    "select_the_decode_parameters_to_set_all_to_for_index":
        MessageLookupByLibrary.simpleMessage("请从下方选择预设参数，或点击“自定义”进行手动配置"),
    "select_weights_or_local_pth_hint": MessageLookupByLibrary.simpleMessage(
      "选择配置文件中的权重或者本地模型文件",
    ),
    "selected_count": m58,
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage("发送消息给 RWKV"),
    "server_error": MessageLookupByLibrary.simpleMessage("服务器错误"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("会话配置"),
    "set_all_batch_params": MessageLookupByLibrary.simpleMessage("设置全部批量参数"),
    "set_all_to_question_mark": MessageLookupByLibrary.simpleMessage(
      "全部设置为 ???",
    ),
    "set_custom_directory": MessageLookupByLibrary.simpleMessage("设置自定义目录"),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("设置网格值"),
    "settings": MessageLookupByLibrary.simpleMessage("设置"),
    "share": MessageLookupByLibrary.simpleMessage("分享"),
    "share_chat": MessageLookupByLibrary.simpleMessage("分享聊天"),
    "show_prefill_log_only": MessageLookupByLibrary.simpleMessage(
      "仅显示 Prefill 日志",
    ),
    "show_stack": MessageLookupByLibrary.simpleMessage("显示思维链堆栈"),
    "show_translations": MessageLookupByLibrary.simpleMessage("显示翻译"),
    "single_thread": MessageLookupByLibrary.simpleMessage("单线程"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "推荐至少选择 1.5B 模型，效果更好",
    ),
    "skip_this_version": MessageLookupByLibrary.simpleMessage("跳过此版本"),
    "small": MessageLookupByLibrary.simpleMessage("小 (90%)"),
    "source_code": MessageLookupByLibrary.simpleMessage("源代码"),
    "source_text": m59,
    "space_rendered": MessageLookupByLibrary.simpleMessage("已渲染空格"),
    "space_symbol_settings": MessageLookupByLibrary.simpleMessage("空格符设置"),
    "space_symbol_style": MessageLookupByLibrary.simpleMessage("空格符样式"),
    "space_symbols_rendered": MessageLookupByLibrary.simpleMessage("已渲染空格符号"),
    "speed": MessageLookupByLibrary.simpleMessage("下载速度："),
    "start": MessageLookupByLibrary.simpleMessage("开始"),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage("开始新聊天"),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage("点击下方按钮开始新聊天"),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("开始对局"),
    "start_download_updates_": MessageLookupByLibrary.simpleMessage(
      "开始后台下载更新...",
    ),
    "start_service": MessageLookupByLibrary.simpleMessage("启动服务"),
    "start_service_and_open_browser": MessageLookupByLibrary.simpleMessage(
      "启动服务并打开支持的浏览器页面。",
    ),
    "start_test": MessageLookupByLibrary.simpleMessage("开始测试"),
    "start_testing": MessageLookupByLibrary.simpleMessage("开始测试"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("开始聊天"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("开始推理"),
    "starting": MessageLookupByLibrary.simpleMessage("启动中..."),
    "state_list": MessageLookupByLibrary.simpleMessage("State 列表"),
    "state_panel": MessageLookupByLibrary.simpleMessage("状态面板"),
    "status": MessageLookupByLibrary.simpleMessage("状态"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "stop_service": MessageLookupByLibrary.simpleMessage("停止服务"),
    "stop_test": MessageLookupByLibrary.simpleMessage("停止测试"),
    "stopping": MessageLookupByLibrary.simpleMessage("停止中..."),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "存储权限未授予",
    ),
    "str_downloading_info": MessageLookupByLibrary.simpleMessage(
      "下载%.1f% 速度%.1fMB/s 剩余%s",
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
    "style": MessageLookupByLibrary.simpleMessage("风格"),
    "submit": MessageLookupByLibrary.simpleMessage("提交"),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("入门"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("专家"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("普通"),
    "suggest": MessageLookupByLibrary.simpleMessage("推荐"),
    "switch_to_creative_mode_for_better_exp":
        MessageLookupByLibrary.simpleMessage("解码参数建议选择 “创意”, 以便获得更好的体验"),
    "syncing": MessageLookupByLibrary.simpleMessage("同步中"),
    "system_mode": MessageLookupByLibrary.simpleMessage("跟随系统"),
    "system_prompt": MessageLookupByLibrary.simpleMessage("系统提示词"),
    "tag_date": MessageLookupByLibrary.simpleMessage("日期"),
    "tag_day_of_week": MessageLookupByLibrary.simpleMessage("星期"),
    "tag_time": MessageLookupByLibrary.simpleMessage("时间"),
    "take_photo": MessageLookupByLibrary.simpleMessage("拍照"),
    "target_text": m60,
    "technical_research_group": MessageLookupByLibrary.simpleMessage("技术研发群"),
    "temperature_with_value": m61,
    "test_data": MessageLookupByLibrary.simpleMessage("测试数据"),
    "test_result": MessageLookupByLibrary.simpleMessage("测试结果"),
    "test_results": MessageLookupByLibrary.simpleMessage("测试结果"),
    "testing": MessageLookupByLibrary.simpleMessage("测试中..."),
    "text": MessageLookupByLibrary.simpleMessage("文本"),
    "text_color": MessageLookupByLibrary.simpleMessage("文本颜色"),
    "text_completion_mode": MessageLookupByLibrary.simpleMessage("文本补全模式"),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage("数独无效"),
    "theme_dim": MessageLookupByLibrary.simpleMessage("深色"),
    "theme_light": MessageLookupByLibrary.simpleMessage("浅色"),
    "theme_lights_out": MessageLookupByLibrary.simpleMessage("黑色"),
    "then_you_can_start_to_chat_with_rwkv":
        MessageLookupByLibrary.simpleMessage("然后您就可以开始与 RWKV 对话了"),
    "think_button_mode_en": m62,
    "think_button_mode_en_long": m63,
    "think_button_mode_en_short": m64,
    "think_button_mode_fast": m65,
    "think_mode_selector_message": MessageLookupByLibrary.simpleMessage(
      "推理模式会影响模型在推理时的表现",
    ),
    "think_mode_selector_recommendation": MessageLookupByLibrary.simpleMessage(
      "推荐至少选择【推理-快】",
    ),
    "think_mode_selector_title": MessageLookupByLibrary.simpleMessage(
      "请选择推理模式",
    ),
    "thinking": MessageLookupByLibrary.simpleMessage("思考中..."),
    "thinking_mode_alert_footer": MessageLookupByLibrary.simpleMessage("模式"),
    "thinking_mode_auto": m66,
    "thinking_mode_button_auto": MessageLookupByLibrary.simpleMessage("中"),
    "thinking_mode_button_en": MessageLookupByLibrary.simpleMessage("英"),
    "thinking_mode_button_en_long": MessageLookupByLibrary.simpleMessage("英长"),
    "thinking_mode_button_en_short": MessageLookupByLibrary.simpleMessage("英短"),
    "thinking_mode_button_fast": MessageLookupByLibrary.simpleMessage("快"),
    "thinking_mode_button_high": MessageLookupByLibrary.simpleMessage("高"),
    "thinking_mode_button_off": MessageLookupByLibrary.simpleMessage("傻"),
    "thinking_mode_high": m67,
    "thinking_mode_off": m68,
    "thinking_mode_template": MessageLookupByLibrary.simpleMessage("思考模式模板"),
    "thinking_tag_preview": MessageLookupByLibrary.simpleMessage("压缩展示思考过程"),
    "thinking_tag_preview_subtitle": MessageLookupByLibrary.simpleMessage(
      "用 5 行预览框展示思考内容，可展开查看全部",
    ),
    "thinking_tag_rendering": MessageLookupByLibrary.simpleMessage("思考标签"),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("这是世界上最难的数独"),
    "this_model_does_not_support_batch_inference":
        MessageLookupByLibrary.simpleMessage("这个模型不支持并行推理, 请选择带有 batch 标签的模型"),
    "thought_result": MessageLookupByLibrary.simpleMessage("思考结果"),
    "top_p_with_value": m69,
    "total_count": MessageLookupByLibrary.simpleMessage("总数"),
    "total_disk_usage": MessageLookupByLibrary.simpleMessage("存储空间占用量"),
    "total_test_items": m70,
    "translate": MessageLookupByLibrary.simpleMessage("翻译"),
    "translating": MessageLookupByLibrary.simpleMessage("翻译中..."),
    "translation": MessageLookupByLibrary.simpleMessage("翻译结果"),
    "translator_debug_info": MessageLookupByLibrary.simpleMessage("翻译器调试信息"),
    "tts": MessageLookupByLibrary.simpleMessage("文本转语音"),
    "tts_detail": MessageLookupByLibrary.simpleMessage("让 RWKV 输出语音"),
    "tts_is_running_please_wait": MessageLookupByLibrary.simpleMessage(
      "TTS 正在运行，请等待其完成",
    ),
    "tts_voice_source_file_panel_hint": MessageLookupByLibrary.simpleMessage(
      "使用下方文件的声音来生成语音",
    ),
    "tts_voice_source_file_subtitle": MessageLookupByLibrary.simpleMessage(
      "选择一个 WAV 文件让 RWKV 模仿它",
    ),
    "tts_voice_source_file_title": MessageLookupByLibrary.simpleMessage("声音文件"),
    "tts_voice_source_my_voice_subtitle": MessageLookupByLibrary.simpleMessage(
      "录制我的声音，让 RWKV 模仿它",
    ),
    "tts_voice_source_my_voice_title": MessageLookupByLibrary.simpleMessage(
      "我的声音",
    ),
    "tts_voice_source_preset_subtitle": MessageLookupByLibrary.simpleMessage(
      "在 RWKV 内置的预设声音中选择",
    ),
    "tts_voice_source_preset_title": MessageLookupByLibrary.simpleMessage(
      "预设声音",
    ),
    "tts_voice_source_sheet_subtitle": MessageLookupByLibrary.simpleMessage(
      "在下列的不同方式中选择录入声音的方式",
    ),
    "tts_voice_source_sheet_title": MessageLookupByLibrary.simpleMessage(
      "选择 RWKV 要模仿的声音",
    ),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("落子权转移"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ui_font_setting": MessageLookupByLibrary.simpleMessage("UI 字体设置"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("超大 (140%)"),
    "unknown": MessageLookupByLibrary.simpleMessage("未知"),
    "unzipping": MessageLookupByLibrary.simpleMessage("解压中"),
    "update_now": MessageLookupByLibrary.simpleMessage("立即更新"),
    "updated_at": MessageLookupByLibrary.simpleMessage("更新时间"),
    "use_default_line_height": MessageLookupByLibrary.simpleMessage("使用默认行距"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("立即使用"),
    "user": MessageLookupByLibrary.simpleMessage("用户:"),
    "user_message_actions_panel_empty": MessageLookupByLibrary.simpleMessage(
      "当前消息暂无可用操作",
    ),
    "user_message_actions_panel_switch_branch_subtitle":
        MessageLookupByLibrary.simpleMessage("通过上一条 / 下一条切换相邻分支"),
    "user_message_actions_panel_switch_branch_title":
        MessageLookupByLibrary.simpleMessage("切换分支"),
    "user_message_actions_panel_title": MessageLookupByLibrary.simpleMessage(
      "消息操作",
    ),
    "user_message_branch_switched": MessageLookupByLibrary.simpleMessage(
      "已切换分支",
    ),
    "using_custom_directory": MessageLookupByLibrary.simpleMessage("正在使用自定义目录"),
    "using_default_directory": MessageLookupByLibrary.simpleMessage("正在使用默认目录"),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "值必须在 0 和 9 之间",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("非常小 (80%)"),
    "visual_understanding_and_ocr": MessageLookupByLibrary.simpleMessage(
      "视觉理解与 OCR",
    ),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("声音克隆"),
    "we_support_npu_socs": MessageLookupByLibrary.simpleMessage(
      "我们目前支持以下 SoC 芯片中的 NPU：",
    ),
    "web_demo_backend_local_albatross": MessageLookupByLibrary.simpleMessage(
      "本地 Albatross",
    ),
    "web_demo_backend_local_rwkv_mobile": MessageLookupByLibrary.simpleMessage(
      "本地 RWKV Mobile",
    ),
    "web_demo_backend_official_cloud": m71,
    "web_demo_cloud": MessageLookupByLibrary.simpleMessage("云端"),
    "web_demo_concurrency": MessageLookupByLibrary.simpleMessage("并发数"),
    "web_demo_continue_editing": MessageLookupByLibrary.simpleMessage("继续编辑"),
    "web_demo_copy_result": MessageLookupByLibrary.simpleMessage("复制结果"),
    "web_demo_count_penalty": MessageLookupByLibrary.simpleMessage("计数惩罚"),
    "web_demo_custom_prompt": MessageLookupByLibrary.simpleMessage("自定义提示词"),
    "web_demo_empty_description": MessageLookupByLibrary.simpleMessage(
      "暂无已生成页面。",
    ),
    "web_demo_empty_title": MessageLookupByLibrary.simpleMessage(
      "生成 HTML 网格来比较候选结果。",
    ),
    "web_demo_endpoint_key_missing": MessageLookupByLibrary.simpleMessage(
      "尚未配置官方 Web Demo 接口密钥",
    ),
    "web_demo_failed": m72,
    "web_demo_failed_to_open_html": MessageLookupByLibrary.simpleMessage(
      "打开 HTML 失败",
    ),
    "web_demo_generate_html_grid": MessageLookupByLibrary.simpleMessage(
      "生成 HTML 网格",
    ),
    "web_demo_html_attached": MessageLookupByLibrary.simpleMessage(
      "已将选中的 HTML 添加到下一次请求。",
    ),
    "web_demo_html_context_ready": MessageLookupByLibrary.simpleMessage(
      "HTML 上下文已就绪",
    ),
    "web_demo_html_saved": MessageLookupByLibrary.simpleMessage("HTML 已保存"),
    "web_demo_inline_preview_unavailable": MessageLookupByLibrary.simpleMessage(
      "当前平台无法使用内嵌预览。",
    ),
    "web_demo_max_tokens": MessageLookupByLibrary.simpleMessage("最大 Token 数"),
    "web_demo_no_html_found": MessageLookupByLibrary.simpleMessage("未找到 HTML"),
    "web_demo_no_key": MessageLookupByLibrary.simpleMessage("未配置密钥"),
    "web_demo_no_source_to_copy": MessageLookupByLibrary.simpleMessage(
      "没有可复制的源代码",
    ),
    "web_demo_open_in_browser": MessageLookupByLibrary.simpleMessage("在浏览器中打开"),
    "web_demo_pages_status": m73,
    "web_demo_penalty_decay": MessageLookupByLibrary.simpleMessage("惩罚衰减"),
    "web_demo_presence_penalty": MessageLookupByLibrary.simpleMessage("存在惩罚"),
    "web_demo_preset_animation": MessageLookupByLibrary.simpleMessage(
      "森林动物与汽车的 3D 动画",
    ),
    "web_demo_preset_dashboard": MessageLookupByLibrary.simpleMessage(
      "SaaS 仪表盘",
    ),
    "web_demo_preset_product": MessageLookupByLibrary.simpleMessage("产品页面"),
    "web_demo_preview_scale_percent": MessageLookupByLibrary.simpleMessage(
      "预览缩放 %",
    ),
    "web_demo_preview_scroll_seconds": MessageLookupByLibrary.simpleMessage(
      "预览滚动秒数",
    ),
    "web_demo_prompt_hint": MessageLookupByLibrary.simpleMessage("描述要生成的网页..."),
    "web_demo_response_missing_content": MessageLookupByLibrary.simpleMessage(
      "RWKV Lightning 响应中没有内容",
    ),
    "web_demo_result_copied": MessageLookupByLibrary.simpleMessage("结果已复制"),
    "web_demo_result_label": m74,
    "web_demo_save_html": MessageLookupByLibrary.simpleMessage("保存 HTML"),
    "web_demo_source_title": m75,
    "web_demo_status_complete": MessageLookupByLibrary.simpleMessage("已完成"),
    "web_demo_status_live": MessageLookupByLibrary.simpleMessage("实时"),
    "web_demo_status_parsing": MessageLookupByLibrary.simpleMessage("解析中"),
    "web_demo_status_waiting": MessageLookupByLibrary.simpleMessage("等待中"),
    "web_demo_temperature": MessageLookupByLibrary.simpleMessage("温度"),
    "web_demo_tokens_and_bytes": m76,
    "web_demo_top_p": MessageLookupByLibrary.simpleMessage("Top P"),
    "web_demo_view_source": MessageLookupByLibrary.simpleMessage("查看源代码"),
    "web_demo_waiting_for_first_tokens": MessageLookupByLibrary.simpleMessage(
      "正在等待首批 Token...",
    ),
    "web_demo_waiting_for_html_document": MessageLookupByLibrary.simpleMessage(
      "正在等待 HTML 文档",
    ),
    "web_search": MessageLookupByLibrary.simpleMessage("联网搜索"),
    "web_search_template": MessageLookupByLibrary.simpleMessage("联网搜索模板"),
    "websocket_service_port": m77,
    "weights_mangement": MessageLookupByLibrary.simpleMessage("权重文件管理"),
    "weights_saving_directory": MessageLookupByLibrary.simpleMessage(
      "权重文件保存目录",
    ),
    "welcome_to_rwkv_chat": MessageLookupByLibrary.simpleMessage(
      "欢迎探索 RWKV Chat",
    ),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage("欢迎使用 RWKV"),
    "what_is_pth_file_message": MessageLookupByLibrary.simpleMessage(
      "本地模型文件是直接从本地文件系统中加载的权重文件，不需要通过下载服务器下载。\n\nRWKV Chat 支持本地 .pth 文件和 RWKV GGUF 文件。其他模型家族的 GGUF 文件不会显示为可加载模型。",
    ),
    "what_is_pth_file_title": MessageLookupByLibrary.simpleMessage(
      "什么是本地模型文件？",
    ),
    "white": MessageLookupByLibrary.simpleMessage("白方"),
    "white_score": MessageLookupByLibrary.simpleMessage("白方得分"),
    "white_wins": MessageLookupByLibrary.simpleMessage("白方获胜！"),
    "window_id": m78,
    "windows_architecture_mismatch_dialog_message": m79,
    "windows_architecture_mismatch_dialog_title":
        MessageLookupByLibrary.simpleMessage("架构不匹配"),
    "windows_architecture_mismatch_warning": m80,
    "world": MessageLookupByLibrary.simpleMessage("See"),
    "x_message_selected": MessageLookupByLibrary.simpleMessage("已选 %d 条消息"),
    "x_pages_found": MessageLookupByLibrary.simpleMessage("已找到 %d 个相关网页"),
    "x_tabs": m81,
    "you_are_now_using": m82,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "现在可以开始与 RWKV 聊天了",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("您可以录制您的声音，然后让 RWKV 模仿它。"),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "您可以选择角色进行聊天",
    ),
    "your_device": MessageLookupByLibrary.simpleMessage("您的设备："),
    "your_voice_is_empty": MessageLookupByLibrary.simpleMessage(
      "您的声音数据为空，请检查您的麦克风",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "您的声音太短，请长按按钮更久以获取您的声音。",
    ),
    "zh_to_en": MessageLookupByLibrary.simpleMessage("中->英"),
  };
}
