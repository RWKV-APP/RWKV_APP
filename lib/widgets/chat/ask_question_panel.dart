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
    final generating = ref.watch(P.rwkv.generating) && ref.watch(P.askQuestion.interceptingEvents);
    final prefixes = ref.watch(P.askQuestion.prefixes);
    final selectedPrefix = ref.watch(P.askQuestion.selectedPrefix);
    final prefixInput = ref.watch(P.askQuestion.prefixInput);
    final questions = ref.watch(P.askQuestion.questions);
    final selectedQuestionIndex = ref.watch(P.askQuestion.selectedQuestionIndex);
    final editingQuestionIndex = ref.watch(P.askQuestion.editingQuestionIndex);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final emptyMessage = targetQuestionCount <= 1 ? s.question_generator_empty_chat_hint : s.question_generator_empty_chat_batch_hint;

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
                    _AskQuestionGenerateBar(
                      generating: generating,
                      targetQuestionCount: targetQuestionCount,
                    ),
                    const SizedBox(height: 12),
                    _AskQuestionResultsCard(
                      title: s.generated_questions,
                      questions: questions,
                      emptyMessage: emptyMessage,
                      generating: generating,
                      selectedQuestionIndex: selectedQuestionIndex,
                      editingQuestionIndex: editingQuestionIndex,
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
    this.padding = const EdgeInsets.all(16),
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
        borderRadius: .circular(18),
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
                  _AskQuestionSelectablePill(
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
          _AskQuestionPrefixInputField(
            value: prefixInput,
            enabled: !generating,
            placeholder: s.question_generator_prefix_input_placeholder,
          ),
        ],
      ),
    );
  }
}

class _AskQuestionPrefixInputField extends ConsumerStatefulWidget {
  const _AskQuestionPrefixInputField({
    required this.value,
    required this.enabled,
    required this.placeholder,
  });

  final String value;
  final bool enabled;
  final String placeholder;

  @override
  ConsumerState<_AskQuestionPrefixInputField> createState() => _AskQuestionPrefixInputFieldState();
}

class _AskQuestionPrefixInputFieldState extends ConsumerState<_AskQuestionPrefixInputField> {
  late final TextEditingController _controller;

