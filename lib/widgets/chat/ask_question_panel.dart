// Dart imports:
import 'dart:math' as math;

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
const _generateBarButtonHeight = 56.0;
const _questionCardRadius = 4.0;

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
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(_maxRadius),
        topRight: .circular(_maxRadius),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _PanelHeader(scrollController: scrollController),
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
                  children: const [
                    _PrefixComposerSection(),
                    SizedBox(height: 12),
                    _GenerateControls(),
                    SizedBox(height: 12),
                    _GeneratedQuestionsSection(),
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

class _PanelHeader extends ConsumerStatefulWidget {
  const _PanelHeader({required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<_PanelHeader> createState() => _PanelHeaderState();
}

class _PanelHeaderState extends ConsumerState<_PanelHeader> {
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

class _PanelSection extends ConsumerWidget {
  final EdgeInsets padding;

  const _PanelSection({
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

class _PrefixComposerSection extends ConsumerWidget {
  const _PrefixComposerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final prefixes = ref.watch(P.askQuestion.prefixes);

    return _PanelSection(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            s.question_generator_prefixes,
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
                for (final prefix in prefixes) _PrefixPill(label: prefix),
              ],
            ),
          if (prefixes.isNotEmpty)
            Container(
              height: .5,
              margin: const .only(top: 14, bottom: 14),
              color: qb.q(.1),
            ),
          const _PrefixInputField(),
        ],
      ),
    );
  }
}

class _PrefixInputField extends ConsumerStatefulWidget {
  const _PrefixInputField();

  @override
  ConsumerState<_PrefixInputField> createState() => _PrefixInputFieldState();
}

class _PrefixInputFieldState extends ConsumerState<_PrefixInputField> {
  late final TextEditingController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final value = ref.watch(P.askQuestion.prefixInput);
    final generating = ref.watch(P.askQuestion.interceptingEvents);
    final hasChatHistory = ref.watch(P.askQuestion.hasChatHistory);

    if (_controller.text != value) {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: qb.q(generating ? .02 : .04),
        borderRadius: .circular(_maxRadius),
        border: .all(color: qb.q(generating ? .08 : .14), width: .5),
      ),
      padding: const .symmetric(horizontal: 14, vertical: 12),
      child: TextField(
        controller: _controller,
        maxLines: 10,
        minLines: 1,
        enabled: !generating,
        onChanged: P.askQuestion.updatePrefixInput,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: .zero,
          hintText: hasChatHistory
              ? S.of(context).question_generator_context_prefix_input_placeholder
              : S.of(context).question_generator_prefix_input_placeholder,
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

class _GenerateControls extends ConsumerWidget {
  const _GenerateControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final generating = ref.watch(P.askQuestion.interceptingEvents);
    final iconSize = theme.textTheme.titleMedium?.fontSize ?? 16.0;
    final isDark = theme.brightness == Brightness.dark;
    final stopBackgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final stopBorderColor = isDark ? const Color(0xFF3C3C3C) : const Color(0xFFD4D4D4);
    final stopForegroundColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF2A2A2A);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            if (generating)
              SizedBox(
                width: _generateBarButtonHeight,
                height: _generateBarButtonHeight,
                child: Tooltip(
                  message: s.stop,
                  child: GD(
                    onTap: P.askQuestion.pauseGeneration,
                    child: Container(
                      decoration: BoxDecoration(
                        color: stopBackgroundColor,
                        borderRadius: .circular(_maxRadius),
                        border: .all(color: stopBorderColor, width: .8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Symbols.stop,
                        size: iconSize,
                        color: stopForegroundColor,
                        fill: 1,
                      ),
                    ),
                  ),
                ),
              ),
            if (generating) const SizedBox(width: 10),
            const Expanded(
              child: _GenerateButton(),
            ),
            const SizedBox(width: 10),
            const _GenerateCountButton(),
          ],
        ),
        const _PrefillProgressNotice(),
      ],
    );
  }
}

class _PrefillProgressNotice extends ConsumerWidget {
  const _PrefillProgressNotice();

