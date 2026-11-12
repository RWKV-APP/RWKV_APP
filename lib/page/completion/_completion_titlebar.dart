// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import 'package:zone/gen/assets.gen.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/page/completion/_completion_controller.dart';
import 'package:zone/page/completion/_completion_state.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/alert.dart';

class CompletionTitleBar extends ConsumerWidget {
  const CompletionTitleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final classic = ref.watch(P.preference.appStyle).isClassic;
    final model = ref.watch(CompletionState.model);
    final batchSettings = ref.watch(CompletionState.batchSettings);
    final s = S.current;
    final buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      minimumSize: classic ? null : const Size(0, 34),
      textStyle: TextStyle(fontSize: classic ? 10 : 12, fontWeight: FontWeight.w500),
    );

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .center,
      children: [
        SizedBox(height: classic ? kToolbarHeight : 8),
        _TopBar(title: classic ? 'RWKV·${s.completion}' : s.completion, classic: classic),
        _ControlBar(
          modelName: model?.name ?? s.select_model,
          batchText: batchSettings.enabled ? s.batch_inference_button(batchSettings.batchSize) : s.batch_inference_short,
          buttonStyle: buttonStyle,
        ),
        SizedBox(height: classic ? 24 : 10),
        Container(
          height: 0.5,
          margin: const EdgeInsets.only(left: 28, right: 28),
          color: theme.dividerColor,
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final bool classic;

  const _TopBar({required this.title, required this.classic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(width: classic ? 24 : 12),
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
          iconSize: 20,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: classic ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w400, height: 1) : theme.textTheme.titleLarge,
          ),
        ),
        IconButton(
          onPressed: CompletionController.current.onClearAllTap,
          icon: SvgPicture.asset(
            Assets.img.chat.newChat,
            colorFilter: ColorFilter.mode(
              theme.iconTheme.color!,
              BlendMode.srcIn,
            ),
          ),
          iconSize: 20,
        ),
        SizedBox(width: classic ? 24 : 12),
      ],
    );
  }
}

class _ControlBar extends StatelessWidget {
  final String modelName;
  final String batchText;
  final ButtonStyle buttonStyle;

  const _ControlBar({
    required this.modelName,
    required this.batchText,
    required this.buttonStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .center,
      children: [
        const SizedBox(width: 16),
        Flexible(
          child: OutlinedButton(
            onPressed: CompletionController.current.onModelSelectTap,
            style: buttonStyle,
            child: Text(
              modelName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {
            CompletionController.current.onParallelTap(context);
          },
          style: buttonStyle,
          child: Text(batchText),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class CompletionDecodeParamButton extends ConsumerWidget {
  final bool filled;
  final ButtonStyle? buttonStyle;

  const CompletionDecodeParamButton({
    super.key,
    this.filled = false,
    this.buttonStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final decodeParamType = ref.watch(CompletionState.decodeParamType);
    final generating = ref.watch(CompletionState.generating);
    final label = decodeParamType.displayNameShort;
    final foregroundColor = buttonStyle?.foregroundColor?.resolve({}) ?? (filled ? theme.colorScheme.onPrimary : theme.colorScheme.primary);
    final icon = Icon(
      Symbols.auto_awesome,
      size: 16,
      color: foregroundColor,
    );
    final child = Row(
      mainAxisSize: .min,
      children: [
        icon,
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    Future<void> onPressed() async {
      if (generating) {
        Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
        return;
      }

      P.app.hapticLight();

      final value = await _showDecodeParamActionSheet(
        context: context,
        current: decodeParamType,
      );

      if (value == null || !context.mounted) {
        return;
      }

      CompletionController.current.onDecodeParamChanged(context, value);
    }

    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: child,
    );
  }
}

Future<DecodeParamType?> _showDecodeParamActionSheet({
  required BuildContext context,
  required DecodeParamType current,
}) async {
  final s = S.current;
  final selectedMark = P.preference.appStyle.q.isClassic ? '☑' : '✓';
  final actionPairs = <({String label, DecodeParamType key})>[
    (label: s.decode_param_custom, key: .custom),
    (label: s.decode_param_default_, key: .defaults),
    (label: s.decode_param_creative, key: .creative),
    (label: s.decode_param_comprehensive, key: .comprehensive),
    (label: s.decode_param_conservative, key: .conservative),
    (label: s.decode_param_fixed, key: .fixed),
  ];
  final actions = actionPairs.map((item) {
    final isCurrent = item.key == current;
    final label = isCurrent ? '$selectedMark ${item.label}' : item.label;

    return SheetAction<DecodeParamType>(
      label: label,
      key: item.key,
    );
  }).toList();

  return showModalActionSheet<DecodeParamType>(
    context: context,
    title: s.decode_param_select_title,
    message: s.decode_param_select_message,
    actions: actions,
  );
}
