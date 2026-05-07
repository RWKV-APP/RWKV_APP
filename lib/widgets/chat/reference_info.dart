// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:sprintf/sprintf.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/ref_info.dart' as model;
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/search_reference_dialog.dart';

class ReferenceInfo extends ConsumerStatefulWidget {
  final model.RefInfo refInfo;
  final bool generating;

  const ReferenceInfo({super.key, required this.refInfo, required this.generating});

  @override
  ConsumerState<ReferenceInfo> createState() => _ReferenceInfoState();
}

class _ReferenceInfoState extends ConsumerState<ReferenceInfo> {
  @override
  Widget build(BuildContext context) {
    final prefill = ref.watch(P.rwkvGeneration.prefillProgress).clamp(0, 1).toDouble();

    final hasError = widget.refInfo.error.isNotEmpty;
    final showProgress = prefill > 0 && prefill < 1 && widget.generating && !hasError;

    final primary = Theme.of(context).colorScheme.primary;
    final searching = widget.refInfo.list.isEmpty && widget.generating && !hasError;

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        if (widget.refInfo.enable)
          Align(
            alignment: .centerLeft,
            child: InkWell(
              borderRadius: .circular(20),
              onTap: hasError || searching ? null : () => SearchReferenceDialog.show(context, widget.refInfo),
              child: Container(
                padding: const .symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.q(.1),
                  borderRadius: .circular(20),
                ),
                child: searching
                    ? _AdvancedBlinkText(text: S.current.searching, color: primary)
                    : Text(
                        hasError ? S.current.search_failed : sprintf(S.current.x_pages_found, [widget.refInfo.list.length]),
                        style: TextStyle(color: primary, fontSize: 12),
                      ),
              ),
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
                    child: CircularProgressIndicator(value: prefill, color: primary, backgroundColor: primary.q(.1)),
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
