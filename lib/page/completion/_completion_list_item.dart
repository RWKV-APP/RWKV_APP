// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/gen/assets.gen.dart';
import 'package:zone/page/completion/_completion_controller.dart';
import 'package:zone/page/completion/_completion_state.dart';
import 'package:zone/store/p.dart';

class CompletionItemDecoration extends StatelessWidget {
  final Widget child;
  final bool isUser;
  final bool gray;

  const CompletionItemDecoration({
    super.key,
    required this.isUser,
    required this.child,
    this.gray = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isUser ? null : theme.colorScheme.primary.q(0.1);
    final borderColor = isUser ? theme.dividerColor : theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: gray ? Colors.grey.q(0.1) : backgroundColor,
        border: Border(
          left: BorderSide(
            color: gray ? Colors.grey : borderColor,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 12),
      child: child,
    );
  }
}

class CompletionListItem extends StatelessWidget {
  final CompletionItemNode item;
  final Widget? footer;
  final bool isLast;
  final TextStyle textStyle;

  const CompletionListItem({
    super.key,
    required this.item,
    this.footer,
    required this.isLast,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final content = _ItemContent(
      item: item,
      textStyle: textStyle,
    );

    if (footer == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: content,
      );
    }

    final wrappedContent = item.isUser ? content : _AutoScrollContent(child: content);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        wrappedContent,
        footer!,
        if (isLast || item.siblingCount == 1) const SizedBox(height: 20),
      ],
    );
  }
}

class _ItemContent extends StatelessWidget {
  final CompletionItemNode item;
  final TextStyle textStyle;

  const _ItemContent({
    required this.item,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return CompletionItemDecoration(
      isUser: item.isUser,
      child: item.content.isEmpty
          ? const _LoadingIndicator()
          : SelectableText(
              item.content,
              style: textStyle,
            ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 14,
        width: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _AutoScrollContent extends StatelessWidget {
  final Widget child;

  const _AutoScrollContent({required this.child});

  @override
  Widget build(BuildContext context) {
    return MeasureSize(
      onChange: (rect) {
        if (rect.isEmpty || !CompletionState.autoScrolling) {
          return;
        }

        if (!CompletionState.generating.q) {
          return;
        }

        final expectedBottom = MediaQuery.sizeOf(context).height - 100;
        final overflow = rect.bottom - expectedBottom;

        if (overflow <= 0) {
          return;
        }

        final scrollable = Scrollable.of(context);
        scrollable.position.animateTo(
          scrollable.position.pixels + overflow,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      },
      child: child,
    );
  }
}

class CompletionSpeed extends ConsumerWidget {
  final CompletionItemNode? item;

  const CompletionSpeed({super.key, this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefillSpeed = item?.prefillSpeed ?? ref.watch(P.rwkv.prefillSpeed) ?? 0;
    final decodeSpeed = item?.decodeSpeed ?? ref.watch(P.rwkv.decodeSpeed) ?? 0;
    final monospaceFF = ref.watch(P.font.finalMonospaceFontFamily);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        "Prefill：${prefillSpeed.toStringAsFixed(1)}t/s Decode:${decodeSpeed.toStringAsFixed(1)}t/s",
        style: TextStyle(fontSize: 8, fontFamily: monospaceFF),
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class CompletionRegenerationButton extends ConsumerWidget {
  final CompletionItemNode item;

  const CompletionRegenerationButton({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final generating = ref.watch(CompletionState.generating);

    if (generating) {
      return const SizedBox();
    }

    return Transform.translate(
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
            theme.iconTheme.color!,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class CompletionListItemFooter extends ConsumerWidget {
  final CompletionItemNode item;
  final bool isLast;

  const CompletionListItemFooter({
    super.key,
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasChoices = item.siblingCount > 1;

    return Row(
      crossAxisAlignment: .center,
      children: [
        if (isLast) CompletionRegenerationButton(item: item),
        if (!hasChoices && isLast) const Expanded(child: CompletionSpeed()),
        if (hasChoices)
          Expanded(
            child: _SiblingChoices(
              item: item,
              isLast: isLast,
              theme: theme,
            ),
          ),
      ],
    );
  }
}

class _SiblingChoices extends StatelessWidget {
  final CompletionItemNode item;
  final bool isLast;
  final ThemeData theme;

  const _SiblingChoices({
    required this.item,
    required this.isLast,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .end,
      crossAxisAlignment: .center,
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
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: item.index == item.siblingCount - 1 ? null : () => CompletionController.current.onNextChooseTap(item),
          icon: const Icon(Icons.arrow_circle_right_outlined, size: 18),
          color: theme.colorScheme.primary,
        ),
        if (isLast) const SizedBox(width: 8),
        if (isLast) const Flexible(child: CompletionSpeed()),
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

    final newSize = child!.size;
    if (oldSize == newSize) {
      return;
    }

    oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offset = localToGlobal(Offset.zero);
      onChange(offset & newSize);
    });
  }
}
