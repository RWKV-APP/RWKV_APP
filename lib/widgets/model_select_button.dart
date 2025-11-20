import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/store/p.dart' show P, $RWKV;
import 'package:zone/widgets/arguments_panel.dart';

import 'package:zone/gen/l10n.dart';
import 'model_selector.dart';

class ModelSelectButton extends ConsumerWidget {
  const ModelSelectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentModel = ref.watch(P.rwkv.currentModel);
    final decodeParamType = ref.watch(P.rwkv.decodeParamType);
    final s = S.of(context);
    final modelDisplay = currentModel?.name ?? s.click_to_select_model;
    final theme = Theme.of(context);

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

    return Ink(
      decoration: BoxDecoration(
        borderRadius: .circular(16),
        border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: .center,
          mainAxisSize: .min,
          children: [
            InkWell(
              borderRadius: const .horizontal(left: .circular(16)),
              onTap: () {
                ModelSelector.show();
              },
              child: Padding(
                padding: const .symmetric(horizontal: 8, vertical: 4),
                child: Text(modelDisplay, style: const TextStyle(fontSize: 10, height: 1, fontWeight: .w500)),
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
                  shape: RoundedRectangleBorder(borderRadius: .circular(8)),
                  menuPadding: .zero,
                  // elevation: 0,
                ),
                child: PopupMenuButton<DecodeParamType?>(
                  padding: .zero,
                  initialValue: decodeParamType,
                  position: PopupMenuPosition.under,
                  itemBuilder: (c) {
                    return [
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
                    ];
                  },
                  onSelected: (i) {
                    if (i == DecodeParamType.unknown) {
                      ArgumentsPanel.show(context);
                    } else {
                      P.rwkv.syncSamplerParamsFromDefault(i!);
                    }
                  },
                  borderRadius: const .horizontal(right: .circular(16)),
                  child: Padding(
                    padding: const .symmetric(horizontal: 12, vertical: 4),
                    child: Text(currentName, style: const TextStyle(fontSize: 10, height: 1)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<DecodeParamType> _buildMenuItem(String text, DecodeParamType value, DecodeParamType current) {
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
