// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';

class PhotoViewerOverlay extends ConsumerWidget {
  const PhotoViewerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingTop = ref.watch(P.app.paddingTop);
    final paddingRight = ref.watch(P.app.paddingRight);
    return Row(
      mainAxisAlignment: .end,
      children: [
        Container(
          margin: .only(top: paddingTop + 12, right: paddingRight + 12),
          child: IconButton(
            onPressed: () {
              pop();
            },
            icon: const Icon(
              Icons.close,
              color: kW,
            ),
          ),
        ),
      ],
    );
  }
}
