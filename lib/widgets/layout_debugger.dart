import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/state/p.dart';

class LayoutDebugger extends ConsumerWidget {
  const LayoutDebugger({
    super.key,
    required this.child,
    this.debugWidget,
    this.name = "",
  });

  final Widget child;
  final Widget? debugWidget;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return child;
    // final showFrame = ref.watch(P.debugger.showFrame);
    // final showFrame = false;
    final frameWidth = HF.randomInt(min: 2, max: 2) / 2.0;

    final colors = [
      const Color(0xFFAA0000),
      const Color(0xFF00AA00),
      const Color(0xFF0000AA),
      const Color(0xFFAA00AA),
      const Color(0xFF000000),
    ];

    final frameColor = colors[HF.randomInt(min: 0, max: colors.length - 1)].q(.33);

    // 注意这里不能写这句话, 否则会影响手势事件
    // if (!showFrame) return child;

    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);

    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: C(
              decoration: BD(
                border: Border.all(color: frameColor, width: frameWidth),
              ),
            ),
          ),
        ),
        if (debugWidget != null)
          Positioned(
            bottom: 0,
            child: Material(
              color: qb.q(.5),
              textStyle: TS(c: qw, s: 8),
              child: C(
                child: debugWidget!,
              ),
            ),
          ),
      ],
    );
  }
}
