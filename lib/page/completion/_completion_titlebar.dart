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
                child: Text('RWKV g1a 12b v1', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                CompletionController.current.onDecodeParamTap();
              },
              style: buttonStyle,
              child: Text('并行 X 4'),
            ),
            const SizedBox(width: 8),
            DecodeParamTypeButton(
              borderRadius: const BorderRadius.all(Radius.circular(100)),
              decodeParamType: decodeParamType,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withAlpha(0x2B),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: theme.primaryColor),
                ),
                child: Text(
                  '创意',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: theme.primaryColor),
                ),
              ),
              onSelected: (v) {
                if (v == DecodeParamType.unknown) {
                  ArgumentsPanel.show(context);
                } else {
                  P.rwkv.syncSamplerParamsFromDefault(v);
                }
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
}
