// Dart imports:
import 'dart:async';
import 'dart:math' as math;

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/model/app_theme.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/msg_node.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/bot_message_bottom.dart';

final List<_BotMessageBottomPreviewCase> _previewCases = [
  const _BotMessageBottomPreviewCase(
    title: "Chat: 默认状态",
    description: "常规消息，按钮可见，非生成中。",
    message: model.Message(
      id: 1001,
      content: "这是默认状态消息。",
      isMine: false,
      paused: false,
      modelName: "RWKV-Preview-1.5B",
      runningMode: ".Fast",
      prefillSpeed: 18.6,
      decodeSpeed: 21.3,
    ),
    demoType: DemoType.chat,
    actionButton: .send,
  ),
  const _BotMessageBottomPreviewCase(
    title: "Chat: changing=true",
    description: "只保留生成中漏斗，隐藏复制/重试/分享/edit。",
    message: model.Message(
      id: 1002,
      content: "这是一条正在生成中的消息。",
      isMine: false,
      changing: true,
      paused: false,
      modelName: "RWKV-Preview-1.5B",
      runningMode: ".Fast",
      prefillSpeed: 27.8,
      decodeSpeed: 24.2,
    ),
    demoType: DemoType.chat,
    actionButton: .send,
  ),
  const _BotMessageBottomPreviewCase(
    title: "Chat: paused + Resume",
    description: "外部点击 Resume 后切换为 changing=true，5 秒后恢复。",
    message: model.Message(
      id: 1003,
      content: "这是一条被暂停的消息。",
      isMine: false,
      paused: true,
      modelName: "RWKV-Preview-1.5B",
      runningMode: ".Fast",
      prefillSpeed: 22.1,
      decodeSpeed: 19.4,
    ),
    demoType: DemoType.chat,
    actionButton: .send,
    resumeChangesToChanging: true,
  ),
  const _BotMessageBottomPreviewCase(
    title: "Chat: 已存在分叉",
    description: "初始即渲染 BranchSwitcher；可直接切换分叉。",
    message: model.Message(
      id: 1007,
      content: "这是一条已有消息分叉的内容。",
      isMine: false,
      paused: false,
      modelName: "RWKV-Preview-Branch",
      runningMode: ".Fast",
      prefillSpeed: 16.3,
      decodeSpeed: 14.6,
    ),
    demoType: DemoType.chat,
    actionButton: .send,
    initialBranchCount: 4,
    initialBranchIndex: 2,
  ),
  const _BotMessageBottomPreviewCase(
    title: "Chat: Batch 内容",
    description: "Batch Inference 预览：会隐藏编辑按钮；这不是消息分叉。",
    message: model.Message(
      id: 1004,
      content: "候选 A${Config.batchMarker}候选 B${Config.batchMarker}0",
      isMine: false,
      paused: false,
      modelName: "RWKV-Preview-Batch",
      runningMode: ".Fast",
      prefillSpeed: 12.4,
      decodeSpeed: 10.1,
    ),
    demoType: DemoType.chat,
  ),
  const _BotMessageBottomPreviewCase(
    title: "Chat: Sensitive / Share 模式",
    description: "敏感或选择模式下隐藏复制、编辑、分享等按钮。",
    message: model.Message(
      id: 1005,
      content: "这是一条敏感消息。",
      isMine: false,
      paused: false,
      isSensitive: true,
      modelName: "RWKV-Preview-1.5B",
      runningMode: ".Fast",
      prefillSpeed: 15.8,
      decodeSpeed: 13.7,
    ),
    demoType: DemoType.chat,
    actionButton: .send,
  ),
  const _BotMessageBottomPreviewCase(
    title: "See 页面专用分支",
    description: "使用 see demo type + runningMode=.None 观察样式。",
    message: model.Message(
      id: 1006,
      content: "这条用于预览 See 场景。",
      isMine: false,
      paused: false,
      modelName: "RWKV-VL-Preview",
      runningMode: ".None",
      prefillSpeed: 11.2,
      decodeSpeed: 9.8,
    ),
    demoType: DemoType.see,
    actionButton: .send,
  ),
];

class PageBotMessageBottomPreview extends ConsumerStatefulWidget {
  const PageBotMessageBottomPreview({super.key});

  @override
  ConsumerState<PageBotMessageBottomPreview> createState() => _PageBotMessageBottomPreviewState();
}

class _PageBotMessageBottomPreviewState extends ConsumerState<PageBotMessageBottomPreview> {
  int _resetSignal = 0;

