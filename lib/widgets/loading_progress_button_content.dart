// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

class LoadingProgressButtonContent extends ConsumerWidget {
  final double? progress;
  final TextStyle textStyle;
  final Color indicatorColor;

  const LoadingProgressButtonContent({
    super.key,
    required this.progress,
    required this.textStyle,
    required this.indicatorColor,
  });

  static double normalizeProgress(double? progress) {
    if (progress == null) {
      return 0.0;
    }

    if (progress.isNaN || progress.isInfinite) {
      return 0.0;
    }

    final double safe = progress.clamp(0.0, 1.0).toDouble();
    return safe;
  }

  static int progressToPercent(double? progress) {
    final double safeProgress = normalizeProgress(progress);
    final int progressPercent = (safeProgress * 100).round();
    return progressPercent.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final double safeProgress = normalizeProgress(progress);
    final int progressPercent = progressToPercent(progress);

    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);

    return Row(
      mainAxisSize: .min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            value: safeProgress,
            strokeWidth: 2,
            color: indicatorColor,
            backgroundColor: indicatorColor.q(.2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          s.loading_progress_percent(progressPercent),
          style: textStyle.copyWith(fontFamily: monospaceFF),
        ),
      ],
    );
  }
}
