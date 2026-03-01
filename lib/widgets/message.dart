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
  bool _userMessageHovered = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.msg;
    final index = widget.index;
    final selectMode = widget.selectMode;
    final preferredDemoType = widget.preferredDemoType;
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final primary = Theme.of(context).colorScheme.primary;

    final appTheme = ref.watch(P.app.theme);
    final botMsgBg = appTheme.botMsgBg;
    final userMsgBg = appTheme.userMsgBg;
    final msgDefaultPadding = appTheme.msgDefaultPadding;

    final DemoType demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    final worldType = ref.watch(P.rwkv.currentWorldType);
    final isMobile = ref.watch(P.app.isMobile);
    final sharingMode = ref.watch(P.chat.isSharing);

    // 由 message 对象是否正在 changing 来决定是否根据 receivedTokens 渲染消息内容
    final received = ref.watch(P.chat.receivedTokens.select((v) => msg.changing ? v : ""));
    final cotDisplayState = ref.watch(P.msg.cotDisplayState(msg.id));

    final editingIndex = ref.watch(P.msg.editingOrRegeneratingIndex);

    final receiveId = ref.watch(P.chat.receiveId);
    final receiving = ref.watch(P.rwkv.generating);

    final inSee = ref.watch(P.app.pageKey) == .see;
    final isMine = msg.isMine;
    final isChat = demoType == .chat;
    final contextActions = UserMessageBottom.resolveContextMenuActions(
      msg: msg,
      worldType: worldType,
      selectMessageMode: selectMode || sharingMode,
    );
    final canShowUserMessageMenu = contextActions.canEdit || contextActions.canCopy;
    final Alignment alignment = isMine ? .centerRight : .centerLeft;
    const kBubbleMinHeight = 44.0;
    const kBubbleMaxWidthAdjust = .0;

    final content = msg.content;
    final changing = msg.changing;
    final reference = msg.reference;

    String finalContent = changing ? (received.isEmpty ? content : received) : content;
    if (msg.isSensitive) finalContent = s.filter;
    if (inSee && isMine) finalContent = finalContent.replaceAll(RegExp(r"<image>.*?</image>"), "");

    finalContent = finalContent.replaceAll("\n", "\n\n");
    while (finalContent.contains("\n\n\n")) {
      finalContent = finalContent.replaceAll("\n\n\n", "\n\n");
    }

    if (isMine) finalContent = finalContent.replaceAll("\n\n", "\n");
    if (isMine) finalContent = finalContent.split(Config.userMsgModifierSep)[0];

    switch (demoType) {
      case .tts:
        finalContent = "";
      case .chat:
      case .fifthteenPuzzle:
      case .othello:
      case .sudoku:
      case .see:
        break;
    }

    final reasoning = finalContent.startsWith("<think>") && !msg.isSensitive;

    String cotContent = "";
    String cotResult = "";

    final subStringCount = worldType == WorldType.reasoningQA ? 8 : 8;

    if (reasoning) {
      assert(!msg.isMine);
      final isCot = finalContent.startsWith("<think>");
      if (isCot) {
        if (finalContent.contains("</think>")) {
          final endIndex = finalContent.indexOf("</think>");
          cotContent = finalContent.substring(7, endIndex);
          if (endIndex + subStringCount < finalContent.length) {
            final startIndex = endIndex + subStringCount;
            cotResult = finalContent.substring(startIndex).trim();
            if (worldType == WorldType.reasoningQA) {
              if (cotResult.endsWith("</answer>")) cotResult = cotResult.replaceFirst("</answer>", "");
              if (cotResult.startsWith("<answer>")) cotResult = cotResult.replaceFirst("<answer>", "");
            }
          } else {
            cotResult = "";
          }
        } else {
          cotContent = finalContent.substring(7);
          cotResult = "";
        }
      }
    }

    final isHistoryForEditing = editingIndex != null && editingIndex > index;
    final isEditing = editingIndex != null && editingIndex == index;
    final isFutureForEditing = editingIndex != null && editingIndex < index;

    final width = ref.watch(P.app.screenWidth);

    double opacity = 1;

    if (isHistoryForEditing) {
      opacity = .667;
    } else if (isFutureForEditing) {
      opacity = .333;
    } else if (isEditing) {
      opacity = 1;
    } else {
      opacity = 1;
    }

    final thisMessageIsReceiving = receiveId == msg.id && receiving;

    final rawFontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
    final userMessageStyle = TS(s: rawFontSize * Config.msgFontScale);

    double? cotContentHeight;

    switch (cotDisplayState) {
      case .showCotHeaderIfCotResultIsEmpty:
        if (cotResult.isEmpty) {
          cotContentHeight = null;
        } else {
          cotContentHeight = 0;
        }
      case .showCotHeaderAndCotContent:
        cotContentHeight = null;
      case .hideCotHeader:
        cotContentHeight = 0;
    }

    final showingCotContent = cotContentHeight != 0;

    final isUserImage = msg.type == .userImage;

    String worldDemoMessageHeader = "";

    EdgeInsets padding = msgDefaultPadding;
    Border? border = .all(color: primary.q(.2));
    double radius = 12;

    switch (msg.type) {
      case .userTTS:
      case .ttsGeneration:
        radius = 16;
      case .userImage:
      case .text:
    }

    BorderRadius? borderRadius = .only(
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
        if (!msg.isMine) border = null;
        if (!msg.isMine) padding = const .only(left: 6, top: 12, right: 6);

      case .ttsGeneration:
    }

    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    final rawMaxWidth = math.min(screenWidth, screenHeight);

    // 如果是快速考 <think>\n<think>, 则不展示思考过程
    final isQuickThinking = cotContent.trim().isEmpty;

    if (isChat) {
      border = null;
      padding = isMine ? appTheme.chatUserMsgBubblePadding : appTheme.chatBotMsgBubblePadding;
    }

    late final bool isBatch;
    late final int batchCount;

    if (isMine) {
      isBatch = false;
    } else {
      (_, isBatch, batchCount, _) = getBatchInfo(finalContent);
    }

    if (isBatch) padding = padding.copyWith(left: 0, right: 0);

    final batchSelection = ref.watch(P.msg.batchSelection(msg));

    final bubbleContent = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width - kBubbleMaxWidthAdjust,
        minHeight: kBubbleMinHeight,
      ),
      child: isMine
          ? Column(
              mainAxisSize: .min,
              crossAxisAlignment: .end,
              children: [
                Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    color: userMsgBg,
                    border: border,
                    borderRadius: borderRadius,
                  ),
                  child: Column(
                    mainAxisSize: .min,
                    crossAxisAlignment: .end,
                    children: [
                      if (kDebugMode && Args.debugMsgId)
                        Container(
                          decoration: BoxDecoration(color: Colors.red.q(1)),
                          child: Text("Debug: ${msg.id}", style: const TS(c: kW)),
                        ),
                      if (!isUserImage && finalContent.isNotEmpty) Text(finalContent, style: userMessageStyle),
                      if (isUserImage)
                        ClipRRect(
                          clipBehavior: Clip.antiAlias,
                          borderRadius: borderRadius,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: rawMaxWidth * .8, maxHeight: rawMaxWidth * .8),
                            child: PhotoViewerImage(
                              borderRadius: 24,
                              imageUrl: msg.imageUrl!,
                              showDefaultCloseButton: false,
                              overlayBuilder: (context) {
                                return const PhotoViewerOverlay();
                              },
                            ),
                          ),
                        ),
                      if (preferredDemoType == .tts) UserTTSContent(msg, index),
                    ],
                  ),
                ),
                if (!isMobile)
                  UserMessageBottom(
                    msg,
                    index,
                    showInlineEditAndCopyButtons: !isMobile,
                    desktopActionsHovered: isMine && !isMobile ? _userMessageHovered : null,
                  ),
              ],
            )
          : Container(
              padding: padding,
              decoration: BoxDecoration(
                color: botMsgBg,
                border: border,
                borderRadius: borderRadius,
              ),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  if (kDebugMode && Args.debugMsgId)
                    Container(
                      decoration: BoxDecoration(color: Colors.red.q(1)),
                      child: Text("Debug: ${msg.id}", style: const TS(c: kW)),
                    ),
                  if (isBatch)
                    Padding(
                      padding: const .only(left: 14, right: 14, bottom: 4),
                      child: Wrap(
                        children: [
                          Text(
                            s.batch_inference_running(batchCount),
                            style: const TS(c: kCG),
                          ),
                          if (batchSelection != null) const SizedBox(width: 16),
                          if (batchSelection != null)
                            Text(
                              s.batch_inference_selected(batchSelection + 1),
                              style: const TS(c: kCG),
                            ),
                        ],
                      ),
                    ),
                  if (worldDemoMessageHeader.isNotEmpty)
                    Text(
                      worldDemoMessageHeader,
                      style: TS(c: qb.q(.5), w: .w700, s: 10),
                    ),
                  if (worldDemoMessageHeader.isNotEmpty) const SizedBox(height: 4),
                  if (!reasoning && !isBatch) MarkdownRender(raw: finalContent),
                  if (reasoning && !isQuickThinking && !isBatch)
                    Semantics(
                      button: true,
                      label: s.thought_result,
                      expanded: showingCotContent,
                      child: GestureDetector(
                        onTap: () {
                          if (showingCotContent) {
                            P.msg.cotDisplayState(msg.id).q = .hideCotHeader;
                          } else {
                            P.msg.cotDisplayState(msg.id).q = .showCotHeaderAndCotContent;
                          }
                        },
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.transparent),
                          child: Row(
                            children: [
                              Text(
                                thisMessageIsReceiving ? s.thinking : s.thought_result,
                                style: TS(c: qb.q(.5), w: .w600),
                              ),
                              showingCotContent ? Icon(Icons.expand_more, color: qb.q(.5)) : Icon(Icons.expand_less, color: qb.q(.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (reasoning && !isQuickThinking && !isBatch) const SizedBox(height: 4),
                  if (reasoning && !isQuickThinking && !isBatch)
                    AnimatedContainer(
                      duration: 250.ms,
                      height: cotContentHeight,
                      child: MarkdownRender(raw: cotContent, color: qb.q(.55)),
                    ),
                  if (cotResult.isNotEmpty && reasoning && showingCotContent && !isQuickThinking && !isBatch) const SizedBox(height: 12),
                  if (cotResult.isNotEmpty && reasoning && !isBatch) MarkdownRender(raw: cotResult),
                  if (isBatch) BatchMessageContent(msg, index, finalContent),
                  if (!selectMode) BotMessageBottom(msg, index, preferredDemoType: preferredDemoType, finalContent: finalContent),
                  if (preferredDemoType == .tts) BotTtsContent(msg, index),
                ],
              ),
            ),
    );

    return GestureDetector(
      child: Align(
        alignment: alignment,
        child: IgnorePointer(
          ignoring: editingIndex != null && editingIndex != index,
          child: AnimatedOpacity(
            opacity: opacity,
            duration: 250.ms,
            child: Padding(
              padding: .only(
                left: appTheme.msgListMarginLeft,
                right: appTheme.msgListMarginRight,
                top: appTheme.msgListMarginTop,
                bottom: appTheme.msgListMarginBottom,
              ),
              child: Column(
                children: [
                  if (demoType == .chat && reference.enable) ReferenceInfo(refInfo: reference, generating: changing),
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
                            onEnter: (_) => setState(() => _userMessageHovered = true),
                            onExit: (_) => setState(() => _userMessageHovered = false),
                            child: bubbleContent,
                          )
                        : bubbleContent,
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
