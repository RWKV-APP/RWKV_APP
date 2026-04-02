// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/all_suggestion_dialog.dart';
import 'package:zone/widgets/dev_options_panel.dart';
import 'package:zone/widgets/model_selector.dart';

const Color _lifeSuggestionColor = Color(0xFFD18B39);
const Color _careerSuggestionColor = Color(0xFF2F80ED);
const Color _familySuggestionColor = Color(0xFFDB6F8E);
const Color _creationSuggestionColor = Color(0xFF9A60F5);
const Color _rolePlaySuggestionColor = Color(0xFFB54ACB);
const Color _encyclopediaSuggestionColor = Color(0xFF1E9E93);
const Color _codeSuggestionColor = Color(0xFF4B5FD6);
const Color _mathematicsSuggestionColor = Color(0xFF2F9D57);

class Empty extends ConsumerWidget {
  const Empty({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final messages = ref.watch(P.msg.list);
    if (messages.isNotEmpty) return Positioned.fill(child: IgnorePointer(child: Container()));
    final loaded = ref.watch(P.rwkv.loaded);
    final currentModel = ref.watch(P.rwkv.latestModel);

    final demoType = ref.watch(P.app.demoType);
    final currentWorldType = ref.watch(P.rwkv.currentWorldType);
    String logoPath = "assets/img/${demoType.name}/logo.square.png";

    final hasSpecificEmpty = demoType == .see && currentWorldType != null;

    final primary = theme.colorScheme.primary;

    final inputHeight = ref.watch(P.chat.inputHeight);
    final version = ref.watch(P.app.version);

    return AnimatedPositioned(
      duration: 200.ms,
      curve: Curves.easeInOutBack,
      bottom: hasSpecificEmpty ? -2000 : 0,
      left: 0,
      right: 0,
      top: 0,
      child: AnimatedOpacity(
        opacity: hasSpecificEmpty ? 0 : 1,
        duration: 200.ms,
        curve: Curves.easeInOutBack,
        child: GestureDetector(
          onTap: () {
            P.chat.focusNode.unfocus();
            P.talk.dismissAllShown();
          },
          child: Stack(
            children: [
              if (demoType == .chat)
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .stretch,
                    children: [
                      const SizedBox(height: 90),
                      const Flexible(
                        child: Scrollbar(
                          thumbVisibility: false,
                          trackVisibility: false,
                          child: SingleChildScrollView(
                            child: _EmptyV2(),
                          ),
                        ),
                      ),
                      SizedBox(height: inputHeight.toDouble()),
                    ],
                  ),
                ),
              if (demoType != .chat)
                Positioned.fill(
                  left: 32,
                  right: 32,
                  child: Column(
                    crossAxisAlignment: .center,
                    children: [
                      const Spacer(),
                      DevOptionsPanel.trigger(child: Image.asset(logoPath, width: 140)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 4,
                        crossAxisAlignment: .end,
                        children: [
                          Opacity(
                            opacity: 0.0,
                            child: Text(version, style: const TS(s: 10)),
                          ),
                          Text(s.chat_welcome_to_use(Config.appTitle), style: const TS(s: 18, w: .w600)),
                          Opacity(
                            opacity: 0.5,
                            child: Padding(
                              padding: const .only(bottom: 4),
                              child: Text(version, style: const TS(s: 10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Text(s.intro),
                      ),
                      const SizedBox(height: 12),
                      if (!loaded) Text(s.start_a_new_chat_by_clicking_the_button_below),
                      if (!loaded) const SizedBox(height: 12),
                      if (!loaded)
                        TextButton(
                          onPressed: () async {
                            ModelSelector.show();
                          },
                          child: Text(
                            demoType == .see ? s.select_a_world_type : s.select_a_model,
                            style: const TS(s: 16, w: .w600),
                          ),
                        ),
                      if (!loaded) const SizedBox(height: 12),
                      if (loaded) Text(s.you_are_now_using("")),
                      const SizedBox(height: 4),
                      if (loaded)
                        Container(
                          padding: const .symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            border: .all(color: primary),
                            borderRadius: .circular(4),
                          ),
                          child: Text(
                            currentModel?.name ?? "",
                            style: TS(s: 16, w: .w600, c: primary),
                          ),
                        ),
                      const Spacer(),
                      if (demoType == .tts) (inputHeight / 1.5).h,
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyV2 extends ConsumerWidget {
  const _EmptyV2();

  String _normalizeCategory(String? category) {
    if (category == null) return "";
    return category.trim().toLowerCase();
  }

  Color _suggestionColor(
    ThemeData theme,
    dynamic suggestion,
  ) {
    if (suggestion is! Suggestion) return theme.colorScheme.primary.q(.82);

    switch (_normalizeCategory(suggestion.category)) {
      case "life":
      case "日常生活":
      case "常识":
        return _lifeSuggestionColor;
      case "career":
      case "职场学业":
        return _careerSuggestionColor;
      case "family":
      case "家庭亲子":
        return _familySuggestionColor;
      case "creation":
      case "创作":
        return _creationSuggestionColor;
      case "role_play":
      case "roleplay":
      case "角色扮演":
        return _rolePlaySuggestionColor;
      case "encyclopedia":
      case "百科":
        return _encyclopediaSuggestionColor;
      case "code":
      case "代码":
        return _codeSuggestionColor;
      case "mathematics":
      case "数学":
        return _mathematicsSuggestionColor;
    }
    return theme.colorScheme.primary.q(.82);
  }

  void _onTap(dynamic suggestion) {
    if (!checkModelSelection(preferredDemoType: .chat)) return;
    final s = (suggestion as Suggestion);
    P.chat.send(s.prompt.isEmpty ? s.display : s.prompt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final suggestions = ref.watch(P.suggestion.suggestion);

    final appTheme = ref.watch(P.app.theme);
    final bgColor = appTheme.qb144;

    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      children: [
        const SizedBox(height: 16),
        Text(
          s.hello_ask_me_anything,
          style: const TextStyle(fontSize: 32, fontWeight: .bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        for (final item in suggestions) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const .symmetric(horizontal: 24),
            child: Material(
              borderRadius: .circular(60),
              color: bgColor,
              child: InkWell(
                borderRadius: .circular(60),
                onTap: () => _onTap(item),
                child: Padding(
                  padding: const .symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: _suggestionColor(theme, item),
                          borderRadius: .circular(60),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          item is Suggestion ? item.display : item.toString(),
                          maxLines: 1,
                          overflow: .ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        if (suggestions.isNotEmpty) const SizedBox(height: 12),
        if (suggestions.isNotEmpty)
          Row(
            mainAxisSize: .min,
            children: [
              Material(
                borderRadius: .circular(60),
                color: bgColor,
                child: InkWell(
                  borderRadius: .circular(60),
                  onTap: () async {
                    final suggestion = await AllSuggestionDialog.show(context);
                    if (suggestion != null) _onTap(suggestion);
                  },
                  child: Padding(
                    padding: const .symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      S.current.more_questions,
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                borderRadius: .circular(60),
                color: bgColor,
                child: InkWell(
                  borderRadius: .circular(60),
                  onTap: P.suggestion.refreshChatSuggestions,
                  child: const Padding(
                    padding: .symmetric(horizontal: 12, vertical: 12),
                    child: Icon(Icons.refresh, size: 16),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
