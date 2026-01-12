// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

class SelectImageButton extends ConsumerWidget {
  const SelectImageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.primary;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
    final s = S.of(context);
    final selectedImagePath = ref.watch(P.see.imagePath);
    return GestureDetector(
      onTap: P.see.selectImage,
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
        padding: const .only(left: 8, top: 8, right: 8, bottom: 8),
        child: T(
          selectedImagePath == null ? s.select_new_image : s.change_selected_image,
          s: TS(c: color),
        ),
      ),
    );
  }
}
