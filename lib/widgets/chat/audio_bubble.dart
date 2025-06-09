// ignore: unused_import

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/state/p.dart';

class AudioBubble extends ConsumerStatefulWidget {
  final model.Message msg;

  const AudioBubble(this.msg, {super.key});

  @override
  ConsumerState<AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends ConsumerState<AudioBubble> {
  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final length = widget.msg.audioLength ?? 2000;
    final base = 4000;
    final width = 200 * (length / (length + base));
    final isPlaying = ref.watch(P.world.playing);
    final latestClickedMessage = ref.watch(P.msg.latestClicked);
    final isLatestClickedMessage = latestClickedMessage?.id == widget.msg.id;
    final qb = ref.watch(P.app.qb);
    return C(
      decoration: const BD(color: kC),
      width: width,
      child: Row(
        mainAxisAlignment: MAA.end,
        children: [
          T(
            (length / 1000).toStringAsFixed(0) + "s",
            s: TS(c: qb.q(.8), w: FW.w600),
          ),
          8.w,
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
        ],
      ),
    );
  }
}
