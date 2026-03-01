// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

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

    final prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final decodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final qb = ref.watch(P.app.qb);
    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);
    return Column(
      crossAxisAlignment: .start,
      mainAxisAlignment: .center,
      children: [
        Text.rich(
          style: TS(c: qb.q(1), s: 10),
          TextSpan(
            children: [
              TextSpan(text: short ? "P: " : "Prefill: "),
              TextSpan(
                text: prefillSpeed.toStringAsFixed(1),
                style: TS(ff: monospaceFF),
              ),
              const TextSpan(text: "t/s"),
            ],
          ),
        ),
        Text.rich(
          style: TS(c: qb.q(1), s: 10),
          TextSpan(
            children: [
              TextSpan(text: short ? "D: " : "Decode: "),
              TextSpan(
                text: decodeSpeed.toStringAsFixed(1),
                style: TS(ff: monospaceFF),
              ),
              const TextSpan(text: "t/s"),
            ],
          ),
        ),
      ],
    );
  }
}
