import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/assets.gen.dart';
import 'package:zone/page/completion/_completion_state.dart';
import 'package:zone/store/p.dart';

import '_completion_controller.dart';

class CompletionListItem extends StatelessWidget {
  final CompletionItemNode item;
  final Widget? footer;
  final bool isLast;

  const CompletionListItem({super.key, required this.item, this.footer, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget content = Container(
      width: double.infinity,
      margin: footer != null ? null : const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: item.isUser ? null : theme.colorScheme.primary.withAlpha(0x1A),
        border: Border(
          left: BorderSide(
            color: item.isUser ? theme.dividerColor : theme.colorScheme.primary,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 16),
      child: item.content.isEmpty
          ? const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : SelectableText(
              item.content, //
              style: const TextStyle(fontSize: 14, height: 2, letterSpacing: 1),
            ),
    );
    if (footer == null) return content;
    if (!item.isUser) {
      content = MeasureSize(
        onChange: (s) {
          if (s.isEmpty || !CompletionState.autoScrolling) return;
          final excepted = MediaQuery.of(context).size.height - 100;
          final offset = s.bottom - excepted;
          if (offset > 0) {
            if (!CompletionState.generating.q) {
              return;
            }
            final sc = Scrollable.of(context);
            sc.position.animateTo(
              sc.position.pixels + offset, //
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          }
        },
        child: content,
      );
    }
    return Column(
      children: [
        content,
        footer!,
        if (isLast || item.siblingCount == 1) const SizedBox(height: 20),
      ],
    );
  }
}

class CompletionListItemFooter extends ConsumerWidget {
  final CompletionItemNode item;
  final bool isLast;

  const CompletionListItemFooter({super.key, required this.item, required this.isLast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasChooses = item.siblingCount > 1;
    final generating = ref.watch(CompletionState.generating);

    final prefillSpeed = ref.watch(P.rwkv.prefillSpeed);
    final decodeSpeed = ref.watch(P.rwkv.decodeSpeed);

    final speed = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        "Prefill：${prefillSpeed.toStringAsFixed(1)}t/s Decode:${decodeSpeed.toStringAsFixed(1)}t/s",
        style: const TextStyle(fontSize: 8, fontFamily: 'monospace'),
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!generating && isLast)
          Transform.translate(
            offset: const Offset(-8, 0),
            child: IconButton(
              onPressed: () {
                CompletionController.current.onRegenerateTap(item);
              },
              icon: SvgPicture.asset(
                Assets.img.chat.regenerate,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).iconTheme.color!,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        if (!hasChooses && isLast) Expanded(child: speed),
        if (hasChooses)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: item.index == 0 ? null : () => CompletionController.current.onPrevChooseTap(item),
                  color: theme.colorScheme.primary,
                  icon: const Icon(
                    Icons.arrow_circle_left_outlined,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.index + 1}/${item.siblingCount}',
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: item.index == item.siblingCount - 1 ? null : () => CompletionController.current.onNextChooseTap(item),
                  icon: const Icon(Icons.arrow_circle_right_outlined, size: 18),
                  color: theme.colorScheme.primary,
                ),
                if (isLast) const SizedBox(width: 8),
                if (isLast) Flexible(child: speed),
              ],
            ),
          ),
      ],
    );
  }
}

class MeasureSize extends SingleChildRenderObjectWidget {
  final void Function(Rect size) onChange;

  const MeasureSize({
    super.key,
    required this.onChange,
    required Widget super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  Size? oldSize;

  void Function(Rect size) onChange;

  _MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();

    Size newSize = child!.size;
    if (oldSize == newSize) return;

    oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offset = localToGlobal(Offset.zero);
      onChange(offset & newSize);
    });
  }
}
