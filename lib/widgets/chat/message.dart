// ignore: unused_import
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:photo_viewer/photo_viewer.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zone/args.dart';
import 'package:zone/config.dart';
import 'package:zone/func/get_batch_info.dart';
import 'package:zone/gen/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/cot_display_state.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/model/message_type.dart' as model;
import 'package:zone/model/ref_info.dart' as model;
import 'package:zone/model/world_type.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/audio_bubble.dart';
import 'package:zone/widgets/chat/batch_message_content.dart';
import 'package:zone/widgets/chat/bot_message_bottom.dart';
import 'package:zone/widgets/chat/search_reference_dialog.dart';
import 'package:zone/widgets/chat/tts/bot_tts_content.dart';
import 'package:zone/widgets/chat/photo_viewer_overlay.dart';
import 'package:zone/widgets/chat/user_message_bottom.dart';
import 'package:zone/widgets/chat/tts/user_tts_content.dart';

const double _kTextScaleFactor = 1.1;
const double _kTextScaleFactorForCotContent = 1;

class Message extends ConsumerWidget {
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

  void _onTapLink(String? href, String title) async {
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
      final end = DateTime.now().millisecondsSinceEpoch;
      qqq("mergeWavFiles: ${end - start}ms");
      if (P.world.playing.q) {
        P.world.stopPlaying();
      } else {
        if (!msg.ttsIsDone) Alert.info(S.current.playing_partial_generated_audio);
        P.world.play(path: msg.audioUrl!);
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

    final DemoType demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    final worldType = ref.watch(P.rwkv.currentWorldType);

    // 由 message 对象是否正在 changing 来决定是否根据 receivedTokens 渲染消息内容
    final received = ref.watch(P.chat.receivedTokens.select((v) => msg.changing ? v : ""));
    final cotDisplayState = ref.watch(P.msg.cotDisplayState(msg.id));

    final editingIndex = ref.watch(P.msg.editingOrRegeneratingIndex);

    final receiveId = ref.watch(P.chat.receiveId);
    final receiving = ref.watch(P.chat.receivingTokens);

    final inSee = ref.watch(P.app.pageKey) == PageKey.see;
    final isMine = msg.isMine;
    final isChat = demoType == DemoType.chat;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    const marginHorizontal = 12.0;
    const marginVertical = .0;
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
      case DemoType.tts:
        finalContent = "";
      case DemoType.chat:
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.sudoku:
      case DemoType.world:
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

    final textScaleFactor = TextScaler.linear(MediaQuery.textScalerOf(context).scale(_kTextScaleFactor));

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

    EdgeInsets padding = const EI.o(t: 12, l: 12, r: 12);
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

    // 如果是快速考 <think>\n<think>, 则不展示思考过程
    final isQuickThinking = cotContent.trim().isEmpty;

    if (isChat) {
      border = null;
      padding = const EI.o(t: 12, l: 12, r: 12, b: 4);
      borderRadius = BorderRadius.circular(16);
    }

    final botMessageBackgroundColor = Theme.of(context).colorScheme.surface;

    late final bool isBatch;
    late final int batchCount;

    if (isMine) {
      isBatch = false;
    } else {
      (_, isBatch, batchCount, _) = getBatchInfo(finalContent);
    }

    if (isBatch) padding = padding.copyWith(left: 0, right: 0);

    final batchSelection = ref.watch(P.msg.batchSelection(msg));

    final gptMarkdownStyle = TextStyle(
      // color: kCR,
      fontSize: rawFontSize * _kTextScaleFactor,
    );

    final bubbleContent = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width - kBubbleMaxWidthAdjust, minHeight: kBubbleMinHeight),
      child: ClipRRect(
        borderRadius: clipBorderRadius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isMine ? primaryContainer : botMessageBackgroundColor,
            border: border,
            borderRadius: borderRadius,
          ),
          child: Column(
            crossAxisAlignment: isMine ? CAA.end : CAA.start,
            children: [
              if (kDebugMode && Args.debugMsgId)
                Container(
                  decoration: BoxDecoration(color: kCR.q(1)),
                  child: T("Debug: ${msg.id}", s: const TS(c: kW)),
                ),
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
                if (preferredDemoType == DemoType.tts) UserTTSContent(msg, index),
                UserMessageBottom(msg, index),
              ],
              if (!isMine) ...[
                if (isBatch)
                  Padding(
                    padding: const EI.o(l: 14, b: 4, r: 14),
                    child: Wrap(
                      children: [
                        Text(
                          s.batch_inference_running(batchCount),
                          style: const TS(c: kCG),
                        ),
                        if (batchSelection != null) 16.w,
                        if (batchSelection != null)
                          Text(
                            s.batch_inference_selected(batchSelection + 1),
                            style: const TS(c: kCG),
                          ),
                      ],
                    ),
                  ),
                // 🔥 Bot message audio recognition result
                if (worldDemoMessageHeader.isNotEmpty)
                  T(
                    worldDemoMessageHeader,
                    s: TS(c: qb.q(.5), w: FontWeight.w700, s: 10),
                  ),
                if (worldDemoMessageHeader.isNotEmpty) 4.h,
                // 🔥 Bot message
                if (!reasoning && !isBatch)
                  GptMarkdown(
                    finalContent.replaceAll("\n\n", "\n"),
                    onLinkTap: _onTapLink,
                    style: gptMarkdownStyle,
                  ),
                // 🔥 Bot message cot header
                if (reasoning && !isQuickThinking && !isBatch)
                  GestureDetector(
                    onTap: () {
                      if (showingCotContent) {
                        P.msg.cotDisplayState(msg.id).q = CoTDisplayState.hideCotHeader;
                      } else {
                        P.msg.cotDisplayState(msg.id).q = CoTDisplayState.showCotHeaderAndCotContent;
                      }
                    },
                    child: Container(
                      decoration: const BoxDecoration(color: kC),
                      child: Row(
                        children: [
                          T(
                            thisMessageIsReceiving ? s.thinking : s.thought_result,
                            s: TS(c: qb.q(.5), w: FontWeight.w600),
                          ),
                          showingCotContent ? Icon(Icons.expand_more, color: qb.q(.5)) : Icon(Icons.expand_less, color: qb.q(.5)),
                        ],
                      ),
                    ),
                  ),
                // 🔥 Bot message cot content
                if (reasoning && !isQuickThinking && !isBatch) 4.h,
                if (reasoning && !isQuickThinking && !isBatch)
                  AnimatedContainer(
                    duration: 250.ms,
                    height: cotContentHeight,
                    child: GptMarkdown(
                      cotContent.replaceAll("\n\n", "\n"),
                      onLinkTap: _onTapLink,
                      style: TextStyle(
                        color: qb.q(.6),
                        fontSize: rawFontSize * _kTextScaleFactorForCotContent,
                      ),
                    ),
                  ),
                // 🔥 Bot message cot result
                if (cotResult.isNotEmpty && reasoning && showingCotContent && !isQuickThinking && !isBatch) 12.h,
                if (cotResult.isNotEmpty && reasoning && !isBatch)
                  GptMarkdown(
                    cotResult.replaceAll("\n\n", "\n"),
                    onLinkTap: _onTapLink,
                    style: gptMarkdownStyle,
                    orderedListBuilder: (context, no, child, config) {
                      return MediaQuery.withNoTextScaling(child: child);
                    },
                    unOrderedListBuilder: (context, child, config) {
                      return MediaQuery.withNoTextScaling(child: child);
                    },
                  ),
                if (isBatch) BatchMessageContent(msg, index, finalContent),
                if (!selectMode) BotMessageBottom(msg, index, preferredDemoType: preferredDemoType, finalContent: finalContent),
                if (preferredDemoType == DemoType.tts) BotTtsContent(msg, index),
              ],
            ],
          ),
        ),
      ),
    );

    final v = textScaleFactor.scale(14.0) / 14.0;
    final alphaS = 1.5 / v;

    return GptMarkdownTheme(
      gptThemeData: GptMarkdownTheme.of(context).copyWith(
        h1: TextStyle(fontSize: rawFontSize * 1.0 * alphaS),
        h2: TextStyle(fontSize: rawFontSize * 0.98 * alphaS),
        h3: TextStyle(fontSize: rawFontSize * 0.96 * alphaS),
        h4: TextStyle(fontSize: rawFontSize * 0.94 * alphaS),
        h5: TextStyle(fontSize: rawFontSize * 0.92 * alphaS),
        h6: TextStyle(fontSize: rawFontSize * 0.9 * alphaS),
      ),
      child: GestureDetector(
        child: Align(
          alignment: alignment,
          child: IgnorePointer(
            ignoring: editingIndex != null && editingIndex != index,
            child: AnimatedOpacity(
              opacity: opacity,
              duration: 250.ms,
              child: Padding(
                padding: const EI.s(h: marginHorizontal, v: marginVertical),
                child: Column(
                  children: [
                    if (demoType == DemoType.chat && reference.enable) _ReferenceInfo(refInfo: reference, generating: changing),
                    GestureDetector(onTap: _onTap, child: bubbleContent),
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

class _ReferenceInfo extends ConsumerStatefulWidget {
  final model.RefInfo refInfo;
  final bool generating;

  const _ReferenceInfo({required this.refInfo, required this.generating});

  @override
  ConsumerState<_ReferenceInfo> createState() => _ReferenceInfoState();
}

class _ReferenceInfoState extends ConsumerState<_ReferenceInfo> {
  @override
  Widget build(BuildContext context) {
    final prefill = ref.watch(P.rwkv.prefillProgress).clamp(0, 1).toDouble();

    final hasError = widget.refInfo.error.isNotEmpty;
    final showProgress = prefill > 0 && prefill < 1 && widget.generating && !hasError;

    final primary = Theme.of(context).colorScheme.primary;
    final searching = widget.refInfo.list.isEmpty && widget.generating && !hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.refInfo.enable)
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: hasError || searching ? null : () => SearchReferenceDialog.show(context, widget.refInfo),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.q(.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: searching
                    ? _AdvancedBlinkText(text: S.current.searching, color: primary)
                    : Text(
                        hasError ? S.current.search_failed : sprintf(S.current.x_pages_found, [widget.refInfo.list.length]),
                        style: TextStyle(color: primary, fontSize: 12),
                      ),
              ),
            ),
          ),
        if (showProgress) const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: showProgress ? 1 : 0,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 100),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              height: showProgress ? 20 : 0,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(value: prefill, color: primary, backgroundColor: primary.q(.1)),
                  ),
                  const SizedBox(width: 10),
                  Text(S.current.analysing_result, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdvancedBlinkText extends StatefulWidget {
  final String text;
  final Color color;

  const _AdvancedBlinkText({required this.text, required this.color});

  @override
  _AdvancedBlinkTextState createState() => _AdvancedBlinkTextState();
}

class _AdvancedBlinkTextState extends State<_AdvancedBlinkText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.color,
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          widget.text,
          style: TextStyle(fontSize: 12, color: _colorAnimation.value),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
