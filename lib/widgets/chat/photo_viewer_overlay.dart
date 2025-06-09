// ignore: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/route/method.dart';
import 'package:zone/state/p.dart';

class PhotoViewerOverlay extends ConsumerWidget {
  const PhotoViewerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qw = ref.watch(P.app.qw);
    final paddingTop = ref.watch(P.app.paddingTop);
    final paddingRight = ref.watch(P.app.paddingRight);
    return Row(
      mainAxisAlignment: MAA.end,
      children: [
        C(
          margin: EI.o(t: paddingTop + 12, r: paddingRight + 12),
          child: IconButton(
            onPressed: () {
              pop();
            },
            icon: Icon(
              Icons.close,
              color: qw,
            ),
          ),
        ),
      ],
    );
  }
}
