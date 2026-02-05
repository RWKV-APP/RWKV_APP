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
      .lighting => Colors.transparent,
      .fast => Colors.transparent,
      .free => theme.colorScheme.surfaceContainer,
      .none => Colors.transparent,
      .preferChinese => primary,
      .en => primary,
      .enShort => primary,
      .enLong => primary,
    };

    final textColor = switch (thinkingMode) {
      .lighting => Colors.grey,
      .fast => Colors.grey,
      .none => theme.colorScheme.onPrimary,
      .free => Colors.grey,
      .preferChinese => theme.colorScheme.onPrimary,
      .en => theme.colorScheme.onPrimary,
      .enShort => theme.colorScheme.onPrimary,
      .enLong => theme.colorScheme.onPrimary,
    };

    final iconWidget = switch (thinkingMode) {
      .free => Icon(Icons.translate, color: textColor, size: 18),
      .preferChinese => Icon(Icons.translate, color: textColor, size: 18),
      _ => null,
    };

    final textWidget = switch (thinkingMode) {
      .lighting => null,
      .none => null,
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
      .lighting => const .all(0),
      .fast => const .all(0),
      .none => const .all(0),
      .free => const .symmetric(horizontal: 12),
      .preferChinese => const .symmetric(horizontal: 12),
      .en => const .symmetric(horizontal: 12),
      .enShort => const .symmetric(horizontal: 12),
      .enLong => const .symmetric(horizontal: 12),
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
