import 'package:flutter/material.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/decode_param_type.dart';

class DecodeParamTypeButton extends StatelessWidget {
  final DecodeParamType decodeParamType;
  final Widget child;
  final ValueChanged<DecodeParamType>? onSelected;
  final BorderRadius borderRadius;

  const DecodeParamTypeButton({
    super.key,
    required this.decodeParamType,
    required this.child,
    this.onSelected,
    this.borderRadius = const .horizontal(right: .circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    final s = S.current;
    return PopupMenuButton<DecodeParamType?>(
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
        onSelected?.call(i!);
      },
      borderRadius: borderRadius,
      child: child,
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
