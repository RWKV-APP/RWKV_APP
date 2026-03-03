// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/model/message.dart' as model;
import 'package:zone/store/p.dart';

class BranchSwitcher extends ConsumerWidget {
  final model.Message msg;
  final int index;
  final int? debugSiblingCountOverride;
  final int? debugSiblingIndexOverride;
  final VoidCallback? debugOnBackPressedOverride;
  final VoidCallback? debugOnForwardPressedOverride;

  const BranchSwitcher(
    this.msg,
    this.index, {
    super.key,
    this.debugSiblingCountOverride,
    this.debugSiblingIndexOverride,
    this.debugOnBackPressedOverride,
    this.debugOnForwardPressedOverride,
  });

  void _onBackPressed() {
    P.msg.onTapSwitchAtIndex(index, isBack: true, msg: msg);
  }

  void _onForwardPressed() {
    P.msg.onTapSwitchAtIndex(index, isBack: false, msg: msg);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final int siblingCount = debugSiblingCountOverride ?? P.msg.siblingCount(msg);
    final S s = S.of(context);

    if (siblingCount <= 1) return const SizedBox.shrink();

    int siblingIndex = debugSiblingIndexOverride ?? P.msg.siblingIds(msg).indexOf(msg.id);
    if (siblingIndex < 0) siblingIndex = 0;
    if (siblingIndex >= siblingCount) siblingIndex = siblingCount - 1;

    final bool isFirst = siblingIndex == 0;
    final bool isLast = siblingIndex == siblingCount - 1;
    final VoidCallback onBackPressed = debugOnBackPressedOverride ?? _onBackPressed;
    final VoidCallback onForwardPressed = debugOnForwardPressedOverride ?? _onForwardPressed;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            constraints: const BoxConstraints(minWidth: 16),
            child: Center(
              child: Text(
                "${siblingIndex + 1} / $siblingCount",
                style: TS(c: primary, s: 12, w: .w600),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: .min,
          children: [
            IconButton(
              tooltip: isFirst ? s.branch_switcher_tooltip_first : s.branch_switcher_tooltip_prev,
              onPressed: isFirst ? null : onBackPressed,
              padding: const .only(left: 4, right: 16, top: 4, bottom: 4),
              constraints: const BoxConstraints(),
              style: ButtonStyle(
                visualDensity: VisualDensity(horizontal: -3, vertical: -2),
              ),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isFirst ? primary.q(.5) : primary,
                size: 16,
              ),
            ),
            IconButton(
              tooltip: isLast ? s.branch_switcher_tooltip_last : s.branch_switcher_tooltip_next,
              onPressed: isLast ? null : onForwardPressed,
              padding: const .only(left: 16, right: 4, top: 4, bottom: 4),
              constraints: const BoxConstraints(),
              style: ButtonStyle(
                visualDensity: VisualDensity(horizontal: -3, vertical: -2),
              ),
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
