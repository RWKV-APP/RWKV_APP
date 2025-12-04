import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/page/completion/_completion_controller.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/arguments_panel.dart';
import 'package:zone/widgets/decode_param_type_button.dart';

import '_completion_state.dart';

class CompletionTitleBar extends ConsumerWidget {
  const CompletionTitleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTips = !ref.watch(CompletionState.tipsDisabled);
    final mode = ref.watch(CompletionState.decodeParamType);
    final model = ref.watch(CompletionState.model);

    final showBanner = showTips && mode != DecodeParamType.creative && model != null;

    final buttonStyle = OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    );

    final decodeParamType = ref.watch(CompletionState.decodeParamType);

    final s = S.current;

    final currentName =
        {
          DecodeParamType.defaults: s.default_,
          DecodeParamType.creative: s.creative,
          DecodeParamType.conservative: s.conservative.split('(')[0].trim(),
          DecodeParamType.fixed: s.fixed,
          DecodeParamType.comprehensive: s.comprehensive,
          DecodeParamType.unknown: s.custom,
        }[decodeParamType] ??
        s.custom;

    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: kToolbarHeight),
        Row(
          children: [
            const SizedBox(width: 24 + 20),
            Expanded(
              child: Text(
                'RWKV·续写',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, height: 1),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.add),
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
                child: Text(model?.name ?? '选择模型', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                CompletionController.current.onParallelTap();
              },
              style: buttonStyle,
              child: Text('并行 X 4'),
            ),
            const SizedBox(width: 8),
            LayoutBuilder(
              builder: (ctx, cs) {
                return OutlinedButton(
                  onPressed: () async {
                    final pos = ctx.findRenderObject() as RenderBox;
                    final offset = pos.localToGlobal(Offset.zero);
                    final position = RelativeRect.fromLTRB(offset.dx - 100, offset.dy + 24, 0, 0);
                    final v = await showDecodeParamTypeSelect(context, position, decodeParamType);
                    if (v == null) return;
                    if (v == DecodeParamType.unknown) {
                      ArgumentsPanel.show(context);
                    } else {
                      P.rwkv.syncSamplerParamsFromDefault(v);
                    }
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
        Divider(indent: 28, endIndent: 28),
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
          value: DecodeParamType.unknown,
          enabled: false,
          child: Text(s.decode_param, style: const TextStyle(fontSize: 12)),
        ),
        _buildMenuItem(s.creative, DecodeParamType.creative, decodeParamType),
        _buildMenuItem(s.comprehensive, DecodeParamType.comprehensive, decodeParamType),
        _buildMenuItem(s.default_, DecodeParamType.defaults, decodeParamType),
        _buildMenuItem(s.conservative, DecodeParamType.conservative, decodeParamType),
        _buildMenuItem(s.fixed, DecodeParamType.fixed, decodeParamType),
        _buildMenuItem(s.custom, DecodeParamType.unknown, decodeParamType),
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
