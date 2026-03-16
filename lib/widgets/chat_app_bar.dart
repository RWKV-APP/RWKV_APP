// Dart imports:
import 'dart:ui';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:sprintf/sprintf.dart';

// Project imports:
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
import 'package:zone/widgets/state_panel.dart';

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
    final appTheme = ref.watch(P.app.theme);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Theme(
          data: theme.copyWith(
            appBarTheme: theme.appBarTheme.copyWith(
              backgroundColor: appTheme.scaffoldBg,
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
    final completionMode = ref.watch(P.chat.completionMode);
    final qt = ref.watch(P.app.theme);

    final userType = ref.watch(P.preference.userType);
    final version = ref.watch(P.app.version);

    final listAtTop = ref.watch(P.chat.listAtTop);

    final backgroundColor = qt.appBarBgC;

    return Column(
      children: [
        AppBar(
          centerTitle: true,
          backgroundColor: backgroundColor.q(listAtTop ? 1 : 0.5),
          systemOverlayStyle: qt.isLight ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark,
          title: Tooltip(
            message: displayName,
            child: GestureDetector(
              onTap: _onTitlePressed,
              child: Container(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Column(
                  crossAxisAlignment: .center,
                  children: [
                    Row(
                      mainAxisAlignment: .center,
                      mainAxisSize: .min,
                      crossAxisAlignment: .end,
                      children: [
                        const Text(
                          Config.appTitle,
                          style: TextStyle(fontSize: 16, fontWeight: .w600),
                        ),
                        Padding(
                          padding: const .only(bottom: 3, left: 1),
                          child: Text(' $version', style: const TS(s: 8, w: .bold)),
                        ),
                      ],
                    ),
                    ModelSelectButton(preferredDemoType: preferredDemoType),
                  ],
                ),
              ),
            ),
          ),
          // leading: IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
          actions: [
            if ((preferredDemoType == .chat || preferredDemoType == .see) && !completionMode)
              _NewConversationButton(preferredDemoType: preferredDemoType),
            if (preferredDemoType == .chat && userType.isGreaterThan(.user)) _MorePopupMenuButton(preferredDemoType: preferredDemoType),
            if (preferredDemoType != .chat && preferredDemoType != .sudoku && userType.isGreaterThan(.user) && preferredDemoType != .tts)
              IconButton(
                onPressed: _onSettingsPressed,
                icon: const Icon(Icons.tune),
              ),
          ],
        ),
        const _AppBarBottomLine(),
      ],
    );
  }
}

class _AppBarBottomLine extends ConsumerWidget {
  const _AppBarBottomLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qt = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final listAtTop = ref.watch(P.chat.listAtTop);

    return Container(
      height: qt.appBarBottomLineHeight,
      color: listAtTop ? Colors.transparent : qb.q(.2),
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
    await LogPanel.show();
  }

  void _statePanelTapped() async {
    await StatePanel.show();
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
            child: Text(Config.appTitle + " " + version, style: const TS(s: 10)),
          ),
          PopupMenuItem(
            value: 1,
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.screwdriverWrench, size: 14),
                const SizedBox(width: 8),
                Text(s.advance_settings),
              ],
            ),
          ),
          PopupMenuItem(
            value: 2,
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.sliders, size: 14),
                const SizedBox(width: 8),
                Text(s.session_configuration),
              ],
            ),
          ),
          PopupMenuItem(
            value: 3,
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.book, size: 14),
                const SizedBox(width: 8),
                Text(s.open_debug_log_panel),
              ],
            ),
          ),
          PopupMenuItem(
            value: 4,
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.satellite, size: 14),
                const SizedBox(width: 8),
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
    final theme = Theme.of(context);
    final s = S.of(context);
    final isEmpty = ref.watch(P.msg.list.select((v) => v.isEmpty));
    final currentConversationId = ref.watch(P.msg.msgNode.select((v) => v.createAtInUS));
    final guideConversationId = ref.watch(P.chat.newConversationGuideConversationId);
    final showGuide = !isEmpty && guideConversationId == currentConversationId;
    final iconColor = showGuide ? theme.colorScheme.primary : null;

    final Widget icon = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.add_comment_outlined, color: iconColor),
        if (showGuide)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: .circular(999),
              ),
            ),
          ),
      ],
    );

    return Tooltip(
      message: showGuide ? s.conversation_token_limit_recommend_new_chat : s.start_a_new_chat,
      child: IconButton(
        onPressed: !isEmpty
            ? () {
                if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;
                if (showGuide) P.chat.dismissNewConversationGuide();
                P.chat.startNewChat();
              }
            : null,
        icon: icon,
      ),
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
      title: Text(sprintf(s.x_message_selected, [selected.length]), style: const TS(s: 18)),
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
          child: Text(s.all),
        ),
      ],
    );
  }
}
