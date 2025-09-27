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

  static String m0(count) => "Ветка × ${count}";

  static String m1(count) => "Каждый вывод сгенерирует ${count} сообщений";

  static String m2(count) =>
      "Ветвление, генерируется ${count} сообщений одновременно";

  static String m3(index) => "Выбрано ${index} сообщение";

  static String m4(demoName) => "Добро пожаловать в ${demoName}";

  static String m5(maxLength) =>
      "Название диалога не может превышать ${maxLength} символов";

  static String m6(path) =>
      "Записи сообщений будут сохранены в следующей папке\n ${path}";

  static String m7(port) => "HTTP-сервис (Порт: ${port})";

  static String m8(flag, nameCN, nameEN) =>
      "Имитировать голос ${flag} ${nameEN} (${nameCN})";

  static String m9(fileName) => "Имитировать ${fileName}";

  static String m10(memUsed, memFree) =>
      "Использовано памяти: ${memUsed}, Свободно памяти: ${memFree}";

  static String m11(count) => "В очереди: ${count}";

  static String m12(port) => "WebSocket-сервис (Порт: ${port})";

  static String m13(id) => "Окно ${id}";

  static String m14(count) => "${count} вкладок";

  static String m15(modelName) => "Вы сейчас используете ${modelName}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Completion": MessageLookupByLibrary.simpleMessage("Режим дополнения"),
    "about": MessageLookupByLibrary.simpleMessage("О приложении"),
    "according_to_the_following_audio_file":
        MessageLookupByLibrary.simpleMessage("Согласно: "),
    "advance_settings": MessageLookupByLibrary.simpleMessage(
      "Расширенные настройки",
    ),
    "all": MessageLookupByLibrary.simpleMessage("Все"),
    "all_done": MessageLookupByLibrary.simpleMessage("Все готово"),
    "all_prompt": MessageLookupByLibrary.simpleMessage("Все промпты"),
    "allow_background_downloads": MessageLookupByLibrary.simpleMessage(
      "Разрешить фоновые загрузки",
    ),
    "analysing_result": MessageLookupByLibrary.simpleMessage(
      "Анализ результатов поиска",
    ),
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
    "ask_me_anything": MessageLookupByLibrary.simpleMessage(
      "Спроси меня о чем угодно...",
    ),
    "assistant": MessageLookupByLibrary.simpleMessage("RWKV:"),
    "auto": MessageLookupByLibrary.simpleMessage("Автоматически"),
    "auto_detect": MessageLookupByLibrary.simpleMessage("Автоопределение"),
    "back_to_chat": MessageLookupByLibrary.simpleMessage("Вернуться в чат"),
    "balanced": MessageLookupByLibrary.simpleMessage("Сбалансированный"),
    "batch_inference": MessageLookupByLibrary.simpleMessage("Ветвление"),
    "batch_inference_button": m0,
    "batch_inference_count": MessageLookupByLibrary.simpleMessage(
      "Количество параллельных ответов",
    ),
    "batch_inference_count_detail": m1,
    "batch_inference_detail": MessageLookupByLibrary.simpleMessage(
      "После включения ветвления RWKV может генерировать несколько ответов одновременно",
    ),
    "batch_inference_enable_or_not": MessageLookupByLibrary.simpleMessage(
      "Включить или выключить ветвление",
    ),
    "batch_inference_running": m2,
    "batch_inference_selected": m3,
    "batch_inference_settings": MessageLookupByLibrary.simpleMessage(
      "Настройки Ветвления",
    ),
    "batch_inference_short": MessageLookupByLibrary.simpleMessage("Ветвление"),
    "batch_inference_width": MessageLookupByLibrary.simpleMessage(
      "Ширина отображения сообщения",
    ),
    "batch_inference_width_detail": MessageLookupByLibrary.simpleMessage(
      "Ширина каждого сообщения при ветвлении",
    ),
    "beginner": MessageLookupByLibrary.simpleMessage("Новичок"),
    "benchmark": MessageLookupByLibrary.simpleMessage(
      "Тест производительности",
    ),
    "benchmark_result": MessageLookupByLibrary.simpleMessage(
      "Результат теста производительности",
    ),
    "black": MessageLookupByLibrary.simpleMessage("Черные"),
    "black_score": MessageLookupByLibrary.simpleMessage("Счет черных"),
    "black_wins": MessageLookupByLibrary.simpleMessage("Черные победили!"),
    "bot_message_edited": MessageLookupByLibrary.simpleMessage(
      "Сообщение бота отредактировано, теперь вы можете отправить новое сообщение",
    ),
    "browser_status": MessageLookupByLibrary.simpleMessage("Статус браузера"),
    "cached_translations_disk": MessageLookupByLibrary.simpleMessage(
      "Кэшированные переводы (диск)",
    ),
    "cached_translations_memory": MessageLookupByLibrary.simpleMessage(
      "Кэшированные переводы (память)",
    ),
    "can_not_generate": MessageLookupByLibrary.simpleMessage(
      "Не удалось сгенерировать",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Отмена"),
    "cancel_download": MessageLookupByLibrary.simpleMessage(
      "Отменить загрузку",
    ),
    "cancel_update": MessageLookupByLibrary.simpleMessage("Не сейчас"),
    "change": MessageLookupByLibrary.simpleMessage("Изменить"),
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
    "chat_welcome_to_use": m4,
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
    "click_to_load_image": MessageLookupByLibrary.simpleMessage(
      "Нажмите, чтобы загрузить изображение",
    ),
    "click_to_select_model": MessageLookupByLibrary.simpleMessage(
      "Нажмите, чтобы выбрать модель",
    ),
    "color_theme_follow_system": MessageLookupByLibrary.simpleMessage(
      "Цветовая схема как в системе",
    ),
    "completion_mode": MessageLookupByLibrary.simpleMessage("Режим дополнения"),
    "confirm": MessageLookupByLibrary.simpleMessage("Подтвердить"),
    "conservative": MessageLookupByLibrary.simpleMessage("Консервативный"),
    "continue_download": MessageLookupByLibrary.simpleMessage(
      "Продолжить загрузку",
    ),
    "continue_using_smaller_model": MessageLookupByLibrary.simpleMessage(
      "Продолжить использовать меньшую модель",
    ),
    "conversation_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Название диалога не может быть пустым",
    ),
    "conversation_name_cannot_be_longer_than_30_characters": m5,
    "conversations": MessageLookupByLibrary.simpleMessage("Диалоги"),
    "copy_text": MessageLookupByLibrary.simpleMessage("Копировать текст"),
    "create_a_new_one_by_clicking_the_button_above":
        MessageLookupByLibrary.simpleMessage(
          "Нажмите кнопку выше, чтобы создать новую сессию",
        ),
    "created_at": MessageLookupByLibrary.simpleMessage("Создано"),
    "creative": MessageLookupByLibrary.simpleMessage("Творческий"),
    "current_task_tab_id": MessageLookupByLibrary.simpleMessage(
      "ID вкладки текущей задачи",
    ),
    "current_task_text_length": MessageLookupByLibrary.simpleMessage(
      "Длина текста текущей задачи",
    ),
    "current_task_url": MessageLookupByLibrary.simpleMessage(
      "URL текущей задачи",
    ),
    "current_turn": MessageLookupByLibrary.simpleMessage("Текущий ход"),
    "custom": MessageLookupByLibrary.simpleMessage("Пользовательский"),
    "custom_difficulty": MessageLookupByLibrary.simpleMessage(
      "Пользовательская сложность",
    ),
    "dark_mode": MessageLookupByLibrary.simpleMessage("Тёмный режим"),
    "dark_mode_theme": MessageLookupByLibrary.simpleMessage(
      "Тема тёмного режима",
    ),
    "decode": MessageLookupByLibrary.simpleMessage("вывод"),
    "decode_param": MessageLookupByLibrary.simpleMessage("Параметры модели"),
    "deep_web_search": MessageLookupByLibrary.simpleMessage("Глубокий поиск"),
    "default_": MessageLookupByLibrary.simpleMessage("По умолчанию"),
    "delete": MessageLookupByLibrary.simpleMessage("Удалить"),
    "delete_all": MessageLookupByLibrary.simpleMessage("Удалить все"),
    "delete_conversation": MessageLookupByLibrary.simpleMessage(
      "Удалить диалог",
    ),
    "delete_conversation_message": MessageLookupByLibrary.simpleMessage(
      "Вы уверены, что хотите удалить этот диалог?",
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
    "dump_see_files_alert_message": m6,
    "dump_see_files_subtitle": MessageLookupByLibrary.simpleMessage(
      "Помогите нам улучшить алгоритм",
    ),
    "dump_started": MessageLookupByLibrary.simpleMessage(
      "Автоматический дамп включен",
    ),
    "dump_stopped": MessageLookupByLibrary.simpleMessage(
      "Автоматический дамп выключен",
    ),
    "enabled": MessageLookupByLibrary.simpleMessage("Включено"),
    "end": MessageLookupByLibrary.simpleMessage("Конец"),
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
    "expert": MessageLookupByLibrary.simpleMessage("Эксперт"),
    "explore_rwkv": MessageLookupByLibrary.simpleMessage("Исследовать RWKV"),
    "exploring": MessageLookupByLibrary.simpleMessage("Исследую..."),
    "export_conversation_failed": MessageLookupByLibrary.simpleMessage(
      "Не удалось экспортировать диалог",
    ),
    "export_conversation_to_txt": MessageLookupByLibrary.simpleMessage(
      "Экспортировать диалог в файл .txt",
    ),
    "export_data": MessageLookupByLibrary.simpleMessage("Экспорт данных"),
    "export_title": MessageLookupByLibrary.simpleMessage("Название диалога:"),
    "extra_large": MessageLookupByLibrary.simpleMessage("Очень большой (130%)"),
    "feedback": MessageLookupByLibrary.simpleMessage("Обратная связь"),
    "filter": MessageLookupByLibrary.simpleMessage(
      "Я пока не могу ответить на этот вопрос. Давайте поговорим на другую тему.",
    ),
    "finish_recording": MessageLookupByLibrary.simpleMessage(
      "Запись завершена",
    ),
    "fixed": MessageLookupByLibrary.simpleMessage("Фиксированный"),
    "follow_system": MessageLookupByLibrary.simpleMessage("Как в системе"),
    "follow_us_on_twitter": MessageLookupByLibrary.simpleMessage(
      "Следите за нами в Twitter",
    ),
    "font_setting": MessageLookupByLibrary.simpleMessage("Настройки шрифта"),
    "font_size": MessageLookupByLibrary.simpleMessage("Размер шрифта"),
    "font_size_default": MessageLookupByLibrary.simpleMessage(
      "По умолчанию (100%)",
    ),
    "foo_bar": MessageLookupByLibrary.simpleMessage("foo bar"),
    "force_dark_mode": MessageLookupByLibrary.simpleMessage(
      "Принудительный тёмный режим",
    ),
    "from_model": MessageLookupByLibrary.simpleMessage("От модели: %s"),
    "game_over": MessageLookupByLibrary.simpleMessage("Игра окончена!"),
    "generate": MessageLookupByLibrary.simpleMessage("Сгенерировать"),
    "generate_hardest_sudoku_in_the_world":
        MessageLookupByLibrary.simpleMessage(
          "Сгенерировать самый сложный судоку в мире",
        ),
    "generate_random_sudoku_puzzle": MessageLookupByLibrary.simpleMessage(
      "Сгенерировать случайный судоку",
    ),
    "generating": MessageLookupByLibrary.simpleMessage("Генерация..."),
    "github_repository": MessageLookupByLibrary.simpleMessage(
      "Репозиторий Github",
    ),
    "go_to_settings": MessageLookupByLibrary.simpleMessage(
      "Перейти в настройки",
    ),
    "hello_ask_me_anything": MessageLookupByLibrary.simpleMessage(
      "Привет, спроси меня \nо чем угодно...",
    ),
    "hide_stack": MessageLookupByLibrary.simpleMessage(
      "Скрыть стек цепочки мыслей",
    ),
    "hint_system_prompt": MessageLookupByLibrary.simpleMessage(
      "Пример: System: Ты — могущественная большая языковая модель RWKV, и ты всегда терпеливо отвечаешь на вопросы пользователей.",
    ),
    "hold_to_record_release_to_send": MessageLookupByLibrary.simpleMessage(
      "Удерживайте для записи, отпустите для отправки",
    ),
    "home": MessageLookupByLibrary.simpleMessage("Главная"),
    "http_service_port": m7,
    "human": MessageLookupByLibrary.simpleMessage("Человек"),
    "i_want_rwkv_to_say": MessageLookupByLibrary.simpleMessage(
      "Я хочу, чтобы RWKV сказал...",
    ),
    "idle": MessageLookupByLibrary.simpleMessage("Ожидание"),
    "imitate": m8,
    "imitate_fle": m9,
    "imitate_target": MessageLookupByLibrary.simpleMessage("Использовать"),
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
    "its_your_turn": MessageLookupByLibrary.simpleMessage("Твой ход~"),
    "join_our_discord_server": MessageLookupByLibrary.simpleMessage(
      "Присоединяйтесь к нашему серверу Discord",
    ),
    "join_the_community": MessageLookupByLibrary.simpleMessage(
      "Присоединиться к сообществу",
    ),
    "just_watch_me": MessageLookupByLibrary.simpleMessage(
      "😎 Смотри и наслаждайся!",
    ),
    "lan_server": MessageLookupByLibrary.simpleMessage("LAN-сервер"),
    "large": MessageLookupByLibrary.simpleMessage("Большой (120%)"),
    "lazy": MessageLookupByLibrary.simpleMessage("Ленивый"),
    "lazy_thinking_mode_template": MessageLookupByLibrary.simpleMessage(
      "Шаблон ленивого режима мышления",
    ),
    "license": MessageLookupByLibrary.simpleMessage(
      "Лицензия с открытым исходным кодом",
    ),
    "light_mode": MessageLookupByLibrary.simpleMessage("Светлый режим"),
    "load_": MessageLookupByLibrary.simpleMessage("Загрузить"),
    "loaded": MessageLookupByLibrary.simpleMessage("Загружено"),
    "loading": MessageLookupByLibrary.simpleMessage("Загрузка..."),
    "medium": MessageLookupByLibrary.simpleMessage("Средний (110%)"),
    "memory_used": m10,
    "message_content": MessageLookupByLibrary.simpleMessage(
      "Содержимое сообщения",
    ),
    "mode": MessageLookupByLibrary.simpleMessage("Режим"),
    "model": MessageLookupByLibrary.simpleMessage("Модель"),
    "model_loading": MessageLookupByLibrary.simpleMessage("Загрузка модели..."),
    "model_settings": MessageLookupByLibrary.simpleMessage("Настройки модели"),
    "model_size_increased_please_open_a_new_conversation":
        MessageLookupByLibrary.simpleMessage(
          "Размер модели увеличен, откройте новый диалог, чтобы улучшить качество диалога",
        ),
    "more": MessageLookupByLibrary.simpleMessage("Ещё"),
    "more_questions": MessageLookupByLibrary.simpleMessage("Больше вопросов"),
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
    "no_message_to_export": MessageLookupByLibrary.simpleMessage(
      "Нет сообщений для экспорта",
    ),
    "no_model_selected": MessageLookupByLibrary.simpleMessage(
      "Модель не выбрана",
    ),
    "no_puzzle": MessageLookupByLibrary.simpleMessage("Нет судоку"),
    "number": MessageLookupByLibrary.simpleMessage("Число"),
    "nyan_nyan": MessageLookupByLibrary.simpleMessage("Мрр~ Мрявк~"),
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
    "or_select_a_wav_file_to_let_rwkv_to_copy_it":
        MessageLookupByLibrary.simpleMessage(
          "Или выберите wav-файл, чтобы RWKV его имитировал.",
        ),
    "or_you_can_start_a_new_empty_chat": MessageLookupByLibrary.simpleMessage(
      "Или начать пустой чат",
    ),
    "othello_title": MessageLookupByLibrary.simpleMessage("RWKV Отелло"),
    "output": MessageLookupByLibrary.simpleMessage("Вывод"),
    "overseas": MessageLookupByLibrary.simpleMessage("(США)"),
    "pause": MessageLookupByLibrary.simpleMessage("Пауза"),
    "performance_test": MessageLookupByLibrary.simpleMessage(
      "Тест производительности",
    ),
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
    "please_select_a_branch_to_continue_the_conversation":
        MessageLookupByLibrary.simpleMessage(
          "Пожалуйста, выберите ветвь для продолжения диалога",
        ),
    "please_select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите тип задачи",
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
    "please_select_the_difficulty": MessageLookupByLibrary.simpleMessage(
      "Пожалуйста, выберите сложность",
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
    "prebuilt_voices": MessageLookupByLibrary.simpleMessage(
      "Предустановленные голоса",
    ),
    "prefer": MessageLookupByLibrary.simpleMessage("Использовать"),
    "prefer_chinese": MessageLookupByLibrary.simpleMessage("Китайский режим"),
    "prefill": MessageLookupByLibrary.simpleMessage("ввод"),
    "prompt": MessageLookupByLibrary.simpleMessage("Промпт"),
    "prompt_template": MessageLookupByLibrary.simpleMessage("Шаблон промпта"),
    "qq_group_1": MessageLookupByLibrary.simpleMessage("Группа QQ 1"),
    "qq_group_2": MessageLookupByLibrary.simpleMessage("Группа QQ 2"),
    "queued_x": m11,
    "quick_thinking": MessageLookupByLibrary.simpleMessage("Быстрое мышление"),
    "quick_thinking_enabled": MessageLookupByLibrary.simpleMessage(
      "Быстрое мышление включено",
    ),
    "reason": MessageLookupByLibrary.simpleMessage("Мышление"),
    "reasoning_enabled": MessageLookupByLibrary.simpleMessage("Режим мышления"),
    "recording_your_voice": MessageLookupByLibrary.simpleMessage(
      "Идет запись голоса...",
    ),
    "reference_source": MessageLookupByLibrary.simpleMessage("Источник"),
    "regenerate": MessageLookupByLibrary.simpleMessage("Сгенерировать заново"),
    "remaining": MessageLookupByLibrary.simpleMessage("Оставшееся время:"),
    "rename": MessageLookupByLibrary.simpleMessage("Переименовать"),
    "report_an_issue_on_github": MessageLookupByLibrary.simpleMessage(
      "Сообщить о проблеме на Github",
    ),
    "reselect_model": MessageLookupByLibrary.simpleMessage(
      "Выбрать модель заново",
    ),
    "reset": MessageLookupByLibrary.simpleMessage("Сброс"),
    "result": MessageLookupByLibrary.simpleMessage("Результат"),
    "resume": MessageLookupByLibrary.simpleMessage("Возобновить"),
    "rwkv": MessageLookupByLibrary.simpleMessage("RWKV"),
    "rwkv_chat": MessageLookupByLibrary.simpleMessage("RWKV Чат"),
    "rwkv_othello": MessageLookupByLibrary.simpleMessage("RWKV Отелло"),
    "save": MessageLookupByLibrary.simpleMessage("Сохранить"),
    "scan_qrcode": MessageLookupByLibrary.simpleMessage("Сканировать QR-код"),
    "screen_width": MessageLookupByLibrary.simpleMessage("Ширина экрана"),
    "search": MessageLookupByLibrary.simpleMessage("Поиск"),
    "search_breadth": MessageLookupByLibrary.simpleMessage("Ширина поиска"),
    "search_depth": MessageLookupByLibrary.simpleMessage("Глубина поиска"),
    "search_failed": MessageLookupByLibrary.simpleMessage("Ошибка поиска"),
    "searching": MessageLookupByLibrary.simpleMessage("Поиск..."),
    "select_a_model": MessageLookupByLibrary.simpleMessage("Выберите модель"),
    "select_a_world_type": MessageLookupByLibrary.simpleMessage(
      "Выберите тип задачи",
    ),
    "select_from_library": MessageLookupByLibrary.simpleMessage(
      "Выбрать из галереи",
    ),
    "select_image": MessageLookupByLibrary.simpleMessage("Выбрать изображение"),
    "select_model": MessageLookupByLibrary.simpleMessage("Выбрать модель"),
    "select_new_image": MessageLookupByLibrary.simpleMessage(
      "Выбрать новое изображение",
    ),
    "send_message_to_rwkv": MessageLookupByLibrary.simpleMessage(
      "Отправить сообщение в RWKV",
    ),
    "server_error": MessageLookupByLibrary.simpleMessage("Ошибка сервера"),
    "session_configuration": MessageLookupByLibrary.simpleMessage(
      "Конфигурация сессии",
    ),
    "set_the_value_of_grid": MessageLookupByLibrary.simpleMessage(
      "Установить значение ячейки",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Настройки"),
    "share": MessageLookupByLibrary.simpleMessage("Поделиться"),
    "share_chat": MessageLookupByLibrary.simpleMessage("Поделиться чатом"),
    "show_stack": MessageLookupByLibrary.simpleMessage(
      "Показать стек цепочки мыслей",
    ),
    "size_recommendation": MessageLookupByLibrary.simpleMessage(
      "Рекомендуется выбрать модель не менее 1.5B для лучших результатов",
    ),
    "small": MessageLookupByLibrary.simpleMessage("Маленький (90%)"),
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
    "start_service": MessageLookupByLibrary.simpleMessage("Запустить службу"),
    "start_service_and_open_browser": MessageLookupByLibrary.simpleMessage(
      "Запустите службу и откройте поддерживаемую страницу браузера.",
    ),
    "start_testing": MessageLookupByLibrary.simpleMessage(
      "Начать тестирование",
    ),
    "start_to_chat": MessageLookupByLibrary.simpleMessage("Начать чат"),
    "start_to_inference": MessageLookupByLibrary.simpleMessage("Начать вывод"),
    "starting": MessageLookupByLibrary.simpleMessage("Запуск..."),
    "status": MessageLookupByLibrary.simpleMessage("Статус"),
    "stop": MessageLookupByLibrary.simpleMessage("Стоп"),
    "stop_service": MessageLookupByLibrary.simpleMessage("Остановить службу"),
    "stopping": MessageLookupByLibrary.simpleMessage("Остановка..."),
    "storage_permission_not_granted": MessageLookupByLibrary.simpleMessage(
      "Разрешение на доступ к хранилищу не предоставлено",
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
    "submit": MessageLookupByLibrary.simpleMessage("Отправить"),
    "sudoku_easy": MessageLookupByLibrary.simpleMessage("Легкий"),
    "sudoku_hard": MessageLookupByLibrary.simpleMessage("Сложный"),
    "sudoku_medium": MessageLookupByLibrary.simpleMessage("Средний"),
    "suggest": MessageLookupByLibrary.simpleMessage("Рекомендовать"),
    "system_mode": MessageLookupByLibrary.simpleMessage("Как в системе"),
    "system_prompt": MessageLookupByLibrary.simpleMessage("Системный промпт"),
    "take_photo": MessageLookupByLibrary.simpleMessage("Сделать фото"),
    "technical_research_group": MessageLookupByLibrary.simpleMessage(
      "Группа технических исследований",
    ),
    "test_result": MessageLookupByLibrary.simpleMessage("Результат теста"),
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
    "thinking": MessageLookupByLibrary.simpleMessage("Думаю..."),
    "thinking_mode_auto": MessageLookupByLibrary.simpleMessage("Мысли: Авто"),
    "thinking_mode_detail_auto": MessageLookupByLibrary.simpleMessage(
      "Мышление: Автоматическое",
    ),
    "thinking_mode_detail_high": MessageLookupByLibrary.simpleMessage(
      "Мышление: Всегда",
    ),
    "thinking_mode_detail_off": MessageLookupByLibrary.simpleMessage(
      "Мышление: Выключено",
    ),
    "thinking_mode_high": MessageLookupByLibrary.simpleMessage("Мысли: Вкл"),
    "thinking_mode_off": MessageLookupByLibrary.simpleMessage("Мысли: Выкл"),
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
    "turn_transfer": MessageLookupByLibrary.simpleMessage("Переход хода"),
    "twitter": MessageLookupByLibrary.simpleMessage("Twitter"),
    "ultra_large": MessageLookupByLibrary.simpleMessage("Огромный (140%)"),
    "unknown": MessageLookupByLibrary.simpleMessage("Неизвестно"),
    "update_now": MessageLookupByLibrary.simpleMessage("Обновить сейчас"),
    "updated_at": MessageLookupByLibrary.simpleMessage("Обновлено"),
    "use_it_now": MessageLookupByLibrary.simpleMessage("Использовать сейчас"),
    "user": MessageLookupByLibrary.simpleMessage("Пользователь:"),
    "value_must_be_between_0_and_9": MessageLookupByLibrary.simpleMessage(
      "Значение должно быть от 0 до 9",
    ),
    "very_small": MessageLookupByLibrary.simpleMessage("Очень маленький (80%)"),
    "voice_cloning": MessageLookupByLibrary.simpleMessage(
      "Клонирование голоса",
    ),
    "web_search": MessageLookupByLibrary.simpleMessage("Поиск в сети"),
    "web_search_template": MessageLookupByLibrary.simpleMessage(
      "Шаблон веб-поиска",
    ),
    "websocket_service_port": m12,
    "welcome_to_rwkv_chat": MessageLookupByLibrary.simpleMessage(
      "Это RWKV Чат\n Добро пожаловать",
    ),
    "welcome_to_use_rwkv": MessageLookupByLibrary.simpleMessage(
      "Добро пожаловать в RWKV",
    ),
    "white": MessageLookupByLibrary.simpleMessage("Белые"),
    "white_score": MessageLookupByLibrary.simpleMessage("Счет белых"),
    "white_wins": MessageLookupByLibrary.simpleMessage("Белые победили!"),
    "window_id": m13,
    "x_message_selected": MessageLookupByLibrary.simpleMessage(
      "Выбрано %d сообщений",
    ),
    "x_pages_found": MessageLookupByLibrary.simpleMessage("Найдено %d страниц"),
    "x_tabs": m14,
    "you_are_now_using": m15,
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
    "your_voice_is_empty": MessageLookupByLibrary.simpleMessage(
      "Данные вашего голоса пусты, проверьте микрофон",
    ),
    "your_voice_is_too_short": MessageLookupByLibrary.simpleMessage(
      "Ваш голос слишком короткий, удерживайте кнопку дольше, чтобы записать голос.",
    ),
  };
}
