// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:halo_alert/halo_alert.dart';

// Project imports:
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/model/prompt_template.dart' show PromptTemplate;
import 'package:zone/store/p.dart' show P, $Preference;

class ChatTemplateDialog extends StatefulWidget {
  final bool newChat;
  final bool webSearch;
  final bool thinking;
  final bool systemPrompt;

  const ChatTemplateDialog({
    super.key,
    this.newChat = false,
    this.webSearch = false,
    this.thinking = false,
    this.systemPrompt = false,
  });

  static void show(
    BuildContext context, {
    bool newChat = false,
    bool webSearch = false,
    bool thinking = false,
    bool systemPrompt = false,
  }) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (c) => ChatTemplateDialog(
        newChat: newChat,
        webSearch: webSearch,
        thinking: thinking,
        systemPrompt: systemPrompt,
      ),
    );
  }

  @override
  State<ChatTemplateDialog> createState() => _ChatTemplateDialogState();
}

class _ChatTemplateDialogState extends State<ChatTemplateDialog> {
  late final TextEditingController _controllerFree;
  late final TextEditingController _controllerPreferChinese;
  late final TextEditingController _controllerLighting;
  late final TextEditingController _controllerNewChat;
  late final TextEditingController _controllerWebSearch;
  late final TextEditingController _controllerWebSearchChinese;
  late final TextEditingController _controllerSystemPrompt;
  late final TextEditingController _controllerFast;

  @override
  void initState() {
    super.initState();
    final template = P.preference.promptTemplate;
    _controllerFree = TextEditingController(text: template.thinkingFree);
    _controllerPreferChinese = TextEditingController(text: template.thinkingWithChinese);
    _controllerLighting = TextEditingController(text: template.thinkingLighting);
    _controllerNewChat = TextEditingController(text: template.newChatTemplate);
    _controllerWebSearch = TextEditingController(text: template.webSearchTemplate);
    _controllerWebSearchChinese = TextEditingController(text: template.webSearchChineseTemplate);
    _controllerSystemPrompt = TextEditingController(text: template.systemPrompt);
    _controllerFast = TextEditingController(text: template.thinkingFast);
  }

  void onApplyTap() async {
    final template = PromptTemplate(
      thinkingWithChinese: _controllerPreferChinese.text.trim(),
      thinkingLighting: _controllerLighting.text.trim(),
      thinkingFast: _controllerFast.text.trim(),
      thinkingFree: _controllerFree.text.trim(),
      newChatTemplate: _controllerNewChat.text.trim(),
      webSearchTemplate: _controllerWebSearch.text.trim(),
      webSearchChineseTemplate: _controllerWebSearchChinese.text.trim(),
      systemPrompt: _controllerSystemPrompt.text.trim(),
    );
    if (!template.webSearchTemplate.startsWith("%s") || !template.webSearchTemplate.endsWith("%s")) {
      Alert.warning('联网搜索模板格式错误');
      return;
    }
    if (!template.webSearchChineseTemplate.startsWith("%s") || !template.webSearchChineseTemplate.endsWith("%s")) {
      Alert.warning('联网搜索模板格式错误');
      return;
    }
    P.preference.setThinkingModeUserTemplate(template);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    super.dispose();
    _controllerFree.dispose();
    _controllerPreferChinese.dispose();
    _controllerLighting.dispose();
    _controllerFast.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String title = '';
    if (widget.newChat) {
      title = S.current.new_chat_template;
    } else if (widget.webSearch) {
      title = S.current.web_search_template;
    } else if (widget.thinking) {
      title = S.current.thinking_mode_template;
    } else if (widget.systemPrompt) {
      title = S.current.system_prompt;
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: Text(title, style: theme.textTheme.titleMedium),
            actions: [TextButton(onPressed: onApplyTap, child: Text(S.current.apply))],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const .symmetric(horizontal: 12),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  if (widget.systemPrompt) ...buildSystemPromptWidget(),

                  if (widget.newChat)
                    TextField(
                      controller: _controllerNewChat,
                      maxLines: 10,
                      decoration: InputDecoration(
                        labelText: S.current.new_chat_template,
                        labelStyle: const TextStyle(fontSize: 16),
                        border: const OutlineInputBorder(),
                        helperMaxLines: 10,
                        helperText: S.current.new_chat_template_helper_text,
                      ),
                    ),
                  if (widget.newChat) const SizedBox(height: 16),
                  if (widget.webSearch) ...[
                    TextField(
                      controller: _controllerWebSearch,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: S.current.web_search_template,
                        labelStyle: const TextStyle(fontSize: 16),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controllerWebSearchChinese,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: S.current.chinese_web_search_template,
                        labelStyle: const TextStyle(fontSize: 16),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.thinking) ...buildThinkingWidget(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildSystemPromptWidget() {
    void insertTextAtCursor(String text) {
      final sel = _controllerSystemPrompt.selection;
      _controllerSystemPrompt.text = _controllerSystemPrompt.text.replaceRange(sel.start, sel.end, text);
      _controllerSystemPrompt.selection = TextSelection.fromPosition(TextPosition(offset: sel.start + text.length));
    }

    return [
      TextField(
        controller: _controllerSystemPrompt,
        minLines: 1,
        maxLines: 16,
        decoration: InputDecoration(
          labelText: S.current.system_prompt,
          labelStyle: const TextStyle(fontSize: 16),
          border: const OutlineInputBorder(),
          hintText: S.current.hint_system_prompt,
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButtonTheme(
        data: OutlinedButtonThemeData(
          style: ButtonStyle(
            visualDensity: .compact,
            textStyle: .all(const TextStyle(fontSize: 12)),
            padding: .all(const .symmetric(horizontal: 12, vertical: 8)),
            minimumSize: .all(const Size(0, 36)),
            shape: .all(RoundedRectangleBorder(borderRadius: .circular(12))),
          ),
        ),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () {
                insertTextAtCursor('{{date}}');
              },
              child: Text(S.current.tag_date),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () {
                insertTextAtCursor('{{time}}');
              },
              child: Text(S.current.tag_time),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () {
                insertTextAtCursor('{{day_of_week}}');
              },
              child: Text(S.current.tag_day_of_week),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> buildThinkingWidget() {
    return [
      TextField(
        controller: _controllerFree,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: S.current.thinking_mode_template,
          labelStyle: const TextStyle(fontSize: 16),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _controllerPreferChinese,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: S.current.hint_chinese_thinking_mode_template,
          labelText: S.current.chinese_thinking_mode_template,
          labelStyle: const TextStyle(fontSize: 16),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButtonTheme(
        data: OutlinedButtonThemeData(
          style: ButtonStyle(
            visualDensity: .compact,
            textStyle: .all(const TextStyle(fontSize: 12)),
            padding: .all(const .symmetric(horizontal: 12, vertical: 8)),
            minimumSize: .all(const Size(0, 36)),
            shape: .all(RoundedRectangleBorder(borderRadius: .circular(12))),
          ),
        ),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () {
                _controllerPreferChinese.text = '<think>嗯';
              },
              child: const Text('<think>嗯'),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () {
                _controllerPreferChinese.text = '<think>首先';
              },
              child: const Text('<think>首先'),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () {
                _controllerPreferChinese.text = '<think>好的';
              },
              child: const Text('<think>好的'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _controllerLighting,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: S.current.lazy_thinking_mode_template,
          labelStyle: const TextStyle(fontSize: 16),
          border: const OutlineInputBorder(),
        ),
      ),
    ];
  }
}
