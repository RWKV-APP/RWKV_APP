// ignore: unused_import
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:photo_viewer/photo_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zone/func/merge_wav.dart';
import 'package:zone/gen/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/cot_display_state.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/world_type.dart';
import 'package:zone/route/router.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/chat/audio_bubble.dart';
import 'package:zone/widgets/chat/bot_message_bottom.dart';
import 'package:zone/widgets/chat/tts/bot_tts_content.dart';
import 'package:zone/widgets/chat/photo_viewer_overlay.dart';
import 'package:zone/widgets/chat/user_message_bottom.dart';
import 'package:zone/widgets/chat/tts/user_tts_content.dart';

const double _kTextScaleFactor = 1.1;
const double _kTextScaleFactorForCotContent = 1;

class Message extends ConsumerWidget {
  final model.Message msg;
  final bool selectMode;

  /// 页面中第一个消息的 index 为 0
  final int index;

  const Message(this.msg, this.index, {super.key, required this.selectMode});

  void _onTapLink(String text, String? href, String title) async {
    if (href == null) return;
    await launchUrl(Uri.parse(href));
  }

  void _onTap() async {
    qq;

    if (P.rwkv.currentWorldType.q != null) {
      Focus.of(getContext()!).unfocus();
    }

    P.chat.focusNode.unfocus();
    P.tts.dismissAllShown();

    P.msg.latestClicked.q = msg;

    if (msg.type == model.MessageType.userAudio) {
      final audioUrl = msg.audioUrl;
      qqq("audioUrl: $audioUrl");
      if (audioUrl == null) return;
      if (P.world.playing.q) {
        P.world.stopPlaying();
      } else {
        P.world.play(path: audioUrl);
      }
      return;
    }

    if (msg.type == model.MessageType.ttsGeneration) {
      final start = DateTime.now().millisecondsSinceEpoch;
      final audioUrl = await mergeWavFiles(msg.ttsFilePaths!);
      final end = DateTime.now().millisecondsSinceEpoch;
      qqq("mergeWavFiles: ${end - start}ms");
      if (P.world.playing.q) {
        P.world.stopPlaying();
      } else {
        if (!msg.ttsIsDone) Alert.info(S.current.playing_partial_generated_audio);
        P.world.play(path: audioUrl);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final primary = Theme.of(context).colorScheme.primary;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;

    final demoType = ref.watch(P.app.demoType);
    final worldType = ref.watch(P.rwkv.currentWorldType);

    // 由 message 对象是否正在 changing 来决定是否根据 receivedTokens 渲染消息内容
    final received = ref.watch(P.chat.receivedTokens.select((v) => msg.changing ? v : ""));
    final cotDisplayState = ref.watch(P.chat.cotDisplayState(msg.id));

    final editingIndex = ref.watch(P.msg.editingOrRegeneratingIndex);

    final receiveId = ref.watch(P.chat.receiveId);
    final receiving = ref.watch(P.chat.receivingTokens);

    final isMine = msg.isMine;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    const marginHorizontal = 12.0;
    const marginVertical = .0;
    const kBubbleMinHeight = 44.0;
    const kBubbleMaxWidthAdjust = .0;

    final content = msg.content;
    final changing = msg.changing;

    String finalContent = changing ? (received.isEmpty ? content : received) : content;
    if (msg.isSensitive) finalContent = s.filter;

    finalContent = finalContent.replaceAll("\n", "\n\n");
    while (finalContent.contains("\n\n\n")) {
      finalContent = finalContent.replaceAll("\n\n\n", "\n\n");
    }

    if (isMine) finalContent = finalContent.replaceAll("\n\n", "\n");

    switch (demoType) {
      case DemoType.tts:
        finalContent = "";
      case DemoType.chat:
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
      case DemoType.world:
        break;
    }

    final reasoning = msg.isReasoning && !msg.isSensitive;

    String cotContent = "";
    String cotResult = "";

    final subStringCount = worldType == WorldType.reasoningQA ? 8 : 9;

    if (reasoning) {
      assert(!msg.isMine);
      final isCot = finalContent.startsWith("<think>");
      if (isCot) {
        if (finalContent.contains("</think>")) {
          final endIndex = finalContent.indexOf("</think>");
          cotContent = finalContent.substring(7, endIndex);
          if (endIndex + subStringCount < finalContent.length) {
            final startIndex = endIndex + subStringCount;
            cotResult = finalContent.substring(startIndex);
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

    final textScaleFactorForCotContent = TextScaler.linear(MediaQuery.textScalerOf(context).scale(_kTextScaleFactorForCotContent));

    final markdownStyleSheetForCotContent = MarkdownStyleSheet(
      p: TS(c: qb.q(.5)),
      h1: TS(c: qb.q(.5)),
      h2: TS(c: qb.q(.5)),
      h3: TS(c: qb.q(.5)),
      h4: TS(c: qb.q(.5)),
      h5: TS(c: qb.q(.5)),
      h6: TS(c: qb.q(.5)),
      listBullet: TS(c: qb.q(.5)),
      listBulletPadding: const EI.o(l: 0),
      listIndent: 20,
      textScaler: textScaleFactorForCotContent,
    );

    final textScaleFactor = TextScaler.linear(MediaQuery.textScalerOf(context).scale(_kTextScaleFactor));

    final markdownStyleSheet = MarkdownStyleSheet(
      listBulletPadding: const EI.o(l: 0),
      listIndent: 20,
      textScaler: textScaleFactor,
      horizontalRuleDecoration: BoxDecoration(
        color: qb.q(.1),
        border: Border(top: BorderSide(color: qb.q(.1), width: 1)),
      ),
    );

    final rawFontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
    final userMessageStyle = TS(s: rawFontSize * _kTextScaleFactor);

    double? cotContentHeight;

    switch (cotDisplayState) {
      case CoTDisplayState.showCotHeaderIfCotResultIsEmpty:
        if (cotResult.isEmpty) {
          cotContentHeight = null;
        } else {
          cotContentHeight = 0;
        }
      case CoTDisplayState.showCotHeaderAndCotContent:
        cotContentHeight = null;
      case CoTDisplayState.hideCotHeader:
        cotContentHeight = 0;
    }

    final showingCotContent = cotContentHeight != 0;

    final isUserImage = msg.type == model.MessageType.userImage;
    final isUserAudio = msg.type == model.MessageType.userAudio;

    String worldDemoMessageHeader = "";

    switch (worldType) {
      case WorldType.chineseASR:
        if (changing) {
          worldDemoMessageHeader = "正在识别您的声音...";
        } else {
          worldDemoMessageHeader = "语音识别结果";
        }
      case WorldType.engASR:
        if (changing) {
          worldDemoMessageHeader = "Recognizing your voice...";
        } else {
          worldDemoMessageHeader = "Voice recognition result";
        }
      case null:
      case WorldType.engVisualQA:
      case WorldType.qa:
      case WorldType.reasoningQA:
      case WorldType.engAudioQA:
      case WorldType.ocr:
        break;
    }

    bool showUserEditButton = true;
    bool showUserCopyButton = true;

    switch (worldType) {
      case null:
        break;
      default:
        showUserEditButton = false;
        showUserCopyButton = false;
    }

    EI padding = const EI.o(t: 12, l: 12, r: 12);
    Border? border = Border.all(color: primary.q(.2));
    double radius = 20;

    switch (msg.type) {
      case model.MessageType.userTTS:
      case model.MessageType.ttsGeneration:
        radius = 16;
      case model.MessageType.userImage:
      case model.MessageType.text:
      case model.MessageType.userAudio:
    }

    BorderRadius? borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isMine ? radius : 0),
      topRight: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(isMine ? 0 : radius),
    );

    BorderRadius clipBorderRadius = BorderRadius.zero;

    switch (msg.type) {
      case model.MessageType.userImage:
        padding = EI.zero;
        border = Border.all(width: 0);
        clipBorderRadius = borderRadius;
        borderRadius = null;

      case model.MessageType.userTTS:
        padding = EI.zero;

      case model.MessageType.text:
        if (!msg.isMine) border = null;
        if (!msg.isMine) padding = const EI.o(t: 12, l: 6, r: 6);
      case model.MessageType.ttsGeneration:
      case model.MessageType.userAudio:
    }

    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    final rawMaxWidth = math.min(screenWidth, screenHeight);

    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // 如果是快速考 <think>\n<think>, 则不展示思考过程
    final isQuickThinking = cotContent.trim().isEmpty;

    final bubbleContent = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width - kBubbleMaxWidthAdjust, minHeight: kBubbleMinHeight),
      child: ClipRRect(
        borderRadius: clipBorderRadius,
        child: C(
          padding: padding,
          decoration: BD(
            color: isMine ? primaryContainer : null,
            border: border,
            borderRadius: borderRadius,
          ),
          child: Column(
            crossAxisAlignment: isMine ? CAA.end : CAA.start,
            children: [
              if (isMine) ...[
                // 🔥 User message
                if (!isUserImage && !isUserAudio && finalContent.isNotEmpty) T(finalContent, s: userMessageStyle),
                // 🔥 User message image
                if (isUserImage)
                  ConstrainedBox(
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
                // 🔥 User message audio
                if (isUserAudio) AudioBubble(msg),
                UserTTSContent(msg, index),
                UserMessageBottom(msg, index),
              ],
              if (!isMine) ...[
                // 🔥 Bot message audio recognition result
                if (worldDemoMessageHeader.isNotEmpty)
                  T(
                    worldDemoMessageHeader,
                    s: TS(c: qb.q(.5), w: FW.w700, s: 10),
                  ),
                if (worldDemoMessageHeader.isNotEmpty) 4.h,
                // 🔥 Bot message
                if (!reasoning)
                  MarkdownBody(
                    data: finalContent,
                    selectable: false,
                    shrinkWrap: true,
                    styleSheet: markdownStyleSheet,
                    onTapLink: _onTapLink,
                  ),
                // 🔥 Bot message cot header
                if (reasoning && !isQuickThinking)
                  GD(
                    onTap: () {
                      if (showingCotContent) {
                        ref.read(P.chat.cotDisplayState(msg.id).notifier).state = CoTDisplayState.hideCotHeader;
                      } else {
                        ref.read(P.chat.cotDisplayState(msg.id).notifier).state = CoTDisplayState.showCotHeaderAndCotContent;
                      }
                    },
                    child: C(
                      decoration: const BD(color: kC),
                      child: Row(
                        children: [
                          T(
                            thisMessageIsReceiving ? s.thinking : s.thought_result,
                            s: TS(c: qb.q(.5), w: FW.w600),
                          ),
                          showingCotContent ? Icon(Icons.expand_more, color: qb.q(.5)) : Icon(Icons.expand_less, color: qb.q(.5)),
                        ],
                      ),
                    ),
                  ),
                // 🔥 Bot message cot content
                if (reasoning && !isQuickThinking) 4.h,
                if (reasoning && !isQuickThinking)
                  AnimatedContainer(
                    duration: 250.ms,
                    height: cotContentHeight,
                    child: MarkdownBody(
                      data: cotContent,
                      selectable: false,
                      shrinkWrap: true,
                      styleSheet: markdownStyleSheetForCotContent,
                      onTapLink: _onTapLink,
                    ),
                  ),
                // 🔥 Bot message cot result
                if (cotResult.isNotEmpty && reasoning && showingCotContent && !isQuickThinking) 12.h,
                if (cotResult.isNotEmpty && reasoning)
                  MarkdownBody(
                    data: cotResult,
                    selectable: false,
                    shrinkWrap: true,
                    styleSheet: markdownStyleSheet,
                    onTapLink: _onTapLink,
                  ),
                if (!selectMode) BotMessageBottom(msg, index),
                BotTtsContent(msg, index),
              ],
            ],
          ),
        ),
      ),
    );

    return Align(
      alignment: alignment,
      child: IgnorePointer(
        ignoring: editingIndex != null && editingIndex != index,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: 250.ms,
          child: Padding(
            padding: const EI.s(h: marginHorizontal, v: marginVertical),
            child: GD(onTap: _onTap, child: bubbleContent),
          ),
        ),
      ),
    );
  }
}