  int _percentValue({required double progress}) {
    final clampedProgress = progress.clamp(0, 1).toDouble();
    return (clampedProgress * 100).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final generating = ref.watch(P.askQuestion.interceptingEvents);
    final hiddenPrefilling = ref.watch(P.rwkv.hiddenPrefilling);
    final prefillProgress = ref.watch(P.rwkv.prefillProgress).clamp(0, 1).toDouble();
    final prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final showProgress = generating && !hiddenPrefilling && prefillProgress > 0 && prefillProgress < 1;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = qb.q(isDark ? .09 : .035);
    final borderColor = qb.q(isDark ? .18 : .1);
    final titleColor = qb.q(isDark ? .88 : .8);
    final metaColor = qb.q(isDark ? .68 : .56);
    final progressColor = (isDark ? const Color(0xFFE0E0E0) : qb.q(.68)).q(.9);
    final progressBackgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: !showProgress
          ? const SizedBox.shrink()
          : Padding(
              padding: const .only(top: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: .circular(_maxRadius),
                  border: .all(color: borderColor, width: .6),
                ),
                padding: const .fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Symbols.hourglass_top,
                          size: 16,
                          color: metaColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.prefill_progress_percent("${_percentValue(progress: prefillProgress)}%"),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (prefillSpeed > 0)
                          Text(
                            "${prefillSpeed.toStringAsFixed(1)} tokens/s",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: metaColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: .circular(999),
                      child: LinearProgressIndicator(
                        value: prefillProgress,
                        minHeight: 6,
                        color: progressColor,
                        backgroundColor: progressBackgroundColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _GenerateButton extends ConsumerWidget {
  const _GenerateButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final generating = ref.watch(P.askQuestion.interceptingEvents);
    final activelyGenerating = generating && ref.watch(P.rwkv.generating);
    final prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final decodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final iconSize = theme.textTheme.titleMedium?.fontSize ?? 16.0;
    final isGenerateEnabled = !generating;
    final isDark = theme.brightness == Brightness.dark;
    final preferredMonospaceFont = ref.watch(P.font.finalMonospaceFontFamily);
    final backgroundColor = switch ((isDark, isGenerateEnabled)) {
      (true, true) => const Color(0xFF000000),
      (true, false) => const Color(0xFF121212),
      (false, true) => const Color(0xFFFFFFFF),
      (false, false) => const Color(0xFFF0F0F0),
    };
    final borderColor = switch ((isDark, isGenerateEnabled)) {
      (true, true) => const Color(0xFF3C3C3C),
      (true, false) => const Color(0xFF2C2C2C),
      (false, true) => const Color(0xFFD4D4D4),
      (false, false) => const Color(0xFFDCDCDC),
    };
    final foregroundColor = switch ((isDark, isGenerateEnabled)) {
      (true, true) => const Color(0xFFFFFFFF),
      (true, false) => const Color(0xFF888888),
      (false, true) => const Color(0xFF1A1A1A),
      (false, false) => const Color(0xFF8C8C8C),
    };
    final iconColor = switch ((isDark, isGenerateEnabled)) {
      (true, true) => const Color(0xFFE0E0E0),
      (true, false) => const Color(0xFF747474),
      (false, true) => const Color(0xFF666666),
      (false, false) => const Color(0xFF969696),
    };

    final label = switch (activelyGenerating) {
      false => s.generate,
      true when decodeSpeed > 0 => "${s.generating}\ndecode: ${decodeSpeed.toStringAsFixed(1)} tok/s",
      true when prefillSpeed > 0 => s.generating,
      _ => s.generating,
    };

    return SizedBox(
      height: _generateBarButtonHeight,
      child: GD(
        onTap: isGenerateEnabled ? P.askQuestion.generateFromCurrentChat : null,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: .circular(_maxRadius),
            border: .all(color: borderColor, width: .8),
          ),
          padding: .symmetric(horizontal: generating ? 10 : 14),
          child: Row(
            mainAxisAlignment: .center,
            children: [
              if (generating) ...[
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: iconColor,
                  ),
                ),
                12.w,
              ],
              if (!generating) ...[
                Icon(Symbols.auto_awesome, size: iconSize, color: iconColor),
                12.w,
              ],
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                    fontFamily: preferredMonospaceFont,
                    fontSize: 16,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenerateCountButton extends ConsumerWidget {
  const _GenerateCountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final generating = ref.watch(P.askQuestion.interceptingEvents);
    final selectedCount = ref.watch(P.askQuestion.targetQuestionCount);
    final options = ref.watch(P.askQuestion.generateCountOptions);
    final enabled = !generating;
    final isDark = theme.brightness == Brightness.dark;

    final buttonBackground = switch ((isDark, enabled)) {
      (true, true) => const Color(0xFF000000),
      (true, false) => const Color(0xFF121212),
      (false, true) => const Color(0xFFFFFFFF),
      (false, false) => const Color(0xFFF0F0F0),
    };
    final buttonBorderColor = switch ((isDark, enabled)) {
      (true, true) => const Color(0xFF3C3C3C),
      (true, false) => const Color(0xFF2C2C2C),
      (false, true) => const Color(0xFFD4D4D4),
      (false, false) => const Color(0xFFDCDCDC),
    };

    final labelColor = switch ((isDark, enabled)) {
      (true, true) => const Color(0xFFB8B8B8),
      (true, false) => const Color(0xFF747474),
      (false, true) => const Color(0xFF7A7A7A),
      (false, false) => const Color(0xFF989898),
    };
    final valueColor = switch ((isDark, enabled)) {
      (true, true) => const Color(0xFFFFFFFF),
      (true, false) => const Color(0xFF888888),
      (false, true) => const Color(0xFF1A1A1A),
      (false, false) => const Color(0xFF8C8C8C),
    };
    final iconColor = switch ((isDark, enabled)) {
      (true, true) => const Color(0xFFE0E0E0),
      (true, false) => const Color(0xFF747474),
      (false, true) => const Color(0xFF666666),
      (false, false) => const Color(0xFF969696),
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
                      color: isDark ? const Color(0xFFE4E4E4) : const Color(0xFF323232),
                    ),
                ],
              ),
            ),
        ];
      },
      child: SizedBox(
        height: _generateBarButtonHeight,
        width: 100,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const .symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: buttonBackground,
            borderRadius: .circular(_maxRadius),
            border: .all(
              color: buttonBorderColor,
              width: .8,
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

class _GeneratedQuestionsSection extends ConsumerStatefulWidget {
  const _GeneratedQuestionsSection();

  @override
  ConsumerState<_GeneratedQuestionsSection> createState() => _GeneratedQuestionsSectionState();
}

class _GeneratedQuestionsSectionState extends ConsumerState<_GeneratedQuestionsSection> with SingleTickerProviderStateMixin {
  static const _clearAnimationDuration = Duration(milliseconds: 280);

  late final AnimationController _clearController;
  late final Animation<double> _sectionOpacity;
  late final Animation<double> _sectionSize;
  late final Animation<Offset> _sectionSlide;
  late final Animation<double> _bodyOpacity;
  late final Animation<double> _bodySize;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _clearController = AnimationController(
      vsync: this,
      duration: _clearAnimationDuration,
    );
    final sectionCurve = CurvedAnimation(
      parent: _clearController,
      curve: const Interval(
        .5,
        1,
        curve: Cubic(0.25, 1, 0.5, 1),
      ),
    );
    final sectionSizeCurve = CurvedAnimation(
      parent: _clearController,
      curve: const Interval(
        .66,
        1,
        curve: Cubic(0.25, 1, 0.5, 1),
      ),
    );
    final sectionSlideCurve = CurvedAnimation(
      parent: _clearController,
      curve: const Interval(
        .12,
        .92,
        curve: Cubic(0.25, 1, 0.5, 1),
      ),
    );
    final bodyOpacityCurve = CurvedAnimation(
      parent: _clearController,
      curve: const Interval(
        .0,
        .38,
        curve: Cubic(0.25, 1, 0.5, 1),
      ),
    );
    final bodySizeCurve = CurvedAnimation(
      parent: _clearController,
      curve: const Interval(
        .08,
        .58,
        curve: Cubic(0.25, 1, 0.5, 1),
      ),
    );
    _sectionOpacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(sectionCurve);
    _sectionSize = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(sectionSizeCurve);
    _sectionSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -.02),
    ).animate(sectionSlideCurve);
    _bodyOpacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(bodyOpacityCurve);
    _bodySize = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(bodySizeCurve);
  }

  @override
  void dispose() {
    _clearController.dispose();
    super.dispose();
  }

  Future<void> _onClearPressed() async {
    if (_isClearing) return;

    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      P.askQuestion.clearGeneratedQuestions();
      return;
    }

    setState(() {
      _isClearing = true;
    });
    await _clearController.forward(from: 0);
    if (!mounted) return;

    P.askQuestion.clearGeneratedQuestions();
    _clearController.value = 0;
    if (!mounted) return;

    setState(() {
      _isClearing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final questions = ref.watch(P.askQuestion.questions);
    if (questions.isEmpty) return const SizedBox.shrink();

    final generating = ref.watch(P.askQuestion.interceptingEvents);
    final scheduledQuestionCount = ref.watch(P.askQuestion.scheduledQuestionCount);
    final retainedQuestionCount = ref.watch(P.askQuestion.retainedQuestionCount);
    final currentSessionQuestionCount = generating ? math.max(0, questions.length - retainedQuestionCount) : questions.length;
    final currentSessionQuestions = generating ? questions.take(currentSessionQuestionCount).toList() : questions;
    final retainedQuestions = generating ? questions.skip(currentSessionQuestionCount).toList() : const <String>[];
    final pendingQuestionCount = generating && scheduledQuestionCount > questions.length ? scheduledQuestionCount - questions.length : 0;
    final resultItems = <Widget>[
      for (final entry in currentSessionQuestions.indexed)
        _ClearExitItem(
          key: ValueKey(("current", entry.$1)),
          controller: _clearController,
          index: entry.$1,
          total: questions.length + pendingQuestionCount,
          child: _Question(question: entry.$2),
        ),
      for (int i = 0; i < pendingQuestionCount; i++)
        _ClearExitItem(
          key: ValueKey(("pending", i)),
          controller: _clearController,
          index: currentSessionQuestions.length + i,
          total: questions.length + pendingQuestionCount,
          child: const _PendingQuestionCard(),
        ),
      for (final entry in retainedQuestions.indexed)
        _ClearExitItem(
          key: ValueKey(("retained", entry.$1)),
          controller: _clearController,
          index: currentSessionQuestions.length + pendingQuestionCount + entry.$1,
          total: questions.length + pendingQuestionCount,
          child: _Question(question: entry.$2),
        ),
    ];

    return SlideTransition(
      position: _sectionSlide,
      child: FadeTransition(
        opacity: _sectionOpacity,
        child: SizeTransition(
          sizeFactor: _sectionSize,
          axisAlignment: -1,
          child: IgnorePointer(
            ignoring: _isClearing,
            child: _PanelSection(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.generated_questions,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (resultItems.isNotEmpty)
                        _ClearQuestionsButton(
                          onTap: generating || _isClearing ? null : _onClearPressed,
                        ),
                    ],
                  ),
                  FadeTransition(
                    opacity: _bodyOpacity,
                    child: SizeTransition(
                      sizeFactor: _bodySize,
                      axisAlignment: -1,
                      child: Column(
                        crossAxisAlignment: .stretch,
                        children: [
                          Container(
                            height: .5,
                            margin: const .only(top: 12, bottom: 14),
                            color: qb.q(.1),
                          ),
                          if (resultItems.isNotEmpty)
                            Column(
                              crossAxisAlignment: .stretch,
                              children: [
                                for (final entry in resultItems.indexed) ...[
                                  entry.$2,
                                  if (entry.$1 != resultItems.length - 1) const SizedBox(height: 8),
                                ],
                              ],
                            ),
                          if (resultItems.isNotEmpty && !generating)
                            _AskAllAsBatchButton(questions: questions),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearExitItem extends StatelessWidget {
  const _ClearExitItem({
    super.key,
    required this.controller,
    required this.index,
    required this.total,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final int total;
  final Widget child;

  double _intervalEnd({required double start, required double length}) {
    final end = start + length;
    if (end > .64) return .64;
    return end;
  }

  @override
  Widget build(BuildContext context) {
    final safeTotal = math.max(1, total);
    final step = math.min(.045, .18 / safeTotal);
    final start = math.min(.2, index * step);
    final fadeEnd = _intervalEnd(start: start, length: .26);
    final sizeEnd = _intervalEnd(start: start + .04, length: .28);

    final fade = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start,
        fadeEnd,
        curve: const Cubic(0.25, 1, 0.5, 1),
      ),
    );
    final slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -.035),
    ).animate(fade);
    final size =
        Tween<double>(
          begin: 1,
          end: 0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              start + .04,
              sizeEnd,
              curve: const Cubic(0.25, 1, 0.5, 1),
            ),
          ),
        );

    return SizedBox(
      width: double.infinity,
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 1,
          end: 0,
        ).animate(fade),
        child: SlideTransition(
          position: slide,
          child: SizeTransition(
            sizeFactor: size,
            axisAlignment: -1,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ClearQuestionsButton extends ConsumerWidget {
  const _ClearQuestionsButton({
    required this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final questions = ref.watch(P.askQuestion.questions);
    final generating = ref.watch(P.askQuestion.interceptingEvents);
    if (questions.isEmpty) return const SizedBox.shrink();

    final enabled = !generating && onTap != null;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = switch ((isDark, enabled)) {
      (true, true) => const Color(0xFF232323),
      (true, false) => const Color(0xFF1A1A1A),
      (false, true) => const Color(0xFFF2F2F2),
      (false, false) => const Color(0xFFEAEAEA),
    };
    final borderColor = switch ((isDark, enabled)) {
      (true, true) => const Color(0xFF424242),
      (true, false) => const Color(0xFF2C2C2C),
      (false, true) => const Color(0xFFD2D2D2),
      (false, false) => const Color(0xFFDDDDDD),
    };
    final foregroundColor = switch ((isDark, enabled)) {
      (true, true) => const Color(0xFFE2E2E2),
      (true, false) => const Color(0xFF868686),
      (false, true) => const Color(0xFF353535),
      (false, false) => const Color(0xFF9D9D9D),
    };

    return GD(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : .55,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 36,
          padding: const .symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: .circular(10),
            border: .all(color: borderColor, width: .8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.delete,
                size: 15,
                color: foregroundColor,
              ),
              const SizedBox(width: 6),
              Text(
                s.delete,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrefixPill extends ConsumerWidget {
  const _PrefixPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final selected = ref.watch(P.askQuestion.selectedPrefix) == label;
    final bgColor = selected ? qb.q(.12) : qb.q(.025);
    final borderColor = selected ? qb.q(.18) : qb.q(.075);
    final textColor = selected ? qb.q(.96) : qb.q(.7);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        P.askQuestion.selectPrefix(label);
      },
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
    required this.question,
  });

  final String question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
        P.askQuestion.useQuestion(question);
      },
      child: AnimatedContainer(
        width: double.infinity,
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: appTheme.settingItem,
          borderRadius: .circular(_questionCardRadius),
          border: .all(color: qb.q(.12), width: .7),
        ),
        padding: const .symmetric(
          horizontal: 8,
          vertical: 6,
        ),
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

class _PendingQuestionCard extends ConsumerWidget {
  const _PendingQuestionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: .circular(_questionCardRadius),
        border: .all(color: qb.q(.12), width: .7),
      ),
      padding: const .all(14),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: qb.q(.62),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.generating,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: qb.q(.56),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AskAllAsBatchButton extends ConsumerWidget {
  final List<String> questions;

  const _AskAllAsBatchButton({required this.questions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final generating = ref.watch(P.rwkv.generating);
    final supportedBatchSizes = ref.watch(P.rwkv.supportedBatchSizes);
    final bool supported = supportedBatchSizes.isNotEmpty && questions.length >= 2;

    return Padding(
      padding: const .only(top: 12),
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: FilledButton.icon(
          onPressed: supported && !generating
              ? () {
                  pop();
                  P.multiQuestion.sendFromAskQuestion(questions);
                }
              : null,
          icon: const Icon(Symbols.send, size: 16),
          label: Text(s.multi_question_send_all),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            disabledBackgroundColor: theme.colorScheme.primary.q(.3),
            shape: RoundedRectangleBorder(borderRadius: .circular(8)),
          ),
        ),
      ),
    );
  }
}
