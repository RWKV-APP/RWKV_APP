import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/message.dart' as model;
import 'package:path/path.dart' as path;
import 'package:zone/store/p.dart';

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
    final audioUrl = msg.audioUrl;
    if (audioUrl == null) {
      Alert.warning(S.current.no_audio_file);
      return;
    }
    P.see.play(path: msg.audioUrl!);
  }

  void _onTTSPausePressed() {
    P.see.stopPlaying();
  }

  void _onSharePressed() async {
    qq;
    P.msg.latestClicked.q = msg;
    final audioUrl = msg.audioUrl;
    if (audioUrl == null) {
      Alert.warning(S.current.no_audio_file);
      return;
    }
    final file = File(audioUrl);
    if (!await file.exists()) return;
    // final userMessage = ref.watch(P.msg.userMessage);
    String text = path.basename(file.path);
    if (text.isEmpty) text = "RWKV TTS";
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(audioUrl)],
        text: text,
        subject: text,
        title: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    final (String displayFlag, String displayNameCn, String displayNameEn) = P.talk.getSpkInfo(msg.ttsSpeakerName ?? "");

    final latestClickedMessage = ref.watch(P.msg.latestClicked);
    final playing = ref.watch(P.see.playing);
    final isCurrentMessage = latestClickedMessage?.id == msg.id;

    const EdgeInsets buttonPadding = .only(left: 4, top: 8, right: 4, bottom: 4);

    const buttonSize = 24.0;

    final qw = ref.watch(P.app.qw);

    return Padding(
      padding: const .only(left: 8, top: 0, right: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            mainAxisSize: .min,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: qw.q(.5),
                    borderRadius: .circular(8),
                    border: .all(color: primary, width: .5),
                  ),
                  margin: const .only(top: 4),
                  padding: const .only(left: 4, top: 4, right: 4, bottom: 4),
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
                              path.basename(msg.ttsSourceAudioPath!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Spacer(),
              if (playing && isCurrentMessage)
                GestureDetector(
                  onTap: _onTTSPausePressed,
                  child: Padding(
                    padding: buttonPadding,
                    child: Icon(Icons.pause, color: primary.q(.8), size: buttonSize),
                  ),
                ),
              if (!playing || !isCurrentMessage)
                GestureDetector(
                  onTap: _onTTSPlayPressed,
                  child: Padding(
                    padding: buttonPadding,
                    child: Icon(Icons.play_arrow, color: primary.q(.8), size: buttonSize),
                  ),
                ),
              GestureDetector(
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
              GestureDetector(
                onTap: _onSharePressed,
                child: Padding(
                  padding: buttonPadding,
                  child: Icon(
                    Icons.share,
                    color: primary.q(.8),
                    size: buttonSize,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            msg.ttsTarget ?? "null",
            style: const TS(s: 16),
          ),
        ],
      ),
    );
  }
}