  void _onResetAllPressed() {
    setState(() {
      _resetSignal = _resetSignal + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentLight = theme.brightness == Brightness.light;
    final qb = ref.watch(P.app.qb);
    final preferredDarkTheme = ref.watch(P.preference.preferredDarkCustomTheme);
    final darkTheme = preferredDarkTheme == AppTheme.light ? AppTheme.lightsOut : preferredDarkTheme;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    const double paneGap = 12;
    final preferredPaneWidth = (viewportWidth - 32 - paneGap) / 2;
    final double paneWidth = preferredPaneWidth < 120 ? 120 : preferredPaneWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text("BotMessageBottom 调试页"),
      ),
      body: ListView.builder(
        padding: const .all(16),
        itemCount: _previewCases.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _PreviewHeader(
              qb: qb,
              paneWidth: paneWidth,
              paneGap: paneGap,
              isCurrentLight: isCurrentLight,
              onResetAllPressed: _onResetAllPressed,
            );
          }
          final previewCase = _previewCases[index - 1];
          return Padding(
            padding: const .only(top: 12),
            child: _PreviewCaseRow(
              caseNumber: index,
              resetSignal: _resetSignal,
              previewCase: previewCase,
              darkTheme: darkTheme,
              paneWidth: paneWidth,
              paneGap: paneGap,
            ),
          );
        },
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  final Color qb;
  final double paneWidth;
  final double paneGap;
  final bool isCurrentLight;
  final VoidCallback onResetAllPressed;

  const _PreviewHeader({
    required this.qb,
    required this.paneWidth,
    required this.paneGap,
    required this.isCurrentLight,
    required this.onResetAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderText = isCurrentLight ? "左侧浅色，右侧深色" : "左侧深色，右侧浅色";
    final leftPaneTitle = isCurrentLight ? "浅色" : "深色";
    final rightPaneTitle = isCurrentLight ? "深色" : "浅色";

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          "纯 UI 调试页（外部按钮驱动状态）",
          style: TS(
            s: 16,
            w: .w600,
            c: qb,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "$orderText；所有 BotMessageBottom 都在同一个 ListView.builder 内纵向构建。",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: qb.q(.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "统一由外部 Send/Pause 驱动；Regenerate 与 Resume 均由 BotMessageBottom 内按钮触发。",
          style: theme.textTheme.bodySmall?.copyWith(
            color: qb.q(.6),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onResetAllPressed,
          child: const Text("重置全部 Case"),
        ),
        const SizedBox(height: 12),
        Container(
          height: 0.5,
          color: qb.q(.16),
        ),
        SizedBox(height: paneGap),
        SingleChildScrollView(
          scrollDirection: .horizontal,
          child: Row(
            children: [
              _PaneTitle(
                title: leftPaneTitle,
                width: paneWidth,
              ),
              SizedBox(width: paneGap),
              _PaneTitle(
                title: rightPaneTitle,
                width: paneWidth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _PaneTitle extends StatelessWidget {
  final String title;
  final double width;

  const _PaneTitle({
    required this.title,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      padding: const .symmetric(horizontal: 12, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PreviewCaseRow extends StatefulWidget {
  final int caseNumber;
  final int resetSignal;
  final _BotMessageBottomPreviewCase previewCase;
  final AppTheme darkTheme;
  final double paneWidth;
  final double paneGap;

  const _PreviewCaseRow({
    required this.caseNumber,
    required this.resetSignal,
    required this.previewCase,
    required this.darkTheme,
    required this.paneWidth,
    required this.paneGap,
  });

  @override
  State<_PreviewCaseRow> createState() => _PreviewCaseRowState();
}

class _PreviewCaseRowState extends State<_PreviewCaseRow> {
  static final math.Random _runningModeRandom = math.Random();
  static int _previewMessageIdSeed = 700000000;
  late model.Message _initialMessage;
  late model.Message _message;
  late int _parentMessageId;
  late List<model.Message> _branches;
  int _currentBranchIndex = 0;
  Timer? _resetTimer;

  String _bottomDetailsScope() {
    return "preview_bot_message_bottom_case_${widget.caseNumber}";
  }

  @override
  void initState() {
    super.initState();
    P.msg.clearBottomDetailsStateInScope(scope: _bottomDetailsScope());
    _resetCaseState(rerandomRunningMode: true);
  }

  @override
  void didUpdateWidget(covariant _PreviewCaseRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetSignal == widget.resetSignal) return;
    _resetTimer?.cancel();
    P.msg.clearBottomDetailsStateInScope(scope: _bottomDetailsScope());
    _resetCaseState(rerandomRunningMode: true);
  }

  int _allocatePreviewMessageId() {
    _previewMessageIdSeed = _previewMessageIdSeed + 1;
    return _previewMessageIdSeed;
  }

  model.Message _withRandomRunningMode(model.Message source) {
    final useNoneMode = _runningModeRandom.nextBool();
    final runningMode = useNoneMode ? ".None" : ".Fast";
    return source.copyWith(runningMode: runningMode);
  }

  void _resetCaseState({required bool rerandomRunningMode}) {
    late final model.Message template;
    if (rerandomRunningMode) {
      template = _withRandomRunningMode(widget.previewCase.message);
    } else {
      template = widget.previewCase.message.copyWith(runningMode: _initialMessage.runningMode);
    }

    final rawBranchCount = widget.previewCase.initialBranchCount;
    final branchCount = rawBranchCount <= 0 ? 1 : rawBranchCount;
    final maxBranchIndex = branchCount - 1;
    final rawBranchIndex = widget.previewCase.initialBranchIndex;
    final branchIndex = rawBranchIndex < 0 ? 0 : (rawBranchIndex > maxBranchIndex ? maxBranchIndex : rawBranchIndex);

    _parentMessageId = _allocatePreviewMessageId();
    final branches = <model.Message>[];
    for (final i in List<int>.generate(branchCount, (int index) => index)) {
      final useInitialState = branchCount == 1 && i == 0;
      final branchContent = branchCount == 1 ? template.content : "${template.content}（分支 ${i + 1}）";
      final branch = template.copyWith(
        id: _allocatePreviewMessageId(),
        content: branchContent,
        changing: useInitialState ? template.changing : false,
        paused: useInitialState ? template.paused : false,
      );
      branches.add(branch);
    }
    _branches = branches;
    _currentBranchIndex = branchIndex;
    _message = _branches[_currentBranchIndex];
    _initialMessage = _message;
    _ensureBranchTree();
  }

  MsgNode _getOrCreateParentNode() {
    final MsgNode rootNode = P.msg.msgNode.q;
    MsgNode? parentNode = rootNode.findNodeByMsgId(_parentMessageId);
    if (parentNode != null) return parentNode;
    parentNode = rootNode.add(MsgNode(_parentMessageId), keepLatest: true);
    return parentNode;
  }

  void _ensureBranchTree() {
    final MsgNode parentNode = _getOrCreateParentNode();
    for (final model.Message branch in _branches) {
      bool exists = false;
      for (final MsgNode child in parentNode.children) {
        if (child.id != branch.id) continue;
        exists = true;
        break;
      }
      if (exists) continue;
      parentNode.add(MsgNode(branch.id), keepLatest: true);
    }
    for (final child in parentNode.children) {
      if (child.id != _branches[_currentBranchIndex].id) continue;
      parentNode.latest = child;
      break;
    }
  }

  void _replaceCurrentBranchMessage(model.Message message) {
    _branches[_currentBranchIndex] = message;
    _message = message;
  }

  void _simulatePrimaryGeneratingFlow() {
    _resetTimer?.cancel();
    setState(() {
      _replaceCurrentBranchMessage(_message.copyWith(changing: true, paused: false));
    });
    _resetTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _resetCaseState(rerandomRunningMode: false);
      });
    });
  }

  void _onPreviewPrimaryPressed() {
    if (_message.changing) return;
    _simulatePrimaryGeneratingFlow();
  }

  void _onPreviewInlineResumePressed() {
    if (_message.changing) return;
    _simulatePrimaryGeneratingFlow();
  }

  void _onPreviewRegeneratePressed() {
    if (_message.changing) return;
    _resetTimer?.cancel();

    final regeneratedMessage = _message.copyWith(
      id: _allocatePreviewMessageId(),
      changing: true,
      paused: false,
    );

    setState(() {
      _branches = <model.Message>[..._branches, regeneratedMessage];
      _currentBranchIndex = _branches.length - 1;
      _replaceCurrentBranchMessage(regeneratedMessage);
      _ensureBranchTree();
    });

    final settledBranchIndex = _currentBranchIndex;
    _resetTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (settledBranchIndex < 0 || settledBranchIndex >= _branches.length) return;

      final settledMessage = _branches[settledBranchIndex].copyWith(changing: false, paused: false);
      setState(() {
        _branches[settledBranchIndex] = settledMessage;
        if (_currentBranchIndex != settledBranchIndex) return;
        _replaceCurrentBranchMessage(settledMessage);
      });
    });
  }

  void _onPreviewPausePressed() {
    if (!_message.changing) return;
    _resetTimer?.cancel();
    setState(() {
      _replaceCurrentBranchMessage(_message.copyWith(changing: false, paused: true));
    });
  }

  void _onPreviewBranchBackPressed() {
    if (_currentBranchIndex <= 0) return;
    setState(() {
      _currentBranchIndex = _currentBranchIndex - 1;
      _replaceCurrentBranchMessage(_branches[_currentBranchIndex]);
      _ensureBranchTree();
    });
  }

  void _onPreviewBranchForwardPressed() {
    if (_currentBranchIndex >= _branches.length - 1) return;
    setState(() {
      _currentBranchIndex = _currentBranchIndex + 1;
      _replaceCurrentBranchMessage(_branches[_currentBranchIndex]);
      _ensureBranchTree();
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    P.msg.clearBottomDetailsStateInScope(scope: _bottomDetailsScope());
    super.dispose();
  }

  String _resolvedTitle() {
    if (!widget.previewCase.resumeChangesToChanging) return widget.previewCase.title;
    if (_message.paused) return "Chat: paused + Resume";
    if (_message.changing) return "Chat: changing=true（Resume 后）";
    return "Chat: changing=false（5 秒后）";
  }

  String _resolvedDescription() {
    if (!widget.previewCase.resumeChangesToChanging) return widget.previewCase.description;
    if (_message.paused) return "点击 Resume 后将切换为 changing=true。";
    if (_message.changing) return "正在模拟生成中（changing=true），5 秒后自动恢复为初始状态。";
    return "已恢复为默认状态（changing=false）。";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentLight = theme.brightness == Brightness.light;
    final onPreviewPrimaryPressed = _message.changing ? null : _onPreviewPrimaryPressed;
    final onPreviewRegeneratePressed = _message.changing ? null : _onPreviewRegeneratePressed;
    final onPreviewInlineResumePressed = _message.changing ? null : _onPreviewInlineResumePressed;
    final onPreviewPausePressed = _message.changing ? _onPreviewPausePressed : null;
    final onPreviewBranchBackPressed = _currentBranchIndex <= 0 ? null : _onPreviewBranchBackPressed;
    final onPreviewBranchForwardPressed = _currentBranchIndex >= _branches.length - 1 ? null : _onPreviewBranchForwardPressed;
    final currentActionButton = widget.previewCase.actionButton;
    final displayTitle = "${widget.caseNumber}. ${_resolvedTitle()}";
    final displayDescription = _resolvedDescription();

    final Widget lightPane = SizedBox(
      width: widget.paneWidth,
      child: _PreviewPane(
        appTheme: AppTheme.light,
        previewCase: widget.previewCase,
        message: _message,
        onPreviewPrimaryPressed: onPreviewPrimaryPressed,
        onPreviewRegeneratePressed: onPreviewRegeneratePressed,
        onPreviewInlineResumePressed: onPreviewInlineResumePressed,
        onPreviewPausePressed: onPreviewPausePressed,
        onPreviewBranchBackPressed: onPreviewBranchBackPressed,
        onPreviewBranchForwardPressed: onPreviewBranchForwardPressed,
        branchIndicator: "${_currentBranchIndex + 1} / ${_branches.length}",
        bottomDetailsScope: _bottomDetailsScope(),
        currentActionButton: currentActionButton,
        displayTitle: displayTitle,
        displayDescription: displayDescription,
        isDark: false,
      ),
    );
    final Widget darkPane = SizedBox(
      width: widget.paneWidth,
      child: _PreviewPane(
        appTheme: widget.darkTheme,
        previewCase: widget.previewCase,
        message: _message,
        onPreviewPrimaryPressed: onPreviewPrimaryPressed,
        onPreviewRegeneratePressed: onPreviewRegeneratePressed,
        onPreviewInlineResumePressed: onPreviewInlineResumePressed,
        onPreviewPausePressed: onPreviewPausePressed,
        onPreviewBranchBackPressed: onPreviewBranchBackPressed,
        onPreviewBranchForwardPressed: onPreviewBranchForwardPressed,
        branchIndicator: "${_currentBranchIndex + 1} / ${_branches.length}",
        bottomDetailsScope: _bottomDetailsScope(),
        currentActionButton: currentActionButton,
        displayTitle: displayTitle,
        displayDescription: displayDescription,
        isDark: true,
      ),
    );
    final leftPane = isCurrentLight ? lightPane : darkPane;
    final rightPane = isCurrentLight ? darkPane : lightPane;

    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: Row(
        crossAxisAlignment: .start,
        children: [
          leftPane,
          SizedBox(width: widget.paneGap),
          rightPane,
        ],
      ),
    );
  }
}

class _PreviewPane extends StatelessWidget {
  final AppTheme appTheme;
  final _BotMessageBottomPreviewCase previewCase;
  final model.Message message;
  final VoidCallback? onPreviewPrimaryPressed;
  final VoidCallback? onPreviewRegeneratePressed;
  final VoidCallback? onPreviewInlineResumePressed;
  final VoidCallback? onPreviewPausePressed;
  final VoidCallback? onPreviewBranchBackPressed;
  final VoidCallback? onPreviewBranchForwardPressed;
  final String branchIndicator;
  final String bottomDetailsScope;
  final _PreviewActionButton currentActionButton;
  final String displayTitle;
  final String displayDescription;
  final bool isDark;

  const _PreviewPane({
    required this.appTheme,
    required this.previewCase,
    required this.message,
    required this.onPreviewPrimaryPressed,
    required this.onPreviewRegeneratePressed,
    required this.onPreviewInlineResumePressed,
    required this.onPreviewPausePressed,
    required this.onPreviewBranchBackPressed,
    required this.onPreviewBranchForwardPressed,
    required this.branchIndicator,
    required this.bottomDetailsScope,
    required this.currentActionButton,
    required this.displayTitle,
    required this.displayDescription,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewThemeData = _bwThemeData(isDark: isDark);
    final titleColor = appTheme.qb0;
    final bodyColor = appTheme.qb0.q(.72);

    return Theme(
      data: previewThemeData,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.scaffoldBg,
          borderRadius: .circular(12),
          border: Border.all(color: appTheme.qb0.q(.14)),
        ),
        padding: const .all(12),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              displayTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: bodyColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 0.5,
              color: appTheme.qb0.q(.16),
            ),
            const SizedBox(height: 4),
            BotMessageBottom(
              message,
              0,
              preferredDemoType: previewCase.demoType,
              onRegeneratePressed: onPreviewRegeneratePressed,
              onResumePressed: onPreviewInlineResumePressed,
              disableDefaultActions: true,
              bottomDetailsScope: bottomDetailsScope,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: .end,
              children: [
                TextButton(
                  onPressed: onPreviewPrimaryPressed,
                  child: Text(currentActionButton.label),
                ),
                if (onPreviewPausePressed != null) const SizedBox(width: 8),
                if (onPreviewPausePressed != null)
                  TextButton(
                    onPressed: onPreviewPausePressed,
                    child: const Text("Pause"),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: .center,
              children: [
                TextButton(
                  onPressed: onPreviewBranchBackPressed,
                  child: const Text("Prev Branch"),
                ),
                Text(
                  branchIndicator,
                  style: theme.textTheme.bodySmall?.copyWith(color: bodyColor),
                ),
                TextButton(
                  onPressed: onPreviewBranchForwardPressed,
                  child: const Text("Next Branch"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _BotMessageBottomPreviewCase {
  final String title;
  final String description;
  final model.Message message;
  final DemoType demoType;
  final bool resumeChangesToChanging;
  final _PreviewActionButton actionButton;
  final int initialBranchCount;
  final int initialBranchIndex;

  const _BotMessageBottomPreviewCase({
    required this.title,
    required this.description,
    required this.message,
    required this.demoType,
    this.resumeChangesToChanging = false,
    this.actionButton = _PreviewActionButton.send,
    this.initialBranchCount = 1,
    this.initialBranchIndex = 0,
  });
}

enum _PreviewActionButton {
  send,
  ;

  String get label => switch (this) {
    .send => "Send",
  };
}

ThemeData _bwThemeData({required bool isDark}) {
  final base = isDark ? ThemeData.dark() : ThemeData.light();
  final primary = isDark ? Colors.white : Colors.black;
  final colorScheme = base.colorScheme.copyWith(
    primary: primary,
    onPrimary: isDark ? Colors.black : Colors.white,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    iconTheme: base.iconTheme.copyWith(color: primary),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.black,
        borderRadius: .circular(6),
      ),
      textStyle: TextStyle(
        color: isDark ? Colors.black : Colors.white,
        fontSize: 12,
      ),
    ),
  );
}
