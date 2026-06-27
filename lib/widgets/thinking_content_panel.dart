// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/func/shortcuts.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/markdown_render.dart';

const int _kCotPreviewMaxLines = 5;
const double _kCotPanelHorizontalPadding = 8.0;
const double _kCotScrollVerticalPadding = 8.0;
const double _kCotScrollFadeHeight = 18.0;
const double _kCotScrollToBottomButtonHeight = 24.0;
const double _kCotScrollToBottomButtonBottomPadding = 4.0;
const double _kCotPreviewTapMoveThreshold = 8.0;
const Duration _kCotPanelSizeAnimationDuration = Duration(milliseconds: 220);
const bool _kDebugTintStableMarkdown = true;
const Color _kDebugStableMarkdownTint = Color(0x224CAF50);
const ValueKey<String> _kDefaultThinkingContentPanelKey = ValueKey<String>("thinking-content-panel");
const ValueKey<String> _kDefaultThinkingContentScrollKey = ValueKey<String>("thinking-content-scroll");
const ValueKey<String> _kDefaultThinkingScrollToBottomButtonKey = ValueKey<String>("thinking-scroll-to-bottom-button");

class ThinkingFullContentAnimator extends StatefulWidget {
  final bool expanded;
  final Widget child;

  const ThinkingFullContentAnimator({
    required this.expanded,
    required this.child,
    super.key,
  });

  @override
  State<ThinkingFullContentAnimator> createState() => _ThinkingFullContentAnimatorState();
}

