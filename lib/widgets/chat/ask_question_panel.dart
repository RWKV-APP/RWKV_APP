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

String _askQuestionLanguageLabel(S s, Language language) {
  return switch (language) {
    .zh_Hans => s.chinese,
    .zh_Hant => s.chinese,
    .en => s.english,
    .ja => s.japanese,
    .ko => s.korean,
    .ru => s.russian,
    .none => "",
  };
}

class AskQuestionPanel extends ConsumerStatefulWidget {
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
  ConsumerState<AskQuestionPanel> createState() => _AskQuestionPanelState();
}

class _AskQuestionPanelState extends ConsumerState<AskQuestionPanel> {
  @override
  void dispose() {
    P.askQuestion.onPanelHidden();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    P.askQuestion.onPanelShown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final selectedLanguage = ref.watch(P.askQuestion.language);
    final generating = ref.watch(P.askQuestion.generating);
    final questions = ref.watch(P.askQuestion.questions);
    final hasChatHistory = ref.watch(P.askQuestion.hasChatHistory);
    final maxParallelCount = ref.watch(P.askQuestion.maxParallelCount);
    final shouldGenerateWithoutContext = ref.watch(P.askQuestion.shouldGenerateWithoutContext);
    final emptyMessage = switch ((shouldGenerateWithoutContext, hasChatHistory)) {
      (true, _) => s.question_generator_language_switched_hint,
      (false, true) => s.question_generator_tap_generate_hint(maxParallelCount),
      (false, false) => s.question_generator_empty_chat_hint,
    };

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _AskQuestionPanelBar(scrollController: widget.scrollController),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
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
                      for (final language in Language.values)
                        _AskQuestionSelectablePill(
                          label: _askQuestionLanguageLabel(s, language),
                          selected: language == selectedLanguage,
                          onTap: () => P.askQuestion.selectLanguage(language),
                        ),
                    ],
                  ),
                ),
                if (shouldGenerateWithoutContext) ...[
                  const SizedBox(height: 8),
                  _AskQuestionLanguageSwitchedHint(message: s.question_generator_language_switched_hint),
                ],
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
                          key: ValueKey(entry.$2),
                          question: entry.$2,
                          onAsk: (value) {
                            P.askQuestion.useQuestion(value);
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
    final qb = ref.watch(P.app.qb);
    final bgColor = selected ? qb.q(.12) : qb.q(.06);
    final borderColor = selected ? qb.q(.24) : qb.q(.12);
    final textColor = selected ? qb.q(.98) : qb.q(.92);

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

class _AskQuestionCard extends ConsumerStatefulWidget {
  const _AskQuestionCard({
    super.key,
    required this.question,
    required this.onAsk,
  });

  final String question;
  final ValueChanged<String> onAsk;

  @override
  ConsumerState<_AskQuestionCard> createState() => _AskQuestionCardState();
}

class _AskQuestionCardState extends ConsumerState<_AskQuestionCard> {
  late final TextEditingController _controller;

  @override
  void didUpdateWidget(covariant _AskQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question == oldWidget.question) return;
    if (_controller.text == widget.question) return;
    _controller.text = widget.question;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.question);
  }

  @override
  Widget build(BuildContext context) {
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
          TextField(
            controller: _controller,
            maxLines: null,
            minLines: 1,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
              color: qb.q(.94),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                widget.onAsk(_controller.text);
              },
              style: FilledButton.styleFrom(
                backgroundColor: qb.q(.12),
                foregroundColor: qb.q(.96),
                visualDensity: .compact,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(s.ask),
            ),
          ),
        ],
      ),
    );
  }
}

class _AskQuestionLanguageSwitchedHint extends ConsumerWidget {
  const _AskQuestionLanguageSwitchedHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);

    return Container(
      decoration: BoxDecoration(
        color: qb.q(.06),
        borderRadius: .circular(12),
        border: .all(color: qb.q(.14), width: .5),
      ),
      padding: const .all(12),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Icon(
            Symbols.info,
            size: 18,
            color: qb.q(.68),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: qb.q(.84),
                height: 1.4,
              ),
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
    final prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final decodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final iconSize = theme.textTheme.titleMedium?.fontSize ?? 16.0;

    final String label;
    if (!generating) {
      label = s.generate;
    } else if (decodeSpeed > 0) {
      label = "decode ${decodeSpeed.toStringAsFixed(1)} tok/s";
    } else if (prefillSpeed > 0) {
      label = "prefill ${prefillSpeed.toStringAsFixed(1)} tok/s";
    } else {
      label = s.generating;
    }

    return Container(
      padding: .fromLTRB(12, 10, 12, 12 + paddingBottom),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        border: Border(
          top: BorderSide(color: qb.q(.12), width: .5),
        ),
      ),
      child: Row(
        crossAxisAlignment: .center,
        children: [
          if (generating)
            IconButton(
              onPressed: () => P.askQuestion.pauseGeneration(),
              style: IconButton.styleFrom(
                backgroundColor: qb.q(.08),
                foregroundColor: qb.q(.9),
              ),
              icon: Icon(Symbols.pause, size: iconSize),
            ),
          if (generating) const SizedBox(width: 8),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: generating
                  ? null
                  : () {
                      P.askQuestion.generateFromCurrentChat();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: qb.q(.1),
                foregroundColor: qb.q(.96),
                disabledBackgroundColor: qb.q(.05),
                disabledForegroundColor: qb.q(.38),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: generating
                  ? SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: qb.q(.38),
                      ),
                    )
                  : Icon(Symbols.auto_awesome, size: iconSize),
              label: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
