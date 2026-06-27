// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/func/shortcuts.dart';

// Project imports:
import 'package:zone/store/p.dart';

class PerformanceInfo extends ConsumerWidget {
  final bool short;
  const PerformanceInfo({super.key, this.short = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(P.preference.userType);
    if (!userType.isGreaterThan(.user)) {
      return const SizedBox.shrink();
    }

    final prefillSpeed = ref.watch(P.rwkvGeneration.prefillSpeed);
    final decodeSpeed = ref.watch(P.rwkvGeneration.decodeSpeed);
    final qb = ref.watch(P.app.qb);
    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);
    return Column(
      crossAxisAlignment: .start,
      mainAxisAlignment: .center,
      children: [
        Text.rich(
          style: TextStyle(color: qb.q(1), fontSize: 10),
          TextSpan(
            children: [
              TextSpan(text: short ? "P " : "Prefill "),
              TextSpan(
                text: prefillSpeed.toStringAsFixed(1),
                style: TextStyle(fontFamily: monospaceFF),
              ),
              const TextSpan(text: "t/s"),
            ],
          ),
        ),
        Text.rich(
          style: TextStyle(color: qb.q(1), fontSize: 10),
          TextSpan(
            children: [
              TextSpan(text: short ? "D " : "Decode "),
              TextSpan(
                text: decodeSpeed.toStringAsFixed(1),
                style: TextStyle(fontFamily: monospaceFF),
              ),
              const TextSpan(text: "t/s"),
            ],
          ),
        ),
      ],
    );
  }
}
