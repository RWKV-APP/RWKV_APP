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

  static String m0(demoName) => "Welcome to ${demoName}";

  static String m1(path) =>
      "Message records will be stored in the following folder\n ${path}";

  static String m2(flag, nameCN, nameEN) =>
      "Imitate ${flag} ${nameCN}(${nameEN})\'s voice";

  static String m3(fileName) => "Imitate ${fileName}";

  static String m4(memUsed, memFree) =>
      "Memory Used: ${memUsed}, Memory Free: ${memFree}";

  static String m5(modelName) => "You are now using ${modelName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("According to: "),
    "all": MessageLookupByLibrary.simpleMessage("All"),
    "all_done": MessageLookupByLibrary.simpleMessage("All Done"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("All Prompt"),
    "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "Application Internal Test Group",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("Language"),
    "application_settings": MessageLookupByLibrary.simpleMessage(
      "Application Settings",
    ),
    "apply": MessageLookupByLibrary.simpleMessage("Apply"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage(
          "Are you sure you want to delete this model?",
        ),
    "auto": MessageLookupByLibrary.simpleMessage("Auto"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("Back to Chat"),
    "black": MessageLookupByLibrary.simpleMessage("Black"),
    "black_score": MessageLookupByLibrary.simpleMessage("Black Score"),
    "black_wins": MessageLookupByLibrary.simpleMessage("Black Wins!"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "Bot message edited, you can now send a new message",
    ),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("Cannot Generate"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("Cancel Download"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("Not now"),
    "chat_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "Copied to clipboard",
    ),
    "chat_empty_message": MessageLookupByLibrary.simpleMessage(
      "Please enter a message",
    ),
    "chat_model_name": MessageLookupByLibrary.simpleMessage("Model name"),
    "chat_please_select_a_model": MessageLookupByLibrary.simpleMessage(
      "Please select a model",
    ),
    "chat_resume": MessageLookupByLibrary.simpleMessage("Resume"),
    "chat_title": MessageLookupByLibrary.simpleMessage("RWKV Chat"),
    "chat_welcome_to_use": m0,
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage(
          "You need to download the model first, before you can use it.",
        ),
    "chatting": MessageLookupByLibrary.simpleMessage("Chatting"),
    "chinese": MessageLookupByLibrary.simpleMessage("Chinese"),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage(
      "Choose prebuilt character",
    ),
    "clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "Click here to select a new model",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "Click here to start a new chat",
    ),
    "click_to_load_image": MessageLookupByLibrary.simpleMessage(
      "Click to load image",
    ),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage(
      "Click to select model",
    ),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "Follow system appearance",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "continue_download": MessageLookupByLibrary.simpleMessage(
      "Continue Download",
    ),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "Continue using smaller model",
    ),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage(
          "Create a new one by clicking the button above",
        ),
    "current_turn": MessageLookupByLibrary.simpleMessage("Current Turn"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage(
      "Custom Difficulty",
    ),
    "dark_mode": MessageLookupByLibrary.simpleMessage("Dark Mode"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage("Dark Mode Theme"),
    "decode": MessageLookupByLibrary.simpleMessage("Decode"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "delete_all": MessageLookupByLibrary.simpleMessage("Delete All"),
    "difficulty": MessageLookupByLibrary.simpleMessage("Difficulty"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "Difficulty must be greater than 0",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "Difficulty must be less than 81",
    ),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "download_all": MessageLookupByLibrary.simpleMessage("Download All"),
    "download_app": MessageLookupByLibrary.simpleMessage("Download App"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage(
      "Download from browser",
    ),
    "download_missing": MessageLookupByLibrary.simpleMessage(
      "Download Missing Files",
    ),
    "download_model": MessageLookupByLibrary.simpleMessage("Download model"),
    "download_server_": MessageLookupByLibrary.simpleMessage("Download Source"),
    "download_source": MessageLookupByLibrary.simpleMessage("Download Source"),
    "downloading": MessageLookupByLibrary.simpleMessage("Downloading"),
    "draw": MessageLookupByLibrary.simpleMessage("Draw!"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage(
      "Dump Message Records",
    ),
    "dump_see_files_alert_message": m1,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage(
      "Help us improve the algorithm",
    ),
    "dump_started": MessageLookupByLibrary.simpleMessage("Auto dump enabled"),
    "dump_stopped": MessageLookupByLibrary.simpleMessage("Auto dump disabled"),
    "end": MessageLookupByLibrary.simpleMessage("End"),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage(
          "Please ensure your device has enough memory, otherwise the application might crash",
        ),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("Explore RWKV"),
    "exploring": MessageLookupByLibrary.simpleMessage("Exploring..."),
    "extra_large": MessageLookupByLibrary.simpleMessage("Extra Large (130%)"),
    "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
    "filter": MessageLookupByLibrary.simpleMessage(
      "Hello, I can\'t answer this question right now. Let\'s talk about something else.",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage(
      "Recording finished",
    ),
    "follow_system": MessageLookupByLibrary.simpleMessage("System"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "Follow us on Twitter",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("Font Settings"),
    "font_size": MessageLookupByLibrary.simpleMessage("Font Size"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("Default (100%)"),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage("Force Dark Mode"),
    "from_model": MessageLookupByLibrary.simpleMessage("From Model: %s"),
    "game_over": MessageLookupByLibrary.simpleMessage("Game Over!"),
    "generate": MessageLookupByLibrary.simpleMessage("Generate"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage(
          "Generate the world\'s hardest Sudoku",
        ),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "Generate Random Sudoku Puzzle",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("Generating..."),
    "hide_stack": MessageLookupByLibrary.simpleMessage("Hide Thought Stack"),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "Hold to record, release to send",
    ),
    "human": MessageLookupByLibrary.simpleMessage("Human"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage(
      "I want RWKV to say...",
    ),
    "imitate": m2,
    "imitate_fle": m3,
    "imitate_target": MessageLookupByLibrary.simpleMessage("Use"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage(
          "In-context search will be activated when both breadth and depth are greater than 2",
        ),
    "inference_is_done": MessageLookupByLibrary.simpleMessage(
      "🎉 Inference Done",
    ),
    "inference_is_running": MessageLookupByLibrary.simpleMessage(
      "Inference Running",
    ),
    "intonations": MessageLookupByLibrary.simpleMessage("Intonations"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "Explore the RWKV v7 series large language models, including 0.1B/0.4B/1.5B/2.9B parameter versions. Optimized for mobile devices, they run completely offline after loading, no server communication required.",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("Invalid Puzzle"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("Invalid Value"),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("Your turn~"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "Join our Discord Server",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage(
      "Join the Community",
    ),
    "just_watch_me": MessageLookupByLibrary.simpleMessage("😎 Watch me!"),
    "large": MessageLookupByLibrary.simpleMessage("Large (120%)"),
    "lazy": MessageLookupByLibrary.simpleMessage("Lazy"),
    "license": MessageLookupByLibrary.simpleMessage("Open Source License"),
    "light_mode": MessageLookupByLibrary.simpleMessage("Light Mode"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
    "medium": MessageLookupByLibrary.simpleMessage("Medium (110%)"),
    "memory_used": m4,
    "model_settings": MessageLookupByLibrary.simpleMessage("Model Settings"),
    "my_voice": MessageLookupByLibrary.simpleMessage("My Voice"),
    "network_error": MessageLookupByLibrary.simpleMessage("Network Error"),
    "new_chat": MessageLookupByLibrary.simpleMessage("New Chat"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage(
      "New chat started",
    ),
    "new_game": MessageLookupByLibrary.simpleMessage("New Game"),
    "new_version_found": MessageLookupByLibrary.simpleMessage(
      "New version found",
    ),
    "no_cell_available": MessageLookupByLibrary.simpleMessage(
      "No cell available",
    ),
    "no_data": MessageLookupByLibrary.simpleMessage("No Data"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("No Sudoku"),
    "number": MessageLookupByLibrary.simpleMessage("Number"),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage(
          "Or select a WAV file for RWKV to imitate.",
        ),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "Or start a new empty chat",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV Othello"),
    "overseas": MessageLookupByLibrary.simpleMessage(""),
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
    "please_enter_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "Please enter the difficulty",
    ),
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage(
          "Please grant permission to use the microphone",
        ),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage(
      "Please load the model first",
    ),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "Please select a World Type",
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
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "Please select the difficulty",
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
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("Prebuilt Voices"),
    "prefer": MessageLookupByLibrary.simpleMessage("Prefer"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage(
      "Prefer Chinese Inference",
    ),
    "prefill": MessageLookupByLibrary.simpleMessage("Prefill"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQ Group 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQ Group 2"),
    "quick_thinking": MessageLookupByLibrary.simpleMessage("Quick Reasoning"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage(
      "Quick Reasoning Enabled",
    ),
    "reason": MessageLookupByLibrary.simpleMessage("Reason"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("Reasoning Mode"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage(
      "Recording your voice...",
    ),
    "remaining": MessageLookupByLibrary.simpleMessage("Remaining Time:"),
    "reselect_model": MessageLookupByLibrary.simpleMessage("Reselect model"),
    "reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV Chat"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV Othello"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("Scan QR Code"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("Search Breadth"),
    "search_depth": MessageLookupByLibrary.simpleMessage("Search Depth"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("Select a Model"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "Select a World Type",
    ),
    "select_from_library": MessageLookupByLibrary.simpleMessage(
      "Select from Library",
    ),
    "select_image": MessageLookupByLibrary.simpleMessage("Select Image"),
    "select_new_image": MessageLookupByLibrary.simpleMessage(
      "Select New Image",
    ),
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage(
      "Message RWKV",
    ),
    "server_error": MessageLookupByLibrary.simpleMessage("Server Error"),
    "session_configuration": MessageLookupByLibrary.simpleMessage(
      "Session Configuration",
    ),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage(
      "Set Grid Value",
    ),
    "share": MessageLookupByLibrary.simpleMessage("Share"),
    "share_chat": MessageLookupByLibrary.simpleMessage("Share Chat"),
    "show_stack": MessageLookupByLibrary.simpleMessage("Show Thought Stack"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "It is recommended to choose at least a 1.5B model for better results",
    ),
    "small": MessageLookupByLibrary.simpleMessage("Small (90%)"),
    "speed": MessageLookupByLibrary.simpleMessage("Download Speed:"),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "Start a New Chat",
    ),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage(
          "Start a new chat by clicking the button below",
        ),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("Start Game"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("Start to chat"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage(
      "Start Inference",
    ),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "Storage permission not granted",
    ),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("Easy"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("Hard"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("Medium"),
    "system_mode": MessageLookupByLibrary.simpleMessage("System Mode"),
    "take_photo": MessageLookupByLibrary.simpleMessage("Take Photo"),
    "technical_research_group": MessageLookupByLibrary.simpleMessage(
      "Technical Research Group",
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
    "thinking": MessageLookupByLibrary.simpleMessage("Thinking..."),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage(
          "This is the hardest Sudoku in the world",
        ),
    "thought_result": MessageLookupByLibrary.simpleMessage("Thought Result"),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("Turn transfer"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("Ultra Large (140%)"),
    "update_now": MessageLookupByLibrary.simpleMessage("Update now"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("Use it now"),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "Value must be between 0 and 9",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("Very Small (80%)"),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("Voice Cloning"),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage(
      "Welcome to RWKV",
    ),
    "white": MessageLookupByLibrary.simpleMessage("White"),
    "white_score": MessageLookupByLibrary.simpleMessage("White Score"),
    "white_wins": MessageLookupByLibrary.simpleMessage("White Wins!"),
    "x_message_selected": MessageLookupByLibrary.simpleMessage("%d Selected"),
    "you_are_now_using": m5,
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
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "Your voice is too short. Please hold the button longer to capture your voice.",
    ),
  };
}
