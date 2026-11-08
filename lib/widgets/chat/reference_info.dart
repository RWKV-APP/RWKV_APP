// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprintf/sprintf.dart';

// Project imports:
import 'package:zone/func/web_search_report.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/ref_info.dart' as model;
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/search_reference_dialog.dart';
import 'package:zone/widgets/chat/web_search_trace_panel.dart';

class ReferenceInfo extends ConsumerStatefulWidget {
  final model.RefInfo refInfo;
  final bool generating;
  final int? messageId;

  const ReferenceInfo({super.key, required this.refInfo, required this.generating, this.messageId});

  @override
  ConsumerState<ReferenceInfo> createState() => _ReferenceInfoState();
}

class _ReferenceInfoState extends ConsumerState<ReferenceInfo> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefill = ref.watch(P.rwkvGeneration.prefillProgress).clamp(0, 1).toDouble();

    final hasError = widget.refInfo.error.isNotEmpty;
    final showProgress = prefill > 0 && prefill < 1 && widget.generating && !hasError;

    final primary = theme.colorScheme.primary;
    final searching = widget.refInfo.list.isEmpty && widget.generating && !hasError;
    final trace = webSearchTraceForReport(widget.refInfo);
    final canShowTrace = trace.hasData;

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        if (widget.refInfo.enable)
          Align(
            alignment: .centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ReferenceActionButton(
                  tooltip: widget.refInfo.error,
                  label: searching
                      ? S.current.searching
                      : hasError
                      ? S.current.search_failed
                      : sprintf(S.current.x_pages_found, [widget.refInfo.list.length]),
                  icon: hasError ? Icons.error_outline : Icons.public,
                  searching: searching,
                  showChevron: !hasError && !searching,
                  onTap: hasError || searching ? null : () => SearchReferenceDialog.show(context, widget.refInfo),
                ),
                if (canShowTrace)
                  _ReferenceActionButton(
                    label: S.of(context).web_search_report_details_action,
                    icon: Icons.receipt_long,
                    onTap: widget.messageId == null ? null : () => WebSearchTracePanel.show(messageId: widget.messageId!, trace: trace),
                  ),
              ],
            ),
          ),
        if (showProgress) const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: showProgress ? 1 : 0,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 100),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const .only(bottom: 6),
              height: showProgress ? 20 : 0,
              child: Row(
                mainAxisSize: .max,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(value: prefill, color: primary, backgroundColor: primary.withValues(alpha: .1)),
                  ),
                  const SizedBox(width: 10),
                  Text(S.current.analysing_result, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferenceActionButton extends StatelessWidget {
  final String label;
  final String? tooltip;
  final IconData icon;
  final bool searching;
  final bool showChevron;
  final VoidCallback? onTap;

  const _ReferenceActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.searching = false,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Tooltip(
      message: tooltip ?? label,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        child: InkWell(
          borderRadius: .circular(20),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const .symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: .1),
              borderRadius: .circular(20),
              border: Border.all(color: primary.withValues(alpha: .18), width: 0.5),
            ),
            child: Row(
              mainAxisSize: .min,
              children: [
                Icon(icon, size: 16, color: primary),
                const SizedBox(width: 6),
                if (searching)
                  _AdvancedBlinkText(text: label, color: primary)
                else
                  Text(label, style: TextStyle(color: primary, fontSize: 12)),
                if (showChevron) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdvancedBlinkText extends StatefulWidget {
  final String text;
  final Color color;

  const _AdvancedBlinkText({required this.text, required this.color});

  @override
  _AdvancedBlinkTextState createState() => _AdvancedBlinkTextState();
}

class _AdvancedBlinkTextState extends State<_AdvancedBlinkText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.color,
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          widget.text,
          style: TextStyle(fontSize: 12, color: _colorAnimation.value),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
