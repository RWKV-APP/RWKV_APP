// ignore: unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/store/p.dart';

class PerformanceInfo extends ConsumerWidget {
  const PerformanceInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final decodeSpeed = ref.watch(P.rwkv.decodeSpeed);
    final qb = ref.watch(P.app.qb);
    return Column(
      crossAxisAlignment: CAA.start,
      mainAxisAlignment: MAA.center,
      children: [
        Text.rich(
          style: TS(c: qb.q(.6), s: 10),
          TextSpan(
            children: [
              TextSpan(text: "Prefill: "),
              TextSpan(
                text: prefillSpeed.toStringAsFixed(1),
                style: TS(ff: "monospace"),
              ),
              TextSpan(text: "t/s"),
            ],
          ),
        ),
        Text.rich(
          style: TS(c: qb.q(.6), s: 10),
          TextSpan(
            children: [
              TextSpan(text: "Decode: "),
              TextSpan(
                text: decodeSpeed.toStringAsFixed(1),
                style: TS(ff: "monospace"),
              ),
              TextSpan(text: "t/s"),
            ],
          ),
        ),
      ],
    );
  }
}
