// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/app_presentation.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/all_suggestion_dialog.dart';
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
  const Empty({super.key, this.presentation});

  final AppPresentation? presentation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final messages = ref.watch(P.msg.list);
    if (messages.isNotEmpty) return Positioned.fill(child: IgnorePointer(child: Container()));
    if (presentation case final presentation?) {
      return Positioned.fill(child: _EmptyV2ScrollView(presentation: presentation));
    }
    final loaded = ref.watch(P.rwkvModel.loaded);
    final currentModel = ref.watch(P.rwkvModel.latest);

    final demoType = ref.watch(P.app.demoType);
    final currentWorldType = ref.watch(P.rwkvContext.currentWorldType);
    String logoPath = "assets/img/${demoType.name}/logo.square.png";

    final hasSpecificEmpty = demoType == .see && currentWorldType != null;

    final primary = theme.colorScheme.primary;

    final inputHeight = ref.watch(P.chat.inputHeight);
    final version = ref.watch(P.app.version);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutBack,
      bottom: hasSpecificEmpty ? -2000 : 0,
      left: 0,
      right: 0,
      top: 0,
      child: AnimatedOpacity(
        opacity: hasSpecificEmpty ? 0 : 1,
        duration: const Duration(milliseconds: 200),
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
                      const Flexible(child: _EmptyV2ScrollView()),
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
                      Image.asset(logoPath, width: 140),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 4,
                        crossAxisAlignment: .end,
                        children: [
                          Opacity(
                            opacity: 0.0,
                            child: Text(version, style: const TextStyle(fontSize: 10)),
                          ),
                          Text(s.chat_welcome_to_use(Config.appTitle), style: const TextStyle(fontSize: 18, fontWeight: .w600)),
                          Opacity(
                            opacity: 0.5,
                            child: Padding(
                              padding: const .only(bottom: 4),
                              child: Text(version, style: const TextStyle(fontSize: 10)),
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
                            style: const TextStyle(fontSize: 16, fontWeight: .w600),
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
                            style: TextStyle(fontSize: 16, fontWeight: .w600, color: primary),
                          ),
                        ),
                      const Spacer(),
                      if (demoType == .tts) SizedBox(height: inputHeight / 1.5),
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

class _EmptyV2ScrollView extends StatefulWidget {
  const _EmptyV2ScrollView({this.presentation});

  final AppPresentation? presentation;

  @override
  State<_EmptyV2ScrollView> createState() => _EmptyV2ScrollViewState();
}

class _EmptyV2ScrollViewState extends State<_EmptyV2ScrollView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: false,
      trackVisibility: false,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: _EmptyV2(presentation: widget.presentation),
      ),
    );
  }
}

class _EmptyV2 extends ConsumerWidget {
  const _EmptyV2({this.presentation});

  final AppPresentation? presentation;

  String _normalizeCategory(String? category) {
    if (category == null) return "";
    return category.trim().toLowerCase();
  }

  Color _suggestionColor(
    ThemeData theme,
    dynamic suggestion,
  ) {
    if (suggestion is! Suggestion) return theme.colorScheme.primary.withValues(alpha: .82);

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
    return theme.colorScheme.primary.withValues(alpha: .82);
  }

  void _onTap(dynamic suggestion) {
    if (!checkModelSelection(preferredDemoType: .chat)) return;
    final s = (suggestion as Suggestion);
    P.chat.send(s.prompt.isEmpty ? s.display : s.prompt);
  }

  Future<void> _showMore(BuildContext context) async {
    final suggestion = await AllSuggestionDialog.show(context);
    if (suggestion != null) _onTap(suggestion);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final suggestions = ref.watch(P.suggestion.suggestion);
    if (presentation case final presentation?) {
      final prompts = ref.watch(P.suggestion.chatSuggestions);
      final style = ref.watch(P.preference.appStyle);
      final centered = presentation.prompts == .centered;
      final colors = theme.colorScheme;
      return Padding(
        padding: const .fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: centered ? .center : .start,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 22, color: colors.primary),
            const SizedBox(height: 8),
            Text(
              s.hello_ask_me_anything.replaceAll(RegExp(r'\s+'), ' '),
              style: theme.textTheme.headlineSmall,
              textAlign: centered ? .center : .start,
            ),
            if (prompts.isNotEmpty) ...[
              Wrap(
                crossAxisAlignment: .center,
                alignment: centered ? .center : .start,
                children: [
                  TextButton(onPressed: () => _showMore(context), child: Text(s.more_questions)),
                  IconButton(
                    tooltip: s.refresh,
                    onPressed: P.suggestion.refreshChatSuggestions,
                    icon: const Icon(Icons.refresh, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, constraints) {
                  final arrangement = presentation.prompts;
                  final minGridWidth = MediaQuery.textScalerOf(context).scale(14) / 14 * 348;
                  final useColumns = (arrangement == .grid || arrangement == .feature) && constraints.maxWidth >= minGridWidth;
                  final pairedStart = useColumns && arrangement == .feature ? 1 : 0;
                  final shape = RoundedRectangleBorder(borderRadius: .circular(style.radius));
                  Widget promptCard(int index) {
                    final prompt = prompts[index];
                    return Material(
                      color: arrangement == .feature && index == 0 ? colors.primaryContainer : colors.surfaceContainerHigh,
                      shape: shape,
                      child: InkWell(
                        customBorder: shape,
                        onTap: () => _onTap(prompt),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const .symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_outward, size: 18, color: colors.primary),
                                const SizedBox(width: 10),
                                Expanded(child: Text(prompt.display)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      if (pairedStart == 1) promptCard(0),
                      for (int index = pairedStart; index < prompts.length; index += useColumns ? 2 : 1) ...[
                        if (index > 0) const SizedBox(height: 8),
                        if (useColumns)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: .stretch,
                              children: [
                                Expanded(child: promptCard(index)),
                                const SizedBox(width: 8),
                                Expanded(child: index + 1 < prompts.length ? promptCard(index + 1) : const SizedBox.shrink()),
                              ],
                            ),
                          )
                        else
                          promptCard(index),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      );
    }

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
                  onTap: () => _showMore(context),
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
