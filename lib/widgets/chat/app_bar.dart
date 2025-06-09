// ignore: unused_import
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/config.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/route/router.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/arguments_panel.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:zone/widgets/pager.dart';
import 'package:sprintf/sprintf.dart';

class ChatAppBar extends ConsumerWidget {
  const ChatAppBar({super.key});

  void onSettingsPressed() async {
    if (!checkModelSelection()) return;

    final demoType = P.app.demoType.q;
    if (demoType == DemoType.tts) {
      await P.tts.showTTSCFMStepsSelector();
      return;
    }

    await ArgumentsPanel.show(getContext()!);
    return;
  }

  void _onTitlePressed() async {
    ModelSelector.show();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    final demoType = ref.watch(P.app.demoType);
    final primary = Theme.of(context).colorScheme.primary;
    final currentModel = ref.watch(P.rwkv.currentModel);
    final currentGroupInfo = ref.watch(P.rwkv.currentGroupInfo);
    final selectMessageMode = ref.watch(P.chat.selectMessageMode);

    String displayName = s.click_to_select_model;
    if (currentGroupInfo != null) {
      displayName = currentGroupInfo.displayName;
    } else if (currentModel != null) {
      displayName = currentModel.name;
    }

    final theme =Theme.of(context);
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;
    final qb = ref.watch(P.app.qb);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Theme(
            data: theme.copyWith(
              appBarTheme: theme.appBarTheme.copyWith(
                backgroundColor: scaffoldBackgroundColor,
              )
            ),
            child: selectMessageMode
                ? _SelectMessageAppBar() //
                : _buildAppBar(context, displayName, primary, demoType),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String displayName, Color primary, DemoType demoType) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: GD(
        onTap: _onTitlePressed,
        child: C(
          decoration: const BD(
            color: kC,
          ),
          child: Column(
            crossAxisAlignment: CAA.center,
            children: [
              const T(
                Config.appTitle,
                s: TS(s: 18),
              ),
              2.h,
              C(
                padding: const EI.o(l: 4, r: 4, t: 1, b: 1),
                decoration: BD(
                  color: kB.q(.1),
                  borderRadius: 10.r,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CAA.center,
                  mainAxisAlignment: MAA.center,
                  children: [
                    T(
                      displayName,
                      s: TS(s: 10, c: primary),
                    ),
                    4.w,
                    Transform.rotate(
                      angle: 0, // 90度
                      child: SB(
                        width: 10,
                        height: 5,
                        child: CustomPaint(
                          painter: _TrianglePainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      leading: const Row(
        children: [
          _MenuButton(),
        ],
      ),
      actions: [
        if (demoType == DemoType.chat) const _NewConversationButton(),
        if (demoType != DemoType.sudoku)
          IconButton(
            onPressed: onSettingsPressed,
            icon: const Icon(Icons.tune),
          ),
      ],
    );
  }
}

class _NewConversationButton extends ConsumerWidget {
  const _NewConversationButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    late final Widget icon;

    // if (Platform.isIOS || Platform.isMacOS) {
    //   icon = const Icon(CupertinoIcons.news_solid);
    // } else {
    // }

    icon = const Icon(Icons.add_comment_outlined);
    final loaded = ref.watch(P.rwkv.loaded);
    final isEmpty = ref.watch(P.msg.list.select((v) => v.isEmpty));

    return IconButton(
      onPressed: loaded && !isEmpty
          ? () {
              P.chat.startNewChat();
            }
          : null,
      icon: icon,
    );
  }
}

class _MenuButton extends ConsumerWidget {
  const _MenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childOpacity = ref.watch(Pager.childOpacity);
    return Opacity(
      opacity: childOpacity,
      child: const IconButton(
        onPressed: Pager.toggle,
        icon: Icon(Icons.menu),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final qb = P.app.qb.q;
    final paint = Paint()
      ..color = qb.q(.667)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _SelectMessageAppBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(P.chat.selectedMessages);
    final allMessage = ref.watch(P.msg.list);

    final all = allMessage.length == selected.length;

    void onAllTap() {
      P.chat.selectedMessages.q = all ? {} : allMessage.map((e) => e.id).toSet();
    }

    final leading = Row(
      children: [
        Checkbox(
          value: all,
          onChanged: (v) => onAllTap(),
        ),
        GD(
          onTap: onAllTap,
          child: T(S.of(context).all),
        ),
      ],
    );
    sprintf("", []);

    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: T(sprintf(S.of(context).x_message_selected, [selected.length]), s: TS(s: 18)),
      leading: leading,
      leadingWidth: 100,
    );
  }
}
