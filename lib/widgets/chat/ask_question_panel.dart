// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';

const _maxRadius = 12.0;

class AskQuestionPanel extends ConsumerWidget {
  static const String panelKey = 'AskQuestionPanel';

  static Future<void> show() async {
    if (!checkModelSelection(preferredDemoType: .chat)) return;

    await P.ui.showPanel(
      key: panelKey,
      initialChildSize: .78,
      maxChildSize: .94,
      beforeShow: () async {
        P.askQuestion.onPanelShown();
      },
      afterHide: (_) {
        P.askQuestion.onPanelHidden();
      },
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
    final targetQuestionCount = ref.watch(P.askQuestion.targetQuestionCount);
    final generating = ref.watch(P.askQuestion.interceptingEvents);
    final prefixes = ref.watch(P.askQuestion.prefixes);
    final selectedPrefix = ref.watch(P.askQuestion.selectedPrefix);
    final prefixInput = ref.watch(P.askQuestion.prefixInput);
    final questions = ref.watch(P.askQuestion.questions);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(_maxRadius),
        topRight: .circular(_maxRadius),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _AskQuestionPanelBar(scrollController: scrollController),
          Expanded(
            child: DefaultTextStyle.merge(
              style: theme.textTheme.bodyMedium,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  P.askQuestion.clearQuestionSelection();
                },
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: .fromLTRB(
                    12,
                    0,
                    12,
                    12 + paddingBottom,
                  ),
                  children: [
                    _AskQuestionPrefixComposerCard(
                      title: s.question_generator_prefixes,
                      prefixes: prefixes,
                      selectedPrefix: selectedPrefix,
                      prefixInput: prefixInput,
                      generating: generating,
                    ),
                    const SizedBox(height: 12),
                    _GenerateBar(
                      generating: generating,
                    ),
                    const SizedBox(height: 12),
                    _Results(
                      title: s.generated_questions,
                      questions: questions,
                      generating: generating,
                      targetQuestionCount: targetQuestionCount,
                    ),
                  ],
                ),
              ),
            ),
          ),
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

class _AskQuestionSurface extends ConsumerWidget {
  final EdgeInsets padding;

  const _AskQuestionSurface({
    required this.child,
    // ignore: unused_element_parameter
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: .circular(_maxRadius),
        border: .all(color: qb.q(.15), width: .5),
      ),
      padding: padding,
      child: DefaultTextStyle.merge(
        style: theme.textTheme.bodyMedium,
        child: child,
      ),
    );
  }
}

class _AskQuestionPrefixComposerCard extends ConsumerWidget {
  const _AskQuestionPrefixComposerCard({
    required this.title,
    required this.prefixes,
    required this.selectedPrefix,
    required this.prefixInput,
    required this.generating,
  });

  final String title;
  final List<String> prefixes;
  final String? selectedPrefix;
  final String prefixInput;
  final bool generating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);

    return _AskQuestionSurface(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (prefixes.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final prefix in prefixes)
                  _SelectablePill(
                    label: prefix,
                    selected: prefix == selectedPrefix,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      P.askQuestion.selectPrefix(prefix);
                    },
                  ),
              ],
            ),
          if (prefixes.isNotEmpty)
            Container(
              height: .5,
              margin: const .only(top: 14, bottom: 14),
              color: qb.q(.1),
            ),
          _PrefixInputField(
            value: prefixInput,
            enabled: !generating,
            placeholder: s.question_generator_prefix_input_placeholder,
          ),
        ],
      ),
    );
  }
}

class _PrefixInputField extends ConsumerStatefulWidget {
  const _PrefixInputField({
    required this.value,
    required this.enabled,
    required this.placeholder,
  });

  final String value;
  final bool enabled;
  final String placeholder;

  @override
  ConsumerState<_PrefixInputField> createState() => _PrefixInputFieldState();
}

class _PrefixInputFieldState extends ConsumerState<_PrefixInputField> {
  late final TextEditingController _controller;

  @override
  void didUpdateWidget(covariant _PrefixInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _controller.text) return;

    _controller.text = widget.value;
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
    _controller = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: qb.q(widget.enabled ? .04 : .02),
        borderRadius: .circular(_maxRadius),
        border: .all(color: qb.q(widget.enabled ? .14 : .08), width: .5),
      ),
      padding: const .symmetric(horizontal: 14, vertical: 12),
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        maxLines: 4,
        minLines: 3,
        onChanged: P.askQuestion.updatePrefixInput,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: .zero,
          hintText: widget.placeholder,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: qb.q(.42),
          ),
        ),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: qb.q(.95),
          height: 1.35,
        ),
      ),
    );
  }
}

class _GenerateBar extends ConsumerWidget {
  const _GenerateBar({
    required this.generating,
  });

  final bool generating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final hasPrefixInput = ref.watch(P.askQuestion.hasPrefixInput);
    final targetQuestionCount = ref.watch(P.askQuestion.targetQuestionCount);
    final generateCountOptions = ref.watch(P.askQuestion.generateCountOptions);
    final activelyGenerating = generating && ref.watch(P.rwkv.generating);
    final prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final decodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final iconSize = theme.textTheme.titleMedium?.fontSize ?? 16.0;
    final buttonHeight = 56.0;
    final isGenerateEnabled = !generating && hasPrefixInput;
    final appTheme = ref.watch(P.app.theme);

    final settingItemColor = appTheme.settingItem;
    final qb = ref.watch(P.app.qb);

    final pauseButtonBackground = appTheme.settingItem;

    final label = switch (activelyGenerating) {
      false => s.generate,
      true when decodeSpeed > 0 => "${s.generating}\ndecode: ${decodeSpeed.toStringAsFixed(1)} tok/s",
      true when prefillSpeed > 0 => "${s.generating}\nprefill: ${prefillSpeed.toStringAsFixed(1)} tok/s",
      _ => s.generating,
    };

