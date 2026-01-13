import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zone/gen/assets.gen.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/page/completion/_completion_controller.dart';

import '_completion_state.dart';

class CompletionTitleBar extends ConsumerWidget {
  const CompletionTitleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(CompletionState.model);
    final batchSettings = ref.watch(CompletionState.batchSettings);

    final decodeParamType = ref.watch(CompletionState.decodeParamType);

    final s = S.current;

    final currentName =
        {
          DecodeParamType.defaults: s.decode_param_default_,
          DecodeParamType.creative: s.decode_param_creative,
          DecodeParamType.conservative: s.decode_param_conservative.split('(')[0].trim(),
          DecodeParamType.fixed: s.decode_param_fixed,
          DecodeParamType.comprehensive: s.decode_param_comprehensive,
          DecodeParamType.custom: s.decode_param_custom,
        }[decodeParamType] ??
        s.decode_param_custom;

    final buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: kToolbarHeight),
        Row(
          children: [
            const SizedBox(width: 24),
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              iconSize: 20,
            ),
            Expanded(
              child: Text(
                'RWKV·${s.continue2}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400, height: 1),
              ),
            ),
            IconButton(
              onPressed: () {
                CompletionController.current.onClearAllTap();
              },
              icon: SvgPicture.asset(
                Assets.img.chat.newChat,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).iconTheme.color!,
                  BlendMode.srcIn,
                ),
              ),
              iconSize: 20,
            ),
            const SizedBox(width: 24),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            Flexible(
              child: OutlinedButton(
                onPressed: () {
                  CompletionController.current.onModelSelectTap();
                },
                style: buttonStyle,
                child: Text(model?.name ?? s.select_model, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                CompletionController.current.onParallelTap(context);
              },
              style: buttonStyle,
              child: Text(
                batchSettings.enabled
                    ? s.batch_inference_button(batchSettings.batchSize) //
                    : s.batch_inference_short,
              ),
            ),
            const SizedBox(width: 8),
            LayoutBuilder(
              builder: (ctx, cs) {
                return OutlinedButton(
                  onPressed: () async {
                    final pos = ctx.findRenderObject() as RenderBox;
                    final offset = pos.localToGlobal(Offset.zero);
                    final position = RelativeRect.fromLTRB(
                      offset.dx - 100,
                      offset.dy + 24,
                      offset.dx + cs.maxWidth,
                      offset.dy + cs.maxHeight,
                    );
                    final v = await showDecodeParamTypeSelect(context, position, decodeParamType);
                    if (v == null || !ctx.mounted) return;
                    CompletionController.current.onDecodeParamChanged(ctx, v);
                  },
                  style: buttonStyle,
                  child: Text(currentName),
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(indent: 28, endIndent: 28),
      ],
    );
  }

  Future<DecodeParamType?> showDecodeParamTypeSelect(
    BuildContext context, //
    RelativeRect positioned,
    DecodeParamType decodeParamType,
  ) async {
    final s = S.current;
    final v = await showMenu(
      context: context,
      position: positioned,
      items: [
        PopupMenuItem<DecodeParamType?>(
          height: 32,
          value: DecodeParamType.custom,
          enabled: false,
          child: Text(s.decode_param, style: const TextStyle(fontSize: 12)),
        ),
        _buildMenuItem(s.creative_recommended, DecodeParamType.creative, decodeParamType),
        _buildMenuItem(s.decode_param_comprehensive, DecodeParamType.comprehensive, decodeParamType),
        _buildMenuItem(s.decode_param_default_, DecodeParamType.defaults, decodeParamType),
        _buildMenuItem(s.decode_param_conservative, DecodeParamType.conservative, decodeParamType),
        _buildMenuItem(s.decode_param_fixed, DecodeParamType.fixed, decodeParamType),
        _buildMenuItem(s.decode_param_custom, DecodeParamType.custom, decodeParamType),
      ],
    );
    return v;
  }

  PopupMenuItem<DecodeParamType> _buildMenuItem(
    String text, //
    DecodeParamType value,
    DecodeParamType current,
  ) {
    final checked = value == current;
    return PopupMenuItem(
      value: value,
      height: 32,
      child: Row(
        children: [
          if (checked) const Icon(Icons.check, size: 16),
          if (!checked) const SizedBox(width: 16),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(text, style: const TextStyle(height: 1), overflow: .ellipsis),
          ),
        ],
      ),
    );
  }
}
