// ignore: unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/thinking_mode.dart' as thinking_mode;
import 'package:zone/store/p.dart';

class SecondaryOptionsButton extends ConsumerWidget {
  const SecondaryOptionsButton({super.key});

  void _onTap() {
    P.rwkv.onSecondaryOptionsTyped();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final loading = ref.watch(P.rwkv.loading);

    final thinkingMode = ref.watch(P.rwkv.thinkingMode);

    final color = switch (thinkingMode) {
      thinking_mode.Lighting() => kC,
      thinking_mode.Free() => theme.colorScheme.surfaceContainer,
      thinking_mode.None() => kC,
      thinking_mode.PreferChinese() => primary,
    };

    final textColor = switch (thinkingMode) {
      thinking_mode.Lighting() => Colors.grey,
      thinking_mode.None() => theme.colorScheme.onPrimary,
      thinking_mode.Free() => Colors.grey,
      thinking_mode.PreferChinese() => theme.colorScheme.onPrimary,
    };

    final iconWidget = switch (thinkingMode) {
      thinking_mode.Free() => Icon(Icons.translate, color: textColor, size: 18),
      thinking_mode.PreferChinese() => Icon(Icons.translate, color: textColor, size: 18),
      _ => null,
    };

    final textWidget = switch (thinkingMode) {
      thinking_mode.Lighting() => null,
      thinking_mode.None() => null,
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MAA.center,
        children: [
          T(s.prefer, s: TS(c: textColor, s: 10, height: 1)),
          2.h,
          T(s.chinese, s: TS(c: textColor, s: 10, height: 1)),
        ],
      ),
    };

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(14) + 20;

    final padding = switch (thinkingMode) {
      thinking_mode.Lighting() => const EI.s(h: 0),
      thinking_mode.None() => const EI.s(h: 0),
      thinking_mode.Free() => const EI.s(h: 12),
      thinking_mode.PreferChinese() => const EI.s(h: 12),
    };

    return AnimatedSize(
      key: const Key("_SecondaryOptionsButton"),
      duration: 150.ms,
      curve: Curves.easeOutCubic,
      child: IntrinsicWidth(
        child: AnimatedOpacity(
          opacity: loading ? .33 : 1,
          duration: 250.ms,
          child: GestureDetector(
            onTap: _onTap,
            child: AnimatedContainer(
              height: height,
              duration: 150.ms,
              curve: Curves.easeOutCubic,
              padding: padding,
              decoration: BoxDecoration(
                color: color,
                borderRadius: 60.r,
              ),
              child: Row(
                children: [
                  ?iconWidget,
                  if (textWidget != null) 4.w,
                  ?textWidget,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
