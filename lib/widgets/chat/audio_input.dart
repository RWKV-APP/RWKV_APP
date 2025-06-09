// ignore: unused_import
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/world_type.dart';
import 'package:zone/state/p.dart';

const _kButtonSize = 72.0;
const _kButtonBottom = 36.0;
const _kWidgetSize = _kButtonSize + _kButtonBottom;

class AudioInput extends ConsumerWidget {
  const AudioInput({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final primary = Theme.of(context).colorScheme.primary;
    final demoType = ref.watch(P.app.demoType);
    final currentWorldType = ref.watch(P.rwkv.currentWorldType);
    final screenWidth = ref.watch(P.app.screenWidth);
    final receiving = ref.watch(P.chat.receivingTokens);
    final audioInteractorShown = ref.watch(P.tts.audioInteractorShown);

    bool shouldShow = false;

    if (demoType == DemoType.world) {
      switch (currentWorldType) {
        case null:
        case WorldType.engVisualQA:
        case WorldType.qa:
        case WorldType.reasoningQA:
        case WorldType.ocr:
          shouldShow = false;
        case WorldType.engAudioQA:
        case WorldType.chineseASR:
        case WorldType.engASR:
          shouldShow = true;
      }
    }

    String bottomMessage = "";
    double bottomMessageSize = 12;

    if (demoType == DemoType.world) {
      switch (currentWorldType) {
        case null:
        case WorldType.engVisualQA:
        case WorldType.qa:
        case WorldType.reasoningQA:
        case WorldType.ocr:
          bottomMessage = "";
        case WorldType.engAudioQA:
          bottomMessage = "Press and hold the microphone button above\nrelease to send";
        case WorldType.chineseASR:
          bottomMessage = "长按下方麦克风按钮开始录音\n松开即可发送";
        case WorldType.engASR:
          bottomMessage = "Press and hold the microphone button above\nrelease to send";
      }
    }

    double bottomAdjust = 0;

    if (currentWorldType?.isAudioDemo == true) {
      bottomAdjust = 12;
    }

    bool showGradient = true;

    Curve curve = shouldShow ? Curves.easeOutBack : Curves.easeInBack;

    if (demoType == DemoType.tts) {
      shouldShow = audioInteractorShown;
      bottomMessage = s.hold_to_record_release_to_send;
      bottomAdjust = audioInteractorShown ? 24.0 : 0;
      showGradient = false;
      curve = Curves.easeOut;
      bottomMessageSize = 16;
    }

    final customTheme = ref.watch(P.app.customTheme);

    return AnimatedPositioned(
      duration: 250.ms,
      curve: curve,
      bottom: shouldShow ? (0 + paddingBottom + bottomAdjust) : -_kWidgetSize,
      left: 0,
      child: MeasureSize(
        onChange: (size) {
          if (currentWorldType != WorldType.chineseASR && currentWorldType != WorldType.engASR) {
            return;
          }
          P.chat.inputHeight.q = size.height + 30;
        },
        child: SB(
          height: _kWidgetSize + bottomAdjust,
          width: screenWidth,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                height: 50,
                bottom: 0,
                child: C(
                  decoration: BD(
                    gradient: showGradient
                        ? LinearGradient(
                            colors: [
                              customTheme.scaffold.q(0),
                              customTheme.scaffold,
                              customTheme.scaffold,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    GD(
                      onTapDown: _onTapDown,
                      onTapUp: _onTapUp,
                      onTapCancel: _onTapCancel,
                      child: ClipRRect(
                        borderRadius: 1000.r,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: C(
                            height: _kButtonSize,
                            width: _kButtonSize,
                            decoration: BD(
                              color: primary.q(.2),
                              border: Border.all(color: primary.q(.5)),
                              borderRadius: 1000.r,
                            ),
                            child: Center(
                              child: receiving
                                  ? CircularProgressIndicator(
                                      color: primary,
                                      strokeWidth: 3,
                                      backgroundColor: primary.q(.1),
                                      strokeCap: StrokeCap.round,
                                    )
                                  : Icon(
                                      Icons.mic,
                                      size: 32,
                                      color: primary,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    12.h,
                    T(
                      bottomMessage,
                      s: TS(
                        s: bottomMessageSize,
                        c: primary.q(.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  FV _onTapDown(TapDownDetails details) async {
    final receiving = P.chat.receivingTokens.q;
    if (receiving) return;
    P.app.hapticLight();
    Alert.info(S.current.recording_your_voice);
    await P.world.startRecord();
  }

  FV _onTapCancel() async {
    final receiving = P.chat.receivingTokens.q;
    if (receiving) return;
    P.app.hapticLight();
    await P.world.stopRecord(isCancel: true);
  }

  FV _onTapUp(TapUpDetails details) async {
    final receiving = P.chat.receivingTokens.q;
    if (receiving) return;
    P.app.hapticMedium();
    final success = await P.world.stopRecord();
    if (!success) return;
    Alert.success(S.current.finish_recording);
  }
}
