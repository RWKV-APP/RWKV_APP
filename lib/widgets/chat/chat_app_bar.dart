// ignore: unused_import
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/config.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/arguments_panel.dart';
import 'package:zone/widgets/log_panel.dart';
import 'package:zone/widgets/model_select_button.dart';
import 'package:zone/widgets/model_selector.dart';
import 'package:sprintf/sprintf.dart';
import 'package:zone/widgets/state_panel.dart';
import 'package:zone/widgets/triangle_painter.dart';

class ChatAppBar extends ConsumerWidget {
  final DemoType? preferredDemoType;

  const ChatAppBar({super.key, this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    final DemoType demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    final currentModel = ref.watch(P.rwkv.latestModel);
    final currentGroupInfo = ref.watch(P.rwkv.currentGroupInfo);
    final selectMessageMode = ref.watch(P.chat.isSharing);

    String displayName = s.click_to_select_model;

    if (currentGroupInfo != null) displayName = currentGroupInfo.displayName;
    if (currentModel != null) displayName = currentModel.name;

    final theme = Theme.of(context);
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Theme(
          data: theme.copyWith(
            appBarTheme: theme.appBarTheme.copyWith(
              backgroundColor: scaffoldBackgroundColor,
            ),
          ),
          child: selectMessageMode
              ? _SelectMessageChatAppBar() //
              : _ChatAppBar(
                  displayName: displayName,
                  preferredDemoType: demoType,
                ),
        ),
      ),
    );
  }
}

class _ChatAppBar extends ConsumerWidget {
  final String displayName;
  final DemoType preferredDemoType;

  const _ChatAppBar({
    required this.displayName,
    required this.preferredDemoType,
  });

  void _onSettingsPressed() async {
    if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;

    final demoType = P.app.demoType.q;
    if (demoType == .tts) {
      return;
    }

    await ArgumentsPanel.show(getContext()!);
    return;
  }

