// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(error) => "Error: ${error}";

  static String m1(error) => "Failed to start API Server: ${error}";

  static String m2(port) => "API Server started on port ${port}";

  static String m3(count) => "Batch × ${count}";

  static String m4(count) => "Each inference will generate ${count} messages";

  static String m5(count) => "Each inference will generate %d result";

  static String m6(count) => "Batch inference: ${count} outputs";

  static String m7(index) => "Selected output ${index}";

  static String m8(batch) => "Batch ${batch}";

  static String m9(first, last, count) =>
      "Batch ${first}-${last} (${count} runs)";

  static String m10(batch) => "Batch ${batch}";

  static String m11(count) => "Supported up to batch ${count}";

  static String m12(batch, current, total) =>
      "Batch ${batch} · ${current}/${total}";

  static String m13(current, total, speed) =>
      "${current}/${total} · ${speed} t/s";

  static String m14(speed) => "Peak Decode: ${speed} t/s";

  static String m15(progress, speed) => "${progress}% · ${speed} t/s";

  static String m16(prefillSpeed, decodeSpeed) =>
      "Prefill ${prefillSpeed} t/s · Decode ${decodeSpeed} t/s";

  static String m17(current, total, phase) => "${current}/${total} · ${phase}";

  static String m18(demoName) => "Welcome to ${demoName}";

  static String m19(maxLength) =>
      "Conversation name cannot be longer than ${maxLength} characters";

  static String m20(length) => "ctx ${length}";

  static String m21(modelName) => "Current Model: ${modelName}";

  static String m22(current, total) => "Current Progress: ${current}/${total}";

  static String m23(current, total) =>
      "Current Test Item (${current}/${total})";

  static String m24(path) =>
      "Message records will be stored in the following folder\n ${path}";

  static String m25(error) => "Failed to delete file: ${error}";

  static String m26(successCount, failCount) =>
      "${successCount} files moved, ${failCount} failed";

  static String m27(value) => "Frequency Penalty: ${value}";

  static String m28(port) => "HTTP Service (Port: ${port})";

  static String m29(flag, nameCN, nameEN) =>
      "Imitate ${flag} ${nameCN}(${nameEN})\'s voice";

  static String m30(fileName) => "Imitate ${fileName}";

  static String m31(count) => "Import successful: ${count} files imported";

  static String m32(percent) => "Loading ${percent}%";

  static String m33(folderName) => "Local folder: ${folderName}";

  static String m34(memUsed, memFree) =>
      "Memory Used: ${memUsed}, Memory Free: ${memFree}";

  static String m35(count) => "${count} messages are in queue";

  static String m36(text) => "Model output: ${text}";

  static String m37(socName) =>
      "NPU support for your chip ${socName} not yet available";

  static String m38(takePhoto) =>
      "Click ${takePhoto}. RWKV will translate the text in the image.";

  static String m39(error) => "Failed to create empty folder: ${error}";

  static String m40(os) =>
      "Opening folder is not supported on the current OS (${os}).";

  static String m41(path) => "Path: ${path}";

  static String m42(value) => "Penalty Decay: ${value}";

  static String m43(index) =>
      "Please select the sampler and penalty parameters to set for message ${index}";

  static String m44(percent) => "Prefill progress ${percent}";

  static String m45(value) => "Presence Penalty: ${value}";

  static String m46(count) =>
      "Tap Generate and let RWKV turn your chosen opening into up to ${count} question ideas.";

  static String m47(count) => "Queued: ${count}";

  static String m48(count) =>
      "This model does not support ${count} response styles";

  static String m49(count) => "Selected ${count}";

  static String m50(text) => "Source Text: ${text}";

  static String m51(text) => "Target Text: ${text}";

  static String m52(value) => "Temperature: ${value}";

  static String m53(footer) => "Reasoning${footer}-EN";

  static String m54(footer) => "Reasoning${footer}-EN Long";

  static String m55(footer) => "Reasoning${footer}-EN Short";

  static String m56(footer) => "Reasoning${footer}-Fast";

  static String m57(footer) => "Reasoning${footer}-Auto";

  static String m58(footer) => "Reasoning${footer}-High";

  static String m59(footer) => "Reasoning${footer}-Off";

  static String m60(value) => "Top P: ${value}";

  static String m61(count) => "Total Test Items: ${count}";

  static String m62(port) => "WebSocket Service (Port: ${port})";

  static String m63(id) => "Window ${id}";

  static String m64(buildArchitecture, operatingSystemArchitecture, url) =>
      "This app is built for ${buildArchitecture}, but your Windows operating system architecture is ${operatingSystemArchitecture}.\n\nPlease go to the official download page and download the matching executable:\n${url}";

  static String m65(buildArchitecture, operatingSystemArchitecture, url) =>
      "Architecture mismatch detected: this app is built for ${buildArchitecture}, but your Windows operating system architecture is ${operatingSystemArchitecture}. Please download the matching build from the official page: ${url}";

  static String m66(count) => "${count} tabs";

  static String m67(modelName) => "You are now using ${modelName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("According to: "),
    "accuracy": MessageLookupByLibrary.simpleMessage("Accuracy"),
    "adapting_more_inference_chips": MessageLookupByLibrary.simpleMessage(
      "We are continuously adapting more inference chips, please stay tuned.",
    ),
    "add_local_folder": MessageLookupByLibrary.simpleMessage(
      "Add local folder",
    ),
    "advance_settings": MessageLookupByLibrary.simpleMessage(
      "Advanced Settings",
    ),
    "all": MessageLookupByLibrary.simpleMessage("All"),
    "all_done": MessageLookupByLibrary.simpleMessage("All Done"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("All Prompts"),
    "all_the_same": MessageLookupByLibrary.simpleMessage("All the same"),
    "allow_background_downloads": MessageLookupByLibrary.simpleMessage(
      "Allow background downloads",
    ),
    "already_using_this_directory": MessageLookupByLibrary.simpleMessage(
      "Already using this directory",
    ),
    "analysing_result": MessageLookupByLibrary.simpleMessage(
      "Analysing Search Result",
    ),
    "api_server": MessageLookupByLibrary.simpleMessage("API Server"),
    "api_server_active_request_no": MessageLookupByLibrary.simpleMessage(
      "Active Request: No",
    ),
    "api_server_active_request_stopped": MessageLookupByLibrary.simpleMessage(
      "Stopped active request",
    ),
    "api_server_active_request_yes": MessageLookupByLibrary.simpleMessage(
      "Active Request: Yes",
    ),
    "api_server_android_foreground_hint": MessageLookupByLibrary.simpleMessage(
      "Keep the app in the foreground and connect the computer and phone to the same Wi-Fi.",
    ),
    "api_server_chat_empty_hint": MessageLookupByLibrary.simpleMessage(
      "Send a message to test the API",
    ),
    "api_server_chat_error": m0,
    "api_server_chat_input_hint": MessageLookupByLibrary.simpleMessage(
      "Type a message...",
    ),
    "api_server_chat_test": MessageLookupByLibrary.simpleMessage("Chat Test"),
    "api_server_curl_hint": MessageLookupByLibrary.simpleMessage(
      "Usage Example",
    ),
    "api_server_description": MessageLookupByLibrary.simpleMessage(
      "Start an OpenAI compatible local server",
    ),
    "api_server_docs": MessageLookupByLibrary.simpleMessage("API Docs"),
    "api_server_failed_to_start": m1,
    "api_server_logs": MessageLookupByLibrary.simpleMessage("Request Logs"),
    "api_server_no_active_request": MessageLookupByLibrary.simpleMessage(
      "No active request",
    ),
    "api_server_no_lan_address": MessageLookupByLibrary.simpleMessage(
      "No LAN address detected for computer access",
    ),
    "api_server_no_model": MessageLookupByLibrary.simpleMessage(
      "No model loaded",
    ),
    "api_server_open_dashboard": MessageLookupByLibrary.simpleMessage(
      "Open Dashboard",
    ),
    "api_server_port": MessageLookupByLibrary.simpleMessage("Port"),
    "api_server_request_count": MessageLookupByLibrary.simpleMessage(
      "Requests",
    ),
    "api_server_running": MessageLookupByLibrary.simpleMessage(
      "Server Running",
    ),
    "api_server_select_model_first": MessageLookupByLibrary.simpleMessage(
      "Please select a chat model first",
    ),
    "api_server_send": MessageLookupByLibrary.simpleMessage("Send"),
    "api_server_start": MessageLookupByLibrary.simpleMessage("Start Server"),
    "api_server_started_on_port": m2,
    "api_server_starting": MessageLookupByLibrary.simpleMessage(
      "Server Starting",
    ),
    "api_server_stop": MessageLookupByLibrary.simpleMessage("Stop Server"),
    "api_server_stopped": MessageLookupByLibrary.simpleMessage(
      "Server Stopped",
    ),
    "api_server_url": MessageLookupByLibrary.simpleMessage("Server URL"),
    "app_is_already_up_to_date": MessageLookupByLibrary.simpleMessage(
      "App is already up to date",
    ),
    "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "Application Internal Test Group",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage(
      "Application Language",
    ),
    "application_mode": MessageLookupByLibrary.simpleMessage(
      "Application Mode",
    ),
    "application_settings": MessageLookupByLibrary.simpleMessage(
      "Application Settings",
    ),
    "apply": MessageLookupByLibrary.simpleMessage("Apply"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage(
          "Are you sure you want to delete this model?",
        ),
    "ask": MessageLookupByLibrary.simpleMessage("Ask"),
    "ask_me_anything": MessageLookupByLibrary.simpleMessage(
      "Ask me anything...",
    ),
    "assistant": MessageLookupByLibrary.simpleMessage("RWKV:"),
    "auto": MessageLookupByLibrary.simpleMessage("Auto"),
    "auto_detect": MessageLookupByLibrary.simpleMessage("Auto Detect"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("Back to Chat"),
    "background_color": MessageLookupByLibrary.simpleMessage(
      "Background color",
    ),
    "balanced": MessageLookupByLibrary.simpleMessage("Balanced"),
    "batch_completion": MessageLookupByLibrary.simpleMessage(
      "Batch Completion",
    ),
    "batch_completion_settings": MessageLookupByLibrary.simpleMessage(
      "Batch Completion Settings",
    ),
    "batch_inference": MessageLookupByLibrary.simpleMessage("Batch Inference"),
    "batch_inference_button": m3,
    "batch_inference_count": MessageLookupByLibrary.simpleMessage(
      "Batch Inference Count",
    ),
    "batch_inference_count_detail": m4,
    "batch_inference_count_detail_2": m5,
    "batch_inference_detail": MessageLookupByLibrary.simpleMessage(
      "After enabling batch inference, RWKV can generate multiple answers at the same time",
    ),
    "batch_inference_enable_or_not": MessageLookupByLibrary.simpleMessage(
      "Enable or disable batch inference",
    ),
    "batch_inference_running": m6,
    "batch_inference_selected": m7,
    "batch_inference_settings": MessageLookupByLibrary.simpleMessage(
      "Batch Inference Settings",
    ),
    "batch_inference_short": MessageLookupByLibrary.simpleMessage("Batch"),
    "batch_inference_width": MessageLookupByLibrary.simpleMessage(
      "Message Display Width",
    ),
    "batch_inference_width_2": MessageLookupByLibrary.simpleMessage(
      "Result Display Width",
    ),
    "batch_inference_width_detail": MessageLookupByLibrary.simpleMessage(
      "Batch Inference Each Message Width",
    ),
    "batch_inference_width_detail_2": MessageLookupByLibrary.simpleMessage(
      "Width of Each Result",
    ),
    "beginner": MessageLookupByLibrary.simpleMessage("Beginner"),
    "below_are_your_local_folders": MessageLookupByLibrary.simpleMessage(
      "Below are your local folders",
    ),
    "benchmark": MessageLookupByLibrary.simpleMessage("Benchmark"),
    "benchmark_batch": m8,
    "benchmark_batch_not_supported_by_model":
        MessageLookupByLibrary.simpleMessage("Not supported by model"),
    "benchmark_batch_plan_range": m9,
    "benchmark_batch_plan_single": MessageLookupByLibrary.simpleMessage(
      "Batch 1",
    ),
    "benchmark_batch_result": m10,
    "benchmark_batch_supported_up_to": m11,
    "benchmark_batch_waiting_for_backend": MessageLookupByLibrary.simpleMessage(
      "Waiting for backend",
    ),
    "benchmark_best_bw": MessageLookupByLibrary.simpleMessage("Best BW"),
    "benchmark_best_decode": MessageLookupByLibrary.simpleMessage(
      "Best Decode",
    ),
    "benchmark_best_decode_per_batch": MessageLookupByLibrary.simpleMessage(
      "Best Decode / Batch",
    ),
    "benchmark_best_flops": MessageLookupByLibrary.simpleMessage("Best FLOPS"),
    "benchmark_current": MessageLookupByLibrary.simpleMessage("Current"),
    "benchmark_current_batch": m12,
    "benchmark_decode_per_batch": MessageLookupByLibrary.simpleMessage(
      "Decode / Batch",
    ),
    "benchmark_decode_progress_speed": m13,
    "benchmark_info_app_version": MessageLookupByLibrary.simpleMessage(
      "App Version",
    ),
    "benchmark_info_backend": MessageLookupByLibrary.simpleMessage("Backend"),
    "benchmark_info_build_mode": MessageLookupByLibrary.simpleMessage(
      "Build Mode",
    ),
    "benchmark_info_cpu_name": MessageLookupByLibrary.simpleMessage("CPU"),
    "benchmark_info_device_model": MessageLookupByLibrary.simpleMessage(
      "Device Model",
    ),
    "benchmark_info_file_size": MessageLookupByLibrary.simpleMessage(
      "File Size",
    ),
    "benchmark_info_gpu_name": MessageLookupByLibrary.simpleMessage("GPU"),
    "benchmark_info_os": MessageLookupByLibrary.simpleMessage("OS"),
    "benchmark_info_os_version": MessageLookupByLibrary.simpleMessage(
      "OS Version",
    ),
    "benchmark_info_soc_brand": MessageLookupByLibrary.simpleMessage(
      "SoC Brand",
    ),
    "benchmark_info_soc_name": MessageLookupByLibrary.simpleMessage("SoC Name"),
    "benchmark_info_total_memory": MessageLookupByLibrary.simpleMessage(
      "Total Memory",
    ),
    "benchmark_info_total_vram": MessageLookupByLibrary.simpleMessage(
      "Total VRAM",
    ),
    "benchmark_peak_decode": m14,
    "benchmark_plan": MessageLookupByLibrary.simpleMessage("Plan"),
    "benchmark_progress": MessageLookupByLibrary.simpleMessage(
      "Benchmark Progress",
    ),
    "benchmark_progress_speed": m15,
    "benchmark_result": MessageLookupByLibrary.simpleMessage(
      "Benchmark Result",
    ),
    "benchmark_result_speed_line": m16,
    "benchmark_run": MessageLookupByLibrary.simpleMessage("Run"),
    "benchmark_run_status": m17,
    "benchmark_support": MessageLookupByLibrary.simpleMessage("Support"),
    "benchmark_total_decode": MessageLookupByLibrary.simpleMessage(
      "Total Decode",
    ),
    "black": MessageLookupByLibrary.simpleMessage("Black"),
    "black_score": MessageLookupByLibrary.simpleMessage("Black Score"),
    "black_wins": MessageLookupByLibrary.simpleMessage("Black Wins!"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "Bot message edited, you can now send a new message",
    ),
    "branch_switcher_tooltip_first": MessageLookupByLibrary.simpleMessage(
      "Already the first message",
    ),
    "branch_switcher_tooltip_last": MessageLookupByLibrary.simpleMessage(
      "Already the last message",
    ),
    "branch_switcher_tooltip_next": MessageLookupByLibrary.simpleMessage(
      "Next message",
    ),
    "branch_switcher_tooltip_prev": MessageLookupByLibrary.simpleMessage(
      "Previous message",
    ),
    "browser_status": MessageLookupByLibrary.simpleMessage("Browser Status"),
    "cached_translations_disk": MessageLookupByLibrary.simpleMessage(
      "Cached translations (disk)",
    ),
    "cached_translations_memory": MessageLookupByLibrary.simpleMessage(
      "Cached translations (memory)",
    ),
    "camera": MessageLookupByLibrary.simpleMessage("Camera"),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("Cannot Generate"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancel_all_selection": MessageLookupByLibrary.simpleMessage(
      "Cancel All Selection",
    ),
    "cancel_download": MessageLookupByLibrary.simpleMessage("Cancel Download"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("Not now"),
    "change": MessageLookupByLibrary.simpleMessage("Change"),
    "change_selected_image": MessageLookupByLibrary.simpleMessage(
      "Change Image",
    ),
    "chat": MessageLookupByLibrary.simpleMessage("Chat"),
    "chat_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "Copied to clipboard",
    ),
    "chat_empty_message": MessageLookupByLibrary.simpleMessage(
      "Please enter a message",
    ),
    "chat_history": MessageLookupByLibrary.simpleMessage("Chat History"),
    "chat_mode": MessageLookupByLibrary.simpleMessage("Chat Mode"),
    "chat_model_name": MessageLookupByLibrary.simpleMessage("Model name"),
    "chat_please_select_a_model": MessageLookupByLibrary.simpleMessage(
      "Please select a model",
    ),
    "chat_resume": MessageLookupByLibrary.simpleMessage("Resume"),
    "chat_title": MessageLookupByLibrary.simpleMessage("RWKV Chat"),
    "chat_welcome_to_use": m18,
    "chat_with_rwkv_model": MessageLookupByLibrary.simpleMessage(
      "Chat with RWKV models",
    ),
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage(
          "You need to download the model first, before you can use it.",
        ),
    "chatting": MessageLookupByLibrary.simpleMessage("Chatting"),
    "check_for_updates": MessageLookupByLibrary.simpleMessage(
      "Check for updates",
    ),
    "chinese": MessageLookupByLibrary.simpleMessage("Chinese"),
    "chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "Chinese Thinking Mode Template",
    ),
    "chinese_translation_result": MessageLookupByLibrary.simpleMessage(
      "Chinese Translation Result",
    ),
    "chinese_web_search_template": MessageLookupByLibrary.simpleMessage(
      "Chinese Web Search Template",
    ),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage(
      "Choose prebuilt character",
    ),
    "clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "clear_memory_cache": MessageLookupByLibrary.simpleMessage(
      "Clear Memory Cache",
    ),
    "clear_text": MessageLookupByLibrary.simpleMessage("Clear text"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "Click here to select a new model",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "Click here to start a new chat",
    ),
    "click_plus_add_local_folder": MessageLookupByLibrary.simpleMessage(
      "Click + to add local folder. RWKV Chat will scan the folder for .pth files and list them as loadable weights",
    ),
    "click_plus_to_add_more_folders": MessageLookupByLibrary.simpleMessage(
      "Click + to add more local folders",
    ),
    "click_to_load_image": MessageLookupByLibrary.simpleMessage(
      "Click to load image",
    ),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage(
      "Click to select model",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Close"),
    "code_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "Code copied to clipboard",
    ),
    "colon": MessageLookupByLibrary.simpleMessage(": "),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "Follow system appearance",
    ),
    "completion": MessageLookupByLibrary.simpleMessage("Completion"),
    "completion_mode": MessageLookupByLibrary.simpleMessage("Completion Mode"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirm_delete_file_message": MessageLookupByLibrary.simpleMessage(
      "The file will be permanently deleted from your local disk",
    ),
    "confirm_delete_file_title": MessageLookupByLibrary.simpleMessage(
      "Delete this file?",
    ),
    "confirm_forget_location_message": MessageLookupByLibrary.simpleMessage(
      "After forgetting, this folder will no longer appear in the local folder list",
    ),
    "confirm_forget_location_title": MessageLookupByLibrary.simpleMessage(
      "Forget this location?",
    ),
    "continue2": MessageLookupByLibrary.simpleMessage("Continue"),
    "continue_download": MessageLookupByLibrary.simpleMessage(
      "Continue Download",
    ),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "Continue using smaller model",
    ),
    "conversation_management": MessageLookupByLibrary.simpleMessage(
      "Management",
    ),
    "conversation_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Conversation name cannot be empty",
    ),
    "conversation_name_cannot_be_longer_than_30_characters": m19,
    "conversation_token_count": MessageLookupByLibrary.simpleMessage(
      "Conversation Token Count",
    ),
    "conversation_token_limit_hint_short": MessageLookupByLibrary.simpleMessage(
      "Consider a new chat",
    ),
    "conversation_token_limit_recommend_new_chat":
        MessageLookupByLibrary.simpleMessage(
          "This conversation has exceeded 8,000 tokens. We recommend starting a new chat.",
        ),
    "conversations": MessageLookupByLibrary.simpleMessage("Conversations"),
    "copy_code": MessageLookupByLibrary.simpleMessage("Copy code"),
    "copy_text": MessageLookupByLibrary.simpleMessage("Copy text"),
    "correct_count": MessageLookupByLibrary.simpleMessage("Correct Count"),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage(
          "Create a new one by clicking the button above",
        ),
    "created_at": MessageLookupByLibrary.simpleMessage("Created at"),
    "creative_recommended": MessageLookupByLibrary.simpleMessage(
      "Creative (Recommended)",
    ),
    "creative_recommended_short": MessageLookupByLibrary.simpleMessage(
      "Creative",
    ),
    "ctx_length_label": m20,
    "current_folder_has_no_local_models": MessageLookupByLibrary.simpleMessage(
      "This folder has no local models",
    ),
    "current_model": m21,
    "current_model_from_latest_json_not_pth":
        MessageLookupByLibrary.simpleMessage(
          "The current model is from latest.json config, not a local .pth file",
        ),
    "current_progress": m22,
    "current_task_tab_id": MessageLookupByLibrary.simpleMessage(
      "Current task Tab ID",
    ),
    "current_task_text_length": MessageLookupByLibrary.simpleMessage(
      "Current task text length",
    ),
    "current_task_url": MessageLookupByLibrary.simpleMessage(
      "Current task URL",
    ),
    "current_test_item": m23,
    "current_turn": MessageLookupByLibrary.simpleMessage("Current Turn"),
    "current_version": MessageLookupByLibrary.simpleMessage("Current Version"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage(
      "Custom Difficulty",
    ),
    "custom_directory_set": MessageLookupByLibrary.simpleMessage(
      "Custom directory set",
    ),
    "dark_mode": MessageLookupByLibrary.simpleMessage("Dark Mode"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage("Dark Mode Theme"),
    "decode": MessageLookupByLibrary.simpleMessage("Decode"),
    "decode_param": MessageLookupByLibrary.simpleMessage("Decode Param"),
    "decode_param_comprehensive": MessageLookupByLibrary.simpleMessage(
      "Comprehensive (Worth a try)",
    ),
    "decode_param_comprehensive_short": MessageLookupByLibrary.simpleMessage(
      "Comprehensive",
    ),
    "decode_param_conservative": MessageLookupByLibrary.simpleMessage(
      "Conservative (Math & Code)",
    ),
    "decode_param_conservative_short": MessageLookupByLibrary.simpleMessage(
      "Conservative",
    ),
    "decode_param_creative": MessageLookupByLibrary.simpleMessage(
      "Creative (Writing, Less Repetitive)",
    ),
    "decode_param_creative_short": MessageLookupByLibrary.simpleMessage(
      "Creative",
    ),
    "decode_param_custom": MessageLookupByLibrary.simpleMessage(
      "Custom (Manual Setup)",
    ),
    "decode_param_custom_short": MessageLookupByLibrary.simpleMessage("Custom"),
    "decode_param_default_": MessageLookupByLibrary.simpleMessage(
      "Default (Default Params)",
    ),
    "decode_param_default_short": MessageLookupByLibrary.simpleMessage(
      "Default",
    ),
    "decode_param_fixed": MessageLookupByLibrary.simpleMessage(
      "Fixed (Most Conservative)",
    ),
    "decode_param_fixed_short": MessageLookupByLibrary.simpleMessage("Fixed"),
    "decode_param_select_message": MessageLookupByLibrary.simpleMessage(
      "We can control RWKV\'s output style through decode parameters",
    ),
    "decode_param_select_title": MessageLookupByLibrary.simpleMessage(
      "Please select decode parameters",
    ),
    "decode_params_for_each_message": MessageLookupByLibrary.simpleMessage(
      "Decode Params for Each Message",
    ),
    "decode_params_for_each_message_detail": MessageLookupByLibrary.simpleMessage(
      "The decode parameters for each message in the batch. Click to edit the decode parameters for each message in batch inference.",
    ),
    "decode_speed_tokens_per_second": MessageLookupByLibrary.simpleMessage(
      "Decode Speed (tokens per second)",
    ),
    "deep_web_search": MessageLookupByLibrary.simpleMessage(
      "Deep Network Search",
    ),
    "default_font": MessageLookupByLibrary.simpleMessage("Default"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "delete_all": MessageLookupByLibrary.simpleMessage("Delete All"),
    "delete_branch_confirmation_message": MessageLookupByLibrary.simpleMessage(
      "This is a destructive action: it will permanently delete the current message and all its child nodes, and sync the related database records. This action cannot be undone. Continue?",
    ),
    "delete_branch_title": MessageLookupByLibrary.simpleMessage(
      "Delete Current Message",
    ),
    "delete_conversation": MessageLookupByLibrary.simpleMessage(
      "Delete Conversation",
    ),
    "delete_conversation_message": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this conversation?",
    ),
    "delete_current_branch": MessageLookupByLibrary.simpleMessage(
      "Delete Current Message",
    ),
    "delete_finished": MessageLookupByLibrary.simpleMessage("Delete completed"),
    "delete_mlx_cache_confirmation": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this MLX/CoreML cache?",
    ),
    "difficulty": MessageLookupByLibrary.simpleMessage("Difficulty"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "Difficulty must be greater than 0",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "Difficulty must be less than 81",
    ),
    "disabled": MessageLookupByLibrary.simpleMessage("Disabled"),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "dont_ask_again": MessageLookupByLibrary.simpleMessage("Don\'t ask again"),
    "download_all": MessageLookupByLibrary.simpleMessage("Download All"),
    "download_all_missing": MessageLookupByLibrary.simpleMessage(
      "Download All Missing Files",
    ),
    "download_app": MessageLookupByLibrary.simpleMessage("Download App"),
    "download_failed": MessageLookupByLibrary.simpleMessage("Download Failed"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage(
      "Download from browser",
    ),
    "download_missing": MessageLookupByLibrary.simpleMessage(
      "Download Missing Files",
    ),
    "download_model": MessageLookupByLibrary.simpleMessage("Download model"),
    "download_now": MessageLookupByLibrary.simpleMessage("Download Now"),
    "download_server_": MessageLookupByLibrary.simpleMessage(
      "Download Server (Please try which one is faster)",
    ),
    "download_source": MessageLookupByLibrary.simpleMessage("Download Source"),
    "downloading": MessageLookupByLibrary.simpleMessage("Downloading"),
    "draw": MessageLookupByLibrary.simpleMessage("Draw!"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage(
      "Dump Message Records",
    ),
    "dump_see_files_alert_message": m24,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage(
      "Help us improve the algorithm",
    ),
    "dump_started": MessageLookupByLibrary.simpleMessage("Auto dump enabled"),
    "dump_stopped": MessageLookupByLibrary.simpleMessage("Auto dump disabled"),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editing": MessageLookupByLibrary.simpleMessage("Editing"),
    "en_to_zh": MessageLookupByLibrary.simpleMessage("EN->ZH"),
    "enable_system_proxy": MessageLookupByLibrary.simpleMessage(
      "Enable system proxy",
    ),
    "enabled": MessageLookupByLibrary.simpleMessage("Enabled"),
    "end": MessageLookupByLibrary.simpleMessage("End"),
    "english": MessageLookupByLibrary.simpleMessage("English"),
    "english_translation_result": MessageLookupByLibrary.simpleMessage(
      "English Translation Result",
    ),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage(
          "Please ensure your device has enough memory, otherwise the application might crash",
        ),
    "enter_text_to_expand": MessageLookupByLibrary.simpleMessage(
      "Enter text to expand",
    ),
    "enter_text_to_translate": MessageLookupByLibrary.simpleMessage(
      "Enter text to translate...",
    ),
    "escape_characters_rendered": MessageLookupByLibrary.simpleMessage(
      "Escape characters rendered",
    ),
    "expert": MessageLookupByLibrary.simpleMessage("Expert"),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("Explore RWKV"),
    "exploring": MessageLookupByLibrary.simpleMessage("Exploring..."),
    "export_all_weight_files": MessageLookupByLibrary.simpleMessage(
      "Export All Weight Files",
    ),
    "export_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "All downloaded weight files will be exported as individual files to the selected directory. Existing files with the same name will be skipped.",
    ),
    "export_conversation_failed": MessageLookupByLibrary.simpleMessage(
      "Export conversation failed",
    ),
    "export_conversation_to_txt": MessageLookupByLibrary.simpleMessage(
      "Export conversation to .txt file",
    ),
    "export_data": MessageLookupByLibrary.simpleMessage("Export Data"),
    "export_failed": MessageLookupByLibrary.simpleMessage("Export failed"),
    "export_success": MessageLookupByLibrary.simpleMessage("Export successful"),
    "export_title": MessageLookupByLibrary.simpleMessage("Conversation title:"),
    "export_weight_file": MessageLookupByLibrary.simpleMessage(
      "Export Weight File",
    ),
    "extra_large": MessageLookupByLibrary.simpleMessage("Extra Large (130%)"),
    "failed_to_check_for_updates": MessageLookupByLibrary.simpleMessage(
      "Failed to check for updates",
    ),
    "failed_to_create_directory": MessageLookupByLibrary.simpleMessage(
      "Failed to create directory",
    ),
    "failed_to_delete_file": m25,
    "fake_batch_inference_benchmark": MessageLookupByLibrary.simpleMessage(
      "Fake batch inference benchmark",
    ),
    "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
    "file_already_exists": MessageLookupByLibrary.simpleMessage(
      "File already exists",
    ),
    "file_not_found": MessageLookupByLibrary.simpleMessage("File not found"),
    "file_not_supported": MessageLookupByLibrary.simpleMessage(
      "This file is not yet supported. Please check if the file name is correct",
    ),
    "file_path_not_found": MessageLookupByLibrary.simpleMessage(
      "File path not found",
    ),
    "files": MessageLookupByLibrary.simpleMessage("files"),
    "files_moved_with_failures": m26,
    "filter": MessageLookupByLibrary.simpleMessage(
      "Hello, I can\'t answer this question right now. Let\'s talk about something else.",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage(
      "Recording finished",
    ),
    "folder_already_added": MessageLookupByLibrary.simpleMessage(
      "This folder has already been added",
    ),
    "folder_not_accessible_check_permission":
        MessageLookupByLibrary.simpleMessage(
          "This folder is not accessible. Please check folder permissions",
        ),
    "folder_not_found_on_device": MessageLookupByLibrary.simpleMessage(
      "This folder was not found on your device",
    ),
    "follow_system": MessageLookupByLibrary.simpleMessage("System"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "Follow us on Twitter",
    ),
    "font_preview_markdown_asset": MessageLookupByLibrary.simpleMessage(
      "assets/lib/font_preview/font_preview_en.md",
    ),
    "font_preview_user_message": MessageLookupByLibrary.simpleMessage(
      "Hello! This is a preview of user messages.\nThe second line changes with the line height you choose.",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("Font Settings"),
    "font_size": MessageLookupByLibrary.simpleMessage("Font Size"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("Default (100%)"),
    "font_size_follow_system": MessageLookupByLibrary.simpleMessage(
      "Follow System Font Size",
    ),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage("Force Dark Mode"),
    "forget_location_success": MessageLookupByLibrary.simpleMessage(
      "Location forgotten",
    ),
    "forget_this_location": MessageLookupByLibrary.simpleMessage(
      "Forget this location",
    ),
    "found_new_version_available": MessageLookupByLibrary.simpleMessage(
      "Found New Version Available",
    ),
    "frequency_penalty_with_value": m27,
    "from_model": MessageLookupByLibrary.simpleMessage("From Model: %s"),
    "gallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "game_over": MessageLookupByLibrary.simpleMessage("Game Over!"),
    "generate": MessageLookupByLibrary.simpleMessage("Generate"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage(
          "Generate the world\'s hardest Sudoku",
        ),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "Generate Random Sudoku Puzzle",
    ),
    "generated_questions": MessageLookupByLibrary.simpleMessage(
      "Generated Questions",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("Generating..."),
    "github_repository": MessageLookupByLibrary.simpleMessage(
      "Github Repository",
    ),
    "go_to_home_page": MessageLookupByLibrary.simpleMessage("Go to Home Page"),
    "go_to_settings": MessageLookupByLibrary.simpleMessage("Go to settings"),
    "got_it": MessageLookupByLibrary.simpleMessage("Got it"),
    "hello_ask_me_anything": MessageLookupByLibrary.simpleMessage(
      "Hello, Ask Me \nAnything...",
    ),
    "hide_stack": MessageLookupByLibrary.simpleMessage("Hide Thought Stack"),
    "hide_translations": MessageLookupByLibrary.simpleMessage(
      "Hide Translations",
    ),
    "hint_chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "Default use \'<think>好的\', in models released before 2025-09-21, will automatically use \'<think>嗯\'",
    ),
    "hint_system_prompt": MessageLookupByLibrary.simpleMessage(
      "Example: System: You are a powerful RWKV large language model, and you always patiently answer users\' questions.",
    ),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "Hold to record, release to send",
    ),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "http_service_port": m28,
    "human": MessageLookupByLibrary.simpleMessage("Human"),
    "hyphen": MessageLookupByLibrary.simpleMessage("-"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage(
      "I want RWKV to say...",
    ),
    "idle": MessageLookupByLibrary.simpleMessage("Idle"),
    "imitate": m29,
    "imitate_fle": m30,
    "imitate_target": MessageLookupByLibrary.simpleMessage("Use"),
    "import_all_weight_files": MessageLookupByLibrary.simpleMessage(
      "Import All Weight Files",
    ),
    "import_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "Select a ZIP file exported from this app. All weight files in the ZIP will be imported. Existing files will be overwritten if they have the same name.",
    ),
    "import_all_weight_files_success": m31,
    "import_failed": MessageLookupByLibrary.simpleMessage("Import failed"),
    "import_success": MessageLookupByLibrary.simpleMessage("Import successful"),
    "import_weight_file": MessageLookupByLibrary.simpleMessage(
      "Import Weight File",
    ),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage(
          "In-context search will be activated when both breadth and depth are greater than 2",
        ),
    "inference_engine": MessageLookupByLibrary.simpleMessage(
      "Inference Engine",
    ),
    "inference_is_done": MessageLookupByLibrary.simpleMessage(
      "🎉 Inference Done",
    ),
    "inference_is_running": MessageLookupByLibrary.simpleMessage(
      "Inference Running",
    ),
    "input_chinese_text_here": MessageLookupByLibrary.simpleMessage(
      "Input Chinese text here",
    ),
    "input_english_text_here": MessageLookupByLibrary.simpleMessage(
      "Input English text here",
    ),
    "intonations": MessageLookupByLibrary.simpleMessage("Intonations"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "Explore the RWKV v7 series large language models, including 0.1B/0.4B/1.5B/2.9B parameter versions. Optimized for mobile devices, they run completely offline after loading, no server communication required.",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("Invalid Puzzle"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("Invalid Value"),
    "invalid_zip_file": MessageLookupByLibrary.simpleMessage(
      "Invalid ZIP file or file format not recognized",
    ),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("Your turn~"),
    "japanese": MessageLookupByLibrary.simpleMessage("Japanese"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "Join our Discord Server",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage(
      "Join the Community",
    ),
    "just_watch_me": MessageLookupByLibrary.simpleMessage("😎 Watch me!"),
    "korean": MessageLookupByLibrary.simpleMessage("Korean"),
    "lambada_test": MessageLookupByLibrary.simpleMessage("LAMBADA Test"),
    "lan_server": MessageLookupByLibrary.simpleMessage("LAN Server"),
    "large": MessageLookupByLibrary.simpleMessage("Large (120%)"),
    "latest_version": MessageLookupByLibrary.simpleMessage("Latest Version"),
    "lazy": MessageLookupByLibrary.simpleMessage("Lazy"),
    "lazy_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "Lazy Thinking Mode Template",
    ),
    "less_than_01_gb": MessageLookupByLibrary.simpleMessage("< 0.01 GB"),
    "license": MessageLookupByLibrary.simpleMessage("Open Source License"),
    "life_span": MessageLookupByLibrary.simpleMessage("Life Span"),
    "light_mode": MessageLookupByLibrary.simpleMessage("Light Mode"),
    "line_break_rendered": MessageLookupByLibrary.simpleMessage(
      "Line break rendered",
    ),
    "line_break_symbol_settings": MessageLookupByLibrary.simpleMessage(
      "Line break symbol",
    ),
    "load_": MessageLookupByLibrary.simpleMessage("Load"),
    "load_data": MessageLookupByLibrary.simpleMessage("Load Data"),
    "loaded": MessageLookupByLibrary.simpleMessage("Loaded"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
    "loading_progress_percent": m32,
    "local_folder_name": m33,
    "local_pth_files_section_title": MessageLookupByLibrary.simpleMessage(
      "Local .pth file",
    ),
    "local_pth_option_files_in_config": MessageLookupByLibrary.simpleMessage(
      "Weights in config",
    ),
    "local_pth_option_local_pth_files": MessageLookupByLibrary.simpleMessage(
      "Local .pth file",
    ),
    "local_pth_you_can_select": MessageLookupByLibrary.simpleMessage(
      "You can select and load a local .pth file",
    ),
    "medium": MessageLookupByLibrary.simpleMessage("Medium (110%)"),
    "memory_used": m34,
    "message_content": MessageLookupByLibrary.simpleMessage("Message content"),
    "message_in_queue": m35,
    "message_line_height": MessageLookupByLibrary.simpleMessage(
      "Message Line Height",
    ),
    "message_line_height_default_hint": MessageLookupByLibrary.simpleMessage(
      "Default uses the font and renderer\'s native line height instead of a fixed 1.0x. The custom range here is 1.0x to 2.0x.",
    ),
    "message_token_count": MessageLookupByLibrary.simpleMessage(
      "Message Token Count",
    ),
    "mimic": MessageLookupByLibrary.simpleMessage("Mimic"),
    "mlx_cache": MessageLookupByLibrary.simpleMessage("MLX/CoreML Cache"),
    "mlx_cache_notice": MessageLookupByLibrary.simpleMessage(
      "Deleting MLX/CoreML cache can free disk space, but the next MLX/CoreML model load may take longer.",
    ),
    "mode": MessageLookupByLibrary.simpleMessage("Mode"),
    "model": MessageLookupByLibrary.simpleMessage("Model"),
    "model_item_ios18_weight_hint": MessageLookupByLibrary.simpleMessage(
      "Upgrade to iOS 18+ to use this weight, faster and more power-efficient",
    ),
    "model_loading": MessageLookupByLibrary.simpleMessage("Model Loading..."),
    "model_output": m36,
    "model_settings": MessageLookupByLibrary.simpleMessage("Model Settings"),
    "model_size_increased_please_open_a_new_conversation":
        MessageLookupByLibrary.simpleMessage(
          "Model size increased, please open a new conversation, to improve the conversation quality",
        ),
    "monospace_font_setting": MessageLookupByLibrary.simpleMessage(
      "Monospace Font Setting",
    ),
    "more": MessageLookupByLibrary.simpleMessage("More"),
    "more_questions": MessageLookupByLibrary.simpleMessage("More Questions"),
    "moving_files": MessageLookupByLibrary.simpleMessage("Moving files..."),
    "multi_question_continue": MessageLookupByLibrary.simpleMessage("Continue"),
    "multi_question_entry_detail": MessageLookupByLibrary.simpleMessage(
      "Ask multiple questions and get answers in parallel",
    ),
    "multi_question_input_hint": MessageLookupByLibrary.simpleMessage(
      "Enter your question...",
    ),
    "multi_question_no_answer": MessageLookupByLibrary.simpleMessage(
      "No answer yet",
    ),
    "multi_question_send_all": MessageLookupByLibrary.simpleMessage("Send All"),
    "multi_question_title": MessageLookupByLibrary.simpleMessage(
      "Multi-Question Parallel",
    ),
    "multi_thread": MessageLookupByLibrary.simpleMessage("Multi-threaded"),
    "my_voice": MessageLookupByLibrary.simpleMessage("My Voice"),
    "neko": MessageLookupByLibrary.simpleMessage("Neko"),
    "network_error": MessageLookupByLibrary.simpleMessage("Network Error"),
    "new_chat": MessageLookupByLibrary.simpleMessage("New Chat"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage(
      "New chat started",
    ),
    "new_chat_template": MessageLookupByLibrary.simpleMessage(
      "New Chat Template",
    ),
    "new_chat_template_helper_text": MessageLookupByLibrary.simpleMessage(
      "This will be inserted with each new conversation, separated by two line breaks, for example: \nHello, who are you?\n\nHello, I\'m RWKV, is there anything I can help you with?",
    ),
    "new_conversation": MessageLookupByLibrary.simpleMessage(
      "New Conversation",
    ),
    "new_game": MessageLookupByLibrary.simpleMessage("New Game"),
    "new_version_available": MessageLookupByLibrary.simpleMessage(
      "New version available",
    ),
    "new_version_found": MessageLookupByLibrary.simpleMessage(
      "New version found",
    ),
    "no_audio_file": MessageLookupByLibrary.simpleMessage("No audio file"),
    "no_browser_windows_connected": MessageLookupByLibrary.simpleMessage(
      "No browser windows connected",
    ),
    "no_cell_available": MessageLookupByLibrary.simpleMessage(
      "No cell available",
    ),
    "no_conversation_yet": MessageLookupByLibrary.simpleMessage(
      "No conversation yet",
    ),
    "no_conversations_yet": MessageLookupByLibrary.simpleMessage(
      "No Conversations Yet",
    ),
    "no_data": MessageLookupByLibrary.simpleMessage("No Data"),
    "no_files_in_zip": MessageLookupByLibrary.simpleMessage(
      "No valid weight files found in the ZIP file",
    ),
    "no_latest_version_info": MessageLookupByLibrary.simpleMessage(
      "No latest version information",
    ),
    "no_local_folders": MessageLookupByLibrary.simpleMessage(
      "You haven\'t added a local folder that contains .pth files",
    ),
    "no_local_pth_loaded_yet": MessageLookupByLibrary.simpleMessage(
      "No local .pth file loaded yet",
    ),
    "no_message_to_export": MessageLookupByLibrary.simpleMessage(
      "No message to export",
    ),
    "no_model_selected": MessageLookupByLibrary.simpleMessage(
      "No model selected",
    ),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("No Sudoku"),
    "no_weight_files_guide_message": MessageLookupByLibrary.simpleMessage(
      "You haven\'t downloaded any weight files yet. Go to the home page to download and experience the app.",
    ),
    "no_weight_files_guide_title": MessageLookupByLibrary.simpleMessage(
      "No Weight Files",
    ),
    "no_weight_files_to_export": MessageLookupByLibrary.simpleMessage(
      "No weight files to export",
    ),
    "not_all_the_same": MessageLookupByLibrary.simpleMessage(
      "Not all the same",
    ),
    "not_syncing": MessageLookupByLibrary.simpleMessage("Not syncing"),
    "npu_not_supported_title": m37,
    "number": MessageLookupByLibrary.simpleMessage("Number"),
    "nyan_nyan": MessageLookupByLibrary.simpleMessage("Nyan~~,Nyan~~"),
    "ocr_guide_text": m38,
    "ocr_title": MessageLookupByLibrary.simpleMessage("OCR"),
    "off": MessageLookupByLibrary.simpleMessage("Off"),
    "offline_translator": MessageLookupByLibrary.simpleMessage(
      "Offline Translator",
    ),
    "offline_translator_detail": MessageLookupByLibrary.simpleMessage(
      "Translate text on your device",
    ),
    "offline_translator_server": MessageLookupByLibrary.simpleMessage(
      "Offline Translator Server",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "open_containing_folder": MessageLookupByLibrary.simpleMessage(
      "Open containing folder",
    ),
    "open_database_folder": MessageLookupByLibrary.simpleMessage(
      "Open Database Folder",
    ),
    "open_debug_log_panel": MessageLookupByLibrary.simpleMessage(
      "Open Debug Log Panel",
    ),
    "open_folder": MessageLookupByLibrary.simpleMessage("Open folder"),
    "open_folder_create_failed": m39,
    "open_folder_created_success": MessageLookupByLibrary.simpleMessage(
      "Empty folder created successfully.",
    ),
    "open_folder_creating_empty": MessageLookupByLibrary.simpleMessage(
      "Folder does not exist, creating empty folder.",
    ),
    "open_folder_path_is_null": MessageLookupByLibrary.simpleMessage(
      "Folder path is null.",
    ),
    "open_folder_unsupported_on_platform": m40,
    "open_official_download_page": MessageLookupByLibrary.simpleMessage(
      "Open Official Download Page",
    ),
    "open_state_panel": MessageLookupByLibrary.simpleMessage(
      "Open State Panel",
    ),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage(
          "Or select a WAV file for RWKV to imitate.",
        ),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "Or start a new empty chat",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV Othello"),
    "other_files": MessageLookupByLibrary.simpleMessage(
      "Other Files (These may be outdated or unsupported weights that RWKV Chat no longer needs)",
    ),
    "other_settings": MessageLookupByLibrary.simpleMessage("Other Settings"),
    "output": MessageLookupByLibrary.simpleMessage("Output"),
    "overseas": MessageLookupByLibrary.simpleMessage("(Overseas)"),
    "overwrite": MessageLookupByLibrary.simpleMessage("Overwrite"),
    "overwrite_file_confirmation": MessageLookupByLibrary.simpleMessage(
      "File already exists. Do you want to overwrite it?",
    ),
    "parameter_description": MessageLookupByLibrary.simpleMessage(
      "Parameter Description",
    ),
    "parameter_description_detail": MessageLookupByLibrary.simpleMessage(
      "Temperature: Controls randomness. Higher values (e.g., 0.8) make output more creative/random; lower values (e.g., 0.2) make it more focused/deterministic.\n\nTop P: Controls diversity. The model considers only tokens with cumulative probability summing to Top P. Lower values (e.g., 0.5) ignore low-probability words, making output more relevant.\n\nPresence Penalty: Penalizes tokens based on whether they have appeared in the text. Positive values increase the likelihood of talking about new topics.\n\nFrequency Penalty: Penalizes tokens based on their frequency in the text. Positive values decrease the likelihood of repeating lines verbatim.\n\nPenalty Decay: Controls how the penalty decays over distance.",
    ),
    "path_label": m41,
    "pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "penalty_decay_with_value": m42,
    "performance_test": MessageLookupByLibrary.simpleMessage(
      "Performance Test",
    ),
    "performance_test_description": MessageLookupByLibrary.simpleMessage(
      "Test speed and accuracy",
    ),
    "perplexity": MessageLookupByLibrary.simpleMessage("Perplexity"),
    "players": MessageLookupByLibrary.simpleMessage("Players"),
    "playing_partial_generated_audio": MessageLookupByLibrary.simpleMessage(
      "Playing partially generated audio",
    ),
    "please_check_the_result": MessageLookupByLibrary.simpleMessage(
      "Please check the result",
    ),
    "please_enter_a_number_0_means_empty": MessageLookupByLibrary.simpleMessage(
      "Please enter a number. 0 means empty.",
    ),
    "please_enter_conversation_name": MessageLookupByLibrary.simpleMessage(
      "Please enter conversation name",
    ),
    "please_enter_text_to_generate_tts": MessageLookupByLibrary.simpleMessage(
      "Please enter text to generate TTS",
    ),
    "please_enter_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "Please enter the difficulty",
    ),
    "please_entry_some_text_to_continue": MessageLookupByLibrary.simpleMessage(
      "Please entry some text to continue",
    ),
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage(
          "Please grant permission to use the microphone",
        ),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage(
      "Please load the model first",
    ),
    "please_manually_migrate_files": MessageLookupByLibrary.simpleMessage(
      "Path updated. Please manually move or copy files if needed.",
    ),
    "please_select_a_branch_to_continue_the_conversation":
        MessageLookupByLibrary.simpleMessage(
          "Please select a branch to continue the conversation",
        ),
    "please_select_a_spk_or_a_wav_file": MessageLookupByLibrary.simpleMessage(
      "Please select a preset voice or record your voice",
    ),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "Please select a See Type",
    ),
    "please_select_an_image_first": MessageLookupByLibrary.simpleMessage(
      "Please select an image first",
    ),
    "please_select_an_image_from_the_following_options":
        MessageLookupByLibrary.simpleMessage(
          "Please select an image from the following options",
        ),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "Please select application language",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage(
      "Please select font size",
    ),
    "please_select_model": MessageLookupByLibrary.simpleMessage(
      "Please Select Model",
    ),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "Please select the difficulty",
    ),
    "please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index":
        m43,
    "please_select_the_sampler_and_penalty_parameters_to_set_for_all_messages":
        MessageLookupByLibrary.simpleMessage(
          "Please select the sampler and penalty parameters to set for all messages",
        ),
    "please_wait_for_it_to_finish": MessageLookupByLibrary.simpleMessage(
      "Please wait for it to finish",
    ),
    "please_wait_for_the_model_to_finish_generating":
        MessageLookupByLibrary.simpleMessage(
          "Please wait for the model to finish generating",
        ),
    "please_wait_for_the_model_to_generate":
        MessageLookupByLibrary.simpleMessage(
          "Please wait for the model to generate",
        ),
    "please_wait_for_the_model_to_load": MessageLookupByLibrary.simpleMessage(
      "Please wait for the model to load",
    ),
    "power_user": MessageLookupByLibrary.simpleMessage("Power User"),
    "prebuilt": MessageLookupByLibrary.simpleMessage("Prebuilt"),
    "prebuilt_models_intro": MessageLookupByLibrary.simpleMessage(
      "Below are RWKV Chat pre-quantized models",
    ),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("Prebuilt Voices"),
    "prefer": MessageLookupByLibrary.simpleMessage("Prefer"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage(
      "Prefer Chinese Inference",
    ),
    "prefill": MessageLookupByLibrary.simpleMessage("Prefill"),
    "prefill_progress_percent": m44,
    "prefill_speed_tokens_per_second": MessageLookupByLibrary.simpleMessage(
      "Prefill Speed (tokens per second)",
    ),
    "prefix_bank": MessageLookupByLibrary.simpleMessage("Prefix Bank"),
    "prefix_examples": MessageLookupByLibrary.simpleMessage("Prefix Examples"),
    "presence_penalty_with_value": m45,
    "preview": MessageLookupByLibrary.simpleMessage("Preview"),
    "prompt": MessageLookupByLibrary.simpleMessage("Prompt"),
    "prompt_template": MessageLookupByLibrary.simpleMessage("Prompt Template"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQ Group 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQ Group 2"),
    "quantization": MessageLookupByLibrary.simpleMessage("Quantization"),
    "question": MessageLookupByLibrary.simpleMessage("Question"),
    "question_generator": MessageLookupByLibrary.simpleMessage(
      "Question Generator",
    ),
    "question_generator_context_prefix_input_placeholder":
        MessageLookupByLibrary.simpleMessage(
          "If you leave this blank, RWKV will generate questions based on the context.",
        ),
    "question_generator_count": MessageLookupByLibrary.simpleMessage("Count"),
    "question_generator_empty_chat_batch_hint":
        MessageLookupByLibrary.simpleMessage(
          "Choose an opening above, then tap Generate and let RWKV suggest a few questions you can send right away.",
        ),
    "question_generator_empty_chat_hint": MessageLookupByLibrary.simpleMessage(
      "Choose an opening above, then tap Generate and let RWKV suggest a question you can send right away.",
    ),
    "question_generator_language_switched_hint":
        MessageLookupByLibrary.simpleMessage(
          "After switching languages, the suggested openings above will change as well. Pick one you like and let RWKV continue from there.",
        ),
    "question_generator_mock_batch_description":
        MessageLookupByLibrary.simpleMessage(
          "Need a little inspiration? Let RWKV suggest a few questions for you.",
        ),
    "question_generator_mock_description": MessageLookupByLibrary.simpleMessage(
      "Not sure how to start? Let RWKV come up with a question for you.",
    ),
    "question_generator_prefix_guide": MessageLookupByLibrary.simpleMessage(
      "Tap different openings below and RWKV will build questions from them. You can also edit the text box below to write your own opening.",
    ),
    "question_generator_prefix_input_placeholder":
        MessageLookupByLibrary.simpleMessage(
          "Write the opening you want RWKV to continue...",
        ),
    "question_generator_prefix_required": MessageLookupByLibrary.simpleMessage(
      "Please enter a question prefix first",
    ),
    "question_generator_prefixes": MessageLookupByLibrary.simpleMessage(
      "Question Prefixes",
    ),
    "question_generator_question_action_guide":
        MessageLookupByLibrary.simpleMessage(
          "Tap any generated question to paste it into the chat input box.",
        ),
    "question_generator_tap_generate_hint": m46,
    "question_language": MessageLookupByLibrary.simpleMessage(
      "I want RWKV to ask in this language...",
    ),
    "queued_x": m47,
    "quick_thinking": MessageLookupByLibrary.simpleMessage("Quick Reasoning"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage(
      "Quick Reasoning Enabled",
    ),
    "reached_bottom": MessageLookupByLibrary.simpleMessage("Stay tuned"),
    "real_time_update": MessageLookupByLibrary.simpleMessage(
      "Real-time Update",
    ),
    "reason": MessageLookupByLibrary.simpleMessage("Reasoning"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("Reasoning Mode"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage(
      "Recording your voice...",
    ),
    "reference_source": MessageLookupByLibrary.simpleMessage(
      "Reference Source",
    ),
    "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "refresh_complete": MessageLookupByLibrary.simpleMessage(
      "Refresh complete",
    ),
    "refreshed": MessageLookupByLibrary.simpleMessage("Refreshed"),
    "regenerate": MessageLookupByLibrary.simpleMessage("Regenerate"),
    "remaining": MessageLookupByLibrary.simpleMessage("Remaining Time:"),
    "rename": MessageLookupByLibrary.simpleMessage("Rename"),
    "render_newline_directly": MessageLookupByLibrary.simpleMessage(
      "Render newline directly",
    ),
    "render_space_symbol": MessageLookupByLibrary.simpleMessage(
      "Render space symbol",
    ),
    "report_an_issue_on_github": MessageLookupByLibrary.simpleMessage(
      "Report an issue on Github",
    ),
    "reselect_model": MessageLookupByLibrary.simpleMessage("Reselect model"),
    "reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "reset_to_default": MessageLookupByLibrary.simpleMessage(
      "Reset to default",
    ),
    "reset_to_default_directory": MessageLookupByLibrary.simpleMessage(
      "Reset to default directory",
    ),
    "response_style": MessageLookupByLibrary.simpleMessage("Response Style"),
    "response_style_auto_switched_to_jin": MessageLookupByLibrary.simpleMessage(
      "Switched back to Jin style automatically",
    ),
    "response_style_batch_not_supported": m48,
    "response_style_button": MessageLookupByLibrary.simpleMessage("Style"),
    "response_style_keep_one": MessageLookupByLibrary.simpleMessage(
      "Keep at least one response style enabled",
    ),
    "response_style_route_en_detail": MessageLookupByLibrary.simpleMessage(
      "English answer",
    ),
    "response_style_route_gu": MessageLookupByLibrary.simpleMessage("古"),
    "response_style_route_gu_detail": MessageLookupByLibrary.simpleMessage(
      "Classical Chinese answer",
    ),
    "response_style_route_ja_detail": MessageLookupByLibrary.simpleMessage(
      "Japanese answer",
    ),
    "response_style_route_jin": MessageLookupByLibrary.simpleMessage("今"),
    "response_style_route_jin_detail": MessageLookupByLibrary.simpleMessage(
      "Normal answer",
    ),
    "response_style_route_mao": MessageLookupByLibrary.simpleMessage("猫"),
    "response_style_route_mao_detail": MessageLookupByLibrary.simpleMessage(
      "Cat-style answer",
    ),
    "response_style_route_yue_detail": MessageLookupByLibrary.simpleMessage(
      "Cantonese answer",
    ),
    "restore_default": MessageLookupByLibrary.simpleMessage("Restore Default"),
    "result": MessageLookupByLibrary.simpleMessage("Result"),
    "resume": MessageLookupByLibrary.simpleMessage("Resume"),
    "role_play": MessageLookupByLibrary.simpleMessage("Role Play"),
    "role_play_intro": MessageLookupByLibrary.simpleMessage(
      "Play as your favorite character",
    ),
    "runtime_log_panel": MessageLookupByLibrary.simpleMessage(
      "Runtime Log Panel",
    ),
    "russian": MessageLookupByLibrary.simpleMessage("Russian"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV Chat"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV Othello"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("Scan QR Code"),
    "scanning_folder_for_pth": MessageLookupByLibrary.simpleMessage(
      "Scanning this folder for .pth files",
    ),
    "screen_width": MessageLookupByLibrary.simpleMessage("Screen width"),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("Search Breadth"),
    "search_depth": MessageLookupByLibrary.simpleMessage("Search Depth"),
    "search_failed": MessageLookupByLibrary.simpleMessage("Search Failed"),
    "searching": MessageLookupByLibrary.simpleMessage("Searching..."),
    "see": MessageLookupByLibrary.simpleMessage("Image Q&A"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("Select a Model"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "Select a See Type",
    ),
    "select_all": MessageLookupByLibrary.simpleMessage("Select All"),
    "select_from_file": MessageLookupByLibrary.simpleMessage(
      "Select Image File",
    ),
    "select_from_library": MessageLookupByLibrary.simpleMessage(
      "Select from Library",
    ),
    "select_image": MessageLookupByLibrary.simpleMessage("Select Image"),
    "select_local_pth_file_button": MessageLookupByLibrary.simpleMessage(
      "Select local .pth file",
    ),
    "select_model": MessageLookupByLibrary.simpleMessage("Select Model"),
    "select_new_image": MessageLookupByLibrary.simpleMessage("Select Image"),
    "select_the_decode_parameters_to_set_all_to_for_index":
        MessageLookupByLibrary.simpleMessage(
          "Please select a preset from below, or tap \'Custom\' to configure manually",
        ),
    "select_weights_or_local_pth_hint": MessageLookupByLibrary.simpleMessage(
      "Select weights from config or local .pth file",
    ),
    "selected_count": m49,
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage(
      "Message RWKV",
    ),
    "server_error": MessageLookupByLibrary.simpleMessage("Server Error"),
    "session_configuration": MessageLookupByLibrary.simpleMessage(
      "Session Configuration",
    ),
    "set_all_batch_params": MessageLookupByLibrary.simpleMessage(
      "Set All Batch Params",
    ),
    "set_all_to_question_mark": MessageLookupByLibrary.simpleMessage(
      "Set all to ???",
    ),
    "set_custom_directory": MessageLookupByLibrary.simpleMessage(
      "Set custom directory",
    ),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage(
      "Set Grid Value",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "share": MessageLookupByLibrary.simpleMessage("Share"),
    "share_chat": MessageLookupByLibrary.simpleMessage("Share Chat"),
    "show_prefill_log_only": MessageLookupByLibrary.simpleMessage(
      "Show only Prefill log",
    ),
    "show_stack": MessageLookupByLibrary.simpleMessage("Show Thought Stack"),
    "show_translations": MessageLookupByLibrary.simpleMessage(
      "Show Translations",
    ),
    "single_thread": MessageLookupByLibrary.simpleMessage("Single-threaded"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "It is recommended to choose at least a 1.5B model for better results",
    ),
    "skip_this_version": MessageLookupByLibrary.simpleMessage(
      "Skip This Version",
    ),
    "small": MessageLookupByLibrary.simpleMessage("Small (90%)"),
    "source_code": MessageLookupByLibrary.simpleMessage("Source Code"),
    "source_text": m50,
    "space_rendered": MessageLookupByLibrary.simpleMessage("Spaces rendered"),
    "space_symbol_settings": MessageLookupByLibrary.simpleMessage(
      "Space symbol",
    ),
    "space_symbol_style": MessageLookupByLibrary.simpleMessage(
      "Space symbol style",
    ),
    "space_symbols_rendered": MessageLookupByLibrary.simpleMessage(
      "Space symbols rendered",
    ),
    "speed": MessageLookupByLibrary.simpleMessage("Download Speed:"),
    "start": MessageLookupByLibrary.simpleMessage("Start"),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "Start a New Chat",
    ),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage(
          "Start a new chat by clicking the button below",
        ),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("Start Game"),
    "start_download_updates_": MessageLookupByLibrary.simpleMessage(
      "Start downloading updates...",
    ),
    "start_service": MessageLookupByLibrary.simpleMessage("Start Service"),
    "start_service_and_open_browser": MessageLookupByLibrary.simpleMessage(
      "Start the service and open a supported browser page.",
    ),
    "start_test": MessageLookupByLibrary.simpleMessage("Start Test"),
    "start_testing": MessageLookupByLibrary.simpleMessage("Start Testing"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("Start to chat"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage(
      "Start Inference",
    ),
    "starting": MessageLookupByLibrary.simpleMessage("Starting..."),
    "state_list": MessageLookupByLibrary.simpleMessage("State List"),
    "state_panel": MessageLookupByLibrary.simpleMessage("State Panel"),
    "status": MessageLookupByLibrary.simpleMessage("Status"),
    "stop": MessageLookupByLibrary.simpleMessage("Stop"),
    "stop_service": MessageLookupByLibrary.simpleMessage("Stop Service"),
    "stop_test": MessageLookupByLibrary.simpleMessage("Stop Test"),
    "stopping": MessageLookupByLibrary.simpleMessage("Stopping..."),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "Storage permission not granted",
    ),
    "str_downloading_info": MessageLookupByLibrary.simpleMessage(
      "Downloaded %.1f%% Speed %.1fMB/s Remain %s",
    ),
    "str_model_selection_dialog_hint": MessageLookupByLibrary.simpleMessage(
      "We recommend choosing at least the 1.5B model, 2.9B is preferable.",
    ),
    "str_please_disable_battery_opt_": MessageLookupByLibrary.simpleMessage(
      "Please disable battery optimization to allow background downloads, otherwise downloads may pause when switching to other apps",
    ),
    "str_please_select_app_mode_": MessageLookupByLibrary.simpleMessage(
      "Choose an app mode according to your familiarity with AI and LLMs.",
    ),
    "style": MessageLookupByLibrary.simpleMessage("Style"),
    "submit": MessageLookupByLibrary.simpleMessage("Submit"),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("Easy"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("Hard"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("Medium"),
    "suggest": MessageLookupByLibrary.simpleMessage("Suggest"),
    "switch_to_creative_mode_for_better_exp":
        MessageLookupByLibrary.simpleMessage(
          "Switch Decode Param to \'Creative\' for better experience",
        ),
    "syncing": MessageLookupByLibrary.simpleMessage("Syncing"),
    "system_mode": MessageLookupByLibrary.simpleMessage("System Mode"),
    "system_prompt": MessageLookupByLibrary.simpleMessage("System Prompt"),
    "tag_date": MessageLookupByLibrary.simpleMessage("Date"),
    "tag_day_of_week": MessageLookupByLibrary.simpleMessage("Day of Week"),
    "tag_time": MessageLookupByLibrary.simpleMessage("Time"),
    "take_photo": MessageLookupByLibrary.simpleMessage("Take Photo"),
    "target_text": m51,
    "technical_research_group": MessageLookupByLibrary.simpleMessage(
      "Technical Research Group",
    ),
    "temperature_with_value": m52,
    "test_data": MessageLookupByLibrary.simpleMessage("Test Data"),
    "test_result": MessageLookupByLibrary.simpleMessage("Test Result"),
    "test_results": MessageLookupByLibrary.simpleMessage("Test Results"),
    "testing": MessageLookupByLibrary.simpleMessage("Testing..."),
    "text": MessageLookupByLibrary.simpleMessage("Text"),
    "text_color": MessageLookupByLibrary.simpleMessage("Text color"),
    "text_completion_mode": MessageLookupByLibrary.simpleMessage(
      "Text completion mode",
    ),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage(
      "The Sudoku puzzle is not valid",
    ),
    "theme_dim": MessageLookupByLibrary.simpleMessage("Dim"),
    "theme_light": MessageLookupByLibrary.simpleMessage("Light"),
    "theme_lights_out": MessageLookupByLibrary.simpleMessage("Lights out"),
    "then_you_can_start_to_chat_with_rwkv":
        MessageLookupByLibrary.simpleMessage(
          "Then you can start to chat with RWKV",
        ),
    "think_button_mode_en": m53,
    "think_button_mode_en_long": m54,
    "think_button_mode_en_short": m55,
    "think_button_mode_fast": m56,
    "think_mode_selector_message": MessageLookupByLibrary.simpleMessage(
      "The reasoning mode affects the model\'s performance during reasoning",
    ),
    "think_mode_selector_recommendation": MessageLookupByLibrary.simpleMessage(
      "Recommended: choose at least \"Reasoning-Fast\"",
    ),
    "think_mode_selector_title": MessageLookupByLibrary.simpleMessage(
      "Please select a reasoning mode",
    ),
    "thinking": MessageLookupByLibrary.simpleMessage("Thinking..."),
    "thinking_mode_alert_footer": MessageLookupByLibrary.simpleMessage(" Mode"),
    "thinking_mode_auto": m57,
    "thinking_mode_high": m58,
    "thinking_mode_off": m59,
    "thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "Thinking Mode Template",
    ),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage(
          "This is the hardest Sudoku in the world",
        ),
    "this_model_does_not_support_batch_inference":
        MessageLookupByLibrary.simpleMessage(
          "This model does not support batch inference, please select a model with the \"batch\" tag",
        ),
    "thought_result": MessageLookupByLibrary.simpleMessage("Thought Result"),
    "top_p_with_value": m60,
    "total_count": MessageLookupByLibrary.simpleMessage("Total Count"),
    "total_disk_usage": MessageLookupByLibrary.simpleMessage(
      "Storage Space Usage",
    ),
    "total_test_items": m61,
    "translate": MessageLookupByLibrary.simpleMessage("Translate"),
    "translating": MessageLookupByLibrary.simpleMessage("Translating..."),
    "translation": MessageLookupByLibrary.simpleMessage("Translation"),
    "translator_debug_info": MessageLookupByLibrary.simpleMessage(
      "Translator Debug Info",
    ),
    "tts": MessageLookupByLibrary.simpleMessage("Text-to-Speech"),
    "tts_detail": MessageLookupByLibrary.simpleMessage("Let RWKV output voice"),
    "tts_is_running_please_wait": MessageLookupByLibrary.simpleMessage(
      "TTS is running, please wait for it to finish",
    ),
    "tts_voice_source_file_panel_hint": MessageLookupByLibrary.simpleMessage(
      "Use the audio file below to generate speech",
    ),
    "tts_voice_source_file_subtitle": MessageLookupByLibrary.simpleMessage(
      "Select a WAV file for RWKV to mimic",
    ),
    "tts_voice_source_file_title": MessageLookupByLibrary.simpleMessage(
      "Audio file",
    ),
    "tts_voice_source_my_voice_subtitle": MessageLookupByLibrary.simpleMessage(
      "Record my voice so RWKV can mimic it",
    ),
    "tts_voice_source_my_voice_title": MessageLookupByLibrary.simpleMessage(
      "My voice",
    ),
    "tts_voice_source_preset_subtitle": MessageLookupByLibrary.simpleMessage(
      "Choose from RWKV\'s built-in preset voices",
    ),
    "tts_voice_source_preset_title": MessageLookupByLibrary.simpleMessage(
      "Preset voice",
    ),
    "tts_voice_source_sheet_subtitle": MessageLookupByLibrary.simpleMessage(
      "Choose how you want to provide a voice sample",
    ),
    "tts_voice_source_sheet_title": MessageLookupByLibrary.simpleMessage(
      "Choose a voice for RWKV to mimic",
    ),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("Turn transfer"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ui_font_setting": MessageLookupByLibrary.simpleMessage("UI Font Setting"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("Ultra Large (140%)"),
    "unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "unzipping": MessageLookupByLibrary.simpleMessage("Unzipping"),
    "update_now": MessageLookupByLibrary.simpleMessage("Update now"),
    "updated_at": MessageLookupByLibrary.simpleMessage("Updated at"),
    "use_default_line_height": MessageLookupByLibrary.simpleMessage(
      "Use Default Line Height",
    ),
    "use_it_now": MessageLookupByLibrary.simpleMessage("Use it now"),
    "user": MessageLookupByLibrary.simpleMessage("User:"),
    "user_message_actions_panel_empty": MessageLookupByLibrary.simpleMessage(
      "No actions are available for this message",
    ),
    "user_message_actions_panel_switch_branch_subtitle":
        MessageLookupByLibrary.simpleMessage(
          "Switch adjacent branches with previous / next",
        ),
    "user_message_actions_panel_switch_branch_title":
        MessageLookupByLibrary.simpleMessage("Switch Branch"),
    "user_message_actions_panel_title": MessageLookupByLibrary.simpleMessage(
      "Message Actions",
    ),
    "user_message_branch_switched": MessageLookupByLibrary.simpleMessage(
      "Branch switched",
    ),
    "using_custom_directory": MessageLookupByLibrary.simpleMessage(
      "Using custom directory",
    ),
    "using_default_directory": MessageLookupByLibrary.simpleMessage(
      "Using default directory",
    ),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "Value must be between 0 and 9",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("Very Small (80%)"),
    "visual_understanding_and_ocr": MessageLookupByLibrary.simpleMessage(
      "Visual Understanding & OCR",
    ),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("Voice Cloning"),
    "we_support_npu_socs": MessageLookupByLibrary.simpleMessage(
      "We currently support NPU on the following SoC chips:",
    ),
    "web_search": MessageLookupByLibrary.simpleMessage("Network Search"),
    "web_search_template": MessageLookupByLibrary.simpleMessage(
      "Web Search Template",
    ),
    "websocket_service_port": m62,
    "weights_mangement": MessageLookupByLibrary.simpleMessage(
      "Weight File Management",
    ),
    "weights_saving_directory": MessageLookupByLibrary.simpleMessage(
      "Weights Saving Directory",
    ),
    "welcome_to_rwkv_chat": MessageLookupByLibrary.simpleMessage(
      "Welcome to RWKV Chat",
    ),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage(
      "Welcome to RWKV",
    ),
    "what_is_pth_file_message": MessageLookupByLibrary.simpleMessage(
      ".pth files are weight files loaded directly from the local file system, without downloading from a server.\n\nModels trained with PyTorch are often saved as .pth files.\n\nRWKV Chat supports loading .pth files.",
    ),
    "what_is_pth_file_title": MessageLookupByLibrary.simpleMessage(
      "What is a .pth file?",
    ),
    "white": MessageLookupByLibrary.simpleMessage("White"),
    "white_score": MessageLookupByLibrary.simpleMessage("White Score"),
    "white_wins": MessageLookupByLibrary.simpleMessage("White Wins!"),
    "window_id": m63,
    "windows_architecture_mismatch_dialog_message": m64,
    "windows_architecture_mismatch_dialog_title":
        MessageLookupByLibrary.simpleMessage("Architecture Mismatch"),
    "windows_architecture_mismatch_warning": m65,
    "world": MessageLookupByLibrary.simpleMessage("See"),
    "x_message_selected": MessageLookupByLibrary.simpleMessage("%d Selected"),
    "x_pages_found": MessageLookupByLibrary.simpleMessage("%d Pages Found"),
    "x_tabs": m66,
    "you_are_now_using": m67,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "You can now start chatting with RWKV",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage(
          "You can record your voice and let RWKV imitate it.",
        ),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "You can select a role to chat with",
    ),
    "your_device": MessageLookupByLibrary.simpleMessage("Your device: "),
    "your_voice_is_empty": MessageLookupByLibrary.simpleMessage(
      "Your voice data is empty, please check your microphone",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "Your voice is too short. Please hold the button longer to capture your voice.",
    ),
    "zh_to_en": MessageLookupByLibrary.simpleMessage("ZH->EN"),
  };
}
