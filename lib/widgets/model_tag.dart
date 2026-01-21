// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
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
    this.fontWeight = .w500,
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    required this.displayTagName,
  });
}

class ModelTag extends ConsumerWidget {
  final String tag;
  final bool forceUppercase;
  final Color? forceBgColor;
  final Color? forceTextColor;

  const ModelTag({super.key, required this.tag, this.forceUppercase = false, this.forceBgColor, this.forceTextColor});

  _RenderingOptions _getRenderingOptions(String tagName, WidgetRef ref, BuildContext context) {
    final qb = ref.watch(P.app.qb);
    final qw = ref.watch(P.app.qw);
    final logicTagName = tagName.toLowerCase();
    final primary = Theme.of(context).colorScheme.primary;
    switch (logicTagName) {
      case "mlx":
        return _RenderingOptions(
          footer: Padding(
            padding: const .only(bottom: 2),
            child: Icon(Icons.apple, size: 13, color: qb),
          ),
          bgColor: Colors.transparent,
          textColor: qb,
          borderColor: qb,
          displayTagName: "GPU",
        );
      case "coreml":
        return _RenderingOptions(
          footer: Padding(
            padding: const .only(bottom: 2),
            child: Icon(Icons.apple, size: 13, color: qb),
          ),
          bgColor: Colors.transparent,
          textColor: qb,
          borderColor: qb,
          displayTagName: "NPU",
        );
      case "npu":
        return _RenderingOptions(
          footer: const T("⚡"),
          bgColor: kCG,
          textColor: qw,
          borderColor: kCG,
          displayTagName: "NPU",
        );
      case "gpu":
        return _RenderingOptions(
          bgColor: kCG,
          textColor: qw,
          borderColor: kCG,
          displayTagName: "GPU",
        );
      case "DeepEmbedding":
        return _RenderingOptions(
          bgColor: kCG,
          textColor: qw,
          borderColor: kCG,
          displayTagName: "DE",
        );
      case "batch":
        return _RenderingOptions(
          bgColor: kCG,
          textColor: qw,
          borderColor: kCG,
          displayTagName: "BATCH",
        );
      case "webrwkv":
        return _RenderingOptions(
          bgColor: kCG,
          textColor: qw,
          borderColor: kCG,
          displayTagName: "WebRWKV",
        );
      case "cpu":
        return _RenderingOptions(
          bgColor: kG.q(.2),
          textColor: qb,
          borderColor: kG.q(.2),
          displayTagName: "CPU",
          fontWeight: .w400,
        );
      case "translate":
        return _RenderingOptions(
          bgColor: kG.q(.2),
          textColor: qb,
          borderColor: kG.q(.2),
          displayTagName: "Translation",
        );
      case "tts":
        return _RenderingOptions(
          bgColor: primary.q(.2),
          textColor: primary.q(1),
          borderColor: primary.q(1),
          displayTagName: tagName.toUpperCase(),
          fontWeight: .w400,
        );
      case "vision":
        return _RenderingOptions(
          bgColor: primary.q(.2),
          textColor: primary.q(1),
          borderColor: primary.q(1),
          displayTagName: tagName.toUpperCase(),
          fontWeight: .w400,
        );
      default:
        return _RenderingOptions(
          bgColor: kG.q(.2),
          textColor: qb,
          borderColor: kG.q(.2),
          displayTagName: tagName,
          fontWeight: .w400,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opt = _getRenderingOptions(tag, ref, context);

    return Container(
      decoration: BoxDecoration(
        color: forceBgColor ?? opt.bgColor,
        border: Border.all(color: opt.borderColor, width: .5),
        borderRadius: 4.r,
      ),
      padding: const .symmetric(horizontal: 4),
      child: IntrinsicWidth(
        child: Row(
          children: [
            Text(
              forceUppercase ? opt.displayTagName.toUpperCase() : opt.displayTagName,
              style: TS(
                c: forceTextColor ?? opt.textColor,
                w: opt.fontWeight,
              ),
            ),
            ?opt.footer,
          ],
        ),
      ),
    );
  }
}
