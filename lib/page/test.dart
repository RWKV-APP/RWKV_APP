// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/store/p.dart';

class PageTest extends ConsumerWidget {
  const PageTest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    return Scaffold(
      appBar: AppBar(
        title: const Text("测试页面"),
      ),
      body: Stack(
        children: [
          // Positioned.fill(
          //   left: screenWidth / 2,
          //   child: CachedNetworkImage(
          //     imageUrl:
          //         "https://cdna.artstation.com/p/assets/images/images/090/145/192/large/weta-workshop-design-studio-0011-ht-isengard-exterior-01a-am.jpg?1753050808",
          //     fit: BoxFit.cover,
          //   ),
          // ),
          Positioned.fill(
            left: screenWidth / 2,
            child: ListView.builder(
              itemCount: 200,
              itemBuilder: (context, index) {
                return Container(
                  height: 50,
                  color: kC,
                  child: Center(
                    child: Text("Item $index" + HF.randomString(min: 0, max: 100)),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: screenHeight - 200,
            left: 0,
            width: screenWidth,
            height: 200,
            child: const _GradientBlur(),
          ),
        ],
      ),
    );
  }
}

/// 这个组件的核心目的其实就是为了给人一种就是文本刚刚进入这个区域的时候,它的模糊程度较小,随着这个页面逐渐向下滚动,文本越来越贴近屏幕,然后它的这个模糊程度就越来越大,因为apple好像没有开放这样的API,或者说安卓也没有开放这样的API,以及flutter也没有提供这样的API,所以我想这种一种类似于被我称作层叠式的层叠式模糊的一个widget。
class _GradientBlur extends ConsumerWidget {
  const _GradientBlur();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSections = [
      [
        [.800, 4.00],
        [.600, 3.50],
        [.400, 3.00],
        [.300, 2.50],
        [.200, 2.00],
        [.100, 1.50],
        [.075, 1.25],
        [.050, 1.00],
        [.025, 0.75],
        [.020, 0.70],
        // [.015, 0.65],
        // [.010, 0.60],
        // [.005, 0.50],
        [.000, 0.50],
      ],
      [
        [0.900, 3.00],
        [0.800, 2.50],
        [0.750, 1.50],
        [0.500, 1.00],
        [0.250, 0.50],
        [0.125, 0.50],
        [0.000, 0.50],
      ],
    ];

    // final sections = allSections[0];
    final sections = allSections[1];

    final qb = ref.watch(P.app.qb);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                // color: Colors.red.q(.1),
              ),
            ),
            ...sections.map((config) {
              final scale = config[0];
              final blur = config[1];
              return Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: scale * height,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              );
            }),
            ...sections.map((config) {
              final scale = config[0];
              return Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: scale * height,
                child: Container(
                  decoration: BD(
                    border: Border.all(
                      color: qb.q(.0),
                      width: .5,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
