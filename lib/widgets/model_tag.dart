// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/store/p.dart';

class _RenderingOptions {
  final Widget? footer;
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final String displayTagName;
  final FontWeight fontWeight;

  _RenderingOptions({
    this.footer,
    this.fontWeight = .w400,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    required this.displayTagName,
  });
}

class ModelTag extends ConsumerWidget {
  static final Color _tagSoftGreenIconColor = const Color(0xFF_FF_B5_2F);
  static final Color _tagSoftGreenIconColorDark = const Color(0xFFFFD54F);

  final String tag;
  final bool forceUppercase;
  final Color? forceBgColor;
  final Color? forceTextColor;

  const ModelTag({super.key, required this.tag, this.forceUppercase = false, this.forceBgColor, this.forceTextColor});

  _RenderingOptions _getRenderingOptions(String tagName, WidgetRef ref, Color primary, Brightness brightness) {
    final qb = ref.watch(P.app.qb);

    final bool isDark = brightness == Brightness.dark;

    final Color tagBoltColor = isDark ? _tagSoftGreenIconColorDark : _tagSoftGreenIconColor;

    final logicTagName = tagName.toLowerCase();
    switch (logicTagName) {
      case "mlx":
        return _RenderingOptions(
          footer: Icon(
            Icons.apple,
            size: 14,
            color: qb,
          ),
          bgColor: qb.q(.1),
          textColor: qb,
          borderColor: qb.q(.1),
          displayTagName: "GPU",
          fontWeight: .w400,
        );
      case "coreml":
      case "npu":
        return _RenderingOptions(
          footer: Icon(
            Icons.bolt,
            size: 14,
            color: tagBoltColor,
          ),
          bgColor: qb.q(.1),
          textColor: qb,
          borderColor: qb.q(.1),
          displayTagName: "NPU",
        );
      case "deepembedding":
        return _RenderingOptions(
          bgColor: qb.q(.1),
          textColor: qb,
          borderColor: qb.q(.1),
          displayTagName: "DeepEmb",
        );
      case "batch":
        return _RenderingOptions(
          bgColor: qb.q(.1),
          textColor: qb,
          borderColor: qb.q(.1),
          displayTagName: "BATCH",
        );
      case "webrwkv":
        return _RenderingOptions(
          bgColor: qb.q(.1),
          textColor: qb,
          borderColor: qb.q(.1),
          displayTagName: "WebRWKV",
        );
      case "cpu":
        return _RenderingOptions(
          bgColor: qb.q(.1),
          textColor: qb,
          borderColor: qb.q(.1),
          displayTagName: "CPU",
          fontWeight: .w400,
        );
      case "translate":
        return _RenderingOptions(
          bgColor: qb.q(.1),
          textColor: qb,
          borderColor: qb.q(.1),
          displayTagName: "Translation",
        );
      case "tts":
        return _RenderingOptions(
          bgColor: qb.q(.1),
          textColor: qb,
          borderColor: qb.q(.1),
          displayTagName: tagName.toUpperCase(),
          fontWeight: .w400,
        );
      case "vision":
        return _RenderingOptions(
          bgColor: qb.q(.1),
          textColor: qb,
          borderColor: qb.q(.1),
          displayTagName: tagName.toUpperCase(),
          fontWeight: .w400,
        );
      case "gpu":
      default:
        return _RenderingOptions(
          bgColor: qb.q(.1),
          textColor: qb,
          borderColor: qb.q(.1),
          displayTagName: tagName,
          fontWeight: .w400,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final opt = _getRenderingOptions(tag, ref, theme.colorScheme.primary, theme.brightness);

    return Container(
      decoration: BoxDecoration(
        color: forceBgColor ?? opt.bgColor,
        border: .all(color: opt.borderColor, width: .5),
        borderRadius: .circular(4),
      ),
      padding: const .only(
        left: 4,
        right: 4,
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisAlignment: .center,
          children: [
            if (opt.footer != null) 2.w,
            Container(
              padding: const .symmetric(vertical: 1),
              child: Text(
                forceUppercase ? opt.displayTagName.toUpperCase() : opt.displayTagName,
                style: TS(
                  c: forceTextColor ?? opt.textColor,
                  w: opt.fontWeight,
                  height: 1.2,
                ),
              ),
            ),
            ?opt.footer,
          ],
        ),
      ),
    );
  }
}
