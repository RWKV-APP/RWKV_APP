// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/func/show_image_selector.dart';
import 'package:zone/gen/l10n.dart';

class SelectImageButton extends ConsumerWidget {
  const SelectImageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.primary;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;
    final s = S.of(context);
    return GestureDetector(
      onTap: () async {
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
          s.select_new_image,
          s: TS(c: color),
        ),
      ),
    );
  }
}