  @override
  void didUpdateWidget(covariant _AskQuestionPrefixInputField oldWidget) {
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
        borderRadius: .circular(16),
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

class _AskQuestionGenerateBar extends ConsumerWidget {
  const _AskQuestionGenerateBar({
    required this.generating,
    required this.targetQuestionCount,
  });

  final bool generating;
  final int targetQuestionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final hasPrefixInput = ref.watch(P.askQuestion.hasPrefixInput);
    final prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final decodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final iconSize = theme.textTheme.titleMedium?.fontSize ?? 16.0;

    final label = switch (generating) {
      false => targetQuestionCount > 1 ? "${s.generate} · $targetQuestionCount" : s.generate,
      true when decodeSpeed > 0 => "decode ${decodeSpeed.toStringAsFixed(1)} tok/s",
      true when prefillSpeed > 0 => "prefill ${prefillSpeed.toStringAsFixed(1)} tok/s",
      _ => s.generating,
    };

    return Row(
      children: [
        if (generating)
          IconButton(
            onPressed: P.askQuestion.pauseGeneration,
            style: IconButton.styleFrom(
              backgroundColor: qb.q(.08),
              foregroundColor: qb.q(.94),
            ),
            icon: Icon(Symbols.pause, size: iconSize),
          ),
        if (generating) const SizedBox(width: 10),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: generating || !hasPrefixInput ? null : P.askQuestion.generateFromCurrentChat,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: qb.q(.1),
              foregroundColor: qb.q(.96),
              disabledBackgroundColor: qb.q(.05),
              disabledForegroundColor: qb.q(.34),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
            label: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AskQuestionResultsCard extends ConsumerWidget {
  const _AskQuestionResultsCard({
    required this.title,
    required this.questions,
    required this.emptyMessage,
    required this.generating,
    required this.selectedQuestionIndex,
    required this.editingQuestionIndex,
    required this.targetQuestionCount,
  });

  final String title;
  final List<String> questions;
  final String emptyMessage;
  final bool generating;
  final int? selectedQuestionIndex;
  final int? editingQuestionIndex;
  final int targetQuestionCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);

    return _AskQuestionSurface(
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
          if (questions.isEmpty)
            _AskQuestionEmptyState(
              message: generating ? s.generating : emptyMessage,
            ),
          if (questions.isNotEmpty)
            Column(
              crossAxisAlignment: .stretch,
              children: [
                for (final entry in questions.indexed) ...[
                  _AskQuestionQuestionCard(
                    key: ValueKey(entry.$2),
                    question: entry.$2,
                    selected: selectedQuestionIndex == entry.$1,
                    editing: editingQuestionIndex == entry.$1,
                    onSelect: () {
                      FocusScope.of(context).unfocus();
                      P.askQuestion.selectQuestion(entry.$1);
                    },
                    onBeginEdit: () {
                      P.askQuestion.beginEditingQuestion(entry.$1);
                    },
                    onCancelEdit: P.askQuestion.cancelEditingQuestion,
                    onAsk: (value) {
                      P.askQuestion.useQuestion(value);
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

class _AskQuestionEmptyState extends ConsumerWidget {
  const _AskQuestionEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: qb.q(.04),
        borderRadius: .circular(16),
        border: .all(color: qb.q(.1), width: .5),
      ),
      padding: const .all(18),
      child: Column(
        children: [
          Icon(
            Symbols.lightbulb,
            color: qb.q(.6),
            size: 20,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: qb.q(.74),
              height: 1.45,
            ),
          ),
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
    final bgColor = selected ? qb.q(.12) : qb.q(.05);
    final borderColor = selected ? qb.q(.18) : qb.q(.1);
    final textColor = selected ? qb.q(.98) : qb.q(.86);

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
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AskQuestionQuestionCard extends ConsumerStatefulWidget {
  const _AskQuestionQuestionCard({
    super.key,
    required this.question,
    required this.selected,
    required this.editing,
    required this.onSelect,
    required this.onBeginEdit,
    required this.onCancelEdit,
    required this.onAsk,
  });

  final String question;
  final bool selected;
  final bool editing;
  final VoidCallback onSelect;
  final VoidCallback onBeginEdit;
  final VoidCallback onCancelEdit;
  final ValueChanged<String> onAsk;

  @override
  ConsumerState<_AskQuestionQuestionCard> createState() => _AskQuestionQuestionCardState();
}

class _AskQuestionQuestionCardState extends ConsumerState<_AskQuestionQuestionCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void didUpdateWidget(covariant _AskQuestionQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editing && !oldWidget.editing) {
      _controller.text = widget.question;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
      });
      return;
    }

    if (widget.question == oldWidget.question) return;
    if (_controller.text == widget.question) return;

    _controller.text = widget.question;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.question);
    _focusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final backgroundColor = widget.selected ? qb.q(.1) : appTheme.settingItem;
    final borderColor = widget.selected ? qb.q(.22) : qb.q(.12);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.editing ? null : widget.onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: .circular(16),
          border: .all(color: borderColor, width: .7),
        ),
        padding: const .all(14),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            if (widget.editing)
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 2,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: .zero,
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: qb.q(.96),
                  height: 1.35,
                ),
              )
            else
              Text(
                widget.question,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: qb.q(.94),
                  height: 1.4,
                ),
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: !widget.selected
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const .only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: widget.editing ? widget.onCancelEdit : widget.onBeginEdit,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: qb.q(.92),
                              side: BorderSide(color: qb.q(.18)),
                              visualDensity: .compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(widget.editing ? s.cancel : s.edit),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              final value = widget.editing ? _controller.text : widget.question;
                              widget.onAsk(value);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: qb.q(.14),
                              foregroundColor: qb.q(.98),
                              visualDensity: .compact,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(s.ask),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
