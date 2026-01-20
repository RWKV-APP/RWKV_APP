// ignore: unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/services/font_service.dart';
import 'package:zone/store/p.dart';

class PerformanceInfo extends ConsumerWidget {
  const PerformanceInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(P.preference.userType);
    if (!userType.isGreaterThan(.user)) {
      return const SizedBox.shrink();
    }

    final prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final decodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final qb = ref.watch(P.app.qb);
    final preferredMonospaceFont = ref.watch(P.preference.preferredMonospaceFont);
    final effectiveMonospaceFont = FontService.getEffectiveMonospaceFont(preferredMonospaceFont);
    return Column(
      crossAxisAlignment: .start,
      mainAxisAlignment: .center,
      children: [
        Text.rich(
          style: TS(c: qb.q(.6), s: 10),
          TextSpan(
            children: [
              const TextSpan(text: "Prefill: "),
              TextSpan(
                text: prefillSpeed.toStringAsFixed(1),
                style: TS(ff: effectiveMonospaceFont),
              ),
              const TextSpan(text: "t/s"),
            ],
          ),
        ),
        Text.rich(
          style: TS(c: qb.q(.6), s: 10),
          TextSpan(
            children: [
              const TextSpan(text: "Decode: "),
              TextSpan(
                text: decodeSpeed.toStringAsFixed(1),
                style: TS(ff: effectiveMonospaceFont),
              ),
              const TextSpan(text: "t/s"),
            ],
          ),
        ),
      ],
    );
  }
}
