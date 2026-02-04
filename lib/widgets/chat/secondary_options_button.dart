// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/thinking_mode.dart' as thinking_mode;
import 'package:zone/store/p.dart';

class SecondaryOptionsButton extends ConsumerWidget {
  const SecondaryOptionsButton({super.key});

  void _onTap() {
    P.rwkv.onSecondaryOptionsTapped();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final loading = ref.watch(P.rwkv.loading);

    final thinkingMode = ref.watch(P.rwkv.thinkingMode);

    final color = switch (thinkingMode) {
      thinking_mode.Lighting() => Colors.transparent,
      thinking_mode.Fast() => Colors.transparent,
      thinking_mode.Free() => theme.colorScheme.surfaceContainer,
      thinking_mode.None() => Colors.transparent,
      thinking_mode.PreferChinese() => primary,
      thinking_mode.En() => primary,
      thinking_mode.EnShort() => primary,
      thinking_mode.EnLong() => primary,
    };

    final textColor = switch (thinkingMode) {
      thinking_mode.Lighting() => Colors.grey,
      thinking_mode.Fast() => Colors.grey,
      thinking_mode.None() => theme.colorScheme.onPrimary,
      thinking_mode.Free() => Colors.grey,
      thinking_mode.PreferChinese() => theme.colorScheme.onPrimary,
      thinking_mode.En() => theme.colorScheme.onPrimary,
      thinking_mode.EnShort() => theme.colorScheme.onPrimary,
      thinking_mode.EnLong() => theme.colorScheme.onPrimary,
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
        crossAxisAlignment: .start,
        mainAxisAlignment: .center,
        children: [
          Text(s.prefer, style: TS(c: textColor, s: 10, height: 1)),
          const SizedBox(height: 2),
          Text(s.chinese, style: TS(c: textColor, s: 10, height: 1)),
        ],
      ),
    };

    final textScaleFactor = MediaQuery.textScalerOf(context);
    final height = textScaleFactor.scale(14) + 20;

    final EdgeInsets padding = switch (thinkingMode) {
      thinking_mode.Lighting() => const .all(0),
      thinking_mode.Fast() => const .all(0),
      thinking_mode.None() => const .all(0),
      thinking_mode.Free() => const .symmetric(horizontal: 12),
      thinking_mode.PreferChinese() => const .symmetric(horizontal: 12),
      thinking_mode.En() => const .symmetric(horizontal: 12),
      thinking_mode.EnShort() => const .symmetric(horizontal: 12),
      thinking_mode.EnLong() => const .symmetric(horizontal: 12),
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
                borderRadius: .circular(60),
              ),
              child: Row(
                children: [
                  ?iconWidget,
                  if (textWidget != null) const SizedBox(width: 4),
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
