// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru locale. All the
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
  String get localeName => 'ru';

  static String m0(error) => "Ошибка: ${error}";

  static String m1(error) => "Не удалось запустить API сервер: ${error}";

  static String m2(port) => "API сервер запущен на порту ${port}";

  static String m3(count) => "Ветка × ${count}";

  static String m4(count) => "Каждый вывод сгенерирует ${count} сообщений";

  static String m5(count) => "Каждый вывод сгенерирует ${count} результата";

  static String m6(count) => "Параллельный инференс: ${count} выходов";

  static String m7(index) => "Выбран выход ${index}";

  static String m8(batch) => "Batch ${batch}";

  static String m9(first, last, count) =>
      "Batch ${first}-${last} (${count} запусков)";

  static String m10(batch) => "Batch ${batch}";

  static String m11(count) => "Поддерживается до Batch ${count}";

  static String m12(batch, current, total) =>
      "Batch ${batch} · ${current}/${total}";

  static String m13(current, total, speed) =>
      "${current}/${total} · ${speed} t/s";

  static String m14(speed) => "Пик Decode: ${speed} t/s";

  static String m15(progress, speed) => "${progress}% · ${speed} t/s";

  static String m16(prefillSpeed, decodeSpeed) =>
      "Prefill ${prefillSpeed} t/s · Decode ${decodeSpeed} t/s";

  static String m17(current, total, phase) => "${current}/${total} · ${phase}";

  static String m18(demoName) => "Добро пожаловать в ${demoName}";

  static String m19(maxLength) =>
      "Название диалога не может превышать ${maxLength} символов";

  static String m20(length) => "ctx ${length}";

  static String m21(modelName) => "Текущая модель: ${modelName}";

  static String m22(current, total) => "Текущий прогресс: ${current}/${total}";

  static String m23(current, total) =>
      "Текущий тестовый элемент (${current}/${total})";

  static String m24(path) =>
      "Записи сообщений будут сохранены в следующей папке\n ${path}";

  static String m25(error) => "Не удалось удалить файл: ${error}";

  static String m26(successCount, failCount) =>
      "${successCount} файлов перемещено, ${failCount} не удалось";

  static String m27(value) => "Frequency Penalty: ${value}";

  static String m28(port) => "HTTP-сервис (Порт: ${port})";

  static String m29(flag, nameCN, nameEN) =>
      "Имитировать голос ${flag} ${nameEN} (${nameCN})";

  static String m30(fileName) => "Имитировать ${fileName}";

  static String m31(count) => "Импорт успешен: импортировано ${count} файлов";

  static String m32(percent) => "Загрузка ${percent}%";

  static String m33(folderName) => "Локальная папка: ${folderName}";

  static String m34(memUsed, memFree) =>
      "Использовано памяти: ${memUsed}, Свободно памяти: ${memFree}";

  static String m35(count) => "В очереди ${count} сообщений";

  static String m36(text) => "Вывод модели: ${text}";

  static String m37(socName) =>
      "Поддержка NPU для вашего чипа ${socName} пока недоступна";

  static String m38(takePhoto) =>
      "Нажмите ${takePhoto}. RWKV переведет текст на изображении.";

  static String m39(error) => "Не удалось создать пустую папку: ${error}";

  static String m40(os) =>
      "Открытие папки не поддерживается в текущей ОС (${os}).";

  static String m41(path) => "Путь: ${path}";

  static String m42(value) => "Penalty Decay: ${value}";

  static String m43(index) =>
      "Пожалуйста, выберите параметры сэмплера и штрафов для сообщения ${index}";

  static String m44(percent) => "Прогресс prefill ${percent}";

  static String m45(value) => "Presence Penalty: ${value}";

  static String m46(count) =>
      "Нажмите Generate, и RWKV превратит выбранное начало в максимум ${count} вариантов вопросов.";

  static String m47(count) => "В очереди: ${count}";

  static String m48(count) =>
      "Эта модель не поддерживает ${count} стилей ответа";

  static String m49(count) => "Выбрано ${count}";

  static String m50(text) => "Исходный текст: ${text}";

  static String m51(text) => "Целевой текст: ${text}";

  static String m52(value) => "Temperature: ${value}";

  static String m53(footer) => "Мышление${footer}-Англ";

  static String m54(footer) => "Мышление${footer}-Англ Длинно";

  static String m55(footer) => "Мышление${footer}-Англ Коротко";

  static String m56(footer) => "Мышление${footer}-Быстро";

  static String m57(footer) => "Мышление${footer}-Авто";

  static String m58(footer) => "Мышление${footer}-Вкл";

  static String m59(footer) => "Мышление${footer}-Выкл";

  static String m60(value) => "Top P: ${value}";

  static String m61(count) => "Всего тестовых элементов: ${count}";

  static String m62(port) => "WebSocket-сервис (Порт: ${port})";

  static String m63(id) => "Окно ${id}";

  static String m64(buildArchitecture, operatingSystemArchitecture, url) =>
      "Приложение собрано для ${buildArchitecture}, а архитектура Windows — ${operatingSystemArchitecture}.\n\nПерейдите на официальную страницу загрузки и скачайте подходящий исполняемый файл:\n${url}";

  static String m65(buildArchitecture, operatingSystemArchitecture, url) =>
      "Обнаружено несоответствие архитектуры: приложение собрано для ${buildArchitecture}, а архитектура Windows — ${operatingSystemArchitecture}. Скачайте подходящую версию с официальной страницы: ${url}";

  static String m66(count) => "${count} вкладок";

  static String m67(modelName) => "Вы сейчас используете ${modelName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("О приложении"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("Согласно: "),
    "accuracy": MessageLookupByLibrary.simpleMessage("Точность"),
    "adapting_more_inference_chips": MessageLookupByLibrary.simpleMessage(
      "Мы продолжаем адаптировать больше чипов для вывода, следите за обновлениями.",
    ),
    "add_local_folder": MessageLookupByLibrary.simpleMessage(
      "Добавить локальную папку",
    ),
    "advance_settings": MessageLookupByLibrary.simpleMessage(
      "Расширенные настройки",
    ),
    "all": MessageLookupByLibrary.simpleMessage("Все"),
    "all_done": MessageLookupByLibrary.simpleMessage("Все готово"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("Все промпты"),
    "all_the_same": MessageLookupByLibrary.simpleMessage("Все одинаковые"),
    "allow_background_downloads": MessageLookupByLibrary.simpleMessage(
      "Разрешить фоновые загрузки",
    ),
    "already_using_this_directory": MessageLookupByLibrary.simpleMessage(
      "Уже используется этот каталог",
    ),
    "analysing_result": MessageLookupByLibrary.simpleMessage(
      "Анализ результатов поиска",
    ),
    "api_server": MessageLookupByLibrary.simpleMessage("API Сервер"),
    "api_server_active_request_no": MessageLookupByLibrary.simpleMessage(
      "Активный запрос: Нет",
    ),
    "api_server_active_request_stopped": MessageLookupByLibrary.simpleMessage(
      "Активный запрос остановлен",
    ),
    "api_server_active_request_yes": MessageLookupByLibrary.simpleMessage(
      "Активный запрос: Да",
    ),
    "api_server_android_foreground_hint": MessageLookupByLibrary.simpleMessage(
      "Держите приложение на переднем плане и подключите компьютер и телефон к одной сети Wi-Fi.",
    ),
    "api_server_chat_empty_hint": MessageLookupByLibrary.simpleMessage(
      "Отправьте сообщение, чтобы проверить API",
    ),
    "api_server_chat_error": m0,
    "api_server_chat_input_hint": MessageLookupByLibrary.simpleMessage(
      "Введите сообщение...",
    ),
    "api_server_chat_test": MessageLookupByLibrary.simpleMessage("Тест чата"),
    "api_server_curl_hint": MessageLookupByLibrary.simpleMessage(
      "Пример использования",
    ),
    "api_server_description": MessageLookupByLibrary.simpleMessage(
      "Запустить локальный OpenAI-совместимый сервер",
    ),
    "api_server_docs": MessageLookupByLibrary.simpleMessage("Документация API"),
    "api_server_failed_to_start": m1,
    "api_server_logs": MessageLookupByLibrary.simpleMessage("Журнал запросов"),
    "api_server_no_active_request": MessageLookupByLibrary.simpleMessage(
      "Активных запросов нет",
    ),
    "api_server_no_lan_address": MessageLookupByLibrary.simpleMessage(
      "Не найден LAN-адрес, доступный с компьютера",
    ),
    "api_server_no_model": MessageLookupByLibrary.simpleMessage(
      "Модель не загружена",
    ),
    "api_server_open_dashboard": MessageLookupByLibrary.simpleMessage(
      "Открыть панель управления",
    ),
    "api_server_port": MessageLookupByLibrary.simpleMessage("Порт"),
    "api_server_request_count": MessageLookupByLibrary.simpleMessage(
      "Запросов",
    ),
    "api_server_running": MessageLookupByLibrary.simpleMessage(
      "Сервер работает",
    ),
    "api_server_select_model_first": MessageLookupByLibrary.simpleMessage(
      "Сначала выберите модель чата",
    ),
    "api_server_send": MessageLookupByLibrary.simpleMessage("Отправить"),
    "api_server_start": MessageLookupByLibrary.simpleMessage(
      "Запустить сервер",
    ),
    "api_server_started_on_port": m2,
    "api_server_starting": MessageLookupByLibrary.simpleMessage(
      "Сервер запускается",
    ),
    "api_server_stop": MessageLookupByLibrary.simpleMessage(
      "Остановить сервер",
    ),
    "api_server_stopped": MessageLookupByLibrary.simpleMessage(
      "Сервер остановлен",
    ),
    "api_server_url": MessageLookupByLibrary.simpleMessage("URL сервера"),
    "app_is_already_up_to_date": MessageLookupByLibrary.simpleMessage(
      "У вас последняя версия",
    ),
    "appearance": MessageLookupByLibrary.simpleMessage("Внешний вид"),
    "application_internal_test_group": MessageLookupByLibrary.simpleMessage(
      "Группа внутреннего тестирования приложения",
    ),
    "application_language": MessageLookupByLibrary.simpleMessage(
      "Язык приложения",
    ),
    "application_mode": MessageLookupByLibrary.simpleMessage(
      "Уровень возможностей",
    ),
    "application_settings": MessageLookupByLibrary.simpleMessage(
      "Настройки приложения",
    ),
    "apply": MessageLookupByLibrary.simpleMessage("Применить"),
    "are_you_sure_you_want_to_delete_this_model":
        MessageLookupByLibrary.simpleMessage(
          "Вы уверены, что хотите удалить эту модель?",
        ),
    "ask": MessageLookupByLibrary.simpleMessage("Спросить"),
    "ask_me_anything": MessageLookupByLibrary.simpleMessage(
      "Спроси меня о чем угодно...",
    ),
    "assistant": MessageLookupByLibrary.simpleMessage("RWKV:"),
    "auto": MessageLookupByLibrary.simpleMessage("Автоматически"),
    "auto_detect": MessageLookupByLibrary.simpleMessage("Автоопределение"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("Вернуться в чат"),
    "background_color": MessageLookupByLibrary.simpleMessage("Цвет фона"),
    "balanced": MessageLookupByLibrary.simpleMessage("Сбалансированный"),
    "batch_completion": MessageLookupByLibrary.simpleMessage(
      "Пакетное дополнение",
    ),
    "batch_completion_settings": MessageLookupByLibrary.simpleMessage(
      "Настройки пакетного дополнения",
    ),
    "batch_inference": MessageLookupByLibrary.simpleMessage("Ветвление"),
    "batch_inference_button": m3,
    "batch_inference_count": MessageLookupByLibrary.simpleMessage(
      "Количество параллельных ответов",
    ),
    "batch_inference_count_detail": m4,
    "batch_inference_count_detail_2": m5,
    "batch_inference_detail": MessageLookupByLibrary.simpleMessage(
      "После включения ветвления RWKV может генерировать несколько ответов одновременно",
    ),
    "batch_inference_enable_or_not": MessageLookupByLibrary.simpleMessage(
      "Включить или выключить ветвление",
    ),
    "batch_inference_running": m6,
    "batch_inference_selected": m7,
    "batch_inference_settings": MessageLookupByLibrary.simpleMessage(
      "Настройки Ветвления",
    ),
    "batch_inference_short": MessageLookupByLibrary.simpleMessage("Ветвление"),
    "batch_inference_width": MessageLookupByLibrary.simpleMessage(
      "Ширина отображения сообщения",
    ),
    "batch_inference_width_2": MessageLookupByLibrary.simpleMessage(
      "Ширина отображения результатов",
    ),
    "batch_inference_width_detail": MessageLookupByLibrary.simpleMessage(
      "Ширина каждого сообщения при ветвлении",
    ),
    "batch_inference_width_detail_2": MessageLookupByLibrary.simpleMessage(
      "Ширина каждого результата",
    ),
    "beginner": MessageLookupByLibrary.simpleMessage("Новичок"),
    "below_are_your_local_folders": MessageLookupByLibrary.simpleMessage(
      "Ниже представлены ваши локальные папки",
    ),
    "benchmark": MessageLookupByLibrary.simpleMessage(
      "Тест производительности",
    ),
    "benchmark_batch": m8,
    "benchmark_batch_not_supported_by_model":
        MessageLookupByLibrary.simpleMessage("Не поддерживается моделью"),
    "benchmark_batch_plan_range": m9,
    "benchmark_batch_plan_single": MessageLookupByLibrary.simpleMessage(
      "Batch 1",
    ),
    "benchmark_batch_result": m10,
    "benchmark_batch_supported_up_to": m11,
    "benchmark_batch_waiting_for_backend": MessageLookupByLibrary.simpleMessage(
      "Ожидание данных бэкенда",
    ),
    "benchmark_best_bw": MessageLookupByLibrary.simpleMessage(
      "Лучшая пропускная способность",
    ),
    "benchmark_best_decode": MessageLookupByLibrary.simpleMessage(
      "Лучший Decode",
    ),
    "benchmark_best_decode_per_batch": MessageLookupByLibrary.simpleMessage(
      "Лучший Decode / Batch",
    ),
    "benchmark_best_flops": MessageLookupByLibrary.simpleMessage(
      "Лучший FLOPS",
    ),
    "benchmark_current": MessageLookupByLibrary.simpleMessage("Текущий"),
    "benchmark_current_batch": m12,
    "benchmark_decode_per_batch": MessageLookupByLibrary.simpleMessage(
      "Decode / Batch",
    ),
    "benchmark_decode_progress_speed": m13,
    "benchmark_info_app_version": MessageLookupByLibrary.simpleMessage(
      "Версия приложения",
    ),
    "benchmark_info_backend": MessageLookupByLibrary.simpleMessage("Бэкенд"),
    "benchmark_info_build_mode": MessageLookupByLibrary.simpleMessage(
      "Режим сборки",
    ),
    "benchmark_info_cpu_name": MessageLookupByLibrary.simpleMessage("CPU"),
    "benchmark_info_device_model": MessageLookupByLibrary.simpleMessage(
      "Модель устройства",
    ),
    "benchmark_info_file_size": MessageLookupByLibrary.simpleMessage(
      "Размер файла",
    ),
    "benchmark_info_gpu_name": MessageLookupByLibrary.simpleMessage("GPU"),
    "benchmark_info_os": MessageLookupByLibrary.simpleMessage("ОС"),
    "benchmark_info_os_version": MessageLookupByLibrary.simpleMessage(
      "Версия ОС",
    ),
    "benchmark_info_soc_brand": MessageLookupByLibrary.simpleMessage(
      "Бренд SoC",
    ),
    "benchmark_info_soc_name": MessageLookupByLibrary.simpleMessage(
      "Название SoC",
    ),
    "benchmark_info_total_memory": MessageLookupByLibrary.simpleMessage(
      "Всего памяти",
    ),
    "benchmark_info_total_vram": MessageLookupByLibrary.simpleMessage(
      "Всего VRAM",
    ),
    "benchmark_peak_decode": m14,
    "benchmark_plan": MessageLookupByLibrary.simpleMessage("План"),
    "benchmark_progress": MessageLookupByLibrary.simpleMessage(
      "Прогресс бенчмарка",
    ),
    "benchmark_progress_speed": m15,
    "benchmark_result": MessageLookupByLibrary.simpleMessage(
      "Результат теста производительности",
    ),
    "benchmark_result_speed_line": m16,
    "benchmark_run": MessageLookupByLibrary.simpleMessage("Запуск"),
    "benchmark_run_status": m17,
    "benchmark_support": MessageLookupByLibrary.simpleMessage("Поддержка"),
    "benchmark_total_decode": MessageLookupByLibrary.simpleMessage(
      "Общий Decode",
    ),
    "black": MessageLookupByLibrary.simpleMessage("Черные"),
    "black_score": MessageLookupByLibrary.simpleMessage("Счет черных"),
    "black_wins": MessageLookupByLibrary.simpleMessage("Черные победили!"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "Сообщение бота отредактировано, теперь вы можете отправить новое сообщение",
    ),
    "branch_switcher_tooltip_first": MessageLookupByLibrary.simpleMessage(
      "Уже первое сообщение",
    ),
    "branch_switcher_tooltip_last": MessageLookupByLibrary.simpleMessage(
      "Уже последнее сообщение",
    ),
    "branch_switcher_tooltip_next": MessageLookupByLibrary.simpleMessage(
      "Следующее сообщение",
    ),
    "branch_switcher_tooltip_prev": MessageLookupByLibrary.simpleMessage(
      "Предыдущее сообщение",
    ),
    "browser_status": MessageLookupByLibrary.simpleMessage("Статус браузера"),
    "cached_translations_disk": MessageLookupByLibrary.simpleMessage(
      "Кэшированные переводы (диск)",
    ),
    "cached_translations_memory": MessageLookupByLibrary.simpleMessage(
      "Кэшированные переводы (память)",
    ),
    "camera": MessageLookupByLibrary.simpleMessage("Камера"),
    "can_not_generate": MessageLookupByLibrary.simpleMessage(
      "Не удалось сгенерировать",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Отмена"),
    "cancel_all_selection": MessageLookupByLibrary.simpleMessage(
      "Отменить выбор всех",
    ),
    "cancel_download": MessageLookupByLibrary.simpleMessage(
      "Отменить загрузку",
    ),
    "cancel_update": MessageLookupByLibrary.simpleMessage("Не сейчас"),
    "change": MessageLookupByLibrary.simpleMessage("Изменить"),
    "change_selected_image": MessageLookupByLibrary.simpleMessage(
      "Изменить изображение",
    ),
    "chat": MessageLookupByLibrary.simpleMessage("Чат"),
    "chat_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "Скопировано в буфер обмена",
    ),
    "chat_empty_message": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите сообщение",
    ),
    "chat_history": MessageLookupByLibrary.simpleMessage("История чатов"),
    "chat_mode": MessageLookupByLibrary.simpleMessage("Режим чата"),
    "chat_model_name": MessageLookupByLibrary.simpleMessage("Название модели"),
    "chat_please_select_a_model": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите модель",
    ),
    "chat_resume": MessageLookupByLibrary.simpleMessage("Продолжить"),
    "chat_title": MessageLookupByLibrary.simpleMessage("RWKV Чат"),
    "chat_welcome_to_use": m18,
    "chat_with_rwkv_model": MessageLookupByLibrary.simpleMessage(
      "Общайтесь с моделями RWKV",
    ),
    "chat_you_need_download_model_if_you_want_to_use_it":
        MessageLookupByLibrary.simpleMessage(
          "Сначала скачайте модель, чтобы использовать функцию",
        ),
    "chatting": MessageLookupByLibrary.simpleMessage("В чате"),
    "check_for_updates": MessageLookupByLibrary.simpleMessage(
      "Проверить обновления",
    ),
    "chinese": MessageLookupByLibrary.simpleMessage("Китайский"),
    "chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "Шаблон китайского режима мышления",
    ),
    "chinese_translation_result": MessageLookupByLibrary.simpleMessage(
      "Результат перевода на китайский",
    ),
    "chinese_web_search_template": MessageLookupByLibrary.simpleMessage(
      "Шаблон китайского веб-поиска",
    ),
    "choose_prebuilt_character": MessageLookupByLibrary.simpleMessage(
      "Выбрать предустановленного персонажа",
    ),
    "clear": MessageLookupByLibrary.simpleMessage("Очистить"),
    "clear_memory_cache": MessageLookupByLibrary.simpleMessage(
      "Очистить кэш в памяти",
    ),
    "clear_text": MessageLookupByLibrary.simpleMessage("Очистить текст"),
    "click_here_to_select_a_new_model": MessageLookupByLibrary.simpleMessage(
      "Нажмите здесь, чтобы выбрать новую модель",
    ),
    "click_here_to_start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "Нажмите здесь, чтобы начать новый чат",
    ),
    "click_plus_add_local_folder": MessageLookupByLibrary.simpleMessage(
      "Нажмите +, чтобы добавить локальную папку. RWKV Chat просканирует папку на наличие .pth файлов и покажет их как загружаемые веса",
    ),
    "click_plus_to_add_more_folders": MessageLookupByLibrary.simpleMessage(
      "Нажмите +, чтобы добавить локальные папки",
    ),
    "click_to_load_image": MessageLookupByLibrary.simpleMessage(
      "Нажмите, чтобы загрузить изображение",
    ),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage(
      "Нажмите, чтобы выбрать модель",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Закрыть"),
    "code_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "Код скопирован в буфер обмена",
    ),
    "colon": MessageLookupByLibrary.simpleMessage(": "),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "Цветовая схема как в системе",
    ),
    "completion": MessageLookupByLibrary.simpleMessage("Режим дополнения"),
    "completion_mode": MessageLookupByLibrary.simpleMessage("Режим дополнения"),
    "confirm": MessageLookupByLibrary.simpleMessage("Подтвердить"),
    "confirm_delete_file_message": MessageLookupByLibrary.simpleMessage(
      "Файл будет безвозвратно удалён с вашего локального диска",
    ),
    "confirm_delete_file_title": MessageLookupByLibrary.simpleMessage(
      "Удалить этот файл?",
    ),
    "confirm_forget_location_message": MessageLookupByLibrary.simpleMessage(
      "После забытия эта папка больше не будет отображаться в списке локальных папок",
    ),
    "confirm_forget_location_title": MessageLookupByLibrary.simpleMessage(
      "Забыть это расположение?",
    ),
    "continue_download": MessageLookupByLibrary.simpleMessage(
      "Продолжить загрузку",
    ),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "Продолжить использовать меньшую модель",
    ),
    "conversation_management": MessageLookupByLibrary.simpleMessage(
      "Управление",
    ),
    "conversation_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Название диалога не может быть пустым",
    ),
    "conversation_name_cannot_be_longer_than_30_characters": m19,
    "conversation_token_count": MessageLookupByLibrary.simpleMessage(
      "Количество токенов в текущем диалоге",
    ),
    "conversation_token_limit_hint_short": MessageLookupByLibrary.simpleMessage(
      "Рекомендуется новый чат",
    ),
    "conversation_token_limit_recommend_new_chat":
        MessageLookupByLibrary.simpleMessage(
          "Текущий диалог превысил 8 000 токенов. Рекомендуется начать новый чат.",
        ),
    "conversations": MessageLookupByLibrary.simpleMessage("Диалоги"),
    "copy_code": MessageLookupByLibrary.simpleMessage("Копировать код"),
    "copy_text": MessageLookupByLibrary.simpleMessage("Копировать текст"),
    "correct_count": MessageLookupByLibrary.simpleMessage(
      "Количество правильных",
    ),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage(
          "Нажмите кнопку выше, чтобы создать новую сессию",
        ),
    "created_at": MessageLookupByLibrary.simpleMessage("Создано"),
    "creative_recommended": MessageLookupByLibrary.simpleMessage(
      "Творческий (Рекомендуется)",
    ),
    "creative_recommended_short": MessageLookupByLibrary.simpleMessage(
      "Творческий",
    ),
    "ctx_length_label": m20,
    "current_folder_has_no_local_models": MessageLookupByLibrary.simpleMessage(
      "В этой папке нет локальных моделей",
    ),
    "current_model": m21,
    "current_model_from_latest_json_not_pth": MessageLookupByLibrary.simpleMessage(
      "Текущая модель загружена из конфигурации latest.json, а не из локального .pth файла",
    ),
    "current_progress": m22,
    "current_task_tab_id": MessageLookupByLibrary.simpleMessage(
      "ID вкладки текущей задачи",
    ),
    "current_task_text_length": MessageLookupByLibrary.simpleMessage(
      "Длина текста текущей задачи",
    ),
    "current_task_url": MessageLookupByLibrary.simpleMessage(
      "URL текущей задачи",
    ),
    "current_test_item": m23,
    "current_turn": MessageLookupByLibrary.simpleMessage("Текущий ход"),
    "current_version": MessageLookupByLibrary.simpleMessage("Текущая версия"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage(
      "Пользовательская сложность",
    ),
    "custom_directory_set": MessageLookupByLibrary.simpleMessage(
      "Пользовательский каталог установлен",
    ),
    "dark_mode": MessageLookupByLibrary.simpleMessage("Тёмный режим"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage(
      "Тема тёмного режима",
    ),
    "decode": MessageLookupByLibrary.simpleMessage("вывод"),
    "decode_param": MessageLookupByLibrary.simpleMessage("Параметры модели"),
    "decode_param_comprehensive": MessageLookupByLibrary.simpleMessage(
      "Всесторонний (Стоит попробовать)",
    ),
    "decode_param_comprehensive_short": MessageLookupByLibrary.simpleMessage(
      "Всесторонний",
    ),
    "decode_param_conservative": MessageLookupByLibrary.simpleMessage(
      "Консервативный (Для математики и кода)",
    ),
    "decode_param_conservative_short": MessageLookupByLibrary.simpleMessage(
      "Консервативный",
    ),
    "decode_param_creative": MessageLookupByLibrary.simpleMessage(
      "Творческий (Для письма, меньше повторов)",
    ),
    "decode_param_creative_short": MessageLookupByLibrary.simpleMessage(
      "Творческий",
    ),
    "decode_param_custom": MessageLookupByLibrary.simpleMessage(
      "Пользовательский (Ручная настройка)",
    ),
    "decode_param_custom_short": MessageLookupByLibrary.simpleMessage(
      "Пользовательский",
    ),
    "decode_param_default_": MessageLookupByLibrary.simpleMessage(
      "По умолчанию (Стандартные параметры)",
    ),
    "decode_param_default_short": MessageLookupByLibrary.simpleMessage(
      "По умолчанию",
    ),
    "decode_param_fixed": MessageLookupByLibrary.simpleMessage(
      "Фиксированный (Самый консервативный)",
    ),
    "decode_param_fixed_short": MessageLookupByLibrary.simpleMessage(
      "Фиксированный",
    ),
    "decode_param_select_message": MessageLookupByLibrary.simpleMessage(
      "Мы можем контролировать стиль вывода RWKV через параметры декодирования",
    ),
    "decode_param_select_title": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите параметры декодирования",
    ),
    "decode_params_for_each_message": MessageLookupByLibrary.simpleMessage(
      "Параметры декодирования для каждого сообщения",
    ),
    "decode_params_for_each_message_detail": MessageLookupByLibrary.simpleMessage(
      "Параметры декодирования для каждого сообщения в пакете. Нажмите, чтобы изменить параметры для каждого сообщения при пакетном выводе.",
    ),
    "decode_speed_tokens_per_second": MessageLookupByLibrary.simpleMessage(
      "Скорость декодирования (токенов в секунду)",
    ),
    "deep_web_search": MessageLookupByLibrary.simpleMessage("Глубокий поиск"),
    "default_font": MessageLookupByLibrary.simpleMessage("По умолчанию"),
    "delete": MessageLookupByLibrary.simpleMessage("Удалить"),
    "delete_all": MessageLookupByLibrary.simpleMessage("Удалить все"),
    "delete_branch_confirmation_message": MessageLookupByLibrary.simpleMessage(
      "Это опасное действие: текущее сообщение и все его дочерние узлы будут удалены навсегда, а связанные записи в базе данных также будут удалены. Это действие нельзя отменить. Продолжить?",
    ),
    "delete_branch_title": MessageLookupByLibrary.simpleMessage(
      "Удалить текущее сообщение",
    ),
    "delete_conversation": MessageLookupByLibrary.simpleMessage(
      "Удалить диалог",
    ),
    "delete_conversation_message": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите удалить этот диалог?",
    ),
    "delete_current_branch": MessageLookupByLibrary.simpleMessage(
      "Удалить текущее сообщение",
    ),
    "delete_finished": MessageLookupByLibrary.simpleMessage(
      "Удаление завершено",
    ),
    "delete_mlx_cache_confirmation": MessageLookupByLibrary.simpleMessage(
      "Удалить этот кэш MLX/CoreML?",
    ),
    "difficulty": MessageLookupByLibrary.simpleMessage("Сложность"),
    "difficulty_must_be_greater_than_0": MessageLookupByLibrary.simpleMessage(
      "Сложность должна быть больше 0",
    ),
    "difficulty_must_be_less_than_81": MessageLookupByLibrary.simpleMessage(
      "Сложность должна быть меньше 81",
    ),
    "disabled": MessageLookupByLibrary.simpleMessage("Выключено"),
    "discord": MessageLookupByLibrary.simpleMessage("Discord"),
    "dont_ask_again": MessageLookupByLibrary.simpleMessage(
      "Больше не спрашивать",
    ),
    "download_all": MessageLookupByLibrary.simpleMessage("Скачать все"),
    "download_all_missing": MessageLookupByLibrary.simpleMessage(
      "Скачать все недостающие файлы",
    ),
    "download_app": MessageLookupByLibrary.simpleMessage("Скачать приложение"),
    "download_failed": MessageLookupByLibrary.simpleMessage("Ошибка загрузки"),
    "download_from_browser": MessageLookupByLibrary.simpleMessage(
      "Скачать из браузера",
    ),
    "download_missing": MessageLookupByLibrary.simpleMessage(
      "Скачать недостающие файлы",
    ),
    "download_model": MessageLookupByLibrary.simpleMessage("Скачать модель"),
    "download_now": MessageLookupByLibrary.simpleMessage("Скачать сейчас"),
    "download_server_": MessageLookupByLibrary.simpleMessage(
      "Сервер загрузки (выберите тот, что быстрее)",
    ),
    "download_source": MessageLookupByLibrary.simpleMessage(
      "Источник загрузки",
    ),
    "downloading": MessageLookupByLibrary.simpleMessage("Загрузка"),
    "draw": MessageLookupByLibrary.simpleMessage("Ничья!"),
    "dump_see_files": MessageLookupByLibrary.simpleMessage(
      "Записи сообщений автоматического дампа",
    ),
    "dump_see_files_alert_message": m24,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage(
      "Помогите нам улучшить алгоритм",
    ),
    "dump_started": MessageLookupByLibrary.simpleMessage(
      "Автоматический дамп включен",
    ),
    "dump_stopped": MessageLookupByLibrary.simpleMessage(
      "Автоматический дамп выключен",
    ),
    "edit": MessageLookupByLibrary.simpleMessage("Редактировать"),
    "editing": MessageLookupByLibrary.simpleMessage("Редактирование"),
    "en_to_zh": MessageLookupByLibrary.simpleMessage("АН->КН"),
    "enabled": MessageLookupByLibrary.simpleMessage("Включено"),
    "end": MessageLookupByLibrary.simpleMessage("Конец"),
    "english": MessageLookupByLibrary.simpleMessage("English"),
    "english_translation_result": MessageLookupByLibrary.simpleMessage(
      "Результат перевода на английский",
    ),
    "ensure_you_have_enough_memory_to_load_the_model":
        MessageLookupByLibrary.simpleMessage(
          "Убедитесь, что на вашем устройстве достаточно памяти, иначе приложение может вылететь",
        ),
    "enter_text_to_translate": MessageLookupByLibrary.simpleMessage(
      "Введите текст для перевода...",
    ),
    "escape_characters_rendered": MessageLookupByLibrary.simpleMessage(
      "Символы новой строки отображены",
    ),
    "expert": MessageLookupByLibrary.simpleMessage("Эксперт"),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("Исследовать RWKV"),
    "exploring": MessageLookupByLibrary.simpleMessage("Исследую..."),
    "export_all_weight_files": MessageLookupByLibrary.simpleMessage(
      "Экспортировать все файлы весов",
    ),
    "export_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "Все загруженные файлы весов будут экспортированы как отдельные файлы в выбранную директорию. Существующие файлы с тем же именем будут пропущены.",
    ),
    "export_conversation_failed": MessageLookupByLibrary.simpleMessage(
      "Не удалось экспортировать диалог",
    ),
    "export_conversation_to_txt": MessageLookupByLibrary.simpleMessage(
      "Экспортировать диалог в файл .txt",
    ),
    "export_data": MessageLookupByLibrary.simpleMessage("Экспорт данных"),
    "export_failed": MessageLookupByLibrary.simpleMessage("Экспорт не удался"),
    "export_success": MessageLookupByLibrary.simpleMessage("Экспорт успешен"),
    "export_title": MessageLookupByLibrary.simpleMessage("Название диалога:"),
    "export_weight_file": MessageLookupByLibrary.simpleMessage(
      "Экспортировать файл весов",
    ),
    "extra_large": MessageLookupByLibrary.simpleMessage("Очень большой (130%)"),
    "failed_to_check_for_updates": MessageLookupByLibrary.simpleMessage(
      "Не удалось проверить обновления",
    ),
    "failed_to_create_directory": MessageLookupByLibrary.simpleMessage(
      "Не удалось создать каталог",
    ),
    "failed_to_delete_file": m25,
    "fake_batch_inference_benchmark": MessageLookupByLibrary.simpleMessage(
      "UI benchmark batch inference",
    ),
    "feedback": MessageLookupByLibrary.simpleMessage("Обратная связь"),
    "file_already_exists": MessageLookupByLibrary.simpleMessage(
      "Файл уже существует",
    ),
    "file_not_found": MessageLookupByLibrary.simpleMessage("Файл не найден"),
    "file_not_supported": MessageLookupByLibrary.simpleMessage(
      "Этот файл пока не поддерживается. Пожалуйста, проверьте, правильно ли указано имя файла",
    ),
    "file_path_not_found": MessageLookupByLibrary.simpleMessage(
      "Путь к файлу не найден",
    ),
    "files": MessageLookupByLibrary.simpleMessage("файлов"),
    "files_moved_with_failures": m26,
    "filter": MessageLookupByLibrary.simpleMessage(
      "Я пока не могу ответить на этот вопрос. Давайте поговорим на другую тему.",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage(
      "Запись завершена",
    ),
    "folder_already_added": MessageLookupByLibrary.simpleMessage(
      "Эта папка уже добавлена",
    ),
    "folder_not_accessible_check_permission":
        MessageLookupByLibrary.simpleMessage(
          "К этой папке нет доступа. Проверьте права доступа",
        ),
    "folder_not_found_on_device": MessageLookupByLibrary.simpleMessage(
      "Эта папка не найдена на вашем устройстве",
    ),
    "follow_system": MessageLookupByLibrary.simpleMessage("Как в системе"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "Следите за нами в Twitter",
    ),
    "font_preview_markdown_asset": MessageLookupByLibrary.simpleMessage(
      "assets/lib/font_preview/font_preview_ru.md",
    ),
    "font_preview_user_message": MessageLookupByLibrary.simpleMessage(
      "Привет! Это предпросмотр сообщения пользователя.\nВторая строка тоже меняется вместе с выбранным межстрочным интервалом.",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("Настройки шрифта"),
    "font_size": MessageLookupByLibrary.simpleMessage("Размер шрифта"),
    "font_size_default": MessageLookupByLibrary.simpleMessage(
      "По умолчанию (100%)",
    ),
    "font_size_follow_system": MessageLookupByLibrary.simpleMessage(
      "Размер шрифта как в системе",
    ),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage(
      "Принудительный тёмный режим",
    ),
    "forget_location_success": MessageLookupByLibrary.simpleMessage(
      "Расположение забыто",
    ),
    "forget_this_location": MessageLookupByLibrary.simpleMessage(
      "Забыть это расположение",
    ),
    "found_new_version_available": MessageLookupByLibrary.simpleMessage(
      "Обнаружена доступная новая версия",
    ),
    "frequency_penalty_with_value": m27,
    "from_model": MessageLookupByLibrary.simpleMessage("От модели: %s"),
    "gallery": MessageLookupByLibrary.simpleMessage("Галерея"),
    "game_over": MessageLookupByLibrary.simpleMessage("Игра окончена!"),
    "generate": MessageLookupByLibrary.simpleMessage("Сгенерировать"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage(
          "Сгенерировать самый сложный судоку в мире",
        ),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "Сгенерировать случайный судоку",
    ),
    "generated_questions": MessageLookupByLibrary.simpleMessage(
      "Сгенерированные вопросы",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("Генерация..."),
    "github_repository": MessageLookupByLibrary.simpleMessage(
      "Репозиторий Github",
    ),
    "go_to_home_page": MessageLookupByLibrary.simpleMessage(
      "Перейти на главную страницу",
    ),
    "go_to_settings": MessageLookupByLibrary.simpleMessage(
      "Перейти в настройки",
    ),
    "got_it": MessageLookupByLibrary.simpleMessage("Я понял"),
    "hello_ask_me_anything": MessageLookupByLibrary.simpleMessage(
      "Привет, спроси меня \nо чем угодно...",
    ),
    "hide_stack": MessageLookupByLibrary.simpleMessage(
      "Скрыть стек цепочки мыслей",
    ),
    "hide_translations": MessageLookupByLibrary.simpleMessage(
      "Скрыть переводы",
    ),
    "hint_chinese_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "По умолчанию используется \'<think>好的\', в моделях, выпущенных до 21.09.2025, автоматически будет использоваться \'<think>嗯\'",
    ),
    "hint_system_prompt": MessageLookupByLibrary.simpleMessage(
      "Пример: System: Ты — могущественная большая языковая модель RWKV, и ты всегда терпеливо отвечаешь на вопросы пользователей.",
    ),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "Удерживайте для записи, отпустите для отправки",
    ),
    "home": MessageLookupByLibrary.simpleMessage("Главная"),
    "http_service_port": m28,
    "human": MessageLookupByLibrary.simpleMessage("Человек"),
    "hyphen": MessageLookupByLibrary.simpleMessage("-"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage(
      "Я хочу, чтобы RWKV сказал...",
    ),
    "idle": MessageLookupByLibrary.simpleMessage("Ожидание"),
    "imitate": m29,
    "imitate_fle": m30,
    "imitate_target": MessageLookupByLibrary.simpleMessage("Использовать"),
    "import_all_weight_files": MessageLookupByLibrary.simpleMessage(
      "Импортировать все файлы весов",
    ),
    "import_all_weight_files_description": MessageLookupByLibrary.simpleMessage(
      "Выберите ZIP-файл, экспортированный из этого приложения. Все файлы весов в ZIP-файле будут импортированы. Существующие файлы с тем же именем будут перезаписаны.",
    ),
    "import_all_weight_files_success": m31,
    "import_failed": MessageLookupByLibrary.simpleMessage("Импорт не удался"),
    "import_success": MessageLookupByLibrary.simpleMessage("Импорт успешен"),
    "import_weight_file": MessageLookupByLibrary.simpleMessage(
      "Импортировать файл весов",
    ),
    "in_context_search_will_be_activated_when_both_breadth_and_depth_are_greater_than_2":
        MessageLookupByLibrary.simpleMessage(
          "Контекстный поиск будет активирован, когда глубина и ширина поиска будут больше 2",
        ),
    "inference_engine": MessageLookupByLibrary.simpleMessage("ИИ-Движок"),
    "inference_is_done": MessageLookupByLibrary.simpleMessage(
      "🎉 Вывод завершен",
    ),
    "inference_is_running": MessageLookupByLibrary.simpleMessage(
      "Идет вывод...",
    ),
    "input_chinese_text_here": MessageLookupByLibrary.simpleMessage(
      "Введите текст на китайском",
    ),
    "input_english_text_here": MessageLookupByLibrary.simpleMessage(
      "Введите текст на английском",
    ),
    "intonations": MessageLookupByLibrary.simpleMessage("Интонации"),
    "intro": MessageLookupByLibrary.simpleMessage(
      "Исследуйте большие языковые модели серии RWKV v7, включая версии с параметрами 0.1B/0.4B/1.5B/2.9B, оптимизированные для мобильных устройств. После загрузки они работают полностью в офлайн-режиме без необходимости связи с сервером",
    ),
    "invalid_puzzle": MessageLookupByLibrary.simpleMessage(
      "Недопустимый судоку",
    ),
    "invalid_value": MessageLookupByLibrary.simpleMessage(
      "Недопустимое значение",
    ),
    "invalid_zip_file": MessageLookupByLibrary.simpleMessage(
      "Неверный ZIP-файл или формат файла не распознан",
    ),
    "its_your_turn": MessageLookupByLibrary.simpleMessage("Твой ход~"),
    "japanese": MessageLookupByLibrary.simpleMessage("日本語"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "Присоединяйтесь к нашему серверу Discord",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage(
      "Присоединиться к сообществу",
    ),
    "just_watch_me": MessageLookupByLibrary.simpleMessage(
      "😎 Смотри и наслаждайся!",
    ),
    "korean": MessageLookupByLibrary.simpleMessage("한국어"),
    "lambada_test": MessageLookupByLibrary.simpleMessage("LAMBADA тест"),
    "lan_server": MessageLookupByLibrary.simpleMessage("LAN-сервер"),
    "large": MessageLookupByLibrary.simpleMessage("Большой (120%)"),
    "latest_version": MessageLookupByLibrary.simpleMessage("Последняя версия"),
    "lazy": MessageLookupByLibrary.simpleMessage("Ленивый"),
    "lazy_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "Шаблон ленивого режима мышления",
    ),
    "less_than_01_gb": MessageLookupByLibrary.simpleMessage("< 0.01 GB"),
    "license": MessageLookupByLibrary.simpleMessage(
      "Лицензия с открытым исходным кодом",
    ),
    "life_span": MessageLookupByLibrary.simpleMessage("Life Span"),
    "light_mode": MessageLookupByLibrary.simpleMessage("Светлый режим"),
    "line_break_rendered": MessageLookupByLibrary.simpleMessage(
      "Новая строка отображена",
    ),
    "line_break_symbol_settings": MessageLookupByLibrary.simpleMessage(
      "Символ перевода строки",
    ),
    "load_": MessageLookupByLibrary.simpleMessage("Загрузить"),
    "load_data": MessageLookupByLibrary.simpleMessage("Загрузить данные"),
    "loaded": MessageLookupByLibrary.simpleMessage("Загружено"),
    "loading": MessageLookupByLibrary.simpleMessage("Загрузка..."),
    "loading_progress_percent": m32,
    "local_folder_name": m33,
    "local_pth_files_section_title": MessageLookupByLibrary.simpleMessage(
      "Локальный .pth файл",
    ),
    "local_pth_option_files_in_config": MessageLookupByLibrary.simpleMessage(
      "Веса из конфигурации",
    ),
    "local_pth_option_local_pth_files": MessageLookupByLibrary.simpleMessage(
      "Локальный .pth файл",
    ),
    "local_pth_you_can_select": MessageLookupByLibrary.simpleMessage(
      "Вы можете выбрать и загрузить локальный .pth файл",
    ),
    "medium": MessageLookupByLibrary.simpleMessage("Средний (110%)"),
    "memory_used": m34,
    "message_content": MessageLookupByLibrary.simpleMessage(
      "Содержимое сообщения",
    ),
    "message_in_queue": m35,
    "message_line_height": MessageLookupByLibrary.simpleMessage(
      "Межстрочный интервал сообщений",
    ),
    "message_line_height_default_hint": MessageLookupByLibrary.simpleMessage(
      "По умолчанию используется собственный межстрочный интервал шрифта и рендерера, а не фиксированное значение 1.0x. Пользовательский диапазон здесь: от 1.0x до 2.0x.",
    ),
    "message_token_count": MessageLookupByLibrary.simpleMessage(
      "Количество токенов в сообщении",
    ),
    "mimic": MessageLookupByLibrary.simpleMessage("Имитация"),
    "mlx_cache": MessageLookupByLibrary.simpleMessage("Кэш MLX/CoreML"),
    "mlx_cache_notice": MessageLookupByLibrary.simpleMessage(
      "Удаление кэша MLX/CoreML освободит место, но следующая загрузка модели MLX/CoreML будет дольше.",
    ),
    "mode": MessageLookupByLibrary.simpleMessage("Режим"),
    "model": MessageLookupByLibrary.simpleMessage("Модель"),
    "model_item_ios18_weight_hint": MessageLookupByLibrary.simpleMessage(
      "Обновитесь до iOS 18+, чтобы использовать этот вес — быстрее и экономичнее",
    ),
    "model_loading": MessageLookupByLibrary.simpleMessage("Загрузка модели..."),
    "model_output": m36,
    "model_settings": MessageLookupByLibrary.simpleMessage("Настройки модели"),
    "model_size_increased_please_open_a_new_conversation":
        MessageLookupByLibrary.simpleMessage(
          "Размер модели увеличен, откройте новый диалог, чтобы улучшить качество диалога",
        ),
    "monospace_font_setting": MessageLookupByLibrary.simpleMessage(
      "Настройка моноширинного шрифта",
    ),
    "more": MessageLookupByLibrary.simpleMessage("Ещё"),
    "more_questions": MessageLookupByLibrary.simpleMessage("Больше вопросов"),
    "moving_files": MessageLookupByLibrary.simpleMessage(
      "Перемещение файлов...",
    ),
    "multi_question_continue": MessageLookupByLibrary.simpleMessage(
      "Продолжить",
    ),
    "multi_question_entry_detail": MessageLookupByLibrary.simpleMessage(
      "Задайте несколько вопросов и получите ответы параллельно",
    ),
    "multi_question_input_hint": MessageLookupByLibrary.simpleMessage(
      "Введите вопрос...",
    ),
    "multi_question_no_answer": MessageLookupByLibrary.simpleMessage(
      "Ответа пока нет",
    ),
    "multi_question_send_all": MessageLookupByLibrary.simpleMessage(
      "Отправить все",
    ),
    "multi_question_title": MessageLookupByLibrary.simpleMessage(
      "Параллельные вопросы",
    ),
    "multi_thread": MessageLookupByLibrary.simpleMessage("Многопоточный"),
    "my_voice": MessageLookupByLibrary.simpleMessage("Мой голос"),
    "neko": MessageLookupByLibrary.simpleMessage("Неко"),
    "network_error": MessageLookupByLibrary.simpleMessage("Ошибка сети"),
    "new_chat": MessageLookupByLibrary.simpleMessage("Новый чат"),
    "new_chat_started": MessageLookupByLibrary.simpleMessage("Начат новый чат"),
    "new_chat_template": MessageLookupByLibrary.simpleMessage(
      "Шаблон нового чата",
    ),
    "new_chat_template_helper_text": MessageLookupByLibrary.simpleMessage(
      "Этот текст будет вставляться в начало каждого нового диалога, разделенный двумя переносами строки. Пример:\nПривет, кто ты?\n\nПривет, я RWKV, чем могу помочь?",
    ),
    "new_conversation": MessageLookupByLibrary.simpleMessage("Новый диалог"),
    "new_game": MessageLookupByLibrary.simpleMessage("Новая игра"),
    "new_version_available": MessageLookupByLibrary.simpleMessage(
      "Доступна новая версия",
    ),
    "new_version_found": MessageLookupByLibrary.simpleMessage(
      "Найдена новая версия",
    ),
    "no_audio_file": MessageLookupByLibrary.simpleMessage("Нет аудиофайла"),
    "no_browser_windows_connected": MessageLookupByLibrary.simpleMessage(
      "Нет подключенных окон браузера",
    ),
    "no_cell_available": MessageLookupByLibrary.simpleMessage(
      "Нет доступных ходов",
    ),
    "no_conversation_yet": MessageLookupByLibrary.simpleMessage(
      "Пока нет диалогов",
    ),
    "no_conversations_yet": MessageLookupByLibrary.simpleMessage(
      "Пока нет диалогов",
    ),
    "no_data": MessageLookupByLibrary.simpleMessage("Нет данных"),
    "no_files_in_zip": MessageLookupByLibrary.simpleMessage(
      "В ZIP-файле не найдено действительных файлов весов",
    ),
    "no_latest_version_info": MessageLookupByLibrary.simpleMessage(
      "Нет информации о последней версии",
    ),
    "no_local_folders": MessageLookupByLibrary.simpleMessage(
      "Вы ещё не добавили локальную папку с файлами .pth",
    ),
    "no_local_pth_loaded_yet": MessageLookupByLibrary.simpleMessage(
      "Локальные .pth файлы ещё не загружены",
    ),
    "no_message_to_export": MessageLookupByLibrary.simpleMessage(
      "Нет сообщений для экспорта",
    ),
    "no_model_selected": MessageLookupByLibrary.simpleMessage(
      "Модель не выбрана",
    ),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("Нет судоку"),
    "no_weight_files_guide_message": MessageLookupByLibrary.simpleMessage(
      "Вы еще не загрузили файлы весов. Перейдите на главную страницу, чтобы загрузить и попробовать приложение.",
    ),
    "no_weight_files_guide_title": MessageLookupByLibrary.simpleMessage(
      "Нет файлов весов",
    ),
    "no_weight_files_to_export": MessageLookupByLibrary.simpleMessage(
      "Нет файлов весов для экспорта",
    ),
    "not_all_the_same": MessageLookupByLibrary.simpleMessage(
      "Не все одинаковые",
    ),
    "not_syncing": MessageLookupByLibrary.simpleMessage("Не синхронизировано"),
    "npu_not_supported_title": m37,
    "number": MessageLookupByLibrary.simpleMessage("Число"),
    "nyan_nyan": MessageLookupByLibrary.simpleMessage("Мрр~ Мрявк~"),
    "ocr_guide_text": m38,
    "ocr_title": MessageLookupByLibrary.simpleMessage("OCR"),
    "off": MessageLookupByLibrary.simpleMessage("Выключено"),
    "offline_translator": MessageLookupByLibrary.simpleMessage(
      "Офлайн-переводчик",
    ),
    "offline_translator_detail": MessageLookupByLibrary.simpleMessage(
      "Переводите текст в офлайн-режиме",
    ),
    "offline_translator_server": MessageLookupByLibrary.simpleMessage(
      "Офлайн-сервер перевода",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("ОК"),
    "open_containing_folder": MessageLookupByLibrary.simpleMessage(
      "Открыть папку с файлом",
    ),
    "open_database_folder": MessageLookupByLibrary.simpleMessage(
      "Открыть папку базы данных",
    ),
    "open_debug_log_panel": MessageLookupByLibrary.simpleMessage(
      "Открыть панель отладки",
    ),
    "open_folder": MessageLookupByLibrary.simpleMessage("Открыть папку"),
    "open_folder_create_failed": m39,
    "open_folder_created_success": MessageLookupByLibrary.simpleMessage(
      "Пустая папка успешно создана.",
    ),
    "open_folder_creating_empty": MessageLookupByLibrary.simpleMessage(
      "Папка не существует, создаём пустую папку.",
    ),
    "open_folder_path_is_null": MessageLookupByLibrary.simpleMessage(
      "Путь к папке пуст.",
    ),
    "open_folder_unsupported_on_platform": m40,
    "open_official_download_page": MessageLookupByLibrary.simpleMessage(
      "Открыть официальную страницу загрузки",
    ),
    "open_state_panel": MessageLookupByLibrary.simpleMessage(
      "Открыть панель состояния",
    ),
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage(
          "Или выберите wav-файл, чтобы RWKV его имитировал.",
        ),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "Или начать пустой чат",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV Отелло"),
    "other_files": MessageLookupByLibrary.simpleMessage(
      "Другие файлы (Эти файлы могут быть устаревшими или больше не поддерживаемыми весами, которые больше не используются RWKV Chat)",
    ),
    "output": MessageLookupByLibrary.simpleMessage("Вывод"),
    "overseas": MessageLookupByLibrary.simpleMessage("(за рубежом)"),
    "overwrite": MessageLookupByLibrary.simpleMessage("Перезаписать"),
    "overwrite_file_confirmation": MessageLookupByLibrary.simpleMessage(
      "Файл уже существует. Вы хотите перезаписать его?",
    ),
    "parameter_description": MessageLookupByLibrary.simpleMessage(
      "Описание параметров",
    ),
    "parameter_description_detail": MessageLookupByLibrary.simpleMessage(
      "Temperature: Контролирует случайность вывода. Более высокие значения (например, 0.8) делают вывод более творческим и случайным; более низкие (например, 0.2) — более сфокусированным и детерминированным.\n\nTop P: Контролирует разнообразие вывода. Модель рассматривает только токены с совокупной вероятностью, достигающей Top P. Более низкие значения (например, 0.5) игнорируют маловероятные слова, делая вывод более релевантным.\n\nPresence Penalty: Штрафует токены в зависимости от того, появлялись ли они уже в тексте. Положительные значения увеличивают вероятность обсуждения новых тем.\n\nFrequency Penalty: Штрафует токены в зависимости от частоты их появления в тексте. Положительные значения уменьшают вероятность дословного повторения строк.\n\nPenalty Decay: Контролирует затухание штрафа с расстоянием.",
    ),
    "path_label": m41,
    "pause": MessageLookupByLibrary.simpleMessage("Пауза"),
    "penalty_decay_with_value": m42,
    "performance_test": MessageLookupByLibrary.simpleMessage(
      "Тест производительности",
    ),
    "performance_test_description": MessageLookupByLibrary.simpleMessage(
      "Тест скорости и точности",
    ),
    "perplexity": MessageLookupByLibrary.simpleMessage("Перплексия"),
    "players": MessageLookupByLibrary.simpleMessage("Игроки"),
    "playing_partial_generated_audio": MessageLookupByLibrary.simpleMessage(
      "Воспроизведение частично сгенерированного аудио",
    ),
    "please_check_the_result": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, проверьте результат",
    ),
    "please_enter_a_number_0_means_empty": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите число. 0 означает пустую ячейку.",
    ),
    "please_enter_conversation_name": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите название диалога",
    ),
    "please_enter_text_to_generate_tts": MessageLookupByLibrary.simpleMessage(
      "Введите текст, чтобы сгенерировать речь",
    ),
    "please_enter_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, введите сложность",
    ),
    "please_grant_permission_to_use_microphone":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, предоставьте разрешение на использование микрофона",
        ),
    "please_load_model_first": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, сначала загрузите модель",
    ),
    "please_manually_migrate_files": MessageLookupByLibrary.simpleMessage(
      "Путь обновлён. При необходимости перенесите файлы вручную.",
    ),
    "please_select_a_branch_to_continue_the_conversation":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, выберите ветвь для продолжения диалога",
        ),
    "please_select_a_spk_or_a_wav_file": MessageLookupByLibrary.simpleMessage(
      "Выберите предустановленный голос или запишите свой голос",
    ),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите тип задачи",
    ),
    "please_select_an_image_first": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, сначала выберите изображение",
    ),
    "please_select_an_image_from_the_following_options":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, выберите изображение из следующих опций",
        ),
    "please_select_application_language": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите язык приложения",
    ),
    "please_select_font_size": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите размер шрифта",
    ),
    "please_select_model": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите модель",
    ),
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите сложность",
    ),
    "please_select_the_sampler_and_penalty_parameters_to_set_all_to_for_index":
        m43,
    "please_select_the_sampler_and_penalty_parameters_to_set_for_all_messages":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, выберите параметры сэмплера и штрафов для всех сообщений",
        ),
    "please_wait_for_it_to_finish": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, дождитесь завершения вывода",
    ),
    "please_wait_for_the_model_to_finish_generating":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, подождите, пока модель завершит генерацию",
        ),
    "please_wait_for_the_model_to_generate":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, подождите, пока модель сгенерирует ответ",
        ),
    "please_wait_for_the_model_to_load": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, подождите, пока модель загрузится",
    ),
    "power_user": MessageLookupByLibrary.simpleMessage(
      "Продвинутый пользователь",
    ),
    "prebuilt": MessageLookupByLibrary.simpleMessage("Предустановленный"),
    "prebuilt_models_intro": MessageLookupByLibrary.simpleMessage(
      "Ниже представлены предварительно квантизированные модели RWKV Chat",
    ),
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage(
      "Предустановленные голоса",
    ),
    "prefer": MessageLookupByLibrary.simpleMessage("Использовать"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("Китайский режим"),
    "prefill": MessageLookupByLibrary.simpleMessage("ввод"),
    "prefill_progress_percent": m44,
    "prefill_speed_tokens_per_second": MessageLookupByLibrary.simpleMessage(
      "Скорость prefill (токенов в секунду)",
    ),
    "prefix_bank": MessageLookupByLibrary.simpleMessage("Набор префиксов"),
    "prefix_examples": MessageLookupByLibrary.simpleMessage(
      "Примеры префиксов",
    ),
    "presence_penalty_with_value": m45,
    "preview": MessageLookupByLibrary.simpleMessage("Предпросмотр"),
    "prompt": MessageLookupByLibrary.simpleMessage("Промпт"),
    "prompt_template": MessageLookupByLibrary.simpleMessage("Шаблон промпта"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("Группа QQ 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("Группа QQ 2"),
    "quantization": MessageLookupByLibrary.simpleMessage("Квантование"),
    "question": MessageLookupByLibrary.simpleMessage("Вопрос"),
    "question_generator": MessageLookupByLibrary.simpleMessage(
      "Генератор вопросов",
    ),
    "question_generator_context_prefix_input_placeholder":
        MessageLookupByLibrary.simpleMessage(
          "Если оставить поле пустым, RWKV сгенерирует вопросы на основе контекста.",
        ),
    "question_generator_count": MessageLookupByLibrary.simpleMessage(
      "Количество",
    ),
    "question_generator_empty_chat_batch_hint":
        MessageLookupByLibrary.simpleMessage(
          "Выберите начало вопроса выше, затем нажмите Generate — RWKV подскажет несколько вопросов, которые можно сразу отправить.",
        ),
    "question_generator_empty_chat_hint": MessageLookupByLibrary.simpleMessage(
      "Выберите начало вопроса выше, затем нажмите Generate — RWKV подскажет один вопрос, который можно сразу отправить.",
    ),
    "question_generator_language_switched_hint":
        MessageLookupByLibrary.simpleMessage(
          "После смены языка поменяются и варианты начала вопроса выше. Выберите тот, который вам ближе, и позвольте RWKV продолжить его.",
        ),
    "question_generator_mock_batch_description":
        MessageLookupByLibrary.simpleMessage(
          "Если хочется немного вдохновения, пусть RWKV предложит вам несколько вопросов.",
        ),
    "question_generator_mock_description": MessageLookupByLibrary.simpleMessage(
      "Не знаете, с чего начать? Пусть RWKV подскажет вам один вопрос.",
    ),
    "question_generator_prefix_guide": MessageLookupByLibrary.simpleMessage(
      "Попробуйте разные начала ниже, и RWKV продолжит их в полноценные вопросы. А если хочется, вы можете просто отредактировать поле ниже и написать своё начало.",
    ),
    "question_generator_prefix_input_placeholder":
        MessageLookupByLibrary.simpleMessage(
          "Напишите здесь начало вопроса...",
        ),
    "question_generator_prefix_required": MessageLookupByLibrary.simpleMessage(
      "Сначала введите префикс вопроса",
    ),
    "question_generator_prefixes": MessageLookupByLibrary.simpleMessage(
      "Префиксы вопросов",
    ),
    "question_generator_question_action_guide":
        MessageLookupByLibrary.simpleMessage(
          "Нажмите на сгенерированный вопрос, чтобы вставить его в поле ввода чата.",
        ),
    "question_generator_tap_generate_hint": m46,
    "question_language": MessageLookupByLibrary.simpleMessage(
      "Я хочу, чтобы RWKV задавал вопросы на этом языке...",
    ),
    "queued_x": m47,
    "quick_thinking": MessageLookupByLibrary.simpleMessage("Быстрое мышление"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage(
      "Быстрое мышление включено",
    ),
    "reached_bottom": MessageLookupByLibrary.simpleMessage(
      "Следите за обновлениями",
    ),
    "real_time_update": MessageLookupByLibrary.simpleMessage(
      "Обновление в реальном времени",
    ),
    "reason": MessageLookupByLibrary.simpleMessage("Мышление"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("Режим мышления"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage(
      "Идет запись голоса...",
    ),
    "reference_source": MessageLookupByLibrary.simpleMessage("Источник"),
    "refresh": MessageLookupByLibrary.simpleMessage("Обновлено"),
    "refresh_complete": MessageLookupByLibrary.simpleMessage(
      "Обновление завершено",
    ),
    "refreshed": MessageLookupByLibrary.simpleMessage("Обновлено"),
    "regenerate": MessageLookupByLibrary.simpleMessage("Сгенерировать заново"),
    "remaining": MessageLookupByLibrary.simpleMessage("Оставшееся время:"),
    "rename": MessageLookupByLibrary.simpleMessage("Переименовать"),
    "render_newline_directly": MessageLookupByLibrary.simpleMessage(
      "Рендерить перенос строки напрямую",
    ),
    "render_space_symbol": MessageLookupByLibrary.simpleMessage(
      "Рендерить символ пробела",
    ),
    "report_an_issue_on_github": MessageLookupByLibrary.simpleMessage(
      "Сообщить о проблеме на Github",
    ),
    "reselect_model": MessageLookupByLibrary.simpleMessage(
      "Выбрать модель заново",
    ),
    "reset": MessageLookupByLibrary.simpleMessage("Сброс"),
    "reset_to_default": MessageLookupByLibrary.simpleMessage(
      "Сбросить по умолчанию",
    ),
    "reset_to_default_directory": MessageLookupByLibrary.simpleMessage(
      "Сброс к каталогу по умолчанию",
    ),
    "response_style": MessageLookupByLibrary.simpleMessage("Стиль ответа"),
    "response_style_auto_switched_to_jin": MessageLookupByLibrary.simpleMessage(
      "Автоматически переключено на стиль 今",
    ),
    "response_style_batch_not_supported": m48,
    "response_style_button": MessageLookupByLibrary.simpleMessage("Стиль"),
    "response_style_keep_one": MessageLookupByLibrary.simpleMessage(
      "Нужно оставить включённым хотя бы один стиль ответа",
    ),
    "response_style_route_en_detail": MessageLookupByLibrary.simpleMessage(
      "Ответ на английском",
    ),
    "response_style_route_gu": MessageLookupByLibrary.simpleMessage("古"),
    "response_style_route_gu_detail": MessageLookupByLibrary.simpleMessage(
      "Ответ на вэньянь",
    ),
    "response_style_route_ja_detail": MessageLookupByLibrary.simpleMessage(
      "Ответ на японском",
    ),
    "response_style_route_jin": MessageLookupByLibrary.simpleMessage("今"),
    "response_style_route_jin_detail": MessageLookupByLibrary.simpleMessage(
      "Обычный ответ",
    ),
    "response_style_route_mao": MessageLookupByLibrary.simpleMessage("猫"),
    "response_style_route_mao_detail": MessageLookupByLibrary.simpleMessage(
      "Ответ в кошачьем стиле",
    ),
    "response_style_route_yue_detail": MessageLookupByLibrary.simpleMessage(
      "Ответ на кантонском",
    ),
    "restore_default": MessageLookupByLibrary.simpleMessage(
      "Восстановить по умолчанию",
    ),
    "result": MessageLookupByLibrary.simpleMessage("Результат"),
    "resume": MessageLookupByLibrary.simpleMessage("Возобновить"),
    "role_play": MessageLookupByLibrary.simpleMessage("Ролевая игра"),
    "role_play_intro": MessageLookupByLibrary.simpleMessage(
      "Играйте роль любимого персонажа",
    ),
    "runtime_log_panel": MessageLookupByLibrary.simpleMessage(
      "Панель журнала выполнения",
    ),
    "russian": MessageLookupByLibrary.simpleMessage("Русский"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV Чат"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV Отелло"),
    "save": MessageLookupByLibrary.simpleMessage("Сохранить"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("Сканировать QR-код"),
    "scanning_folder_for_pth": MessageLookupByLibrary.simpleMessage(
      "Сканирование папки на наличие .pth файлов",
    ),
    "screen_width": MessageLookupByLibrary.simpleMessage("Ширина экрана"),
    "search": MessageLookupByLibrary.simpleMessage("Поиск"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("Ширина поиска"),
    "search_depth": MessageLookupByLibrary.simpleMessage("Глубина поиска"),
    "search_failed": MessageLookupByLibrary.simpleMessage("Ошибка поиска"),
    "searching": MessageLookupByLibrary.simpleMessage("Поиск..."),
    "see": MessageLookupByLibrary.simpleMessage("Вопросы по изображению"),
    "select_a_model": MessageLookupByLibrary.simpleMessage("Выберите модель"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "Выберите тип задачи",
    ),
    "select_all": MessageLookupByLibrary.simpleMessage("Выбрать все"),
    "select_from_file": MessageLookupByLibrary.simpleMessage(
      "Выбрать файл изображения",
    ),
    "select_from_library": MessageLookupByLibrary.simpleMessage(
      "Выбрать из галереи",
    ),
    "select_image": MessageLookupByLibrary.simpleMessage("Выбрать изображение"),
    "select_local_pth_file_button": MessageLookupByLibrary.simpleMessage(
      "Выбрать локальный .pth файл",
    ),
    "select_model": MessageLookupByLibrary.simpleMessage("Выбрать модель"),
    "select_new_image": MessageLookupByLibrary.simpleMessage(
      "Выбрать изображение",
    ),
    "select_the_decode_parameters_to_set_all_to_for_index":
        MessageLookupByLibrary.simpleMessage(
          "Выберите предустановку ниже или нажмите «Пользовательский», чтобы настроить вручную",
        ),
    "select_weights_or_local_pth_hint": MessageLookupByLibrary.simpleMessage(
      "Выберите веса из конфигурации или локальный .pth файл",
    ),
    "selected_count": m49,
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage(
      "Отправить сообщение в RWKV",
    ),
    "server_error": MessageLookupByLibrary.simpleMessage("Ошибка сервера"),
    "session_configuration": MessageLookupByLibrary.simpleMessage(
      "Конфигурация сессии",
    ),
    "set_all_batch_params": MessageLookupByLibrary.simpleMessage(
      "Установить все параметры пакета",
    ),
    "set_all_to_question_mark": MessageLookupByLibrary.simpleMessage(
      "Установить все в ???",
    ),
    "set_custom_directory": MessageLookupByLibrary.simpleMessage(
      "Установить пользовательский каталог",
    ),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage(
      "Установить значение ячейки",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Настройки"),
    "share": MessageLookupByLibrary.simpleMessage("Поделиться"),
    "share_chat": MessageLookupByLibrary.simpleMessage("Поделиться чатом"),
    "show_prefill_log_only": MessageLookupByLibrary.simpleMessage(
      "Показать только Prefill журнал",
    ),
    "show_stack": MessageLookupByLibrary.simpleMessage(
      "Показать стек цепочки мыслей",
    ),
    "show_translations": MessageLookupByLibrary.simpleMessage(
      "Показать переводы",
    ),
    "single_thread": MessageLookupByLibrary.simpleMessage("Однопоточный"),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "Рекомендуется выбрать модель не менее 1.5B для лучших результатов",
    ),
    "skip_this_version": MessageLookupByLibrary.simpleMessage(
      "Пропустить эту версию",
    ),
    "small": MessageLookupByLibrary.simpleMessage("Маленький (90%)"),
    "source_code": MessageLookupByLibrary.simpleMessage("Исходный код"),
    "source_text": m50,
    "space_rendered": MessageLookupByLibrary.simpleMessage(
      "Пробелы отображены",
    ),
    "space_symbol_settings": MessageLookupByLibrary.simpleMessage(
      "Символ пробела",
    ),
    "space_symbol_style": MessageLookupByLibrary.simpleMessage(
      "Стиль символа пробела",
    ),
    "space_symbols_rendered": MessageLookupByLibrary.simpleMessage(
      "Символы пробела отображены",
    ),
    "speed": MessageLookupByLibrary.simpleMessage("Скорость загрузки:"),
    "start": MessageLookupByLibrary.simpleMessage("Начать"),
    "start_a_new_chat": MessageLookupByLibrary.simpleMessage(
      "Начать новый чат",
    ),
    "start_a_new_chat_by_clicking_the_button_below":
        MessageLookupByLibrary.simpleMessage(
          "Нажмите кнопку ниже, чтобы начать новый чат",
        ),
    "start_a_new_game": MessageLookupByLibrary.simpleMessage("Начать игру"),
    "start_download_updates_": MessageLookupByLibrary.simpleMessage(
      "Начать фоновую загрузку обновлений...",
    ),
    "start_service": MessageLookupByLibrary.simpleMessage("Запустить службу"),
    "start_service_and_open_browser": MessageLookupByLibrary.simpleMessage(
      "Запустите службу и откройте поддерживаемую страницу браузера.",
    ),
    "start_test": MessageLookupByLibrary.simpleMessage("Начать тест"),
    "start_testing": MessageLookupByLibrary.simpleMessage(
      "Начать тестирование",
    ),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("Начать чат"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("Начать вывод"),
    "starting": MessageLookupByLibrary.simpleMessage("Запуск..."),
    "state_list": MessageLookupByLibrary.simpleMessage("Список состояний"),
    "state_panel": MessageLookupByLibrary.simpleMessage("Панель состояния"),
    "status": MessageLookupByLibrary.simpleMessage("Статус"),
    "stop": MessageLookupByLibrary.simpleMessage("Стоп"),
    "stop_service": MessageLookupByLibrary.simpleMessage("Остановить службу"),
    "stop_test": MessageLookupByLibrary.simpleMessage("Остановить тест"),
    "stopping": MessageLookupByLibrary.simpleMessage("Остановка..."),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "Разрешение на доступ к хранилищу не предоставлено",
    ),
    "str_downloading_info": MessageLookupByLibrary.simpleMessage(
      "Скачано %.1f% Скорость %.1fMB/s Осталось %s",
    ),
    "str_model_selection_dialog_hint": MessageLookupByLibrary.simpleMessage(
      "Для наилучшего опыта выберите 1.5B, 2.9B или больше.",
    ),
    "str_please_disable_battery_opt_": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, отключите оптимизацию батареи, чтобы разрешить фоновые загрузки, иначе загрузки могут приостанавливаться при переключении на другие приложения",
    ),
    "str_please_select_app_mode_": MessageLookupByLibrary.simpleMessage(
      "Выберите режим приложения в зависимости от вашего уровня знакомства с ИИ и LLM.",
    ),
    "style": MessageLookupByLibrary.simpleMessage("Стиль"),
    "submit": MessageLookupByLibrary.simpleMessage("Отправить"),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("Легкий"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("Сложный"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("Средний"),
    "suggest": MessageLookupByLibrary.simpleMessage("Рекомендовать"),
    "switch_to_creative_mode_for_better_exp":
        MessageLookupByLibrary.simpleMessage(
          "Рекомендуется переключиться в режим «Творческий» для лучшего опыта",
        ),
    "syncing": MessageLookupByLibrary.simpleMessage("Синхронизация"),
    "system_mode": MessageLookupByLibrary.simpleMessage("Как в системе"),
    "system_prompt": MessageLookupByLibrary.simpleMessage("Системный промпт"),
    "take_photo": MessageLookupByLibrary.simpleMessage("Сделать фото"),
    "target_text": m51,
    "technical_research_group": MessageLookupByLibrary.simpleMessage(
      "Группа технических исследований",
    ),
    "temperature_with_value": m52,
    "test_data": MessageLookupByLibrary.simpleMessage("Тестовые данные"),
    "test_result": MessageLookupByLibrary.simpleMessage("Результат теста"),
    "test_results": MessageLookupByLibrary.simpleMessage("Результаты тестов"),
    "testing": MessageLookupByLibrary.simpleMessage("Тестирование..."),
    "text": MessageLookupByLibrary.simpleMessage("Текст"),
    "text_color": MessageLookupByLibrary.simpleMessage("Цвет текста"),
    "text_completion_mode": MessageLookupByLibrary.simpleMessage(
      "Режим дополнения текста",
    ),
    "the_puzzle_is_not_valid": MessageLookupByLibrary.simpleMessage(
      "Судоку недействителен",
    ),
    "theme_dim": MessageLookupByLibrary.simpleMessage("Приглушенный"),
    "theme_light": MessageLookupByLibrary.simpleMessage("Светлый"),
    "theme_lights_out": MessageLookupByLibrary.simpleMessage("Чёрный"),
    "then_you_can_start_to_chat_with_rwkv":
        MessageLookupByLibrary.simpleMessage(
          "Затем вы можете начать общаться с RWKV",
        ),
    "think_button_mode_en": m53,
    "think_button_mode_en_long": m54,
    "think_button_mode_en_short": m55,
    "think_button_mode_fast": m56,
    "think_mode_selector_message": MessageLookupByLibrary.simpleMessage(
      "Режим мышления влияет на производительность модели при рассуждениях",
    ),
    "think_mode_selector_recommendation": MessageLookupByLibrary.simpleMessage(
      "Рекомендуется выбрать как минимум «Мышление-Быстро»",
    ),
    "think_mode_selector_title": MessageLookupByLibrary.simpleMessage(
      "Выберите режим мышления",
    ),
    "thinking": MessageLookupByLibrary.simpleMessage("Думаю..."),
    "thinking_mode_alert_footer": MessageLookupByLibrary.simpleMessage("Режим"),
    "thinking_mode_auto": m57,
    "thinking_mode_high": m58,
    "thinking_mode_off": m59,
    "thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "Шаблон режима мышления",
    ),
    "this_is_the_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage("Это самый сложный судоку в мире"),
    "this_model_does_not_support_batch_inference":
        MessageLookupByLibrary.simpleMessage(
          "Эта модель не поддерживает парралельный вывод, выберите модель с тегом \"batch\"",
        ),
    "thought_result": MessageLookupByLibrary.simpleMessage(
      "Результат размышлений",
    ),
    "top_p_with_value": m60,
    "total_count": MessageLookupByLibrary.simpleMessage("Общее количество"),
    "total_disk_usage": MessageLookupByLibrary.simpleMessage(
      "Использование места хранения",
    ),
    "total_test_items": m61,
    "translate": MessageLookupByLibrary.simpleMessage("Перевод"),
    "translating": MessageLookupByLibrary.simpleMessage("Перевод..."),
    "translation": MessageLookupByLibrary.simpleMessage("Перевод"),
    "translator_debug_info": MessageLookupByLibrary.simpleMessage(
      "Отладочная информация переводчика",
    ),
    "tts": MessageLookupByLibrary.simpleMessage("Текст в речь"),
    "tts_detail": MessageLookupByLibrary.simpleMessage(
      "Позволить RWKV выводить голос",
    ),
    "tts_is_running_please_wait": MessageLookupByLibrary.simpleMessage(
      "Синтез речи уже выполняется, дождитесь завершения",
    ),
    "tts_voice_source_file_panel_hint": MessageLookupByLibrary.simpleMessage(
      "Сгенерировать речь, используя голос аудиофайла ниже",
    ),
    "tts_voice_source_file_subtitle": MessageLookupByLibrary.simpleMessage(
      "Выберите WAV‑файл, который RWKV будет имитировать",
    ),
    "tts_voice_source_file_title": MessageLookupByLibrary.simpleMessage(
      "Аудиофайл",
    ),
    "tts_voice_source_my_voice_subtitle": MessageLookupByLibrary.simpleMessage(
      "Запишите свой голос, чтобы RWKV мог его имитировать",
    ),
    "tts_voice_source_my_voice_title": MessageLookupByLibrary.simpleMessage(
      "Мой голос",
    ),
    "tts_voice_source_preset_subtitle": MessageLookupByLibrary.simpleMessage(
      "Выберите один из встроенных предустановленных голосов RWKV",
    ),
    "tts_voice_source_preset_title": MessageLookupByLibrary.simpleMessage(
      "Предустановленный голос",
    ),
    "tts_voice_source_sheet_subtitle": MessageLookupByLibrary.simpleMessage(
      "Выберите способ, которым вы хотите предоставить образец голоса",
    ),
    "tts_voice_source_sheet_title": MessageLookupByLibrary.simpleMessage(
      "Выберите голос, который RWKV будет имитировать",
    ),
    "turn_transfer": MessageLookupByLibrary.simpleMessage("Переход хода"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ui_font_setting": MessageLookupByLibrary.simpleMessage(
      "Настройка шрифта интерфейса",
    ),
    "ultra_large": MessageLookupByLibrary.simpleMessage("Огромный (140%)"),
    "unknown": MessageLookupByLibrary.simpleMessage("Неизвестно"),
    "unzipping": MessageLookupByLibrary.simpleMessage("Распаковка"),
    "update_now": MessageLookupByLibrary.simpleMessage("Обновить сейчас"),
    "updated_at": MessageLookupByLibrary.simpleMessage("Обновлено"),
    "use_default_line_height": MessageLookupByLibrary.simpleMessage(
      "Использовать межстрочный интервал по умолчанию",
    ),
    "use_it_now": MessageLookupByLibrary.simpleMessage("Использовать сейчас"),
    "user": MessageLookupByLibrary.simpleMessage("Пользователь:"),
    "user_message_actions_panel_empty": MessageLookupByLibrary.simpleMessage(
      "Для этого сообщения нет доступных действий",
    ),
    "user_message_actions_panel_switch_branch_subtitle":
        MessageLookupByLibrary.simpleMessage(
          "Переключайте соседние ветки кнопками «Назад» / «Вперёд»",
        ),
    "user_message_actions_panel_switch_branch_title":
        MessageLookupByLibrary.simpleMessage("Переключение ветки"),
    "user_message_actions_panel_title": MessageLookupByLibrary.simpleMessage(
      "Операции с сообщением",
    ),
    "user_message_branch_switched": MessageLookupByLibrary.simpleMessage(
      "Ветка переключена",
    ),
    "using_custom_directory": MessageLookupByLibrary.simpleMessage(
      "Используется пользовательский каталог",
    ),
    "using_default_directory": MessageLookupByLibrary.simpleMessage(
      "Используется каталог по умолчанию",
    ),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "Значение должно быть от 0 до 9",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("Очень маленький (80%)"),
    "visual_understanding_and_ocr": MessageLookupByLibrary.simpleMessage(
      "Визуальное понимание и OCR",
    ),
    "voice_cloning": MessageLookupByLibrary.simpleMessage(
      "Клонирование голоса",
    ),
    "we_support_npu_socs": MessageLookupByLibrary.simpleMessage(
      "В настоящее время поддерживается NPU следующих чипов SoC:",
    ),
    "web_search": MessageLookupByLibrary.simpleMessage("Поиск в сети"),
    "web_search_template": MessageLookupByLibrary.simpleMessage(
      "Шаблон веб-поиска",
    ),
    "websocket_service_port": m62,
    "weights_mangement": MessageLookupByLibrary.simpleMessage(
      "Управление файлами весов",
    ),
    "weights_saving_directory": MessageLookupByLibrary.simpleMessage(
      "Директория сохранения файлов весов",
    ),
    "welcome_to_rwkv_chat": MessageLookupByLibrary.simpleMessage(
      "Добро пожаловать в RWKV Чат",
    ),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage(
      "Добро пожаловать в RWKV",
    ),
    "what_is_pth_file_message": MessageLookupByLibrary.simpleMessage(
      ".pth файлы — это файлы весов, загружаемые напрямую из локальной файловой системы, без загрузки с сервера.\n\nМодели, обученные в PyTorch, часто сохраняются как .pth файлы.\n\nRWKV Chat поддерживает загрузку .pth файлов.",
    ),
    "what_is_pth_file_title": MessageLookupByLibrary.simpleMessage(
      "Что такое .pth файл?",
    ),
    "white": MessageLookupByLibrary.simpleMessage("Белые"),
    "white_score": MessageLookupByLibrary.simpleMessage("Счет белых"),
    "white_wins": MessageLookupByLibrary.simpleMessage("Белые победили!"),
    "window_id": m63,
    "windows_architecture_mismatch_dialog_message": m64,
    "windows_architecture_mismatch_dialog_title":
        MessageLookupByLibrary.simpleMessage("Несоответствие архитектуры"),
    "windows_architecture_mismatch_warning": m65,
    "world": MessageLookupByLibrary.simpleMessage("See"),
    "x_message_selected": MessageLookupByLibrary.simpleMessage(
      "Выбрано %d сообщений",
    ),
    "x_pages_found": MessageLookupByLibrary.simpleMessage("Найдено %d страниц"),
    "x_tabs": m66,
    "you_are_now_using": m67,
    "you_can_now_start_to_chat_with_rwkv": MessageLookupByLibrary.simpleMessage(
      "Теперь вы можете начать общаться с RWKV",
    ),
    "you_can_record_your_voice_and_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage(
          "Вы можете записать свой голос, и RWKV его имитирует.",
        ),
    "you_can_select_a_role_to_chat": MessageLookupByLibrary.simpleMessage(
      "Вы можете выбрать роль для общения",
    ),
    "your_device": MessageLookupByLibrary.simpleMessage("Ваше устройство: "),
    "your_voice_is_empty": MessageLookupByLibrary.simpleMessage(
      "Данные вашего голоса пусты, проверьте микрофон",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "Ваш голос слишком короткий, удерживайте кнопку дольше, чтобы записать голос.",
    ),
    "zh_to_en": MessageLookupByLibrary.simpleMessage("КН->АН"),
  };
}
