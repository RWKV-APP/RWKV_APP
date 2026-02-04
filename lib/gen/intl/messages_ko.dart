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

  static String m0(count) => "병렬 × ${count}";

  static String m1(count) => "각 추론마다 ${count}개의 메시지가 생성됩니다";

  static String m2(count) => "각 추론에서 ${count}개의 결과를 생성";

  static String m3(count) => "병렬 추론 실행 중, 동시에 ${count}개의 메시지 생성 중";

  static String m4(index) => "${index}번 메시지 선택됨";

  static String m5(demoName) => "${demoName}을(를) 탐험해 보세요";

  static String m6(maxLength) => "대화 이름은 ${maxLength}자를 초과할 수 없습니다";

  static String m7(length) => "ctx ${length}";

  static String m8(modelName) => "현재 모델: ${modelName}";

  static String m9(current, total) => "현재 진행률: ${current}/${total}";

  static String m10(current, total) => "현재 테스트 항목 (${current}/${total})";

  static String m11(path) => "메시지 기록은 다음 폴더에 저장됩니다:\n ${path}";

  static String m12(error) => "파일 삭제에 실패했습니다: ${error}";

  static String m13(successCount, failCount) =>
      "${successCount}개 파일 이동됨, ${failCount}개 실패";

  static String m14(value) => "Frequency Penalty: ${value}";

  static String m15(port) => "HTTP 서비스 (포트: ${port})";

  static String m16(flag, nameCN, nameEN) =>
      "${flag} ${nameCN}(${nameEN})의 목소리를 모방";

  static String m17(fileName) => "${fileName} 모방";

  static String m18(count) => "가져오기 성공: ${count} 개의 파일을 가져왔습니다";

  static String m19(folderName) => "로컬 폴더: ${folderName}";

  static String m20(memUsed, memFree) =>
      "사용된 메모리: ${memUsed}, 남은 메모리: ${memFree}";

  static String m21(count) => "대기열에 ${count}개의 메시지가 있습니다";

  static String m22(text) => "모델 출력: ${text}";

  static String m23(socName) => "귀하의 칩 ${socName}에 대한 NPU 지원은 아직 사용할 수 없습니다";

  static String m24(takePhoto) => "${takePhoto}를 클릭하세요. RWKV가 이미지의 텍스트를 번역합니다.";

  static String m25(error) => "빈 폴더 생성 실패: ${error}";

  static String m26(os) => "현재 OS(${os})에서는 폴더 열기 작업을 지원하지 않습니다.";

  static String m27(path) => "경로: ${path}";

  static String m28(value) => "Penalty Decay: ${value}";

  static String m29(index) => "메시지 ${index}에 설정할 샘플러 및 페널티 매개변수를 선택하세요";

  static String m30(value) => "Presence Penalty: ${value}";

  static String m31(count) => "대기열: ${count}";

  static String m32(count) => "선택됨 ${count}";

  static String m33(text) => "소스 텍스트: ${text}";

  static String m34(text) => "타겟 텍스트: ${text}";

  static String m35(value) => "Temperature: ${value}";

  static String m36(footer) => "추론${footer}-영어";

  static String m37(footer) => "추론${footer}-영어 길게";

  static String m38(footer) => "추론${footer}-영어 짧게";

  static String m39(footer) => "추론${footer}-빠름";

  static String m40(footer) => "추론${footer}-자동";

  static String m41(footer) => "추론${footer}-높음";

  static String m42(footer) => "추론${footer}-끔";

  static String m43(value) => "Top P: ${value}";

  static String m44(count) => "총 테스트 항목: ${count}";

  static String m45(port) => "WebSocket 서비스 (포트: ${port})";

  static String m46(id) => "창 ${id}";

  static String m47(count) => "${count}개의 탭";

  static String m48(modelName) => "현재 ${modelName}을(를) 사용 중입니다";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("정보"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("다음 오디오 파일에 따라:"),
    "accuracy": MessageLookupByLibrary.simpleMessage("정확도"),
    "adapting_more_inference_chips": MessageLookupByLibrary.simpleMessage(
      "더 많은 추론 칩에 대한 지원을 지속적으로 추가하고 있습니다. 기대해 주세요.",
    ),
    "add_local_folder": MessageLookupByLibrary.simpleMessage("로컬 폴더 추가"),
    "advance_settings": MessageLookupByLibrary.simpleMessage("고급 설정"),
    "all": MessageLookupByLibrary.simpleMessage("모두"),
    "all_done": MessageLookupByLibrary.simpleMessage("모두 완료"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("모든 프롬프트"),
    "all_the_same": MessageLookupByLibrary.simpleMessage("모두 같음"),
    "allow_background_downloads": MessageLookupByLibrary.simpleMessage(
      "백그라운드 다운로드 허용",
    ),
    "already_using_this_directory": MessageLookupByLibrary.simpleMessage(
      "이미 이 디렉토리를 사용 중입니다",
    ),
    "analysing_result": MessageLookupByLibrary.simpleMessage("검색 결과 분석 중"),
    "app_is_already_up_to_date": MessageLookupByLibrary.simpleMessage(
      "앱이 이미 최신 버전입니다",
    ),
    "appearance": MessageLookupByLibrary.simpleMessage("외관"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "응용 프로그램 내부 테스트 그룹",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage("응용 프로그램 언어"),
    "application_mode": MessageLookupByLibrary.simpleMessage("애플리케이션 모드"),
    "application_settings": MessageLookupByLibrary.simpleMessage("응용 프로그램 설정"),
    "apply": MessageLookupByLibrary.simpleMessage("적용"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage("이 모델을 삭제하시겠습니까?"),
    "ask_me_anything": MessageLookupByLibrary.simpleMessage("무엇이든 물어보세요..."),
    "assistant": MessageLookupByLibrary.simpleMessage("RWKV:"),
    "auto": MessageLookupByLibrary.simpleMessage("자동"),
    "auto_detect": MessageLookupByLibrary.simpleMessage("자동 감지"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("채팅으로 돌아가기"),
    "balanced": MessageLookupByLibrary.simpleMessage("균형"),
    "batch_completion": MessageLookupByLibrary.simpleMessage("배치 완성"),
    "batch_completion_settings": MessageLookupByLibrary.simpleMessage(
      "배치 완성 설정",
    ),
    "batch_inference": MessageLookupByLibrary.simpleMessage("병렬 추론"),
    "batch_inference_button": m0,
    "batch_inference_count": MessageLookupByLibrary.simpleMessage("병렬 추론 수"),
    "batch_inference_count_detail": m1,
    "batch_inference_count_detail_2": m2,
    "batch_inference_detail": MessageLookupByLibrary.simpleMessage(
      "병렬 추론을 활성화하면 RWKV가 동시에 여러 답변을 생성할 수 있습니다",
    ),
    "batch_inference_enable_or_not": MessageLookupByLibrary.simpleMessage(
      "병렬 추론 활성화 또는 비활성화",
    ),
    "batch_inference_running": m3,
    "batch_inference_selected": m4,
    "batch_inference_settings": MessageLookupByLibrary.simpleMessage(
      "병렬 추론 설정",
    ),
    "batch_inference_short": MessageLookupByLibrary.simpleMessage("병렬"),
    "batch_inference_width": MessageLookupByLibrary.simpleMessage("메시지 표시 너비"),
    "batch_inference_width_2": MessageLookupByLibrary.simpleMessage("결과 표시 너비"),
    "batch_inference_width_detail": MessageLookupByLibrary.simpleMessage(
      "병렬 추론 각 메시지 너비",
    ),
    "batch_inference_width_detail_2": MessageLookupByLibrary.simpleMessage(
      "각 결과의 너비",
    ),
    "beginner": MessageLookupByLibrary.simpleMessage("초보자"),
    "below_are_your_local_folders": MessageLookupByLibrary.simpleMessage(
      "아래는 로컬 폴더입니다",
    ),
    "benchmark": MessageLookupByLibrary.simpleMessage("벤치마크"),
    "benchmark_result": MessageLookupByLibrary.simpleMessage("벤치마크 결과"),
    "black": MessageLookupByLibrary.simpleMessage("흑"),
    "black_score": MessageLookupByLibrary.simpleMessage("흑 점수"),
    "black_wins": MessageLookupByLibrary.simpleMessage("흑이 이겼습니다!"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "봇 메시지가 편집되었습니다. 이제 새 메시지를 보낼 수 있습니다.",
    ),
    "browser_status": MessageLookupByLibrary.simpleMessage("브라우저 상태"),
    "cached_translations_disk": MessageLookupByLibrary.simpleMessage(
      "캐시된 번역 (디스크)",
    ),
    "cached_translations_memory": MessageLookupByLibrary.simpleMessage(
      "캐시된 번역 (메모리)",
    ),
    "camera": MessageLookupByLibrary.simpleMessage("카메라"),
    "can_not_generate": MessageLookupByLibrary.simpleMessage("생성할 수 없음"),
    "cancel": MessageLookupByLibrary.simpleMessage("취소"),
    "cancel_all_selection": MessageLookupByLibrary.simpleMessage("모두 선택 취소"),
    "cancel_download": MessageLookupByLibrary.simpleMessage("다운로드 취소"),
    "cancel_update": MessageLookupByLibrary.simpleMessage("지금은 업데이트 안 함"),
    "change": MessageLookupByLibrary.simpleMessage("변경"),
    "change_selected_image": MessageLookupByLibrary.simpleMessage("이미지 변경"),
    "chat": MessageLookupByLibrary.simpleMessage("채팅"),
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
    "chat_welcome_to_use": m5,
    "chat_with_rwkv_model": MessageLookupByLibrary.simpleMessage("RWKV 모델과 채팅"),
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage("사용하려면 먼저 모델을 다운로드해야 합니다"),
    "chatting": MessageLookupByLibrary.simpleMessage("채팅 중"),
    "check_for_updates": MessageLookupByLibrary.simpleMessage("업데이트 확인"),
    "chinese": MessageLookupByLibrary.simpleMessage("중국어"),
    "chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "중국어 사고 모드 템플릿",
    ),
    "chinese_translation_result": MessageLookupByLibrary.simpleMessage(
      "중국어 번역 결과",
    ),
    "chinese_web_search_template": MessageLookupByLibrary.simpleMessage(
      "중국어 웹 검색 템플릿",
    ),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage(
      "사전 정의된 캐릭터 선택",
    ),
    "clear": MessageLookupByLibrary.simpleMessage("지우기"),
    "clear_memory_cache": MessageLookupByLibrary.simpleMessage("메모리 캐시 지우기"),
    "clear_text": MessageLookupByLibrary.simpleMessage("텍스트 지우기"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "여기를 클릭하여 새 모델 선택",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "여기를 클릭하여 새 채팅 시작",
    ),
    "click_plus_add_local_folder": MessageLookupByLibrary.simpleMessage(
      "+ 를 클릭하여 로컬 폴더를 추가하세요. RWKV Chat 이 해당 폴더의 .pth 파일을 스캔하여 로드 가능한 가중치로 표시합니다",
    ),
    "click_plus_to_add_more_folders": MessageLookupByLibrary.simpleMessage(
      "+ 를 클릭하여 로컬 폴더 추가",
    ),
    "click_to_load_image": MessageLookupByLibrary.simpleMessage(
      "이미지를 로드하려면 클릭하세요",
    ),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage(
      "모델 선택을 클릭하세요",
    ),
    "close": MessageLookupByLibrary.simpleMessage("닫기"),
    "code_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "코드가 클립보드에 복사되었습니다",
    ),
    "colon": MessageLookupByLibrary.simpleMessage(": "),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "색상 테마 시스템 설정 따르기",
    ),
    "completion": MessageLookupByLibrary.simpleMessage("완성"),
    "completion_mode": MessageLookupByLibrary.simpleMessage("완성 모드"),
    "confirm": MessageLookupByLibrary.simpleMessage("확인"),
    "confirm_delete_file_message": MessageLookupByLibrary.simpleMessage(
      "이 파일은 로컬 디스크에서 영구적으로 삭제됩니다",
    ),
    "confirm_delete_file_title": MessageLookupByLibrary.simpleMessage(
      "이 파일을 삭제하시겠습니까?",
    ),
    "confirm_forget_location_message": MessageLookupByLibrary.simpleMessage(
      "잊으면 이 폴더는 로컬 폴더 목록에 더 이상 표시되지 않습니다",
    ),
    "confirm_forget_location_title": MessageLookupByLibrary.simpleMessage(
      "이 위치를 잊으시겠습니까?",
    ),
    "continue_download": MessageLookupByLibrary.simpleMessage("다운로드 계속"),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "더 작은 모델 계속 사용",
    ),
    "conversation_management": MessageLookupByLibrary.simpleMessage("관리"),
    "conversation_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "대화 이름은 비워둘 수 없습니다",
    ),
    "conversation_name_cannot_be_longer_than_30_characters": m6,
    "conversations": MessageLookupByLibrary.simpleMessage("대화"),
    "copy_code": MessageLookupByLibrary.simpleMessage("코드 복사"),
    "copy_text": MessageLookupByLibrary.simpleMessage("텍스트 복사"),
    "correct_count": MessageLookupByLibrary.simpleMessage("정답 수"),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage("위 버튼을 클릭하여 새로 생성"),
    "created_at": MessageLookupByLibrary.simpleMessage("생성 시간"),
    "creative_recommended": MessageLookupByLibrary.simpleMessage("창의적 (추천)"),
    "creative_recommended_short": MessageLookupByLibrary.simpleMessage("창의적"),
    "ctx_length_label": m7,
    "current_folder_has_no_local_models": MessageLookupByLibrary.simpleMessage(
      "이 폴더에 로컬 모델이 없습니다",
    ),
    "current_model": m8,
    "current_model_from_latest_json_not_pth":
        MessageLookupByLibrary.simpleMessage(
          "현재 로드된 모델은 latest.json 설정에서 가져온 것이며 로컬 .pth 파일이 아닙니다",
        ),
    "current_progress": m9,
    "current_task_tab_id": MessageLookupByLibrary.simpleMessage("현재 작업 탭 ID"),
    "current_task_text_length": MessageLookupByLibrary.simpleMessage(
      "현재 작업 텍스트 길이",
    ),
    "current_task_url": MessageLookupByLibrary.simpleMessage("현재 작업 URL"),
    "current_test_item": m10,
    "current_turn": MessageLookupByLibrary.simpleMessage("현재 차례"),
    "current_version": MessageLookupByLibrary.simpleMessage("현재 버전"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage("맞춤 난이도"),
    "custom_directory_set": MessageLookupByLibrary.simpleMessage(
      "사용자 지정 디렉토리가 설정되었습니다",
    ),
    "dark_mode": MessageLookupByLibrary.simpleMessage("다크 모드"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage("다크 모드 테마"),
    "decode": MessageLookupByLibrary.simpleMessage("디코딩"),
    "decode_param": MessageLookupByLibrary.simpleMessage("디코딩 매개변수"),
    "decode_param_comprehensive": MessageLookupByLibrary.simpleMessage(
      "종합 (시도해 볼 만함)",
    ),
    "decode_param_comprehensive_short": MessageLookupByLibrary.simpleMessage(
      "종합",
    ),
    "decode_param_conservative": MessageLookupByLibrary.simpleMessage(
      "보수적 (수학 및 코드에 적합)",
    ),
    "decode_param_conservative_short": MessageLookupByLibrary.simpleMessage(
      "보수적",
    ),
    "decode_param_creative": MessageLookupByLibrary.simpleMessage(
      "창의적 (글쓰기에 적합, 반복 감소)",
    ),
    "decode_param_creative_short": MessageLookupByLibrary.simpleMessage("창의적"),
    "decode_param_custom": MessageLookupByLibrary.simpleMessage(
      "사용자 지정 (수동 설정)",
    ),
    "decode_param_custom_short": MessageLookupByLibrary.simpleMessage("사용자 지정"),
    "decode_param_default_": MessageLookupByLibrary.simpleMessage(
      "기본값 (기본 설정)",
    ),
    "decode_param_default_short": MessageLookupByLibrary.simpleMessage("기본값"),
    "decode_param_fixed": MessageLookupByLibrary.simpleMessage("고정 (가장 보수적)"),
    "decode_param_fixed_short": MessageLookupByLibrary.simpleMessage("고정"),
    "decode_param_select_message": MessageLookupByLibrary.simpleMessage(
      "디코딩 매개변수를 통해 RWKV의 출력 스타일을 제어할 수 있습니다",
    ),
    "decode_param_select_title": MessageLookupByLibrary.simpleMessage(
      "디코딩 매개변수를 선택하세요",
    ),
    "decode_params_for_each_message": MessageLookupByLibrary.simpleMessage(
      "각 메시지의 디코딩 매개변수",
    ),
    "decode_params_for_each_message_detail":
        MessageLookupByLibrary.simpleMessage(
          "배치 추론에서 각 메시지의 디코딩 매개변수입니다. 클릭하여 편집할 수 있습니다.",
        ),
    "deep_web_search": MessageLookupByLibrary.simpleMessage("심층 네트워크 검색"),
    "default_font": MessageLookupByLibrary.simpleMessage("기본값"),
    "delete": MessageLookupByLibrary.simpleMessage("삭제"),
    "delete_all": MessageLookupByLibrary.simpleMessage("모두 삭제"),
    "delete_conversation": MessageLookupByLibrary.simpleMessage("대화 삭제"),
    "delete_conversation_message": MessageLookupByLibrary.simpleMessage(
      "대화를 삭제하시겠습니까?",
    ),
    "delete_finished": MessageLookupByLibrary.simpleMessage("삭제가 완료되었습니다"),
    "difficulty": MessageLookupByLibrary.simpleMessage("난이도"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "난이도는 0보다 커야 합니다",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "난이도는 81보다 작아야 합니다",
    ),
    "disabled": MessageLookupByLibrary.simpleMessage("비활성화됨"),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "dont_ask_again": MessageLookupByLibrary.simpleMessage("다시 묻지 않음"),
    "download_all": MessageLookupByLibrary.simpleMessage("모두 다운로드"),
    "download_all_missing": MessageLookupByLibrary.simpleMessage(
      "누락된 파일 모두 다운로드",
    ),
    "download_app": MessageLookupByLibrary.simpleMessage("앱 다운로드"),
    "download_failed": MessageLookupByLibrary.simpleMessage("다운로드 실패"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage(
      "브라우저에서 다운로드",
    ),
    "download_missing": MessageLookupByLibrary.simpleMessage("누락된 파일 다운로드"),
    "download_model": MessageLookupByLibrary.simpleMessage("모델 다운로드"),
    "download_now": MessageLookupByLibrary.simpleMessage("지금 다운로드"),
    "download_server_": MessageLookupByLibrary.simpleMessage(
      "다운로드 서버 (어떤 것이 빠른지 시도해보세요)",
    ),
    "download_source": MessageLookupByLibrary.simpleMessage("다운로드 소스"),
    "downloading": MessageLookupByLibrary.simpleMessage("다운로드 중"),
    "draw": MessageLookupByLibrary.simpleMessage("무승부!"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage("자동 덤프 메시지 기록"),
    "dump_see_files_alert_message": m11,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage(
      "알고리즘 개선에 도움을 주세요",
    ),
    "dump_started": MessageLookupByLibrary.simpleMessage("자동 덤프가 시작되었습니다"),
    "dump_stopped": MessageLookupByLibrary.simpleMessage("자동 덤프가 중지되었습니다"),
    "en_to_zh": MessageLookupByLibrary.simpleMessage("영->중"),
    "enabled": MessageLookupByLibrary.simpleMessage("활성화됨"),
    "end": MessageLookupByLibrary.simpleMessage("끝"),
    "english_translation_result": MessageLookupByLibrary.simpleMessage(
      "영어 번역 결과",
    ),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage(
          "기기 메모리가 충분한지 확인하세요. 그렇지 않으면 앱이 충돌할 수 있습니다.",
        ),
    "enter_text_to_translate": MessageLookupByLibrary.simpleMessage(
      "번역할 텍스트 입력...",
    ),
    "escape_characters_rendered": MessageLookupByLibrary.simpleMessage(
      "새로운 줄 문자가 표시되었습니다",
    ),
    "expert": MessageLookupByLibrary.simpleMessage("전문가"),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("RWKV 탐험"),
    "exploring": MessageLookupByLibrary.simpleMessage("탐험 중..."),
    "export_all_weight_files": MessageLookupByLibrary.simpleMessage(
      "모든 가중치 파일 내보내기",
    ),
    "export_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "다운로드한 모든 가중치 파일이 개별 파일로 선택한 디렉토리에 내보내집니다. 같은 이름의 파일은 건너뜁니다.",
    ),
    "export_conversation_failed": MessageLookupByLibrary.simpleMessage(
      "대화 내보내기 실패",
    ),
    "export_conversation_to_txt": MessageLookupByLibrary.simpleMessage(
      "대화를 .txt 파일로 내보내기",
    ),
    "export_data": MessageLookupByLibrary.simpleMessage("데이터 내보내기"),
    "export_failed": MessageLookupByLibrary.simpleMessage("내보내기 실패"),
    "export_success": MessageLookupByLibrary.simpleMessage("내보내기 성공"),
    "export_title": MessageLookupByLibrary.simpleMessage("대화 제목:"),
    "export_weight_file": MessageLookupByLibrary.simpleMessage("가중치 파일 내보내기"),
    "extra_large": MessageLookupByLibrary.simpleMessage("매우 크게 (130%)"),
    "failed_to_check_for_updates": MessageLookupByLibrary.simpleMessage(
      "업데이트 확인 실패",
    ),
    "failed_to_create_directory": MessageLookupByLibrary.simpleMessage(
      "디렉토리 생성에 실패했습니다",
    ),
    "failed_to_delete_file": m12,
    "feedback": MessageLookupByLibrary.simpleMessage("문제 보고"),
    "file_already_exists": MessageLookupByLibrary.simpleMessage("파일이 이미 존재합니다"),
    "file_not_found": MessageLookupByLibrary.simpleMessage("파일을 찾을 수 없습니다"),
    "file_not_supported": MessageLookupByLibrary.simpleMessage(
      "이 파일은 아직 지원되지 않습니다. 파일 이름이 올바른지 확인하세요",
    ),
    "file_path_not_found": MessageLookupByLibrary.simpleMessage(
      "파일 경로를 찾을 수 없습니다",
    ),
    "files": MessageLookupByLibrary.simpleMessage("개 파일"),
    "files_moved_with_failures": m13,
    "filter": MessageLookupByLibrary.simpleMessage(
      "안녕하세요, 이 질문에는 아직 답변할 수 없습니다. 다른 주제로 이야기해 볼까요?",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage("녹음 완료"),
    "folder_already_added": MessageLookupByLibrary.simpleMessage(
      "이 폴더가 이미 추가되었습니다",
    ),
    "folder_not_accessible_check_permission":
        MessageLookupByLibrary.simpleMessage("이 폴더에 액세스할 수 없습니다. 폴더 권한을 확인하세요"),
    "folder_not_found_on_device": MessageLookupByLibrary.simpleMessage(
      "기기에서 이 폴더를 찾을 수 없습니다",
    ),
    "follow_system": MessageLookupByLibrary.simpleMessage("시스템 설정 따르기"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "Twitter에서 저희를 팔로우하세요",
    ),
    "font_preview_markdown_asset": MessageLookupByLibrary.simpleMessage(
      "assets/lib/font_preview/font_preview_ko.md",
    ),
    "font_preview_user_message": MessageLookupByLibrary.simpleMessage(
      "Hello! 안녕하세요! 이것은 사용자 메시지의 미리보기입니다.",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("글꼴 설정"),
    "font_size": MessageLookupByLibrary.simpleMessage("글꼴 크기"),
    "font_size_default": MessageLookupByLibrary.simpleMessage("기본 (100%)"),
    "font_size_follow_system": MessageLookupByLibrary.simpleMessage(
      "글꼴 크기 시스템 설정 따르기",
    ),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage("강제 다크 모드"),
    "forget_location_success": MessageLookupByLibrary.simpleMessage(
      "위치를 잊었습니다",
    ),
    "forget_this_location": MessageLookupByLibrary.simpleMessage("이 위치 잊기"),
    "found_new_version_available": MessageLookupByLibrary.simpleMessage(
      "새 버전 사용 가능함을 발견했습니다",
    ),
    "frequency_penalty_with_value": m14,
    "from_model": MessageLookupByLibrary.simpleMessage("모델에서: %s"),
    "gallery": MessageLookupByLibrary.simpleMessage("갤러리"),
    "game_over": MessageLookupByLibrary.simpleMessage("게임 오버!"),
    "generate": MessageLookupByLibrary.simpleMessage("생성"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("세상에서 가장 어려운 스도쿠 생성"),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "무작위 스도쿠 퍼즐 생성",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("생성 중..."),
    "github_repository": MessageLookupByLibrary.simpleMessage("Github 저장소"),
    "go_to_home_page": MessageLookupByLibrary.simpleMessage("홈 페이지로 이동"),
    "go_to_settings": MessageLookupByLibrary.simpleMessage("설정으로 이동"),
    "got_it": MessageLookupByLibrary.simpleMessage("이해했습니다"),
    "hello_ask_me_anything": MessageLookupByLibrary.simpleMessage(
      "안녕하세요, 무엇이든 \n물어보세요...",
    ),
    "hide_stack": MessageLookupByLibrary.simpleMessage("사고 체인 스택 숨기기"),
    "hide_translations": MessageLookupByLibrary.simpleMessage("번역 숨기기"),
    "hint_chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "기본적으로 \'<think>好的\'를 사용하며, 2025-09-21 이전에 출시된 모델에서는 자동으로 \'<think>嗯\'을 사용합니다",
    ),
    "hint_system_prompt": MessageLookupByLibrary.simpleMessage(
      "예: System: 당신은 강력한 RWKV 대규모 언어 모델이며, 항상 사용자의 질문에 참을성 있게 답변합니다.",
    ),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "녹음을 위해 누르고, 보내려면 놓으세요",
    ),
    "home": MessageLookupByLibrary.simpleMessage("홈"),
    "http_service_port": m15,
    "human": MessageLookupByLibrary.simpleMessage("인간"),
    "hyphen": MessageLookupByLibrary.simpleMessage("-"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage(
      "RWKV가 말하게 하고 싶어요...",
    ),
    "idle": MessageLookupByLibrary.simpleMessage("대기"),
    "imitate": m16,
    "imitate_fle": m17,
    "imitate_target": MessageLookupByLibrary.simpleMessage("사용"),
    "import_all_weight_files": MessageLookupByLibrary.simpleMessage(
      "모든 가중치 파일 가져오기",
    ),
    "import_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "이 앱에서 내보낸 ZIP 파일을 선택하세요. ZIP 파일의 모든 가중치 파일이 가져와집니다. 같은 이름의 파일이 있으면 기존 파일이 덮어쓰기됩니다.",
    ),
    "import_all_weight_files_success": m18,
    "import_failed": MessageLookupByLibrary.simpleMessage("가져오기 실패"),
    "import_success": MessageLookupByLibrary.simpleMessage("가져오기 성공"),
    "import_weight_file": MessageLookupByLibrary.simpleMessage("가중치 파일 가져오기"),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage(
          "검색 깊이와 폭이 모두 2보다 클 때 컨텍스트 검색이 활성화됩니다",
        ),
    "inference_engine": MessageLookupByLibrary.simpleMessage("추론 엔진"),
    "inference_is_done": MessageLookupByLibrary.simpleMessage("🎉 추론 완료"),
    "inference_is_running": MessageLookupByLibrary.simpleMessage("추론 중"),
    "input_chinese_text_here": MessageLookupByLibrary.simpleMessage(
      "여기에 중국어 텍스트 입력",
    ),
    "input_english_text_here": MessageLookupByLibrary.simpleMessage(
      "여기에 영어 텍스트 입력",
    ),
    "intonations": MessageLookupByLibrary.simpleMessage("억양"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "모바일 장치에 최적화된 RWKV v7 시리즈 대규모 언어 모델(0.1B/0.4B/1.5B/2.9B 매개변수 버전 포함)을 탐색해 보세요. 로드 후 완전히 오프라인에서 실행되며 서버 통신이 필요 없습니다.",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage("유효하지 않은 스도쿠"),
    "invalid_value": MessageLookupByLibrary.simpleMessage("유효하지 않은 값"),
    "invalid_zip_file": MessageLookupByLibrary.simpleMessage(
      "잘못된 ZIP 파일이거나 파일 형식을 인식할 수 없습니다",
    ),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("당신 차례입니다~"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "저희 Discord 서버에 가입하세요",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage("커뮤니티 가입"),
    "just_watch_me": MessageLookupByLibrary.simpleMessage("😎 저를 보세요!"),
    "lambada_test": MessageLookupByLibrary.simpleMessage("LAMBADA 테스트"),
    "lan_server": MessageLookupByLibrary.simpleMessage("LAN 서버"),
    "large": MessageLookupByLibrary.simpleMessage("크게 (120%)"),
    "latest_version": MessageLookupByLibrary.simpleMessage("최신 버전"),
    "lazy": MessageLookupByLibrary.simpleMessage("게으른"),
    "lazy_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "게으른 사고 모드 템플릿",
    ),
    "license": MessageLookupByLibrary.simpleMessage("오픈 소스 라이선스"),
    "life_span": MessageLookupByLibrary.simpleMessage("Life Span"),
    "light_mode": MessageLookupByLibrary.simpleMessage("라이트 모드"),
    "line_break_rendered": MessageLookupByLibrary.simpleMessage(
      "새로운 줄 문자가 표시되었습니다",
    ),
    "load_": MessageLookupByLibrary.simpleMessage("로드"),
    "load_data": MessageLookupByLibrary.simpleMessage("데이터 로드"),
    "loaded": MessageLookupByLibrary.simpleMessage("로드됨"),
    "loading": MessageLookupByLibrary.simpleMessage("로드 중..."),
    "local_folder_name": m19,
    "local_pth_files_section_title": MessageLookupByLibrary.simpleMessage(
      "로컬 .pth 파일",
    ),
    "local_pth_option_files_in_config": MessageLookupByLibrary.simpleMessage(
      "설정 파일의 가중치",
    ),
    "local_pth_option_local_pth_files": MessageLookupByLibrary.simpleMessage(
      "로컬 .pth 파일",
    ),
    "local_pth_you_can_select": MessageLookupByLibrary.simpleMessage(
      "로컬 .pth 파일을 선택하여 로드할 수 있습니다",
    ),
    "medium": MessageLookupByLibrary.simpleMessage("중간 (110%)"),
    "memory_used": m20,
    "message_content": MessageLookupByLibrary.simpleMessage("메시지 내용"),
    "message_in_queue": m21,
    "mode": MessageLookupByLibrary.simpleMessage("모드"),
    "model": MessageLookupByLibrary.simpleMessage("모델"),
    "model_loading": MessageLookupByLibrary.simpleMessage("모델 로딩 중..."),
    "model_output": m22,
    "model_settings": MessageLookupByLibrary.simpleMessage("모델 설정"),
    "model_size_increased_please_open_a_new_conversation":
        MessageLookupByLibrary.simpleMessage(
          "모델 크기가 증가했습니다. 대화 품질을 높이려면 새 대화를 시작해주세요",
        ),
    "monospace_font_setting": MessageLookupByLibrary.simpleMessage("고정폭 글꼴 설정"),
    "more": MessageLookupByLibrary.simpleMessage("더 보기"),
    "more_questions": MessageLookupByLibrary.simpleMessage("더 많은 질문"),
    "moving_files": MessageLookupByLibrary.simpleMessage("파일 이동 중..."),
    "multi_thread": MessageLookupByLibrary.simpleMessage("다중 스레드"),
    "my_voice": MessageLookupByLibrary.simpleMessage("내 목소리"),
    "neko": MessageLookupByLibrary.simpleMessage("네코"),
    "network_error": MessageLookupByLibrary.simpleMessage("네트워크 오류"),
    "new_chat": MessageLookupByLibrary.simpleMessage("새 채팅"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("새 채팅 시작"),
    "new_chat_template": MessageLookupByLibrary.simpleMessage("새 채팅 템플릿"),
    "new_chat_template_helper_text": MessageLookupByLibrary.simpleMessage(
      "이 내용은 각 새 대화 시작 시 두 줄 바꿈으로 구분되어 삽입됩니다. 예:\n안녕하세요, 누구세요?\n\n안녕하세요, 저는 RWKV입니다. 무엇을 도와드릴까요?",
    ),
    "new_conversation": MessageLookupByLibrary.simpleMessage("새 대화"),
    "new_game": MessageLookupByLibrary.simpleMessage("새 게임"),
    "new_version_available": MessageLookupByLibrary.simpleMessage("새 버전 사용 가능"),
    "new_version_found": MessageLookupByLibrary.simpleMessage("새 버전 발견"),
    "no_audio_file": MessageLookupByLibrary.simpleMessage("오디오 파일 없음"),
    "no_browser_windows_connected": MessageLookupByLibrary.simpleMessage(
      "연결된 브라우저 창 없음",
    ),
    "no_cell_available": MessageLookupByLibrary.simpleMessage("놓을 수 있는 칸 없음"),
    "no_conversation_yet": MessageLookupByLibrary.simpleMessage("아직 대화가 없습니다"),
    "no_conversations_yet": MessageLookupByLibrary.simpleMessage("아직 대화가 없습니다"),
    "no_data": MessageLookupByLibrary.simpleMessage("데이터 없음"),
    "no_files_in_zip": MessageLookupByLibrary.simpleMessage(
      "ZIP 파일에서 유효한 가중치 파일을 찾을 수 없습니다",
    ),
    "no_latest_version_info": MessageLookupByLibrary.simpleMessage(
      "최신 버전 정보가 없습니다",
    ),
    "no_local_folders": MessageLookupByLibrary.simpleMessage(
      ".pth 파일이 포함된 로컬 폴더를 아직 추가하지 않았습니다",
    ),
    "no_local_pth_loaded_yet": MessageLookupByLibrary.simpleMessage(
      "로드된 로컬 .pth 파일이 없습니다",
    ),
    "no_message_to_export": MessageLookupByLibrary.simpleMessage("내보낼 메시지 없음"),
    "no_model_selected": MessageLookupByLibrary.simpleMessage("선택된 모델 없음"),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("스도쿠 없음"),
    "no_weight_files_guide_message": MessageLookupByLibrary.simpleMessage(
      "아직 가중치 파일을 다운로드하지 않았습니다. 홈 페이지로 이동하여 다운로드하고 앱을 체험해보세요.",
    ),
    "no_weight_files_guide_title": MessageLookupByLibrary.simpleMessage(
      "가중치 파일 없음",
    ),
    "no_weight_files_to_export": MessageLookupByLibrary.simpleMessage(
      "내보낼 가중치 파일이 없습니다",
    ),
    "not_all_the_same": MessageLookupByLibrary.simpleMessage("모두 같지 않음"),
    "not_syncing": MessageLookupByLibrary.simpleMessage("동기화되지 않음"),
    "npu_not_supported_title": m23,
    "number": MessageLookupByLibrary.simpleMessage("숫자"),
    "nyan_nyan": MessageLookupByLibrary.simpleMessage("야옹~~, 야옹~~"),
    "ocr_guide_text": m24,
    "ocr_title": MessageLookupByLibrary.simpleMessage("OCR"),
    "off": MessageLookupByLibrary.simpleMessage("끔"),
    "offline_translator": MessageLookupByLibrary.simpleMessage("오프라인 번역기"),
    "offline_translator_detail": MessageLookupByLibrary.simpleMessage(
      "기기에서 텍스트 번역",
    ),
    "offline_translator_server": MessageLookupByLibrary.simpleMessage(
      "오프라인 번역 서버",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("확인"),
    "open_containing_folder": MessageLookupByLibrary.simpleMessage("포함 폴더 열기"),
    "open_database_folder": MessageLookupByLibrary.simpleMessage(
      "데이터베이스 폴더 열기",
    ),
    "open_debug_log_panel": MessageLookupByLibrary.simpleMessage(
      "디버그 로그 패널 열기",
    ),
    "open_folder": MessageLookupByLibrary.simpleMessage("폴더 열기"),
    "open_folder_create_failed": m25,
    "open_folder_created_success": MessageLookupByLibrary.simpleMessage(
      "빈 폴더가 성공적으로 생성되었습니다.",
    ),
    "open_folder_creating_empty": MessageLookupByLibrary.simpleMessage(
      "폴더가 존재하지 않아 빈 폴더를 생성 중입니다.",
    ),
    "open_folder_path_is_null": MessageLookupByLibrary.simpleMessage(
      "폴더 경로가 비어 있습니다.",
    ),
    "open_folder_unsupported_on_platform": m26,
    "open_state_panel": MessageLookupByLibrary.simpleMessage("State Panel 열기"),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage(
          "또는 RWKV가 복사하도록 wav 파일을 선택할 수 있습니다.",
        ),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "또는 새 빈 채팅을 시작할 수 있습니다",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV 오셀로"),
    "other_files": MessageLookupByLibrary.simpleMessage(
      "기타 파일 (이러한 파일은 만료되었거나 더 이상 지원되지 않는 가중치로, RWKV Chat 에서 더 이상 사용할 필요가 없을 수 있습니다)",
    ),
    "output": MessageLookupByLibrary.simpleMessage("출력"),
    "overseas": MessageLookupByLibrary.simpleMessage("(해외)"),
    "overwrite": MessageLookupByLibrary.simpleMessage("덮어쓰기"),
    "overwrite_file_confirmation": MessageLookupByLibrary.simpleMessage(
      "파일이 이미 존재합니다. 덮어쓰시겠습니까?",
    ),
    "parameter_description": MessageLookupByLibrary.simpleMessage("매개변수 설명"),
    "parameter_description_detail": MessageLookupByLibrary.simpleMessage(
      "Temperature: 출력의 무작위성을 제어합니다. 높은 값(예: 0.8)은 더 창의적이고 무작위적으로, 낮은 값(예: 0.2)은 더 집중적이고 결정적으로 만듭니다.\n\nTop P: 출력의 다양성을 제어합니다. 모델은 누적 확률이 Top P에 도달하는 토큰만 고려합니다. 낮은 값(예: 0.5)은 확률이 낮은 단어를 무시하여 관련성을 높입니다.\n\nPresence Penalty: 토큰이 텍스트에 이미 나타났는지 여부에 따라 페널티를 부여합니다. 양수 값은 새로운 주제에 대해 이야기할 가능성을 높입니다.\n\nFrequency Penalty: 텍스트 내 빈도에 따라 토큰에 페널티를 부여합니다. 양수 값은 같은 줄을 그대로 반복할 가능성을 줄입니다.\n\nPenalty Decay: 거리에 따른 페널티 감소를 제어합니다.",
    ),
    "path_label": m27,
    "pause": MessageLookupByLibrary.simpleMessage("일시 정지"),
    "penalty_decay_with_value": m28,
    "performance_test": MessageLookupByLibrary.simpleMessage("성능 테스트"),
    "performance_test_description": MessageLookupByLibrary.simpleMessage(
      "속도와 정확도 테스트",
    ),
    "perplexity": MessageLookupByLibrary.simpleMessage("혼란도"),
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
    "please_manually_migrate_files": MessageLookupByLibrary.simpleMessage(
      "경로가 업데이트되었습니다. 파일 이동이 필요하면 수동으로 선택하여 이동하세요.",
    ),
    "please_select_a_branch_to_continue_the_conversation":
        MessageLookupByLibrary.simpleMessage("대화를 계속하려면 분기를 선택해주세요"),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "작업 유형을 선택해주세요",
    ),
    "please_select_an_image_first": MessageLookupByLibrary.simpleMessage(
      "먼저 이미지를 선택해주세요",
    ),
    "please_select_an_image_from_the_following_options":
        MessageLookupByLibrary.simpleMessage("다음 옵션에서 이미지를 선택해주세요"),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "응용 프로그램 언어를 선택해주세요",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage(
      "글꼴 크기를 선택해주세요",
    ),
    "please_select_model": MessageLookupByLibrary.simpleMessage("모델을 선택해주세요"),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "난이도를 선택해주세요",
    ),
    "please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index":
        m29,
    "please_select_the_sampler_and_penalty_parameters_to_set_for_all_messages":
        MessageLookupByLibrary.simpleMessage(
          "모든 메시지에 설정할 샘플러 및 페널티 매개변수를 선택하세요",
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
    "power_user": MessageLookupByLibrary.simpleMessage("고급 사용자"),
    "prebuilt": MessageLookupByLibrary.simpleMessage("사전 정의된"),
    "prebuilt_models_intro": MessageLookupByLibrary.simpleMessage(
      "아래는 RWKV Chat이 미리 양자화한 모델입니다",
    ),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage("사전 정의된 음성"),
    "prefer": MessageLookupByLibrary.simpleMessage("사용"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("중국어 추론 사용"),
    "prefill": MessageLookupByLibrary.simpleMessage("사전 채우기"),
    "presence_penalty_with_value": m30,
    "prompt": MessageLookupByLibrary.simpleMessage("프롬프트"),
    "prompt_template": MessageLookupByLibrary.simpleMessage("프롬프트 템플릿"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("QQ 그룹 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("QQ 그룹 2"),
    "queued_x": m31,
    "quick_thinking": MessageLookupByLibrary.simpleMessage("빠른 사고"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage(
      "빠른 사고가 활성화되었습니다",
    ),
    "reached_bottom": MessageLookupByLibrary.simpleMessage("기대해 주세요"),
    "real_time_update": MessageLookupByLibrary.simpleMessage("실시간 업데이트"),
    "reason": MessageLookupByLibrary.simpleMessage("추론"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("추론 모드"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage("음성 녹음 중..."),
    "reference_source": MessageLookupByLibrary.simpleMessage("참조 소스"),
    "refresh": MessageLookupByLibrary.simpleMessage("새로고침"),
    "refresh_complete": MessageLookupByLibrary.simpleMessage("새로고침 완료"),
    "refreshed": MessageLookupByLibrary.simpleMessage("새로고침"),
    "regenerate": MessageLookupByLibrary.simpleMessage("재생성"),
    "remaining": MessageLookupByLibrary.simpleMessage("남은 시간:"),
    "rename": MessageLookupByLibrary.simpleMessage("이름 변경"),
    "report_an_issue_on_github": MessageLookupByLibrary.simpleMessage(
      "Github에 문제 보고",
    ),
    "reselect_model": MessageLookupByLibrary.simpleMessage("모델 다시 선택"),
    "reset": MessageLookupByLibrary.simpleMessage("초기화"),
    "reset_to_default": MessageLookupByLibrary.simpleMessage("기본값으로 재설정"),
    "reset_to_default_directory": MessageLookupByLibrary.simpleMessage(
      "기본 디렉토리로 재설정되었습니다",
    ),
    "restore_default": MessageLookupByLibrary.simpleMessage("기본값으로 복원"),
    "result": MessageLookupByLibrary.simpleMessage("결과"),
    "resume": MessageLookupByLibrary.simpleMessage("재개"),
    "role_play": MessageLookupByLibrary.simpleMessage("역할 놀이"),
    "role_play_intro": MessageLookupByLibrary.simpleMessage("좋아하는 캐릭터를 연기하세요"),
    "runtime_log_panel": MessageLookupByLibrary.simpleMessage("런타임 로그 패널"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV 채팅"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV 오셀로"),
    "save": MessageLookupByLibrary.simpleMessage("저장"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("QR 코드 스캔"),
    "scanning_folder_for_pth": MessageLookupByLibrary.simpleMessage(
      "이 폴더에서 .pth 파일 스캔 중",
    ),
    "screen_width": MessageLookupByLibrary.simpleMessage("화면 너비"),
    "search": MessageLookupByLibrary.simpleMessage("검색"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("검색 폭"),
    "search_depth": MessageLookupByLibrary.simpleMessage("검색 깊이"),
    "search_failed": MessageLookupByLibrary.simpleMessage("검색 실패"),
    "searching": MessageLookupByLibrary.simpleMessage("검색 중..."),
    "see": MessageLookupByLibrary.simpleMessage("이미지 문답"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("모델 선택"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage("작업 유형 선택"),
    "select_all": MessageLookupByLibrary.simpleMessage("모두 선택"),
    "select_from_file": MessageLookupByLibrary.simpleMessage("이미지 파일 선택"),
    "select_from_library": MessageLookupByLibrary.simpleMessage("갤러리에서 선택"),
    "select_image": MessageLookupByLibrary.simpleMessage("이미지 선택"),
    "select_local_pth_file_button": MessageLookupByLibrary.simpleMessage(
      "로컬 .pth 파일 선택",
    ),
    "select_model": MessageLookupByLibrary.simpleMessage("모델 선택"),
    "select_new_image": MessageLookupByLibrary.simpleMessage("이미지 선택"),
    "select_the_decode_parameters_to_set_all_to_for_index":
        MessageLookupByLibrary.simpleMessage(
          "아래에서 사전 설정을 선택하거나 \'사용자 지정\'을 탭하여 수동으로 구성하세요",
        ),
    "select_weights_or_local_pth_hint": MessageLookupByLibrary.simpleMessage(
      "설정 파일의 가중치 또는 로컬 .pth 파일 선택",
    ),
    "selected_count": m32,
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage(
      "RWKV에게 메시지 보내기",
    ),
    "server_error": MessageLookupByLibrary.simpleMessage("서버 오류"),
    "session_configuration": MessageLookupByLibrary.simpleMessage("세션 구성"),
    "set_all_batch_params": MessageLookupByLibrary.simpleMessage(
      "모든 배치 매개변수 설정",
    ),
    "set_all_to_question_mark": MessageLookupByLibrary.simpleMessage(
      "모두 ???로 설정",
    ),
    "set_custom_directory": MessageLookupByLibrary.simpleMessage(
      "사용자 지정 디렉토리 설정",
    ),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage("그리드 값 설정"),
    "settings": MessageLookupByLibrary.simpleMessage("설정"),
    "share": MessageLookupByLibrary.simpleMessage("공유"),
    "share_chat": MessageLookupByLibrary.simpleMessage("채팅 공유"),
    "show_escape_characters": MessageLookupByLibrary.simpleMessage(
      "새로운 줄 문자 표시",
    ),
    "show_prefill_log_only": MessageLookupByLibrary.simpleMessage(
      "Prefill 로그만 표시",
    ),
    "show_stack": MessageLookupByLibrary.simpleMessage("사고 체인 스택 표시"),
    "show_translations": MessageLookupByLibrary.simpleMessage("번역 표시"),
    "single_thread": MessageLookupByLibrary.simpleMessage("단일 스레드"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "최소 1.5B 모델을 선택하는 것이 좋으며, 더 큰 2.9B 모델이 더 좋습니다.",
    ),
    "skip_this_version": MessageLookupByLibrary.simpleMessage("이 버전 건너뛰기"),
    "small": MessageLookupByLibrary.simpleMessage("작게 (90%)"),
    "source_code": MessageLookupByLibrary.simpleMessage("소스 코드"),
    "source_text": m33,
    "speed": MessageLookupByLibrary.simpleMessage("다운로드 속도:"),
    "start": MessageLookupByLibrary.simpleMessage("시작"),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage("새 채팅 시작"),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage("아래 버튼을 클릭하여 새 채팅을 시작하세요"),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("게임 시작"),
    "start_download_updates_": MessageLookupByLibrary.simpleMessage(
      "백그라운드 업데이트 다운로드 시작...",
    ),
    "start_service": MessageLookupByLibrary.simpleMessage("서비스 시작"),
    "start_service_and_open_browser": MessageLookupByLibrary.simpleMessage(
      "서비스를 시작하고 지원되는 브라우저 페이지를 여세요.",
    ),
    "start_test": MessageLookupByLibrary.simpleMessage("테스트 시작"),
    "start_testing": MessageLookupByLibrary.simpleMessage("테스트 시작"),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("채팅 시작"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("추론 시작"),
    "starting": MessageLookupByLibrary.simpleMessage("시작 중..."),
    "state_list": MessageLookupByLibrary.simpleMessage("State 목록"),
    "state_panel": MessageLookupByLibrary.simpleMessage("상태 패널"),
    "status": MessageLookupByLibrary.simpleMessage("상태"),
    "stop": MessageLookupByLibrary.simpleMessage("중지"),
    "stop_service": MessageLookupByLibrary.simpleMessage("서비스 중지"),
    "stop_test": MessageLookupByLibrary.simpleMessage("테스트 중지"),
    "stopping": MessageLookupByLibrary.simpleMessage("중지 중..."),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "저장소 권한이 부여되지 않았습니다",
    ),
    "str_downloading_info": MessageLookupByLibrary.simpleMessage(
      "다운로드 %.1f% 속도 %.1fMB/s 남은 %s",
    ),
    "str_model_selection_dialog_hint": MessageLookupByLibrary.simpleMessage(
      "최소 1.5B 모델을 선택하는 것이 좋으며, 더 큰 2.9B 모델이 더 좋습니다.",
    ),
    "str_please_disable_battery_opt_": MessageLookupByLibrary.simpleMessage(
      "백그라운드 다운로드를 허용하려면 배터리 최적화를 비활성화하세요. 그렇지 않으면 다른 앱으로 전환할 때 다운로드가 일시 중지될 수 있습니다.",
    ),
    "str_please_select_app_mode_": MessageLookupByLibrary.simpleMessage(
      "AI 및 LLM에 대한 숙련도에 따라 앱 모드를 선택하세요.",
    ),
    "style": MessageLookupByLibrary.simpleMessage("스타일"),
    "submit": MessageLookupByLibrary.simpleMessage("제출"),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("초급"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("전문가"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("보통"),
    "suggest": MessageLookupByLibrary.simpleMessage("제안"),
    "switch_to_creative_mode_for_better_exp":
        MessageLookupByLibrary.simpleMessage(
          "더 나은 경험을 위해 \'창의적 모드\'로 전환하는 것을 권장합니다",
        ),
    "syncing": MessageLookupByLibrary.simpleMessage("동기화 중"),
    "system_mode": MessageLookupByLibrary.simpleMessage("시스템 설정 따르기"),
    "system_prompt": MessageLookupByLibrary.simpleMessage("시스템 프롬프트"),
    "take_photo": MessageLookupByLibrary.simpleMessage("사진 찍기"),
    "target_text": m34,
    "technical_research_group": MessageLookupByLibrary.simpleMessage(
      "기술 연구 그룹",
    ),
    "temperature_with_value": m35,
    "test_data": MessageLookupByLibrary.simpleMessage("테스트 데이터"),
    "test_result": MessageLookupByLibrary.simpleMessage("테스트 결과"),
    "test_results": MessageLookupByLibrary.simpleMessage("테스트 결과"),
    "testing": MessageLookupByLibrary.simpleMessage("테스트 중..."),
    "text": MessageLookupByLibrary.simpleMessage("텍스트"),
    "text_completion_mode": MessageLookupByLibrary.simpleMessage("텍스트 완성 모드"),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage(
      "스도쿠가 유효하지 않습니다",
    ),
    "theme_dim": MessageLookupByLibrary.simpleMessage("어둡게"),
    "theme_light": MessageLookupByLibrary.simpleMessage("밝게"),
    "theme_lights_out": MessageLookupByLibrary.simpleMessage("검정"),
    "then_you_can_start_to_chat_with_rwkv":
        MessageLookupByLibrary.simpleMessage("그럼 이제 RWKV와 채팅을 시작할 수 있습니다"),
    "think_button_mode_en": m36,
    "think_button_mode_en_long": m37,
    "think_button_mode_en_short": m38,
    "think_button_mode_fast": m39,
    "think_mode_selector_message": MessageLookupByLibrary.simpleMessage(
      "추론 모드는 모델의 추론 성능에 영향을 미칩니다",
    ),
    "think_mode_selector_title": MessageLookupByLibrary.simpleMessage(
      "추론 모드를 선택해주세요",
    ),
    "thinking": MessageLookupByLibrary.simpleMessage("생각 중..."),
    "thinking_mode_alert_footer": MessageLookupByLibrary.simpleMessage("모드"),
    "thinking_mode_auto": m40,
    "thinking_mode_high": m41,
    "thinking_mode_off": m42,
    "thinking_mode_template": MessageLookupByLibrary.simpleMessage("사고 모드 템플릿"),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("이것은 세상에서 가장 어려운 스도쿠입니다"),
    "this_model_does_not_support_batch_inference":
        MessageLookupByLibrary.simpleMessage(
          "이 모델은 병렬 추론을 지원하지 않습니다. \'batch\' 태그가 있는 모델을 선택해주세요",
        ),
    "thought_result": MessageLookupByLibrary.simpleMessage("생각 결과"),
    "top_p_with_value": m43,
    "total_count": MessageLookupByLibrary.simpleMessage("총 수"),
    "total_disk_usage": MessageLookupByLibrary.simpleMessage("저장 공간 사용량"),
    "total_test_items": m44,
    "translate": MessageLookupByLibrary.simpleMessage("번역"),
    "translating": MessageLookupByLibrary.simpleMessage("번역 중..."),
    "translation": MessageLookupByLibrary.simpleMessage("번역"),
    "translator_debug_info": MessageLookupByLibrary.simpleMessage("번역기 디버그 정보"),
    "tts": MessageLookupByLibrary.simpleMessage("텍스트 음성 변환"),
    "tts_detail": MessageLookupByLibrary.simpleMessage("RWKV가 음성을 출력하도록 허용"),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("차례 넘기기"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ui_font_setting": MessageLookupByLibrary.simpleMessage("UI 글꼴 설정"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("초대형 (140%)"),
    "unknown": MessageLookupByLibrary.simpleMessage("알 수 없음"),
    "unzipping": MessageLookupByLibrary.simpleMessage("압축 해제 중"),
    "update_now": MessageLookupByLibrary.simpleMessage("지금 업데이트"),
    "updated_at": MessageLookupByLibrary.simpleMessage("업데이트 시간"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("지금 사용하기"),
    "user": MessageLookupByLibrary.simpleMessage("사용자:"),
    "using_custom_directory": MessageLookupByLibrary.simpleMessage(
      "사용자 지정 디렉토리 사용 중",
    ),
    "using_default_directory": MessageLookupByLibrary.simpleMessage(
      "기본 디렉토리 사용 중",
    ),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "값은 0에서 9 사이여야 합니다",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("매우 작게 (80%)"),
    "visual_understanding_and_ocr": MessageLookupByLibrary.simpleMessage(
      "시각적 이해 및 OCR",
    ),
    "voice_cloning": MessageLookupByLibrary.simpleMessage("음성 복제"),
    "we_support_npu_socs": MessageLookupByLibrary.simpleMessage(
      "현재 다음 SoC 칩의 NPU를 지원합니다",
    ),
    "web_search": MessageLookupByLibrary.simpleMessage("네트워크 검색"),
    "web_search_template": MessageLookupByLibrary.simpleMessage("웹 검색 템플릿"),
    "websocket_service_port": m45,
    "weights_mangement": MessageLookupByLibrary.simpleMessage("가중치 파일 관리"),
    "weights_saving_directory": MessageLookupByLibrary.simpleMessage(
      "가중치 파일 저장 디렉토리",
    ),
    "welcome_to_rwkv_chat": MessageLookupByLibrary.simpleMessage(
      "RWKV 채팅에 오신 것을 환영합니다",
    ),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage(
      "RWKV 사용을 환영합니다",
    ),
    "what_is_pth_file_message": MessageLookupByLibrary.simpleMessage(
      ".pth 파일은 다운로드 서버 없이 로컬 파일 시스템에서 직접 로드하는 가중치 파일입니다.\n\nPyTorch로 학습한 모델은 일반적으로 .pth 파일로 저장됩니다.\n\nRWKV Chat은 .pth 파일 로드를 지원합니다.",
    ),
    "what_is_pth_file_title": MessageLookupByLibrary.simpleMessage(
      ".pth 파일이란?",
    ),
    "white": MessageLookupByLibrary.simpleMessage("백"),
    "white_score": MessageLookupByLibrary.simpleMessage("백 점수"),
    "white_wins": MessageLookupByLibrary.simpleMessage("백이 이겼습니다!"),
    "window_id": m46,
    "world": MessageLookupByLibrary.simpleMessage("See"),
    "x_message_selected": MessageLookupByLibrary.simpleMessage("%d개 메시지 선택됨"),
    "x_pages_found": MessageLookupByLibrary.simpleMessage("%d페이지 찾음"),
    "x_tabs": m47,
    "you_are_now_using": m48,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "이제 RWKV와 채팅을 시작할 수 있습니다",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage("목소리를 녹음하여 RWKV가 복사하도록 할 수 있습니다."),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "채팅할 역할을 선택할 수 있습니다",
    ),
    "your_device": MessageLookupByLibrary.simpleMessage("기기: "),
    "your_voice_is_empty": MessageLookupByLibrary.simpleMessage(
      "음성 데이터가 비어 있습니다. 마이크를 확인해주세요",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "목소리가 너무 짧습니다. 목소리를 얻으려면 버튼을 더 오래 누르고 계세요.",
    ),
    "zh_to_en": MessageLookupByLibrary.simpleMessage("중->영"),
  };
}
