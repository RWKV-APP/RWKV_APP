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

  static String m0(demoName) => "${demoName}을(를) 탐험해 보세요";

  static String m1(maxLength) => "대화 이름은 ${maxLength}자를 초과할 수 없습니다";

  static String m2(path) => "메시지 기록은 다음 폴더에 저장됩니다:\n ${path}";

  static String m3(flag, nameCN, nameEN) =>
      "${flag} ${nameCN}(${nameEN})의 목소리를 모방";

  static String m4(fileName) => "${fileName} 모방";

  static String m5(memUsed, memFree) =>
      "사용된 메모리: ${memUsed}, 남은 메모리: ${memFree}";

  static String m6(modelName) => "현재 ${modelName}을(를) 사용 중입니다";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("정보"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("다음 오디오 파일에 따라:"),
    "all": MessageLookupByLibrary.simpleMessage("모두"),
    "all_done": MessageLookupByLibrary.simpleMessage("모두 완료"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("모든 프롬프트"),
    "appearance": MessageLookupByLibrary.simpleMessage("외관"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "응용 프로그램 내부 테스트 그룹",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("응용 프로그램 언어"),
    "application_settings": MessageLookupByLibrary.simpleMessage("응용 프로그램 설정"),
    "apply": MessageLookupByLibrary.simpleMessage("적용"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage("이 모델을 삭제하시겠습니까?"),
    "auto": MessageLookupByLibrary.simpleMessage("자동"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("채팅으로 돌아가기"),
    "black": MessageLookupByLibrary.simpleMessage("흑"),
    "black_score": MessageLookupByLibrary.simpleMessage("흑 점수"),
    "black_wins": MessageLookupByLibrary.simpleMessage("흑이 이겼습니다!"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "봇 메시지가 편집되었습니다. 이제 새 메시지를 보낼 수 있습니다.",
    ),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("생성할 수 없음"),
    "cancel": MessageLookupByLibrary.simpleMessage("취소"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("다운로드 취소"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("지금은 업데이트 안 함"),
    "chat_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "클립보드에 복사되었습니다",
    ),
    "chat_empty_message": MessageLookupByLibrary.simpleMessage(
      "메시지 내용을 입력해주세요",
    ),
    "chat_history": MessageLookupByLibrary.simpleMessage("채팅 기록"),
    "chat_mode": MessageLookupByLibrary.simpleMessage("채팅 모드"),
    "chat_model_name": MessageLookupByLibrary.simpleMessage("모델 이름"),
    "chat_please_select_a_model": MessageLookupByLibrary.simpleMessage(
      "모델을 선택해주세요",
    ),
    "chat_resume": MessageLookupByLibrary.simpleMessage("계속"),
    "chat_title": MessageLookupByLibrary.simpleMessage("RWKV 채팅"),
    "chat_welcome_to_use": m0,
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage("사용하려면 먼저 모델을 다운로드해야 합니다"),
    "chatting": MessageLookupByLibrary.simpleMessage("채팅 중"),
    "chinese": MessageLookupByLibrary.simpleMessage("중국어"),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage(
      "사전 정의된 캐릭터 선택",
    ),
    "clear": MessageLookupByLibrary.simpleMessage("지우기"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "여기를 클릭하여 새 모델 선택",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "여기를 클릭하여 새 채팅 시작",
    ),
    "click_to_load_image": MessageLookupByLibrary.simpleMessage(
      "이미지를 로드하려면 클릭하세요",
    ),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage(
      "모델 선택을 클릭하세요",
    ),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "색상 테마 시스템 설정 따르기",
    ),
    "completion_mode": MessageLookupByLibrary.simpleMessage("완성 모드"),
    "confirm": MessageLookupByLibrary.simpleMessage("확인"),
    "continue_download": MessageLookupByLibrary.simpleMessage("다운로드 계속"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "더 작은 모델 계속 사용",
    ),
    "conversation_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "대화 이름은 비워둘 수 없습니다",
    ),
    "conversation_name_cannot_be_longer_than_30_characters": m1,
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("위 버튼을 클릭하여 새로 생성"),
    "current_turn": MessageLookupByLibrary.simpleMessage("현재 차례"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage("맞춤 난이도"),
    "dark_mode": MessageLookupByLibrary.simpleMessage("다크 모드"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage("다크 모드 테마"),
    "decode": MessageLookupByLibrary.simpleMessage("디코딩"),
    "delete": MessageLookupByLibrary.simpleMessage("삭제"),
    "delete_all": MessageLookupByLibrary.simpleMessage("모두 삭제"),
    "delete_conversation": MessageLookupByLibrary.simpleMessage("대화 삭제"),
    "delete_conversation_message": MessageLookupByLibrary.simpleMessage(
      "대화를 삭제하시겠습니까?",
    ),
    "difficulty": MessageLookupByLibrary.simpleMessage("난이도"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "난이도는 0보다 커야 합니다",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "난이도는 81보다 작아야 합니다",
    ),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "download_all": MessageLookupByLibrary.simpleMessage("모두 다운로드"),
    "download_app": MessageLookupByLibrary.simpleMessage("앱 다운로드"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage(
      "브라우저에서 다운로드",
    ),
    "download_missing": MessageLookupByLibrary.simpleMessage("누락된 파일 다운로드"),
    "download_model": MessageLookupByLibrary.simpleMessage("모델 다운로드"),
    "download_server_": MessageLookupByLibrary.simpleMessage(
      "다운로드 서버 (어떤 것이 빠른지 시도해보세요)",
    ),
    "download_source": MessageLookupByLibrary.simpleMessage("다운로드 소스"),
    "downloading": MessageLookupByLibrary.simpleMessage("다운로드 중"),
    "draw": MessageLookupByLibrary.simpleMessage("무승부!"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage("자동 덤프 메시지 기록"),
    "dump_see_files_alert_message": m2,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage(
      "알고리즘 개선에 도움을 주세요",
    ),
    "dump_started": MessageLookupByLibrary.simpleMessage("자동 덤프가 시작되었습니다"),
    "dump_stopped": MessageLookupByLibrary.simpleMessage("자동 덤프가 중지되었습니다"),
    "end": MessageLookupByLibrary.simpleMessage("끝"),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage(
          "기기 메모리가 충분한지 확인하세요. 그렇지 않으면 앱이 충돌할 수 있습니다.",
        ),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("RWKV 탐험"),
    "exploring": MessageLookupByLibrary.simpleMessage("탐험 중..."),
    "export_data": MessageLookupByLibrary.simpleMessage("데이터 내보내기"),
    "extra_large": MessageLookupByLibrary.simpleMessage("매우 크게 (130%)"),
    "feedback": MessageLookupByLibrary.simpleMessage("문제 보고"),
    "filter": MessageLookupByLibrary.simpleMessage(
      "안녕하세요, 이 질문에는 아직 답변할 수 없습니다. 다른 주제로 이야기해 볼까요?",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("녹음 완료"),
    "follow_system": MessageLookupByLibrary.simpleMessage("시스템 설정 따르기"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "Twitter에서 저희를 팔로우하세요",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("글꼴 설정"),
    "font_size": MessageLookupByLibrary.simpleMessage("글꼴 크기"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("기본 (100%)"),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage("강제 다크 모드"),
    "from_model": MessageLookupByLibrary.simpleMessage("모델에서: %s"),
    "game_over": MessageLookupByLibrary.simpleMessage("게임 오버!"),
    "generate": MessageLookupByLibrary.simpleMessage("생성"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("세상에서 가장 어려운 스도쿠 생성"),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "무작위 스도쿠 퍼즐 생성",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("생성 중..."),
    "hide_stack": MessageLookupByLibrary.simpleMessage("사고 체인 스택 숨기기"),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "녹음을 위해 누르고, 보내려면 놓으세요",
    ),
    "human": MessageLookupByLibrary.simpleMessage("인간"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage(
      "RWKV가 말하게 하고 싶어요...",
    ),
    "imitate": m3,
    "imitate_fle": m4,
    "imitate_target": MessageLookupByLibrary.simpleMessage("사용"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage(
          "검색 깊이와 폭이 모두 2보다 클 때 컨텍스트 검색이 활성화됩니다",
        ),
    "inference_is_done": MessageLookupByLibrary.simpleMessage("🎉 추론 완료"),
    "inference_is_running": MessageLookupByLibrary.simpleMessage("추론 중"),
    "intonations": MessageLookupByLibrary.simpleMessage("억양"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "RWKV v7 시리즈 대규모 언어 모델(0.1B/0.4B/1.5B/2.9B 매개변수 버전 포함)을 탐험해 보세요. 모바일 장치에 최적화되어 로드 후 완전히 오프라인에서 실행할 수 있으며 서버 통신이 필요 없습니다.",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("유효하지 않은 스도쿠"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("유효하지 않은 값"),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("당신 차례입니다~"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "저희 Discord 서버에 가입하세요",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage("커뮤니티 가입"),
    "just_watch_me": MessageLookupByLibrary.simpleMessage("😎 저를 보세요!"),
    "large": MessageLookupByLibrary.simpleMessage("크게 (120%)"),
    "lazy": MessageLookupByLibrary.simpleMessage("게으른"),
    "license": MessageLookupByLibrary.simpleMessage("오픈 소스 라이선스"),
    "light_mode": MessageLookupByLibrary.simpleMessage("라이트 모드"),
    "loading": MessageLookupByLibrary.simpleMessage("로드 중..."),
    "medium": MessageLookupByLibrary.simpleMessage("중간 (110%)"),
    "memory_used": m5,
    "model_settings": MessageLookupByLibrary.simpleMessage("모델 설정"),
    "more": MessageLookupByLibrary.simpleMessage("더 보기"),
    "my_voice": MessageLookupByLibrary.simpleMessage("내 목소리"),
    "network_error": MessageLookupByLibrary.simpleMessage("네트워크 오류"),
    "new_chat": MessageLookupByLibrary.simpleMessage("새 채팅"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("새 채팅 시작"),
    "new_game": MessageLookupByLibrary.simpleMessage("새 게임"),
    "new_version_found": MessageLookupByLibrary.simpleMessage("새 버전 발견"),
    "no_cell_available": MessageLookupByLibrary.simpleMessage("놓을 수 있는 칸 없음"),
    "no_data": MessageLookupByLibrary.simpleMessage("데이터 없음"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("스도쿠 없음"),
    "number": MessageLookupByLibrary.simpleMessage("숫자"),
    "ok": MessageLookupByLibrary.simpleMessage("확인"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage(
          "또는 RWKV가 복사하도록 wav 파일을 선택할 수 있습니다.",
        ),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "또는 새 빈 채팅을 시작할 수 있습니다",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV 오셀로"),
    "output": MessageLookupByLibrary.simpleMessage("출력"),
    "overseas": MessageLookupByLibrary.simpleMessage("(해외)"),
    "pause": MessageLookupByLibrary.simpleMessage("일시 정지"),
    "players": MessageLookupByLibrary.simpleMessage("플레이어"),
    "playing_partial_generated_audio": MessageLookupByLibrary.simpleMessage(
      "부분 생성된 오디오 재생 중",
    ),
    "please_check_the_result": MessageLookupByLibrary.simpleMessage(
      "결과를 확인해주세요",
    ),
    "please_enter_a_number_0_means_empty": MessageLookupByLibrary.simpleMessage(
      "숫자를 입력해주세요. 0은 빈칸을 의미합니다.",
    ),
    "please_enter_conversation_name": MessageLookupByLibrary.simpleMessage(
      "대화 이름을 입력해주세요",
    ),
    "please_enter_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "난이도를 입력해주세요",
    ),
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage("마이크 사용 권한을 허용해주세요"),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage(
      "먼저 모델을 로드해주세요",
    ),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "작업 유형을 선택해주세요",
    ),
    "please_select_an_image_from_the_following_options":
        MessageLookupByLibrary.simpleMessage("다음 옵션에서 이미지를 선택해주세요"),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "응용 프로그램 언어를 선택해주세요",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage(
      "글꼴 크기를 선택해주세요",
    ),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "난이도를 선택해주세요",
    ),
    "please_wait_for_it_to_finish": MessageLookupByLibrary.simpleMessage(
      "추론이 완료될 때까지 기다려 주세요",
    ),
    "please_wait_for_the_model_to_finish_generating":
        MessageLookupByLibrary.simpleMessage("모델 생성 완료를 기다려 주세요"),
    "please_wait_for_the_model_to_generate":
        MessageLookupByLibrary.simpleMessage("모델 생성을 기다려 주세요"),
    "please_wait_for_the_model_to_load": MessageLookupByLibrary.simpleMessage(
      "모델 로드를 기다려 주세요",
    ),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("사전 정의된 음성"),
    "prefer": MessageLookupByLibrary.simpleMessage("사용"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("중국어 추론 사용"),
    "prefill": MessageLookupByLibrary.simpleMessage("사전 채우기"),
    "prompt": MessageLookupByLibrary.simpleMessage("프롬프트"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQ 그룹 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQ 그룹 2"),
    "quick_thinking": MessageLookupByLibrary.simpleMessage("빠른 사고"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage(
      "빠른 사고가 활성화되었습니다",
    ),
    "reason": MessageLookupByLibrary.simpleMessage("추론"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("추론 모드"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("음성 녹음 중..."),
    "regenerate": MessageLookupByLibrary.simpleMessage("재생성"),
    "remaining": MessageLookupByLibrary.simpleMessage("남은 시간:"),
    "rename": MessageLookupByLibrary.simpleMessage("이름 변경"),
    "reselect_model": MessageLookupByLibrary.simpleMessage("모델 다시 선택"),
    "reset": MessageLookupByLibrary.simpleMessage("초기화"),
    "resume": MessageLookupByLibrary.simpleMessage("재개"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV 채팅"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV 오셀로"),
    "save": MessageLookupByLibrary.simpleMessage("저장"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("QR 코드 스캔"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("검색 폭"),
    "search_depth": MessageLookupByLibrary.simpleMessage("검색 깊이"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("모델 선택"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("작업 유형 선택"),
    "select_from_library": MessageLookupByLibrary.simpleMessage("갤러리에서 선택"),
    "select_image": MessageLookupByLibrary.simpleMessage("이미지 선택"),
    "select_new_image": MessageLookupByLibrary.simpleMessage("새 이미지 선택"),
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage(
      "RWKV에게 메시지 보내기",
    ),
    "server_error": MessageLookupByLibrary.simpleMessage("서버 오류"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("세션 구성"),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("그리드 값 설정"),
    "settings": MessageLookupByLibrary.simpleMessage("설정"),
    "share": MessageLookupByLibrary.simpleMessage("공유"),
    "share_chat": MessageLookupByLibrary.simpleMessage("채팅 공유"),
    "show_stack": MessageLookupByLibrary.simpleMessage("사고 체인 스택 표시"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "최소 1.5B 모델을 선택하는 것이 좋으며, 더 큰 2.9B 모델이 더 좋습니다.",
    ),
    "small": MessageLookupByLibrary.simpleMessage("작게 (90%)"),
    "speed": MessageLookupByLibrary.simpleMessage("다운로드 속도:"),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage("새 채팅 시작"),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage("아래 버튼을 클릭하여 새 채팅을 시작하세요"),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("게임 시작"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("채팅 시작"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("추론 시작"),
    "stop": MessageLookupByLibrary.simpleMessage("중지"),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "저장소 권한이 부여되지 않았습니다",
    ),
    "str_model_selection_dialog_hint": MessageLookupByLibrary.simpleMessage(
      "최소 1.5B 모델을 선택하는 것이 좋으며, 더 큰 2.9B 모델이 더 좋습니다.",
    ),
    "submit": MessageLookupByLibrary.simpleMessage("제출"),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("초급"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("전문가"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("보통"),
    "system_mode": MessageLookupByLibrary.simpleMessage("시스템 설정 따르기"),
    "take_photo": MessageLookupByLibrary.simpleMessage("사진 찍기"),
    "technical_research_group": MessageLookupByLibrary.simpleMessage(
      "기술 연구 그룹",
    ),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage(
      "스도쿠가 유효하지 않습니다",
    ),
    "theme_dim": MessageLookupByLibrary.simpleMessage("어둡게"),
    "theme_light": MessageLookupByLibrary.simpleMessage("밝게"),
    "theme_lights_out": MessageLookupByLibrary.simpleMessage("검정"),
    "then_you_can_start_to_chat_with_rwkv":
        MessageLookupByLibrary.simpleMessage("그럼 이제 RWKV와 채팅을 시작할 수 있습니다"),
    "thinking": MessageLookupByLibrary.simpleMessage("생각 중..."),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("이것은 세상에서 가장 어려운 스도쿠입니다"),
    "thought_result": MessageLookupByLibrary.simpleMessage("생각 결과"),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("차례 넘기기"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("초대형 (140%)"),
    "update_now": MessageLookupByLibrary.simpleMessage("지금 업데이트"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("지금 사용하기"),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "값은 0에서 9 사이여야 합니다",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("매우 작게 (80%)"),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("음성 복제"),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage(
      "RWKV 사용을 환영합니다",
    ),
    "white": MessageLookupByLibrary.simpleMessage("백"),
    "white_score": MessageLookupByLibrary.simpleMessage("백 점수"),
    "white_wins": MessageLookupByLibrary.simpleMessage("백이 이겼습니다!"),
    "x_message_selected": MessageLookupByLibrary.simpleMessage("%d개 메시지 선택됨"),
    "you_are_now_using": m6,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "이제 RWKV와 채팅을 시작할 수 있습니다",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("목소리를 녹음하여 RWKV가 복사하도록 할 수 있습니다."),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "채팅할 역할을 선택할 수 있습니다",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "목소리가 너무 짧습니다. 목소리를 얻으려면 버튼을 더 오래 누르고 계세요.",
    ),
  };
}
