// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/func/show_image_selector.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';

class SelectImageButton extends ConsumerWidget {
  const SelectImageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.primary;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
    final s = S.of(context);
    final selectedImagePath = ref.watch(P.world.imagePath);
    return GestureDetector(
      onTap: () async {
        if (!checkModelSelection(preferredDemoType: DemoType.world)) return;
        await showImageSelector();
      },
      child: AnimatedContainer(
        duration: 150.ms,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: primaryContainer,
          border: Border.all(
            color: color.q(.5),
          ),
          borderRadius: 12.r,
        ),
        padding: const EI.o(l: 8, r: 8, t: 8, b: 8),
        child: T(
          selectedImagePath == null ? s.select_new_image : s.change_selected_image,
          s: TS(c: color),
        ),
      ),
    );
  }
}
