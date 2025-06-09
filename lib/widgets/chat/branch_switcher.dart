// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/model/message.dart' as model;
import 'package:zone/state/p.dart';

class BranchSwitcher extends ConsumerWidget {
  final model.Message msg;
  final int index;

  const BranchSwitcher(this.msg, this.index, {super.key});

  void _onBackPressed() {
    P.msg.onTapSwitchAtIndex(index, isBack: true, msg: msg);
  }

  void _onForwardPressed() {
    P.msg.onTapSwitchAtIndex(index, isBack: false, msg: msg);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final siblingCount = P.msg.siblingCount(msg);
    final index = P.msg.siblingIds(msg).indexOf(msg.id);

    if (siblingCount <= 1) return const SizedBox.shrink();

    bool isFirst = index == 0;
    bool isLast = index == siblingCount - 1;

    return Stack(
      children: [
        Positioned.fill(
          child: C(
            constraints: const BoxConstraints(minWidth: 16),
            child: Center(
              child: T(
                "${index + 1} / $siblingCount",
                s: TS(c: primary, s: 12, w: FW.w600),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: isFirst ? null : _onBackPressed,
              padding: const EdgeInsets.only(left: 4, right: 16, top: 4, bottom: 4),
              constraints: const BoxConstraints(), // override default min size of 48px
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isFirst ? primary.q(.5) : primary,
                size: 16,
              ),
            ),
            IconButton(
              onPressed: isLast ? null : _onForwardPressed,
              padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
              constraints: const BoxConstraints(), // override default min size of 48px
              icon: Icon(
                Icons.arrow_forward_ios,
                color: isLast ? primary.q(.5) : primary,
                size: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