  void _onTitlePressed() async {
    await ModelSelector.show(
      showNeko: P.app.pageKey.q == .neko,
      preferredDemoType: preferredDemoType,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final completionMode = ref.watch(P.chat.completionMode);
    final qb = ref.watch(P.app.qb);
    final customTheme = ref.watch(P.app.customTheme);
    final scaffold = customTheme.scaffold;
    final isChat = preferredDemoType == .chat;
    final isTTS = preferredDemoType == .tts;
    final isWorld = preferredDemoType == .see;

    final userType = ref.watch(P.preference.userType);
    final version = ref.watch(P.app.version);
    final light = ref.watch(P.app.light);
    Color backgroundColor = light ? const Color.fromRGBO(239, 243, 251, 0.5) : kB.q(.5);
    if (isChat || isTTS || isWorld) {
      backgroundColor = backgroundColor;
    } else {
      backgroundColor = scaffold.q(.7);
    }

    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: backgroundColor,
      systemOverlayStyle: customTheme.light ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark,
      title: GestureDetector(
        onTap: _onTitlePressed,
        child: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Column(
            crossAxisAlignment: .center,
            children: [
              if (isChat)
                Row(
                  mainAxisAlignment: .center,
                  mainAxisSize: .min,
                  crossAxisAlignment: .end,
                  children: [
                    const T(
                      Config.appTitle,
                      s: TextStyle(fontSize: 16, fontWeight: .w600),
                    ),
                    Padding(
                      padding: const .only(bottom: 2, left: 1),
                      child: T(' $version', s: const TS(s: 8, w: .bold)),
                    ),
                  ],
                ),
              if (!isChat)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: version,
                        style: const TS(s: 10, c: Colors.transparent),
                      ),
                      const TextSpan(text: Config.appTitle, style: TS(s: 18)),
                      TextSpan(
                        text: ' $version',
                        style: const TS(s: 8),
                      ),
                    ],
                  ),
                ),
              if (isChat) const ModelSelectButton(),
              if (!isChat)
                Container(
                  padding: const .only(left: 4, top: 1, right: 4, bottom: 1),
                  decoration: BoxDecoration(
                    color: kB.q(.1),
                    borderRadius: 10.r,
                  ),
                  child: Row(
                    mainAxisSize: .min,
                    crossAxisAlignment: .center,
                    mainAxisAlignment: .center,
                    children: [
                      T(
                        displayName,
                        s: TS(s: 10, c: primary),
                      ),
                      4.w,
                      Transform.rotate(
                        angle: 0, // 90度
                        child: SizedBox(
                          width: 10,
                          height: 5,
                          child: CustomPaint(
                            painter: TrianglePainter(color: qb.q(.667)),
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
      actions: [
        if ((preferredDemoType == .chat || preferredDemoType == .see) && !completionMode)
          _NewConversationButton(preferredDemoType: preferredDemoType),
        if (preferredDemoType == .chat && userType.isGreaterThan(.user)) _MorePopupMenuButton(preferredDemoType: preferredDemoType),
        if (preferredDemoType != .chat && preferredDemoType != .sudoku && userType.isGreaterThan(.user))
          IconButton(
            onPressed: _onSettingsPressed,
            icon: const Icon(Icons.tune),
          ),
      ],
    );
  }
}

class _MorePopupMenuButton extends ConsumerWidget {
  final DemoType preferredDemoType;
  const _MorePopupMenuButton({required this.preferredDemoType});

  void _onSettingsPressed() async {
    if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;

    final demoType = P.app.demoType.q;
    if (demoType == .tts) {
      return;
    }

    await ArgumentsPanel.show(getContext()!);
    return;
  }

  void _logPanelTapped() async {
    await LogPanel.show(getContext()!);
  }

  void _statePanelTapped() async {
    await StatePanel.show(getContext()!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(P.app.version);
    final s = S.of(context);

    return PopupMenuButton(
      onSelected: (v) {
        switch (v) {
          case 1:
            push(.advancedSettings);
            break;
          case 2:
            _onSettingsPressed();
            break;
          case 3:
            _logPanelTapped();
            break;
          case 4:
            _statePanelTapped();
            break;
          default:
            break;
        }
      },
      itemBuilder: (v) {
        return [
          PopupMenuItem(
            value: -1,
            enabled: false,
            height: 20,
            child: T(Config.appTitle + " " + version, s: const TS(s: 10)),
          ),
          PopupMenuItem(
            value: 1,
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.screwdriverWrench, size: 14),
                8.w,
                Text(s.advance_settings),
              ],
            ),
          ),
          PopupMenuItem(
            value: 2,
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.sliders, size: 14),
                8.w,
                Text(s.session_configuration),
              ],
            ),
          ),
          PopupMenuItem(
            value: 3,
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.book, size: 14),
                8.w,
                Text(s.open_debug_log_panel),
              ],
            ),
          ),
          PopupMenuItem(
            value: 4,
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.satellite, size: 14),
                8.w,
                Text(s.open_state_panel),
              ],
            ),
          ),
        ];
      },
    );
  }
}

class _NewConversationButton extends ConsumerWidget {
  final DemoType preferredDemoType;

  const _NewConversationButton({required this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    late final Widget icon;

    icon = const Icon(Icons.add_comment_outlined);
    final isEmpty = ref.watch(P.msg.list.select((v) => v.isEmpty));

    return IconButton(
      onPressed: !isEmpty
          ? () {
              if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;
              P.chat.startNewChat();
            }
          : null,
      icon: icon,
    );
  }
}

class _SelectMessageChatAppBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final selected = ref.watch(P.chat.sharingSelectedMsgIds);
    final allMessage = ref.watch(P.msg.list);

    final all = allMessage.length == selected.length;

    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: T(sprintf(s.x_message_selected, [selected.length]), s: const TS(s: 18)),
      leading: _SelectAllRow(
        all: all,
        onAllTap: () {
          P.chat.sharingSelectedMsgIds.q = all ? {} : allMessage.map((e) => e.id).toSet();
        },
      ),
      leadingWidth: 100,
    );
  }
}

class _SelectAllRow extends ConsumerWidget {
  final bool all;
  final VoidCallback onAllTap;

  const _SelectAllRow({
    required this.all,
    required this.onAllTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Row(
      children: [
        Checkbox(
          value: all,
          onChanged: (v) => onAllTap(),
        ),
        GestureDetector(
          onTap: onAllTap,
          child: T(s.all),
        ),
      ],
    );
  }
}
