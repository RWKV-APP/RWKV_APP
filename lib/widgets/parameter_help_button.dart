import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zone/gen/l10n.dart';

class ParameterHelpButton extends StatefulWidget {
  const ParameterHelpButton({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<ParameterHelpButton> createState() => _ParameterHelpButtonState();
}

class _ParameterHelpButtonState extends State<ParameterHelpButton> {
  final _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = theme.platform == TargetPlatform.android || theme.platform == TargetPlatform.iOS;
    final button = Semantics(
      label: S.of(context).parameter_help_label(widget.title),
      child: IconButton(
        onPressed: isMobile
            ? () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                showDragHandle: true,
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
                builder: (context) => _ParameterHelpSheet(title: widget.title, message: widget.message),
              )
            : () => _tooltipKey.currentState?.ensureTooltipVisible(),
        icon: const Icon(Icons.info_outline, size: 18),
        color: theme.colorScheme.onSurfaceVariant,
        style: IconButton.styleFrom(
          minimumSize: Size.square(isMobile ? 48 : 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
          padding: const .all(6),
        ),
      ),
    );
    if (isMobile) return button;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): Tooltip.dismissAllToolTips},
      child: Tooltip(
        key: _tooltipKey,
        message: widget.message,
        triggerMode: TooltipTriggerMode.manual,
        waitDuration: const Duration(milliseconds: 350),
        showDuration: const Duration(seconds: 30),
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const .all(12),
        margin: const .symmetric(horizontal: 12),
        textStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onInverseSurface, height: 1.45),
        decoration: BoxDecoration(color: theme.colorScheme.inverseSurface, borderRadius: .circular(8)),
        child: button,
      ),
    );
  }
}

class _ParameterHelpSheet extends StatelessWidget {
  const _ParameterHelpSheet({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const .fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                const CloseButton(),
              ],
            ),
            const SizedBox(height: 12),
            Text(message, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }
}
