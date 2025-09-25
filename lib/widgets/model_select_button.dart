import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/store/p.dart' show P, $RWKV;
import 'package:zone/widgets/arguments_panel.dart';

import '../gen/l10n.dart';
import 'model_selector.dart';

class ModelSelectButton extends ConsumerWidget {
  const ModelSelectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentModel = ref.watch(P.rwkv.currentModel);
    final decodeParamType = ref.watch(P.rwkv.decodeParamType);
    final modelDisplay = currentModel?.name ?? S.current.click_to_select_model;
    final theme = Theme.of(context);

    final currentName =
        {
          DecodeParamType.defaults: S.current.default_,
          DecodeParamType.creative: S.current.creative,
          DecodeParamType.conservative: S.current.conservative,
          DecodeParamType.fixed: S.current.fixed,
          DecodeParamType.comprehensive: S.current.comprehensive,
          DecodeParamType.unknown: S.current.custom,
        }[decodeParamType] ??
        S.current.custom;

    return Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              onTap: () {
                ModelSelector.show();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(modelDisplay, style: const TextStyle(fontSize: 10, height: 1, fontWeight: FontWeight.w500)),
              ),
            ),
            if (currentModel == null)
              SizedBox(
                height: 5,
                width: 8,
                child: CustomPaint(
                  painter: _TrianglePainter(color: Colors.grey),
                ),
              ),
            if (currentModel == null) const SizedBox(width: 8),
            if (currentModel != null) const VerticalDivider(thickness: 1, width: 1),
            if (currentModel != null)
              PopupMenuTheme(
                data: PopupMenuThemeData(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  menuPadding: EdgeInsets.zero,
                  // elevation: 0,
                ),
                child: PopupMenuButton<DecodeParamType?>(
                  padding: EdgeInsets.zero,
                  initialValue: decodeParamType,
                  position: PopupMenuPosition.under,
                  itemBuilder: (c) {
                    return [
                      PopupMenuItem<DecodeParamType?>(
                        height: 32,
                        value: DecodeParamType.unknown,
                        enabled: false,
                        child: Text(S.current.decode_param, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                      buildMenuItem(S.current.creative, DecodeParamType.creative, decodeParamType),
                      buildMenuItem(S.current.comprehensive, DecodeParamType.comprehensive, decodeParamType),
                      buildMenuItem(S.current.default_, DecodeParamType.defaults, decodeParamType),
                      buildMenuItem(S.current.conservative, DecodeParamType.conservative, decodeParamType),
                      buildMenuItem(S.current.fixed, DecodeParamType.fixed, decodeParamType),
                      buildMenuItem(S.current.custom, DecodeParamType.unknown, decodeParamType),
                    ];
                  },
                  onSelected: (i) {
                    if (i == DecodeParamType.unknown) {
                      ArgumentsPanel.show(context);
                    } else {
                      P.rwkv.syncSamplerParamsFromDefault(i!);
                    }
                  },
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(currentName, style: const TextStyle(color: Colors.grey, fontSize: 10, height: 1)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<DecodeParamType> buildMenuItem(String text, DecodeParamType value, DecodeParamType current) {
    final checked = value == current;
    return PopupMenuItem(
      value: value,
      height: 32,
      child: Row(
        children: [
          if (checked) const Icon(Icons.check, size: 16),
          if (!checked) const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(height: 1)),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
