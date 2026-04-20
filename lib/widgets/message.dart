// Dart imports:
import 'dart:math' as math;

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:photo_viewer/photo_viewer.dart';

// Project imports:
import 'package:zone/args.dart';
import 'package:zone/config.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/app_theme.dart';
import 'package:zone/model/cot_display_state.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/world_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/bot_message_bottom.dart';
import 'package:zone/widgets/chat/batch_message_content.dart';
import 'package:zone/widgets/chat/reference_info.dart';
import 'package:zone/widgets/markdown_render.dart';
import 'package:zone/widgets/see/photo_viewer_overlay.dart';
import 'package:zone/widgets/talk/bot_tts_content.dart';
import 'package:zone/widgets/talk/user_tts_content.dart';
import 'package:zone/widgets/user_message_bottom.dart';

const double _kBubbleMinHeight = 44.0;
const double _kBubbleMaxWidthAdjust = .0;

class Message extends ConsumerStatefulWidget {
  final model.Message msg;
  final bool selectMode;
  final DemoType? preferredDemoType;

  /// 页面中第一个消息的 index 为 0
  final int index;

  const Message(
    this.msg,
    this.index, {
    super.key,
    this.selectMode = false,
    this.preferredDemoType,
  });

  @override
  ConsumerState<Message> createState() => _MessageState();
}

class _MessageState extends ConsumerState<Message> {
  bool _desktopUserMessageHovered = false;

