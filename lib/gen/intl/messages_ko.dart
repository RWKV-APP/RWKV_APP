// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ko locale. All the
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
  String get localeName => 'ko';

  static String m0(demoName) => "${demoName} 에 오신 것을 환영합니다";

  static String m2(flag, nameCN, nameEN) =>
      "${flag} ${nameCN}(${nameEN}) 의 음성 모방";

  static String m4(memUsed, memFree) =>
      "사용된 메모리: ${memUsed}, 남은 메모리: ${memFree}";

  static String m5(modelName) => "현재 ${modelName} 을 사용 중입니다";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("정보"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("다음 오디오 파일에 따라:"),
    "all_done": MessageLookupByLibrary.simpleMessage("모두 완료"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "애플리케이션 내부 테스트 그룹",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("애플리케이션 언어"),
    "application_settings": MessageLookupByLibrary.simpleMessage("애플리케이션 설정"),
    "apply": MessageLookupByLibrary.simpleMessage("적용"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage("이 모델을 삭제하시겠습니까?"),
    "auto": MessageLookupByLibrary.simpleMessage("자동"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("채팅으로 돌아가기"),
    "black": MessageLookupByLibrary.simpleMessage("흑"),
    "black_score": MessageLookupByLibrary.simpleMessage("흑 점수"),
    "black_wins": MessageLookupByLibrary.simpleMessage("흑 승리!"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "봇 메시지가 편집되었습니다. 이제 새 메시지를 보낼 수 있습니다",
    ),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("생성할 수 없음"),
    "cancel": MessageLookupByLibrary.simpleMessage("취소"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("다운로드 취소"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("지금 업데이트 안 함"),
    "chat_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "클립보드에 복사되었습니다",
    ),
    "chat_empty_message": MessageLookupByLibrary.simpleMessage("메시지 내용을 입력하세요"),
    "chat_model_name": MessageLookupByLibrary.simpleMessage("모델 이름"),
    "chat_please_select_a_model": MessageLookupByLibrary.simpleMessage(
      "모델을 선택하세요",
    ),
    "chat_resume": MessageLookupByLibrary.simpleMessage("계속"),
    "chat_title": MessageLookupByLibrary.simpleMessage("RWKV 채팅"),
    "chat_welcome_to_use": m0,
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage("사용하려면 먼저 모델을 다운로드해야 합니다"),
    "chatting": MessageLookupByLibrary.simpleMessage("채팅 중"),
    "chinese": MessageLookupByLibrary.simpleMessage("중국어"),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage(
      "사전 설정 캐릭터 선택",
    ),
    "clear": MessageLookupByLibrary.simpleMessage("지우기"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "여기를 클릭하여 새 모델 선택",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "여기를 클릭하여 새 채팅 시작",
    ),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage("클릭하여 모델 선택"),
    "continue_download": MessageLookupByLibrary.simpleMessage("다운로드 계속"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "더 작은 모델 계속 사용",
    ),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("위 버튼을 클릭하여 새 세션 생성"),
    "current_turn": MessageLookupByLibrary.simpleMessage("현재 턴"),
    "decode": MessageLookupByLibrary.simpleMessage("디코드"),
    "delete": MessageLookupByLibrary.simpleMessage("삭제"),
    "delete_all": MessageLookupByLibrary.simpleMessage("모두 삭제"),
    "difficulty": MessageLookupByLibrary.simpleMessage("난이도"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "난이도는 0보다 커야 합니다",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "난이도는 81보다 작아야 합니다",
    ),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "download_all": MessageLookupByLibrary.simpleMessage("모두 다운로드"),
    "download_missing": MessageLookupByLibrary.simpleMessage("누락된 파일 다운로드"),
    "download_model": MessageLookupByLibrary.simpleMessage("모델 다운로드"),
    "download_source": MessageLookupByLibrary.simpleMessage("다운로드 소스"),
    "draw": MessageLookupByLibrary.simpleMessage("무승부!"),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage(
          "장치에 충분한 메모리가 있는지 확인하십시오. 그렇지 않으면 애플리케이션이 충돌할 수 있습니다",
        ),
    "exploring": MessageLookupByLibrary.simpleMessage("탐색 중..."),
    "extra_large": MessageLookupByLibrary.simpleMessage("매우 크게 (130%)"),
    "feedback": MessageLookupByLibrary.simpleMessage("피드백"),
    "filter": MessageLookupByLibrary.simpleMessage(
      "안녕하세요, 이 질문에는 지금 답할 수 없습니다. 다른 주제로 이야기해 볼까요?",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("녹음 완료"),
    "follow_system": MessageLookupByLibrary.simpleMessage("시스템 따르기"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "Twitter에서 저희를 팔로우하세요",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("글꼴 설정"),
    "font_size": MessageLookupByLibrary.simpleMessage("글꼴 크기"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("기본값 (100%)"),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "game_over": MessageLookupByLibrary.simpleMessage("게임 오버!"),
    "generate": MessageLookupByLibrary.simpleMessage("생성"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("세계에서 가장 어려운 스도쿠 생성"),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "무작위 스도쿠 퍼즐 생성",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("생성 중..."),
    "hide_stack": MessageLookupByLibrary.simpleMessage("사고 스택 숨기기"),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "녹음하려면 길게 누르고, 보내려면 놓으세요",
    ),
    "human": MessageLookupByLibrary.simpleMessage("인간"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage(
      "RWKV가 말하게 하고 싶습니다...",
    ),
    "imitate": m2,
    "imitate_target": MessageLookupByLibrary.simpleMessage("사용"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage(
          "탐색 깊이와 너비가 모두 2보다 클 때, 인-컨텍스트 검색이 활성화됩니다",
        ),
    "inference_is_done": MessageLookupByLibrary.simpleMessage("🎉 추론 완료"),
    "inference_is_running": MessageLookupByLibrary.simpleMessage("추론 중"),
    "intonations": MessageLookupByLibrary.simpleMessage("억양"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "RWKV v7 시리즈 대규모 언어 모델을 탐색해보세요. 0.1B/0.4B/1.5B/2.9B 파라미터 버전이 있으며, 모바일 장치에 최적화되어 로드 후 완전히 오프라인으로 실행되며 서버 통신이 필요 없습니다.",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("유효하지 않은 스도쿠"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("유효하지 않은 값"),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("당신의 차례입니다~"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "저희 Discord 서버에 가입하세요",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage("커뮤니티 가입"),
    "just_watch_me": MessageLookupByLibrary.simpleMessage("😎 제가 보여드릴게요!"),
    "large": MessageLookupByLibrary.simpleMessage("크게 (120%)"),
    "license": MessageLookupByLibrary.simpleMessage("오픈소스 라이선스"),
    "loading": MessageLookupByLibrary.simpleMessage("로드 중..."),
    "medium": MessageLookupByLibrary.simpleMessage("중간 (110%)"),
    "memory_used": m4,
    "model_settings": MessageLookupByLibrary.simpleMessage("모델 설정"),
    "my_voice": MessageLookupByLibrary.simpleMessage("내 음성"),
    "network_error": MessageLookupByLibrary.simpleMessage("네트워크 오류"),
    "new_chat": MessageLookupByLibrary.simpleMessage("새 채팅"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("새 채팅 시작"),
    "new_game": MessageLookupByLibrary.simpleMessage("새 게임"),
    "new_version_found": MessageLookupByLibrary.simpleMessage("새 버전 발견"),
    "no_cell_available": MessageLookupByLibrary.simpleMessage(
      "놓을 수 있는 돌이 없습니다",
    ),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("스도쿠 없음"),
    "number": MessageLookupByLibrary.simpleMessage("숫자"),
    "ok": MessageLookupByLibrary.simpleMessage("확인"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("또는 RWKV가 모방할 wav 파일을 선택하세요."),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "또는 새 빈 채팅 시작",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV 오셀로"),
    "players": MessageLookupByLibrary.simpleMessage("플레이어"),
    "playing_partial_generated_audio": MessageLookupByLibrary.simpleMessage(
      "부분적으로 생성된 오디오 재생 중",
    ),
    "please_check_the_result": MessageLookupByLibrary.simpleMessage(
      "결과를 확인하세요",
    ),
    "please_enter_a_number_0_means_empty": MessageLookupByLibrary.simpleMessage(
      "숫자를 입력하세요. 0은 빈칸을 의미합니다.",
    ),
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage("마이크 사용 권한을 허용해주세요"),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage(
      "먼저 모델을 로드하세요",
    ),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "월드 유형을 선택하세요",
    ),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "애플리케이션 언어를 선택하세요",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage(
      "글꼴 크기를 선택하세요",
    ),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "난이도를 입력하세요",
    ),
    "please_wait_for_it_to_finish": MessageLookupByLibrary.simpleMessage(
      "완료될 때까지 기다려 주세요",
    ),
    "please_wait_for_the_model_to_finish_generating":
        MessageLookupByLibrary.simpleMessage("모델 생성이 완료될 때까지 기다려 주세요"),
    "please_wait_for_the_model_to_generate":
        MessageLookupByLibrary.simpleMessage("모델이 생성될 때까지 기다려 주세요"),
    "please_wait_for_the_model_to_load": MessageLookupByLibrary.simpleMessage(
      "모델 로드를 기다려 주세요",
    ),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("사전 설정 음성"),
    "prefer": MessageLookupByLibrary.simpleMessage("사용"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("중국어 추론 선호"),
    "prefill": MessageLookupByLibrary.simpleMessage("프리필"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQ 그룹 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQ 그룹 2"),
    "reason": MessageLookupByLibrary.simpleMessage("추론"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("추론 모드"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("음성 녹음 중..."),
    "remaining": MessageLookupByLibrary.simpleMessage("남은 시간:"),
    "reselect_model": MessageLookupByLibrary.simpleMessage("모델 재선택"),
    "reset": MessageLookupByLibrary.simpleMessage("재설정"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV 채팅"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV 오셀로"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("탐색 너비"),
    "search_depth": MessageLookupByLibrary.simpleMessage("탐색 깊이"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("모델 선택"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("월드 유형 선택"),
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage(
      "RWKV에 메시지 전송",
    ),
    "server_error": MessageLookupByLibrary.simpleMessage("서버 오류"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("세션 구성"),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("그리드 값 설정"),
    "show_stack": MessageLookupByLibrary.simpleMessage("사고 스택 표시"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "더 나은 결과를 위해 최소 1.5B 모델을 선택하는 것을 권장합니다",
    ),
    "small": MessageLookupByLibrary.simpleMessage("작게 (90%)"),
    "speed": MessageLookupByLibrary.simpleMessage("다운로드 속도:"),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage("새 채팅 시작"),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage("아래 버튼을 클릭하여 새 채팅 시작"),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("게임 시작"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("채팅 시작"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("추론 시작"),
    "technical_research_group": MessageLookupByLibrary.simpleMessage(
      "기술 연구 그룹",
    ),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage(
      "스도쿠가 유효하지 않습니다",
    ),
    "thinking": MessageLookupByLibrary.simpleMessage("생각 중..."),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("이것은 세계에서 가장 어려운 스도쿠입니다"),
    "thought_result": MessageLookupByLibrary.simpleMessage("생각 결과"),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("턴 전환"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("초고대 (140%)"),
    "update_now": MessageLookupByLibrary.simpleMessage("지금 업데이트"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("지금 사용"),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "값은 0에서 9 사이여야 합니다",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("매우 작게 (80%)"),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("음성 복제"),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage(
      "RWKV 에 오신 것을 환영합니다",
    ),
    "white": MessageLookupByLibrary.simpleMessage("백"),
    "white_score": MessageLookupByLibrary.simpleMessage("백 점수"),
    "white_wins": MessageLookupByLibrary.simpleMessage("백 승리!"),
    "you_are_now_using": m5,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "이제 RWKV 와 채팅을 시작할 수 있습니다",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("음성을 녹음하여 RWKV가 모방하게 할 수 있습니다."),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "채팅할 역할을 선택할 수 있습니다",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "음성이 너무 짧습니다. 음성을 얻기 위해 버튼을 더 길게 눌러주세요.",
    ),
  };
}
