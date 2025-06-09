import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/state/p.dart';

class UserTTSContent extends ConsumerWidget {
  const UserTTSContent(this.msg, this.index, {super.key});

  final model.Message msg;
  final int index;

  void _onCopyPressed() {
    Alert.success(S.current.chat_copied_to_clipboard);
    if (msg.ttsTarget != null) {
      Clipboard.setData(ClipboardData(text: msg.ttsTarget!));
      return;
    }
    Clipboard.setData(ClipboardData(text: msg.content));
  }

  void _onTTSPlayPressed() {
    qq;
    P.msg.latestClicked.q = msg;
    P.world.play(path: msg.audioUrl!);
  }

  void _onTTSPausePressed() {
    P.world.stopPlaying();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final demoType = ref.watch(P.app.demoType);
    if (demoType != DemoType.tts) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;

    // final displayFlag = ref.watch(P.tts.displayFlag);
    // final displayNameCn = ref.watch(P.tts.displayNameCn);
    // final displayNameEn = ref.watch(P.tts.displayNameEn);
    final (String displayFlag, String displayNameCn, String displayNameEn) = P.tts.getSpkInfo(msg.ttsSpeakerName ?? "");

    final latestClickedMessage = ref.watch(P.msg.latestClicked);
    final playing = ref.watch(P.world.playing);
    final isCurrentMessage = latestClickedMessage?.id == msg.id;

    const buttonPadding = EI.o(
      t: 8,
      b: 4,
      l: 4,
      r: 4,
    );

    const buttonSize = 24.0;

    final qw = ref.watch(P.app.qw);

    return Padding(
      padding: const EI.o(
        t: 2,
        l: 6,
        r: 6,
        b: 6,
      ),
      child: Column(
        crossAxisAlignment: CAA.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: C(
                  decoration: BD(
                    color: qw.q(.5),
                    borderRadius: 8.r,
                    border: Border.all(color: primary, width: .5),
                  ),
                  margin: const EI.o(t: 4),
                  padding: const EI.o(
                    h: 4,
                    v: 4,
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (msg.ttsSpeakerName != null) ...[
                          TextSpan(
                            text: s.imitate(
                              displayFlag,
                              displayNameCn,
                              displayNameEn,
                            ),
                          ),
                        ],
                        if (msg.ttsSpeakerName == null && msg.ttsSourceAudioPath != null) ...[
                          TextSpan(
                            text: s.imitate_fle(
                              msg.ttsSourceAudioPath!.split("/").last,
                            ),
                          ),
                        ],
                        if (msg.ttsCFMSteps != null) ...[
                          TextSpan(text: " (CFM Steps: ${msg.ttsCFMSteps!})"),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Spacer(),
              if (playing && isCurrentMessage)
                GD(
                  onTap: _onTTSPausePressed,
                  child: Padding(
                    padding: buttonPadding,
                    child: Icon(Icons.pause, color: primary.q(.8), size: buttonSize),
                  ),
                ),
              if (!playing || !isCurrentMessage)
                GD(
                  onTap: _onTTSPlayPressed,
                  child: Padding(
                    padding: buttonPadding,
                    child: Icon(Icons.play_arrow, color: primary.q(.8), size: buttonSize),
                  ),
                ),
              GD(
                onTap: _onCopyPressed,
                child: Padding(
                  padding: buttonPadding,
                  child: Icon(
                    Icons.copy,
                    color: primary.q(.8),
                    size: buttonSize,
                  ),
                ),
              ),
            ],
          ),
          4.h,
          T(
            msg.ttsTarget,
            s: const TS(s: 16),
          ),
        ],
      ),
    );
  }
}