    final preferredMonospaceFont = ref.watch(P.font.finalMonospaceFontFamily);

    return Row(
      children: [
        if (generating)
          SizedBox(
            width: buttonHeight,
            height: buttonHeight,
            child: GD(
              onTap: P.askQuestion.pauseGeneration,
              child: Container(
                decoration: BoxDecoration(
                  color: pauseButtonBackground,
                  borderRadius: .circular(_maxRadius),
                  border: .all(color: appTheme.qb12, width: .5),
                ),
                padding: const .symmetric(horizontal: 18),
                child: Icon(Symbols.pause, size: iconSize),
              ),
            ),
          ),
        if (generating) const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: GD(
              onTap: isGenerateEnabled ? P.askQuestion.generateFromCurrentChat : null,
              child: Container(
                decoration: BoxDecoration(
                  color: settingItemColor,
                  borderRadius: .circular(_maxRadius),
                  border: .all(color: appTheme.qb12, width: .5),
                ),
                padding: const .symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: .center,
                  children: [
                    if (generating) ...[
                      SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: qb.q(.72),
                        ),
                      ),
                      12.w,
                    ],
                    if (!generating) ...[
                      Icon(Symbols.auto_awesome, size: iconSize),
                      12.w,
                    ],
                    Text(
                      label,
                      style: TS(w: FW.w500, ff: preferredMonospaceFont, s: generating ? 14 : 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _GenerateCountButton(
          height: buttonHeight,
          generating: generating,
          selectedCount: targetQuestionCount,
          options: generateCountOptions,
        ),
      ],
    );
  }
}

class _GenerateCountButton extends ConsumerWidget {
  const _GenerateCountButton({
    required this.height,
    required this.generating,
    required this.selectedCount,
    required this.options,
  });

  final double height;
  final bool generating;
  final int selectedCount;
  final List<int> options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final enabled = !generating;
    final isDark = theme.brightness == Brightness.dark;
    final buttonBackground = ref.watch(P.app.theme).settingItem;
    final appTheme = ref.watch(P.app.theme);
    final labelColor = switch ((isDark, enabled)) {
      (true, true) => const Color(0xFFB8B8B8),
      (true, false) => const Color(0xFF666666),
      (false, true) => const Color(0xFF686868),
      (false, false) => const Color(0xFF9A9A9A),
    };
    final valueColor = switch ((isDark, enabled)) {
      (true, true) => const Color(0xFFF1F1F1),
      (true, false) => const Color(0xFF7A7A7A),
      (false, true) => const Color(0xFF181818),
      (false, false) => const Color(0xFF8A8A8A),
    };
    final iconColor = switch ((isDark, enabled)) {
      (true, true) => const Color(0xFFD9D9D9),
      (true, false) => const Color(0xFF666666),
      (false, true) => const Color(0xFF4D4D4D),
      (false, false) => const Color(0xFF9A9A9A),
    };

    return PopupMenuButton<int>(
      enabled: enabled,
      padding: .zero,
      onSelected: P.askQuestion.setGenerateCount,
      itemBuilder: (_) {
        return [
          for (final count in options)
            PopupMenuItem<int>(
              value: count,
              child: Row(
                children: [
                  Expanded(child: Text("$count")),
                  if (count == selectedCount)
                    Icon(
                      Symbols.check,
                      size: 18,
                      color: qb.q(.88),
                    ),
                ],
              ),
            ),
        ];
      },
      child: SizedBox(
        height: height,
        width: 100,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const .symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: buttonBackground,
            borderRadius: .circular(_maxRadius),
            border: .all(
              color: appTheme.qb12,
              width: .5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      s.question_generator_count,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "$selectedCount",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Symbols.expand_more,
                size: 18,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({
    required this.title,
    required this.questions,
    required this.generating,
    required this.targetQuestionCount,
  });

  final String title;
  final List<String> questions;
  final bool generating;
  final int targetQuestionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);

    return _AskQuestionSurface(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (questions.isNotEmpty || generating)
                Container(
                  decoration: BoxDecoration(
                    color: qb.q(.08),
                    borderRadius: .circular(999),
                    border: .all(color: qb.q(.12)),
                  ),
                  padding: const .symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    generating ? "${questions.length}/$targetQuestionCount" : "${questions.length}",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: qb.q(.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          Container(
            height: .5,
            margin: const .only(top: 12, bottom: 14),
            color: qb.q(.1),
          ),
          if (questions.isNotEmpty)
            Column(
              crossAxisAlignment: .stretch,
              children: [
                for (final entry in questions.indexed) ...[
                  _Question(
                    key: ValueKey(entry.$2),
                    question: entry.$2,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      P.askQuestion.useQuestion(entry.$2);
                    },
                  ),
                  if (entry.$1 != questions.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _SelectablePill extends ConsumerWidget {
  const _SelectablePill({
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
    final bgColor = selected ? qb.q(.12) : qb.q(.025);
    final borderColor = selected ? qb.q(.18) : qb.q(.075);
    final textColor = selected ? qb.q(.96) : qb.q(.7);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: .circular(999),
          border: .all(color: borderColor),
        ),
        padding: const .symmetric(horizontal: 14, vertical: 9),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _Question extends ConsumerWidget {
  const _Question({
    super.key,
    required this.question,
    required this.onTap,
  });

  final String question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: appTheme.settingItem,
          borderRadius: .circular(8),
          border: .all(color: qb.q(.12), width: .7),
        ),
        padding: const .all(14),
        child: Text(
          question,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: qb.q(.94),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