  void _onDesktopHoverChanged(bool hovered) {
    if (_desktopUserMessageHovered == hovered) return;
    setState(() {
      _desktopUserMessageHovered = hovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final msg = widget.msg;
    final index = widget.index;
    final selectMode = widget.selectMode;
    final preferredDemoType = widget.preferredDemoType;
    final s = S.of(context);

    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final DemoType demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    final worldType = ref.watch(P.rwkv.currentWorldType);
    final isMobile = ref.watch(P.app.isMobile);
    final sharingMode = ref.watch(P.chat.isSharing);
    final editingIndex = ref.watch(P.msg.editingOrRegeneratingIndex);
    final receiveId = ref.watch(P.chat.receiveId);
    final receiving = ref.watch(P.rwkv.generating);
    final inSee = ref.watch(P.app.pageKey) == .see;
    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    final received = ref.watch(P.chat.visibleReceivedTokens.select((String value) => msg.changing ? value : ""));
    final cotDisplayState = ref.watch(P.msg.cotDisplayState(msg.id));
    final batchSelection = ref.watch(P.msg.batchSelection(msg));
    final messageLineHeight = ref.watch(P.preference.effectiveMessageLineHeight);

    final isMine = msg.isMine;
    final contextActions = UserMessageBottom.resolveContextMenuActions(
      msg: msg,
      worldType: worldType,
      selectMessageMode: selectMode || sharingMode,
    );
    ref.watch(P.msg.msgNode);
    final canSwitchUserBranch = isMine && !selectMode && !sharingMode && P.msg.siblingCount(msg) > 1;
    final canShowUserMessageMenu = contextActions.canEdit || contextActions.canCopy || canSwitchUserBranch;

    final finalContent = _resolveFinalContent(
      msg: msg,
      received: received,
      inSee: inSee,
      demoType: demoType,
      s: s,
    );
    final showTTSBottomOutsideBubble = !isMine && !selectMode && demoType == .tts;
    final thinkingData = _resolveThinkingData(
      msg: msg,
      finalContent: finalContent,
      worldType: worldType,
    );
    final cotContentHeight = _resolveCotContentHeight(
      cotDisplayState: cotDisplayState,
      cotResult: thinkingData.cotResult,
    );
    final showingCotContent = cotContentHeight != 0;
    final batchData = _resolveBatchData(
      isMine: isMine,
      finalContent: finalContent,
    );

    // 多问题并行的用户消息不渲染，finalization 后 isBatch 为 false 会正常显示
    if (isMine && batchData.isBatch) {
      return const SizedBox.shrink();
    }

    List<String>? perSlotQuestions;
    if (batchData.isBatch && !isMine) {
      perSlotQuestions = _resolvePerSlotQuestions(msg: msg);
    }

    final bubbleStyleData = _resolveBubbleStyleData(
      msg: msg,
      isMine: isMine,
      demoType: demoType,
      appTheme: appTheme,
      primary: theme.colorScheme.primary,
      isBatch: batchData.isBatch,
    );

    final opacity = _resolveMessageOpacity(
      editingIndex: editingIndex,
      index: index,
    );
    final thisMessageIsReceiving = receiveId == msg.id && receiving;
    final rawFontSize = theme.textTheme.bodyMedium?.fontSize ?? 14.0;
    final userMessageStyle = TS(
      s: rawFontSize * Config.msgFontScale,
      height: messageLineHeight,
    );
    final double rawMaxWidth = math.min(screenWidth, screenHeight);

    final Widget bubbleContent = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: screenWidth - _kBubbleMaxWidthAdjust,
        minHeight: _kBubbleMinHeight,
      ),
      child: isMine
          ? _UserMessageBubble(
              msg: msg,
              index: index,
              preferredDemoType: preferredDemoType,
              isMobile: isMobile,
              desktopActionsHovered: _desktopUserMessageHovered,
              finalContent: finalContent,
              userMsgBg: appTheme.userMsgBg,
              userMessageStyle: userMessageStyle,
              rawMaxWidth: rawMaxWidth,
              bubbleStyleData: bubbleStyleData,
              isBatch: batchData.isBatch,
              batchCount: batchData.batchCount,
            )
          : _BotMessageBubble(
              msg: msg,
              index: index,
              selectMode: selectMode,
              preferredDemoType: preferredDemoType,
              finalContent: finalContent,
              botMsgBg: appTheme.botMsgBg,
              qb: qb,
              bubbleStyleData: bubbleStyleData,
              thinkingData: thinkingData,
              cotContentHeight: cotContentHeight,
              showingCotContent: showingCotContent,
              isBatch: batchData.isBatch,
              batchCount: batchData.batchCount,
              batchSelection: batchSelection,
              thisMessageIsReceiving: thisMessageIsReceiving,
              perSlotQuestions: perSlotQuestions,
              slotLabels: msg.batchSlotLabels,
            ),
    );

    return GestureDetector(
      child: Align(
        alignment: isMine ? .centerRight : .centerLeft,
        child: IgnorePointer(
          ignoring: editingIndex != null && editingIndex != index,
          child: AnimatedOpacity(
            opacity: opacity,
            duration: 250.ms,
            child: Padding(
              padding: .only(
                left: batchData.isBatch ? 0 : appTheme.msgListMarginLeft,
                right: batchData.isBatch ? 0 : appTheme.msgListMarginRight,
                top: appTheme.msgListMarginTop,
                bottom: appTheme.msgListMarginBottom,
              ),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  if (demoType == .chat && msg.reference.enable) ReferenceInfo(refInfo: msg.reference, generating: msg.changing),
                  GestureDetector(
                    onTap: () => P.chat.onMessageTapped(msg),
                    onLongPressStart: canShowUserMessageMenu && isMobile
                        ? (_) {
                            P.app.hapticLight();
                            P.chat.showUserMessageContextMenu(
                              context: context,
                              canEdit: contextActions.canEdit,
                              canCopy: contextActions.canCopy,
                              index: index,
                              msg: msg,
                            );
                          }
                        : null,
                    child: isMine && !isMobile
                        ? MouseRegion(
                            onEnter: (_) => _onDesktopHoverChanged(true),
                            onExit: (_) => _onDesktopHoverChanged(false),
                            child: bubbleContent,
                          )
                        : bubbleContent,
                  ),
                  if (showTTSBottomOutsideBubble)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: screenWidth - _kBubbleMaxWidthAdjust),
                      child: BotMessageBottom(
                        msg,
                        index,
                        preferredDemoType: preferredDemoType,
                        finalContent: finalContent,
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

class _UserMessageBubble extends ConsumerWidget {
  final model.Message msg;
  final int index;
  final DemoType? preferredDemoType;
  final bool isMobile;
  final bool desktopActionsHovered;
  final String finalContent;
  final Color userMsgBg;
  final TS userMessageStyle;
  final double rawMaxWidth;
  final _BubbleStyleData bubbleStyleData;
  final bool isBatch;
  final int batchCount;

  const _UserMessageBubble({
    required this.msg,
    required this.index,
    required this.preferredDemoType,
    required this.isMobile,
    required this.desktopActionsHovered,
    required this.finalContent,
    required this.userMsgBg,
    required this.userMessageStyle,
    required this.rawMaxWidth,
    required this.bubbleStyleData,
    required this.isBatch,
    required this.batchCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUserImage = msg.type == .userImage;
    final debugColor = theme.colorScheme.error;
    final screenWidth = ref.watch(P.app.screenWidth);
    ref.watch(P.msg.msgNode);
    final branchSwitcherAvailable = P.msg.siblingCount(msg) > 1;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: screenWidth * 0.8),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .end,
        children: [
          Container(
            padding: bubbleStyleData.padding,
            decoration: BoxDecoration(
              color: userMsgBg,
              border: bubbleStyleData.border,
              borderRadius: bubbleStyleData.borderRadius,
            ),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .end,
              children: [
                if (kDebugMode && Args.debugMsgId) _MessageDebugId(msgId: msg.id, debugColor: debugColor),
                if (!isUserImage && finalContent.isNotEmpty)
                  isBatch
                      ? Text("${S.of(context).multi_question_title} ($batchCount)", style: userMessageStyle)
                      : Text(finalContent, style: userMessageStyle),
                if (isUserImage)
                  ClipRRect(
                    clipBehavior: Clip.antiAlias,
                    borderRadius: bubbleStyleData.borderRadius,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: rawMaxWidth * .8, maxHeight: rawMaxWidth * .8),
                      child: PhotoViewerImage(
                        borderRadius: 24,
                        imageUrl: msg.imageUrl!,
                        showDefaultCloseButton: false,
                        overlayBuilder: (BuildContext context) {
                          return const PhotoViewerOverlay();
                        },
                      ),
                    ),
                  ),
                if (preferredDemoType == .tts) UserTTSContent(msg, index),
              ],
            ),
          ),
          if (!isMobile || branchSwitcherAvailable)
            UserMessageBottom(
              msg,
              index,
              showInlineEditAndCopyButtons: !isMobile,
              desktopActionsHovered: isMobile ? null : desktopActionsHovered,
            ),
        ],
      ),
    );
  }
}

class _BotMessageBubble extends ConsumerWidget {
  final model.Message msg;
  final int index;
  final bool selectMode;
  final DemoType? preferredDemoType;
  final String finalContent;
  final Color botMsgBg;
  final Color qb;
  final _BubbleStyleData bubbleStyleData;
  final _ThinkingData thinkingData;
  final double? cotContentHeight;
  final bool showingCotContent;
  final bool isBatch;
  final int batchCount;
  final int? batchSelection;
  final bool thisMessageIsReceiving;
  final List<String>? perSlotQuestions;
  final List<String>? slotLabels;

  const _BotMessageBubble({
    required this.msg,
    required this.index,
    required this.selectMode,
    required this.preferredDemoType,
    required this.finalContent,
    required this.botMsgBg,
    required this.qb,
    required this.bubbleStyleData,
    required this.thinkingData,
    required this.cotContentHeight,
    required this.showingCotContent,
    required this.isBatch,
    required this.batchCount,
    required this.batchSelection,
    required this.thisMessageIsReceiving,
    this.perSlotQuestions,
    this.slotLabels,
  });

  void _toggleCotContent() {
    if (showingCotContent) {
      P.msg.cotDisplayState(msg.id).q = .hideCotHeader;
      return;
    }
    P.msg.cotDisplayState(msg.id).q = .showCotHeaderAndCotContent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    final showReasoningHeader = thinkingData.reasoning && !thinkingData.isQuickThinking && !isBatch;
    final debugColor = theme.colorScheme.error;
    final cotColor = qb.q(.55);
    final thoughtLabelColor = qb.q(.5);
    final appTheme = ref.watch(P.app.theme);

    double? fixedBatchBubbleHeight;
    if (isBatch) {
      final screenHeight = ref.watch(P.app.screenHeight);
      final paddingTop = ref.watch(P.app.paddingTop);
      final inputHeight = ref.watch(P.chat.inputHeight);
      final reserved =
          paddingTop +
          kToolbarHeight +
          4 +
          inputHeight +
          appTheme.msgListMarginTop +
          appTheme.msgListMarginBottom +
          bubbleStyleData.padding.vertical;
      final computed = screenHeight - reserved;
      fixedBatchBubbleHeight = math.max(200.0, computed);
    }

    final Widget bubble = Container(
      padding: bubbleStyleData.padding,
      decoration: BoxDecoration(
        color: botMsgBg,
        border: bubbleStyleData.border,
        borderRadius: bubbleStyleData.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          if (kDebugMode && Args.debugMsgId) _MessageDebugId(msgId: msg.id, debugColor: debugColor),
          if (isBatch)
            Padding(
              padding: .only(
                left: appTheme.msgListMarginLeft,
                right: appTheme.msgListMarginRight,
                bottom: 8,
              ),
              child: Wrap(
                children: [
                  Text(
                    s.batch_inference_running(batchCount),
                    style: TS(c: appTheme.qb5),
                  ),
                  if (batchSelection != null) const SizedBox(width: 16),
                  if (batchSelection != null)
                    Text(
                      s.batch_inference_selected(batchSelection! + 1),
                      style: TS(c: appTheme.qb5),
                    ),
                ],
              ),
            ),
          if (!thinkingData.reasoning && !isBatch) MarkdownRender(raw: finalContent, useMessageLineHeight: true),
          if (showReasoningHeader)
            GestureDetector(
              onTap: _toggleCotContent,
              child: Container(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Row(
                  children: [
                    Text(
                      thisMessageIsReceiving ? s.thinking : s.thought_result,
                      style: TS(c: thoughtLabelColor, w: .w600),
                    ),
                    showingCotContent
                        ? Icon(Icons.expand_more, color: thoughtLabelColor)
                        : Icon(Icons.expand_less, color: thoughtLabelColor),
                  ],
                ),
              ),
            ),
          if (showReasoningHeader) const SizedBox(height: 4),
          if (showReasoningHeader)
            AnimatedContainer(
              duration: 250.ms,
              height: cotContentHeight,
              child: MarkdownRender(
                raw: thinkingData.cotContent,
                color: cotColor,
                useMessageLineHeight: true,
              ),
            ),
          if (thinkingData.cotResult.isNotEmpty && thinkingData.reasoning && showingCotContent && !thinkingData.isQuickThinking && !isBatch)
            const SizedBox(height: 12),
          if (thinkingData.cotResult.isNotEmpty && thinkingData.reasoning && !isBatch)
            MarkdownRender(
              raw: thinkingData.cotResult,
              useMessageLineHeight: true,
            ),
          if (isBatch)
            Expanded(
              child: BatchMessageContent(msg, index, finalContent, perSlotQuestions: perSlotQuestions, slotLabels: slotLabels),
            ),
          if (demoType == .tts) BotTtsContent(msg, index),
          if (!selectMode && demoType != .tts)
            BotMessageBottom(msg, index, preferredDemoType: preferredDemoType, finalContent: finalContent),
        ],
      ),
    );

    if (fixedBatchBubbleHeight != null) {
      return SizedBox(height: fixedBatchBubbleHeight, child: bubble);
    }
    return bubble;
  }
}

class _MessageDebugId extends StatelessWidget {
  final int msgId;
  final Color debugColor;

