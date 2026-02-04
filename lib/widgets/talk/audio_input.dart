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
import 'package:zone/store/p.dart';

const _kButtonSize = 72.0;
const _kButtonBottom = 36.0;
const _kWidgetSize = _kButtonSize + _kButtonBottom;

class AudioInput extends ConsumerWidget {
  final DemoType demoType;

  const AudioInput({super.key, required this.demoType});

  Future<void> _onPanStart(DragStartDetails details) async {
    qr;
    final receiving = P.rwkv.generating.q;
    if (receiving) return;
    P.app.hapticLight();
    Alert.info(S.current.recording_your_voice);
    await P.see.startRecord();
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    qr;
    final receiving = P.rwkv.generating.q;
    if (receiving) return;
    P.app.hapticMedium();
    final success = await P.see.stopRecord();
    if (!success) return;
    Alert.success(S.current.finish_recording);
  }

  Future<void> _onPanCancel() async {
    qr;
    final receiving = P.rwkv.generating.q;
    if (receiving) return;
    P.app.hapticLight();
    await P.see.stopRecord(isCancel: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final primary = Theme.of(context).colorScheme.primary;
    final currentWorldType = ref.watch(P.rwkv.currentWorldType);
    final screenWidth = ref.watch(P.app.screenWidth);
    final receiving = ref.watch(P.rwkv.generating);
    final audioInteractorShown = ref.watch(P.talk.audioInteractorShown);

    bool shouldShow = false;

    if (demoType == .see) {
      switch (currentWorldType) {
        case null:
        case WorldType.reasoningQA:
        case WorldType.ocr:
        case WorldType.modrwkvV2:
        case WorldType.modrwkvV3:
          shouldShow = false;
      }
    }

    String bottomMessage = "";
    double bottomMessageSize = 12;

    if (demoType == .see) {
      switch (currentWorldType) {
        case null:
        case WorldType.reasoningQA:
        case WorldType.ocr:
        case WorldType.modrwkvV2:
        case WorldType.modrwkvV3:
          bottomMessage = "";
      }
    }

    double bottomAdjust = 0;

    if (currentWorldType?.isAudioDemo == true) {
      bottomAdjust = 12;
    }

    bool showGradient = true;

    Curve curve = shouldShow ? Curves.easeOutBack : Curves.easeInBack;

    if (demoType == .tts) {
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
          P.chat.inputHeight.q = size.height + 30;
        },
        child: SizedBox(
          height: _kWidgetSize + bottomAdjust,
          width: screenWidth,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                height: 50,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: showGradient
                        ? LinearGradient(
                            colors: [
                              customTheme.scaffold.q(0),
                              customTheme.scaffold,
                              customTheme.scaffold,
                            ],
                            begin: .topCenter,
                            end: .bottomCenter,
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
                    GestureDetector(
                      onPanStart: _onPanStart,
                      onPanEnd: _onPanEnd,
                      onPanCancel: _onPanCancel,
                      child: ClipRRect(
                        borderRadius: .circular(1000),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            height: _kButtonSize,
                            width: _kButtonSize,
                            decoration: BoxDecoration(
                              color: primary.q(.2),
                              border: .all(color: primary.q(.5)),
                              borderRadius: .circular(1000),
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
                    const SizedBox(height: 12),
                    Text(
                      bottomMessage,
                      style: TS(
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
}