class _ThinkingFullContentAnimatorState extends State<ThinkingFullContentAnimator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;
  bool _buildContent = false;

  @override
  void initState() {
    super.initState();
    _buildContent = widget.expanded;
    _controller = AnimationController(
      vsync: this,
      duration: 250.ms,
      value: widget.expanded ? 1 : 0,
    )..addStatusListener(_onAnimationStatusChanged);
    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant ThinkingFullContentAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded == oldWidget.expanded) return;
    if (widget.expanded) {
      setState(() {
        _buildContent = true;
      });
      _controller.forward();
      return;
    }
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onAnimationStatusChanged)
      ..dispose();
    super.dispose();
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) return;
    if (widget.expanded) return;
    if (!_buildContent) return;
    setState(() {
      _buildContent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _heightFactor,
          child: SizedBox(
            width: double.infinity,
            child: _buildContent ? widget.child : const SizedBox.shrink(),
          ),
          builder: (context, child) {
            return Align(
              alignment: .topLeft,
              heightFactor: _heightFactor.value,
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class ThinkingContentPanel extends ConsumerStatefulWidget {
  final String raw;
  final Color color;
  final Color baseBackgroundColor;
  final bool streaming;
  final bool expanded;
  final Key panelKey;
  final Key scrollKey;
  final Key scrollToBottomButtonKey;
  final VoidCallback? onPreviewTap;
  final double inlineLatexVerticalPaddingFactor;
  final bool debugTintStableBlocks;
  final Color debugStableBlockTint;

  const ThinkingContentPanel({
    required this.raw,
    required this.color,
    required this.baseBackgroundColor,
    required this.streaming,
    required this.expanded,
    this.panelKey = _kDefaultThinkingContentPanelKey,
    this.scrollKey = _kDefaultThinkingContentScrollKey,
    this.scrollToBottomButtonKey = _kDefaultThinkingScrollToBottomButtonKey,
    this.onPreviewTap,
    this.inlineLatexVerticalPaddingFactor = 0,
    this.debugTintStableBlocks = _kDebugTintStableMarkdown,
    this.debugStableBlockTint = _kDebugStableMarkdownTint,
    super.key,
  });

  @override
  ConsumerState<ThinkingContentPanel> createState() => _ThinkingContentPanelState();
}

class _ThinkingContentPanelState extends ConsumerState<ThinkingContentPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScrollToBottom = true;
  bool _canScroll = false;
  bool _atBottom = true;
  bool _scrollStateSyncScheduled = false;
  Offset? _previewPointerDownPosition;
  bool _previewPointerMoved = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncScrollState);
    _scheduleScrollToBottom();
  }

  @override
  void didUpdateWidget(covariant ThinkingContentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleScrollStateSync();
    if (widget.expanded) {
      _autoScrollToBottom = true;
      return;
    }
    if (oldWidget.expanded && !widget.expanded) {
      _autoScrollToBottom = true;
      _scheduleScrollToBottom();
      return;
    }
    if (oldWidget.raw == widget.raw && oldWidget.expanded == widget.expanded) return;
    _scheduleScrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncScrollState);
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToBottom() {
    if (!_autoScrollToBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.expanded) return;
      if (!_autoScrollToBottom) return;
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _syncScrollState();
    });
  }

  void _scheduleScrollStateSync() {
    if (_scrollStateSyncScheduled) return;
    _scrollStateSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollStateSyncScheduled = false;
      _syncScrollState();
    });
  }

  void _syncScrollState() {
    if (!_scrollController.hasClients) {
      _setScrollState(canScroll: false, atBottom: true);
      return;
    }

    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    final canScroll = position.maxScrollExtent > 0.5;
    final atBottom = !canScroll || position.pixels >= position.maxScrollExtent - 1.0;
    _setScrollState(canScroll: canScroll, atBottom: atBottom);
    if (!widget.expanded && _autoScrollToBottom && canScroll && !atBottom) {
      _scheduleScrollToBottom();
    }
  }

  void _setScrollState({
    required bool canScroll,
    required bool atBottom,
  }) {
    if (_canScroll == canScroll && _atBottom == atBottom) return;
    setState(() {
      _canScroll = canScroll;
      _atBottom = atBottom;
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (widget.expanded) return false;
    if (notification is UserScrollNotification && notification.direction != ScrollDirection.idle) {
      _disableAutoScrollToBottom();
    }
    if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
      _disableAutoScrollToBottom();
    }
    return false;
  }

  void _disableAutoScrollToBottom() {
    if (!_autoScrollToBottom) return;
    setState(() {
      _autoScrollToBottom = false;
    });
  }

  Future<void> _scrollToBottomAndResumeAutoScroll() async {
    _autoScrollToBottom = true;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    await _scrollController.animateTo(
      position.maxScrollExtent,
      duration: 200.ms,
      curve: Curves.easeOut,
    );
    _syncScrollState();
  }

  void _onPreviewPointerDown(PointerDownEvent event) {
    if (widget.onPreviewTap == null) return;
    _previewPointerDownPosition = event.localPosition;
    _previewPointerMoved = false;
  }

  void _onPreviewPointerMove(PointerMoveEvent event) {
    final downPosition = _previewPointerDownPosition;
    if (downPosition == null) return;
    final delta = event.localPosition - downPosition;
    final thresholdSquared = _kCotPreviewTapMoveThreshold * _kCotPreviewTapMoveThreshold;
    if (delta.dx * delta.dx + delta.dy * delta.dy <= thresholdSquared) return;
    _previewPointerMoved = true;
  }

  void _onPreviewPointerUp(PointerUpEvent event) {
    final downPosition = _previewPointerDownPosition;
    _previewPointerDownPosition = null;
    if (downPosition == null) return;
    if (_previewPointerMoved) return;
    if (_isScrollToBottomButtonPointer(event.localPosition)) return;
    widget.onPreviewTap?.call();
  }

  void _onPreviewPointerCancel(PointerCancelEvent event) {
    _previewPointerDownPosition = null;
    _previewPointerMoved = false;
  }

  bool _isScrollToBottomButtonPointer(Offset localPosition) {
    if (!_canScroll || _autoScrollToBottom || _atBottom) return false;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return false;
    final size = renderObject.size;
    final left = (size.width - 48) / 2;
    final right = left + 48;
    final top = size.height - _kCotScrollToBottomButtonBottomPadding - _kCotScrollToBottomButtonHeight;
    final bottom = size.height - _kCotScrollToBottomButtonBottomPadding;
    if (localPosition.dx < left || localPosition.dx > right) return false;
    return localPosition.dy >= top && localPosition.dy <= bottom;
  }

  double _resolvePreviewMaxHeight({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);
    final effectiveScale = Config.msgFontScale * textScaler.scale(1.0);
    final effectiveMessageLineHeight = ref.watch(P.preference.effectiveMessageLineHeight);
    final textStyle = TextStyle(
      fontSize: Config.markdownBodyFontSize * effectiveScale,
      height: effectiveMessageLineHeight,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: "M", style: textStyle),
      textDirection: TextDirection.ltr,
      textScaler: .noScaling,
    )..layout();
    return textPainter.preferredLineHeight * _kCotPreviewMaxLines;
  }

  Widget _content() {
    return StreamingMarkdownRender(
      raw: widget.raw,
      color: widget.color,
      streaming: widget.streaming,
      useMessageLineHeight: true,
      inlineLatexVerticalPaddingFactor: widget.inlineLatexVerticalPaddingFactor,
      debugTintStableBlocks: widget.debugTintStableBlocks,
      debugStableBlockTint: widget.debugStableBlockTint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;
    final qb = ref.watch(P.app.qb);
    final panelBorderColor = qb.q(.12);
    final panelBackgroundColor = qb.q(.025);
    final panelFadeColor = Color.alphaBlend(panelBackgroundColor, widget.baseBackgroundColor);

    if (widget.expanded) {
      return AnimatedSize(
        alignment: .topCenter,
        duration: _kCotPanelSizeAnimationDuration,
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.hardEdge,
        child: KeyedSubtree(
          key: widget.panelKey,
          child: Container(
            width: double.infinity,
            padding: const .symmetric(horizontal: _kCotPanelHorizontalPadding),
            decoration: BoxDecoration(
              color: panelBackgroundColor,
              border: .all(color: panelBorderColor),
              borderRadius: .circular(8),
            ),
            child: Padding(
              padding: const .symmetric(vertical: _kCotScrollVerticalPadding),
              child: _content(),
            ),
          ),
        ),
      );
    }

    final previewMaxHeight = _resolvePreviewMaxHeight(context: context, ref: ref);
    final showScrollToBottomButton = _canScroll && !_autoScrollToBottom && !_atBottom;
    return AnimatedSize(
      alignment: .topCenter,
      duration: _kCotPanelSizeAnimationDuration,
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.hardEdge,
      child: Listener(
        onPointerDown: _onPreviewPointerDown,
        onPointerMove: _onPreviewPointerMove,
        onPointerUp: _onPreviewPointerUp,
        onPointerCancel: _onPreviewPointerCancel,
        child: KeyedSubtree(
          key: widget.panelKey,
          child: Container(
            width: double.infinity,
            padding: const .symmetric(horizontal: _kCotPanelHorizontalPadding),
            decoration: BoxDecoration(
              color: panelBackgroundColor,
              border: .all(color: panelBorderColor),
              borderRadius: .circular(8),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: previewMaxHeight),
              child: ClipRect(
                child: Stack(
                  children: [
                    _ThinkingScrollFade(
                      enabled: _canScroll,
                      color: panelFadeColor,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onScrollNotification,
                        child: ListView(
                          key: widget.scrollKey,
                          controller: _scrollController,
                          padding: .only(
                            top: _kCotScrollVerticalPadding,
                            bottom: showScrollToBottomButton
                                ? _kCotScrollVerticalPadding + _kCotScrollToBottomButtonHeight + _kCotScrollToBottomButtonBottomPadding
                                : _kCotScrollVerticalPadding,
                          ),
                          physics: const ClampingScrollPhysics(),
                          shrinkWrap: true,
                          children: [_content()],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: _kCotScrollToBottomButtonBottomPadding,
                      child: Center(
                        child: _ThinkingScrollToBottomButton(
                          buttonKey: widget.scrollToBottomButtonKey,
                          show: showScrollToBottomButton,
                          onTap: _scrollToBottomAndResumeAutoScroll,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinkingScrollFade extends StatelessWidget {
  final bool enabled;
  final Color color;
  final Widget child;

  const _ThinkingScrollFade({
    required this.enabled,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    if (!enabled) return child;

    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: _kCotScrollFadeHeight,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: .topCenter,
                  end: .bottomCenter,
                  colors: [
                    color,
                    color.q(0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _kCotScrollFadeHeight,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: .bottomCenter,
                  end: .topCenter,
                  colors: [
                    color,
                    color.q(0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThinkingScrollToBottomButton extends ConsumerWidget {
  final Key buttonKey;
  final bool show;
  final VoidCallback onTap;

  const _ThinkingScrollToBottomButton({
    required this.buttonKey,
    required this.show,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);

    return AnimatedOpacity(
      key: buttonKey,
      opacity: show ? 1 : 0,
      duration: 200.ms,
      curve: Curves.easeOut,
      child: IgnorePointer(
        ignoring: !show,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 48,
            height: _kCotScrollToBottomButtonHeight,
            decoration: BoxDecoration(
              color: qw,
              border: .all(color: qb.q(.1)),
              borderRadius: .circular(14),
            ),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: qb.q(.7),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
