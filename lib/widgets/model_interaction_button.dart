// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/model/file_info.dart';
import 'package:zone/store/p.dart';

class ModelInteractionButton extends ConsumerWidget {
  final FileInfo fileInfo;

  final bool overrideIsCurrentModel;

  const ModelInteractionButton({
    super.key,
    required this.fileInfo,
    this.overrideIsCurrentModel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(P.app.theme);
    final startButtonRadius = appTheme.startButtonRadius;
    final Color buttonColor = kG.q(.5);

    return Container(
      decoration: BoxDecoration(
        borderRadius: .circular(startButtonRadius),
        color: buttonColor,
      ),
      padding: const .all(8),
    );
  }
}