  const _MessageDebugId({
    required this.msgId,
    required this.debugColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveDebugColor = debugColor == Colors.transparent ? theme.colorScheme.error : debugColor;

    return Container(
      decoration: BoxDecoration(color: effectiveDebugColor),
      child: Text("Debug: $msgId", style: const TS(c: kW)),
    );
  }
}

class _ThinkingData {
  final bool reasoning;
  final String cotContent;
  final String cotResult;

  const _ThinkingData({
    required this.reasoning,
    required this.cotContent,
    required this.cotResult,
  });

  bool get isQuickThinking => cotContent.trim().isEmpty;
}

class _BatchData {
  final bool isBatch;
  final int batchCount;

  const _BatchData({
    required this.isBatch,
    required this.batchCount,
  });
}

class _BubbleStyleData {
  final EdgeInsets padding;
  final Border? border;
  final BorderRadius borderRadius;

  const _BubbleStyleData({
    required this.padding,
    required this.border,
    required this.borderRadius,
  });
}

String _resolveFinalContent({
  required model.Message msg,
  required String received,
  required bool inSee,
  required DemoType demoType,
  required S s,
}) {
  String finalContent = msg.changing ? (received.isEmpty ? msg.content : received) : msg.content;
  if (msg.isSensitive) {
    finalContent = s.filter;
  }
  if (inSee && msg.isMine) {
    finalContent = finalContent.replaceAll(RegExp(r"<image>.*?</image>"), "");
  }

  finalContent = finalContent.replaceAll("\n", "\n\n");
  while (finalContent.contains("\n\n\n")) {
    finalContent = finalContent.replaceAll("\n\n\n", "\n\n");
  }

  if (msg.isMine) {
    finalContent = finalContent.replaceAll("\n\n", "\n");
    finalContent = finalContent.split(Config.userMsgModifierSep)[0];
  }

  if (demoType == .tts) return "";
  return finalContent;
}

_ThinkingData _resolveThinkingData({
  required model.Message msg,
  required String finalContent,
  required WorldType? worldType,
}) {
  final reasoning = finalContent.startsWith("<think>") && !msg.isSensitive;
  if (!reasoning) {
    return const _ThinkingData(
      reasoning: false,
      cotContent: "",
      cotResult: "",
    );
  }

  const thinkStartTagLength = 7;
  const thinkEndTagLength = 8;
  final endIndex = finalContent.indexOf("</think>");

  if (endIndex < 0) {
    final cotContent = finalContent.substring(thinkStartTagLength);
    return _ThinkingData(
      reasoning: true,
      cotContent: cotContent,
      cotResult: "",
    );
  }

  final cotContent = finalContent.substring(thinkStartTagLength, endIndex);
  if (endIndex + thinkEndTagLength >= finalContent.length) {
    return _ThinkingData(
      reasoning: true,
      cotContent: cotContent,
      cotResult: "",
    );
  }

  String cotResult = finalContent.substring(endIndex + thinkEndTagLength).trim();
  if (worldType == WorldType.reasoningQA) {
    if (cotResult.endsWith("</answer>")) cotResult = cotResult.replaceFirst("</answer>", "");
    if (cotResult.startsWith("<answer>")) cotResult = cotResult.replaceFirst("<answer>", "");
  }

  return _ThinkingData(
    reasoning: true,
    cotContent: cotContent,
    cotResult: cotResult,
  );
}

double? _resolveCotContentHeight({
  required CoTDisplayState cotDisplayState,
  required String cotResult,
}) {
  switch (cotDisplayState) {
    case .showCotHeaderIfCotResultIsEmpty:
      if (cotResult.isEmpty) return null;
      return 0;
    case .showCotHeaderAndCotContent:
      return null;
    case .hideCotHeader:
      return 0;
  }
}

_BatchData _resolveBatchData({
  required bool isMine,
  required String finalContent,
}) {
  final (_, bool isBatch, int batchCount, _) = getBatchInfo(finalContent);
  return _BatchData(
    isBatch: isBatch,
    batchCount: batchCount,
  );
}

List<String>? _resolvePerSlotQuestions({required model.Message msg}) {
  final parentNode = P.msg.msgNode.q.findParentByMsgId(msg.id);
  if (parentNode == null) return null;
  final parentMsg = P.msg.pool.q[parentNode.id];
  if (parentMsg == null || !parentMsg.isMine) return null;
  final parentContent = parentMsg.content.split(Config.userMsgModifierSep)[0];
  final (batch, isBatch, batchCount, _) = getBatchInfo(parentContent);
  if (!isBatch) return null;
  return batch.sublist(0, batchCount);
}

_BubbleStyleData _resolveBubbleStyleData({
  required model.Message msg,
  required bool isMine,
  required DemoType demoType,
  required AppTheme appTheme,
  required Color primary,
  required bool isBatch,
}) {
  EdgeInsets padding = appTheme.msgDefaultPadding;
  Border? border = Border.all(color: primary.q(.2));
  double radius = 12;

  switch (msg.type) {
    case .userTTS:
    case .ttsGeneration:
      radius = 16;
    case .userImage:
    case .text:
      break;
  }

  final borderRadius = BorderRadius.only(
    topLeft: .circular(isMine ? radius : 0),
    topRight: .circular(radius),
    bottomLeft: .circular(radius),
    bottomRight: .circular(radius),
  );

  switch (msg.type) {
    case .userImage:
      padding = .zero;
      border = Border.all(width: 0, color: Colors.transparent);
    case .userTTS:
      padding = .zero;
    case .text:
      if (!isMine) {
        border = null;
        padding = const .only(left: 6, top: 12, right: 6);
      }
    case .ttsGeneration:
      if (!isMine) {
        padding = const .only(left: 6, top: 6, right: 6, bottom: 2);
      }
      break;
  }

  if (demoType == .chat) {
    border = null;
    padding = isMine ? appTheme.chatUserMsgBubblePadding : appTheme.chatBotMsgBubblePadding;
  }

  if (demoType == .see && isMine) {
    padding = appTheme.chatUserMsgBubblePadding.copyWith(bottom: appTheme.chatUserMsgBubblePadding.top);
  }

  if (isBatch) {
    padding = padding.copyWith(left: 0, right: 0);
  }

  return _BubbleStyleData(
    padding: padding,
    border: border,
    borderRadius: borderRadius,
  );
}

double _resolveMessageOpacity({
  required int? editingIndex,
  required int index,
}) {
  if (editingIndex == null) return 1;
  if (editingIndex > index) return .667;
  if (editingIndex < index) return .333;
  return 1;
}
