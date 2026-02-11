// ignore: unused_import

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:path/path.dart' as path;
import 'package:zone/store/p.dart';

class BotTtsContent extends ConsumerStatefulWidget {
  final model.Message msg;
  final int index;

  const BotTtsContent(this.msg, this.index, {super.key});

  @override
  ConsumerState<BotTtsContent> createState() => _BotTtsContentState();
}

class _BotTtsContentState extends ConsumerState<BotTtsContent> {
  Timer? _timer;
  int _tick = 0;
  double _length = 4000;

  @override
  void initState() {
    super.initState();

    if (widget.msg.isMine) return;
    const DemoType demoType = .tts;
    if (demoType != .tts) return;

    ref.listenManual(P.msg.latestClicked, (previous, next) {
      if (next?.id == widget.msg.id) {
        _timer?.cancel();
        _timer = Timer.periodic(500.ms, (timer) {
          _tick++;
          setState(() {});
        });
      } else {
        _timer?.cancel();
      }
    });

    _syncWavDuration().then((value) {
      if (_length == value) return;
      _length = value;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _timer = null;
  }

  Future<double> _syncWavDuration() async {
    final audioUrl = widget.msg.audioUrl;
    if (audioUrl != null) {
      final value = await _getWavDuration(audioUrl);
      return value.toDouble();
    }

    return 4000;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.msg.isMine) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final s = S.of(context);

    _syncWavDuration().then((value) {
      if (_length == value) return;
      _length = value;
      if (mounted) setState(() {});
    });

    final generating = ref.watch(P.talk.generating);

    final changing = widget.msg.changing;
    // final changing = true;

    final primaryColor = theme.colorScheme.primary;
    final length = _length;
    final base = 4000;
    final width = 80 * (length / (length + base)) + 55;
    final isPlaying = ref.watch(P.see.playing);
    final latestClickedMessage = ref.watch(P.msg.latestClicked);
    final isLatestClickedMessage = latestClickedMessage?.id == widget.msg.id;

    final allDone = !changing;
    final qb = ref.watch(P.app.qb);

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      padding: const .all(0),
      width: changing ? 160 : width,
      // height: 50,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          if (changing && generating)
            Padding(
              padding: const .only(top: 4, bottom: 12),
              child: Row(
                mainAxisAlignment: .start,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween(begin: .0, end: 1.0),
                    duration: const Duration(milliseconds: 1000000000),
                    builder: (context, value, child) => Transform.rotate(
                      angle: value * 2 * math.pi * 1000000,
                      child: child,
                    ),
                    child: Icon(
                      Icons.hourglass_top,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.generating + "",
                    style: TS(c: qb.q(.8), w: .w500),
                  ),
                ],
              ),
            ),
          if (!changing)
            Padding(
              padding: const .only(top: 4, bottom: 4),
              child: Row(
                mainAxisAlignment: .start,
                children: [
                  if (_tick % 3 == 0 || !isPlaying || !isLatestClickedMessage)
                    Icon(
                      Icons.volume_up,
                      color: primaryColor,
                    ),
                  if (_tick % 3 == 2 && isPlaying && isLatestClickedMessage)
                    Icon(
                      Icons.volume_down,
                      color: primaryColor,
                    ),
                  if (_tick % 3 == 1 && isPlaying && isLatestClickedMessage)
                    Icon(
                      Icons.volume_mute,
                      color: primaryColor,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    (length / 1000).toStringAsFixed(0) + "s",
                    style: TS(c: qb.q(.8), w: .w600),
                  ),
                  if (allDone)
                    GestureDetector(
                      onTap: _onSharePressed,
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.transparent),
                        padding: const .only(left: 8, right: 4),
                        child: const Icon(Icons.share),
                      ),
                    ),
                ],
              ),
            ),
          if (allDone) const SizedBox(height: 12),
          if (!changing && !allDone)
            Row(
              mainAxisAlignment: .start,
              children: [
                GestureDetector(
                  onTap: _onSharePressed,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.transparent),
                    padding: const .symmetric(horizontal: 3, vertical: 12),
                    child: const Icon(Icons.share),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _onSharePressed() async {
    final audioUrl = widget.msg.audioUrl;
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
}

Future<int> _getWavDuration(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) return 0;

  final bytes = await file.readAsBytes();
  if (bytes.length < 44) return 0; // WAV header is 44 bytes

  // Get sample rate from WAV header (bytes 24-27)
  final sampleRate = bytes[24] + (bytes[25] << 8) + (bytes[26] << 16) + (bytes[27] << 24);

  // Get data size from WAV header (bytes 40-43)
  final dataSize = bytes[40] + (bytes[41] << 8) + (bytes[42] << 16) + (bytes[43] << 24);

  // Calculate duration in milliseconds
  final durationMs = ((dataSize / (sampleRate * 2)) * 1000).round();
  return durationMs;
}
