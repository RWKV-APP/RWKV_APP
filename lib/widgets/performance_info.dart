// ignore: unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/state/p.dart';

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
        T("Prefill: ${prefillSpeed.toStringAsFixed(1)} t/s", s: TS(c: qb.q(.6), s: 10)),
        T("Decode: ${decodeSpeed.toStringAsFixed(1)} t/s", s: TS(c: qb.q(.6), s: 10)),
      ],
    );
  }
}
