// ignore: unused_import

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zone/func/merge_wav.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/state/p.dart';

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
    final demoType = P.app.demoType.q;
    if (demoType != DemoType.tts) return;

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
    final filePaths = widget.msg.ttsFilePaths ?? [];
    if (filePaths.isNotEmpty) {
      final durations = await Future.wait(filePaths.map((e) => _getWavDuration(e)));
      return durations.reduce((a, b) => a + b).toDouble();
    }

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
    final demoType = ref.watch(P.app.demoType);
    if (demoType != DemoType.tts) return const SizedBox.shrink();
    final s = S.of(context);

    _syncWavDuration().then((value) {
      if (_length == value) return;
      _length = value;
      if (mounted) setState(() {});
    });

    // final changing = true;
    final changing = widget.msg.changing;
    final primary = Theme.of(context).colorScheme.primary;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final length = _length;
    final base = 4000;
    final width = 80 * (length / (length + base)) + 55;
    final isPlaying = ref.watch(P.world.playing);
    final latestClickedMessage = ref.watch(P.msg.latestClicked);
    final isLatestClickedMessage = latestClickedMessage?.id == widget.msg.id;

    final overallProgress = widget.msg.ttsOverallProgress ?? 0.0;
    final perWavProgress = widget.msg.ttsPerWavProgress ?? [];

    final allDone = overallProgress >= 1;
    final qb = ref.watch(P.app.qb);

    return C(
      decoration: const BD(color: kC),
      padding: const EI.o(),
      width: changing ? 130 : width,
      // height: 50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CAA.stretch,
        children: [
          if (!allDone)
            Wrap(
              children: [
                ...perWavProgress.map((e) {
                  return Column(
                    children: [
                      Icon(Icons.audio_file, color: primaryColor),
                      2.h,
                      if (e < 1)
                        T(
                          (e * 100).toStringAsFixed(0) + "%",
                          s: TS(c: qb.q(.8), w: FW.w600, s: 10),
                        ),
                      if (e >= 1) Icon(Icons.check, color: primaryColor, size: 12),
                    ],
                  );
                }),
              ],
            ),
          if (changing)
            Padding(
              padding: const EI.o(v: 4),
              child: Row(
                mainAxisAlignment: MAA.start,
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
                  8.w,
                  T(
                    s.generating + " " + (overallProgress * 100).toStringAsFixed(0) + "%",
                    s: TS(c: qb.q(.8), w: FW.w500),
                  ),
                ],
              ),
            ),
          if (!changing || widget.msg.ttsHasContent)
            Padding(
              padding: const EI.o(v: 4),
              child: Row(
                mainAxisAlignment: MAA.start,
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
                  8.w,
                  T(
                    (length / 1000).toStringAsFixed(0) + "s",
                    s: TS(c: qb.q(.8), w: FW.w600),
                  ),
                  if (allDone)
                    GD(
                      onTap: _onSharePressed,
                      child: C(
                        decoration: const BD(color: kC),
                        padding: const EI.o(l: 8, r: 4),
                        child: const Icon(Icons.share),
                      ),
                    ),
                ],
              ),
            ),
          if (allDone) 12.h,
          if (!changing && !allDone)
            Row(
              mainAxisAlignment: MAA.start,
              children: [
                GD(
                  onTap: _onSharePressed,
                  child: C(
                    decoration: const BD(color: kC),
                    padding: const EI.s(
                      v: 12,
                      h: 3,
                    ),
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
    final audioUrl = await mergeWavFiles(widget.msg.ttsFilePaths!);
    final file = File(audioUrl);
    if (!await file.exists()) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(audioUrl)],
        text: widget.msg.content,
        subject: widget.msg.content,
        title: widget.msg.content,
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
