// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/language.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';

String _askQuestionLanguageLabel(S s, AskQuestionLanguage language) {
  return switch (language) {
    AskQuestionLanguage.simplifiedChinese => Language.zh_Hans.display!,
    AskQuestionLanguage.traditionalChinese => Language.zh_Hant.display!,
    AskQuestionLanguage.english => s.english,
    AskQuestionLanguage.japanese => s.japanese,
    AskQuestionLanguage.korean => s.korean,
    AskQuestionLanguage.russian => s.russian,
  };
}

class AskQuestionPanel extends ConsumerWidget {
  static const String panelKey = 'AskQuestionPanel';

  static Future<void> show() async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;

    await P.ui.showPanel(
      key: panelKey,
      initialChildSize: .74,
      maxChildSize: .92,
      builder: (scrollController) => AskQuestionPanel(scrollController: scrollController),
    );
  }

  const AskQuestionPanel({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final selectedLanguage = ref.watch(P.askQuestion.language);
    final generating = ref.watch(P.askQuestion.generating);
    final questions = ref.watch(P.askQuestion.questions);
    final hasChatHistory = ref.watch(P.askQuestion.hasChatHistory);
    final maxParallelCount = ref.watch(P.askQuestion.maxParallelCount);
    final emptyMessage = hasChatHistory ? s.question_generator_tap_generate_hint(maxParallelCount) : s.question_generator_empty_chat_hint;

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _AskQuestionPanelBar(scrollController: scrollController),
          Expanded(
            child: ListView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              padding: .only(
                left: 12,
                top: 12,
                right: 12,
                bottom: 12,
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: appTheme.settingItem,
                    borderRadius: .circular(12),
                    border: .all(color: qb.q(.15), width: .5),
                  ),
                  padding: const .all(14),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        s.question_generator_mock_description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: qb.q(.82),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _AskQuestionSection(
                  title: s.question_language,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final language in AskQuestionLanguage.values)
                        _AskQuestionSelectablePill(
                          label: _askQuestionLanguageLabel(s, language),
                          selected: language == selectedLanguage,
                          onTap: () {
                            P.askQuestion.selectLanguage(language);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _AskQuestionSection(
                  title: s.generated_questions,
                  child: Column(
                    children: [
                      if (questions.isEmpty)
                        Text(
                          generating ? s.generating : emptyMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: qb.q(.72),
                            height: 1.4,
                          ),
                        ),
                      for (final entry in questions.indexed) ...[
                        _AskQuestionCard(
                          question: entry.$2,
                          onAsk: () {
                            P.askQuestion.useQuestion(entry.$2);
                          },
                        ),
                        if (entry.$1 != questions.length - 1) const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _AskQuestionBottomBar(),
        ],
      ),
    );
  }
}

class _AskQuestionPanelBar extends ConsumerStatefulWidget {
  const _AskQuestionPanelBar({required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<_AskQuestionPanelBar> createState() => _AskQuestionPanelBarState();
}

class _AskQuestionPanelBarState extends ConsumerState<_AskQuestionPanelBar> {
  double _opacity = .0;

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final position = widget.scrollController.position;
    double opacity = position.pixels / 100.0;
    if (opacity < 0) opacity = 0;
    if (opacity > 1) opacity = 1;
    if (opacity == _opacity) return;

    _opacity = opacity;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      constraints: const BoxConstraints(
        minHeight: kToolbarHeight - 4,
      ),
      padding: const .only(top: 4),
      decoration: BoxDecoration(
        color: appTheme.settingItem.q(_opacity * _opacity),
        border: Border(
          bottom: BorderSide(color: qb.q(.2 * _opacity * _opacity), width: .5),
        ),
      ),
      child: Row(
        crossAxisAlignment: .center,
        children: [
          (12 + (8 * _opacity)).w,
          Expanded(
            child: Text(
              s.question_generator,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const IconButton(
            onPressed: pop,
            icon: Icon(Icons.close),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _AskQuestionSection extends ConsumerWidget {
  const _AskQuestionSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: .circular(12),
        border: .all(color: qb.q(.15), width: .5),
      ),
      padding: const .all(14),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            height: .5,
            margin: const .only(top: 10, bottom: 12),
            color: qb.q(.12),
          ),
          child,
        ],
      ),
    );
  }
}

class _AskQuestionSelectablePill extends ConsumerWidget {
  const _AskQuestionSelectablePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final bgColor = selected ? appTheme.primary.q(.15) : qb.q(.06);
    final borderColor = selected ? appTheme.primary.q(.5) : qb.q(.12);
    final textColor = selected ? appTheme.primary : qb.q(.92);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: .circular(999),
          border: .all(color: borderColor),
        ),
        padding: const .symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AskQuestionCard extends ConsumerWidget {
  const _AskQuestionCard({
    required this.question,
    required this.onAsk,
  });

  final String question;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);

    return Container(
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: .circular(12),
        border: .all(color: qb.q(.15), width: .5),
      ),
      padding: const .all(12),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            question,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
              color: qb.q(.94),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: onAsk,
              style: FilledButton.styleFrom(
                visualDensity: .compact,
              ),
              child: Text(s.ask),
            ),
          ),
        ],
      ),
    );
  }
}

class _AskQuestionBottomBar extends ConsumerWidget {
  const _AskQuestionBottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final generating = ref.watch(P.askQuestion.generating);

    return Container(
      padding: .fromLTRB(12, 10, 12, 12 + paddingBottom),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        border: Border(
          top: BorderSide(color: qb.q(.12), width: .5),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: generating
              ? null
              : () {
                  P.askQuestion.generateFromCurrentChat();
                },
          icon: Icon(
            generating ? Symbols.progress_activity : Symbols.auto_awesome,
            size: theme.textTheme.titleMedium?.fontSize,
          ),
          label: Text(generating ? s.generating : s.generate),
        ),
      ),
    );
  }
}
