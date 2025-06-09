// ignore: unused_import
import 'dart:developer';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/state/p.dart';

class Pager extends ConsumerStatefulWidget {
  static final page = qs<double>(1.0);
  static final atMainPage = qs(true);
  static final childOpacity = qs(1.0);
  static final drawerOpacity = qs(.0);
  static final _newController = qs<PageController>(PageController());
  static final drawerWidth = qs(100.0);

  static FV toggle() async {
    final currentPage = Pager.page.q;
    final targetPage = currentPage == 0 ? 1 : 0;
    qqq("currentPage: $currentPage, targetPage: $targetPage");
    _CustomPageScrollPhysics.disableGaimon = true;
    HF.wait(20).then((_) {
      if (Platform.isAndroid) P.app.hapticLight();
      if (Platform.isIOS) P.app.hapticSoft();
    });
    await Pager._newController.q.animateToPage(
      targetPage,
      duration: 300.ms,
      curve: Curves.easeOutCubic,
    );
    await Future.delayed(50.ms);
    _CustomPageScrollPhysics.disableGaimon = false;
  }

  final Widget child;
  final Widget drawer;

  const Pager({
    super.key,
    required this.child,
    required this.drawer,
  });

  @override
  ConsumerState<Pager> createState() => _PagerState();
}

class _PagerState extends ConsumerState<Pager> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(P.app.screenWidth, _onScreenWidthChanged, fireImmediately: true);
  }

  void _onScreenWidthChanged(double? previous, double? screenWidth) async {
    if (screenWidth == null || screenWidth <= 0) return;

    double wantedWidth = max(screenWidth - 80, 0.0);
    final maxWidth = min(screenWidth, 414.0);
    final minWidth = min(maxWidth, wantedWidth);

    if (wantedWidth > maxWidth) wantedWidth = maxWidth;
    if (wantedWidth < minWidth) wantedWidth = minWidth;

    final viewportFraction = wantedWidth / screenWidth;

    await Future.delayed(0.ms);
    Pager._newController.q.dispose();
    Pager._newController.q = PageController(
      viewportFraction: viewportFraction,
      initialPage: 1,
    )..addListener(_onPageChanged);

    Pager.drawerWidth.q = wantedWidth;
  }

  void _onPageChanged() async {
    // TODO: @WangCe fix the bug at the first time
    final rawString = (Pager._newController.q.page ?? 0).toStringAsFixed(2);
    double v = double.tryParse(rawString) ?? .0;
    if (v > 1) v = 1;
    if (v < 0) v = 0;
    await Future.delayed(0.ms);
    Pager.page.q = v;
    Pager.atMainPage.q = v == 1;
    Pager.childOpacity.q = v;
    Pager.drawerOpacity.q = 1 - v;
  }

  void _onPopInvokedWithResult(bool didPop, dynamic result) async {
    qqq("didPop: $didPop, result: $result");
    await Pager._newController.q.animateToPage(1, duration: 200.ms, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);

    if (screenWidth == 0) return const SB();

    final ignorePointer = ref.watch(Pager.atMainPage);

    final recording = ref.watch(P.world.recording);

    final drawerWidth = ref.watch(Pager.drawerWidth);

    return PopScope(
      canPop: ignorePointer,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: SingleChildScrollView(
          controller: Pager._newController.q,
          physics: recording ? const NeverScrollableScrollPhysics() : const _CustomPageScrollPhysics(parent: ClampingScrollPhysics()),
          scrollDirection: Axis.horizontal,
          child: SB(
            width: screenWidth + drawerWidth,
            height: screenHeight,
            child: Row(
              children: [
                SB(
                  width: drawerWidth,
                  height: screenHeight,
                  child: widget.drawer,
                ),
                Stack(
                  children: [
                    SB(
                      width: screenWidth,
                      height: screenHeight,
                      child: widget.child,
                    ),
                    const _Dim(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _onNotification(notification) {
    if (notification is ScrollStartNotification) {
      if (notification.depth == 0) {
        if (P.chat.focusNode.hasFocus) P.chat.focusNode.unfocus();
        if (P.tts.focusNode.hasFocus) P.tts.dismissAllShown();
      }
    }
    return false;
  }
}

class _Dim extends ConsumerWidget {
  const _Dim();

  void _onTap() async {
    await Pager.toggle();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = ref.watch(P.app.screenWidth);
    final screenHeight = ref.watch(P.app.screenHeight);
    final ignorePointer = ref.watch(Pager.atMainPage);
    final drawerOpacity = ref.watch(Pager.drawerOpacity);
    final qb = ref.watch(P.app.qb);

    return IgnorePointer(
      ignoring: ignorePointer,
      child: GD(
        onTap: _onTap,
        child: Opacity(
          opacity: drawerOpacity.clamp(0, 1),
          child: Material(
            color: kC,
            child: C(
              width: screenWidth,
              height: screenHeight,
              decoration: BD(color: qb.q(.3)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomPageScrollPhysics extends PageScrollPhysics {
  static int? _latestTargetPage;
  static bool disableGaimon = false;

  const _CustomPageScrollPhysics({super.parent});

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 3, // 质量，控制惯性
    stiffness: 400, // 刚度，控制弹簧力度
    damping: 2, // 阻尼，控制减速
  );

  // 获取目标页面索引
  int getTargetPage(ScrollMetrics position, double velocity) {
    final double pageSize = position.viewportDimension;
    final double currentPage = position.pixels / pageSize;

    // 根据速度和当前位置计算目标页面
    if (velocity.abs() >= minFlingVelocity) {
      // 如果有足够的甩动速度，则根据方向确定目标页
      return velocity > .0 ? currentPage.ceil() : currentPage.floor();
    } else {
      // 如果速度较小，则看当前位置是否超过一半决定目标页
      return (currentPage - currentPage.floor() >= .5) ? currentPage.ceil() : currentPage.floor();
    }
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (Platform.isAndroid) return super.createBallisticSimulation(position, velocity);

    // 在模拟开始前，可以计算并存储目标页面
    final targetPage = getTargetPage(position, velocity);

    if (_latestTargetPage != null && _latestTargetPage != targetPage) {
      if (!disableGaimon) P.app.hapticSoft();
    }

    _latestTargetPage = targetPage;

    // 您可以通过全局状态管理或回调将目标页面暴露给外部
    // 例如：Pager.targetPage.q = targetPage;

    // 返回原始模拟
    return super.createBallisticSimulation(position, velocity);
  }

  @override
  PageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _CustomPageScrollPhysics(parent: buildParent(ancestor));
  }
}
