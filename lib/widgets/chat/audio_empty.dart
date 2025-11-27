// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/store/p.dart';

class AudioEmpty extends ConsumerWidget {
  const AudioEmpty({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    final paddingTop = ref.watch(P.app.paddingTop);
    final inputHeight = ref.watch(P.chat.inputHeight);
    final primary = Theme.of(context).colorScheme.primary;

    final imagePath = ref.watch(P.see.imagePath);
    if (imagePath != null) {
      return Positioned(child: IgnorePointer(child: Container()));
    }

    final messages = ref.watch(P.msg.list);

    bool show = true;
    if (messages.isNotEmpty) {
      show = false;
    }

    String message = "";

    return AnimatedPositioned(
      duration: 200.ms,
      curve: Curves.easeInOutBack,
      bottom: show ? inputHeight : -screenHeight,
      left: 0,
      width: screenWidth,
      top: paddingTop + kToolbarHeight,
      child: IgnorePointer(
        ignoring: true,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: 200.ms,
          curve: Curves.easeInOutBack,
          child: Container(
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Column(
              crossAxisAlignment: .center,
              mainAxisAlignment: .center,
              children: [
                Container(
                  padding: const .symmetric(horizontal: 24),
                  child: T(
                    message,
                    s: TS(s: 20, c: primary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
