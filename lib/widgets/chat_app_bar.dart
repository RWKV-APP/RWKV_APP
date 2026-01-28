// ignore: unused_import
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:remix_icons_flutter/remixicon_ids.dart';
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

const String _chatAi3LineSvg = r'''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M12 1.99996C12.8632 1.99996 13.701 2.10973 14.5 2.31539L14 4.25192C13.3608 4.0874 12.6906 3.99997 12 3.99997C7.58174 3.99997 4.00002 7.58172 4 12C4 13.3344 4.3255 14.6174 4.93945 15.7656L5.28906 16.4189L4.63379 19.3662L7.58105 18.7109L8.23438 19.0605C9.38255 19.6745 10.6656 20 12 20C16.4183 20 20 16.4183 20 12C20 11.6771 19.9805 11.3587 19.9434 11.0459L21.9297 10.8095C21.976 11.1999 22 11.5972 22 12C22 17.5228 17.5228 22 12 22C10.2975 22 8.69425 21.5746 7.29102 20.8242L2 22L3.17578 16.709C2.42541 15.3057 2 13.7025 2 12C2.00002 6.47714 6.47717 1.99996 12 1.99996ZM19.5293 1.3193C19.7058 0.893513 20.2942 0.8935 20.4707 1.3193L20.7236 1.93063C21.1555 2.97343 21.9615 3.80614 22.9746 4.2568L23.6914 4.57614C24.1022 4.75882 24.1022 5.35635 23.6914 5.53903L22.9326 5.87692C21.945 6.3162 21.1534 7.11943 20.7139 8.1279L20.4668 8.69333C20.2863 9.10747 19.7136 9.10747 19.5332 8.69333L19.2861 8.1279C18.8466 7.11942 18.0551 6.3162 17.0674 5.87692L16.3076 5.53903C15.8974 5.35618 15.8974 4.75895 16.3076 4.57614L17.0254 4.2568C18.0384 3.80614 18.8445 2.97343 19.2764 1.93063L19.5293 1.3193Z"></path></svg>
''';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pure white/dark background for app bar
    Color backgroundColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    // Light separator line color
    final separatorColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: customTheme.light ? P.app.systemOverlayStyleLight : P.app.systemOverlayStyleDark,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black), // Black/white icons
          title: GestureDetector(
        onTap: _onTitlePressed,
        child: Container(
          decoration: BoxDecoration(color: Colors.transparent),
          child: Column(
            crossAxisAlignment: .center,
            children: [
              if (isChat)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: .min,
                      crossAxisAlignment: .end,
                      children: [
                        T(
                          displayName,
                          s: const TextStyle(fontSize: 16, fontWeight: .w600),
                        ),
                        Padding(
                          padding: const .only(left: 4, bottom: 1),
                          child: T(
                            version,
                            s: TS(s: 10, c: qb.q(0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
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
      // leading: IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
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
    ),
    // Separator line at the bottom of app bar
    Container(
      height: 0.5,
      color: separatorColor,
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

    return SizedBox(
      width: 40,
      child: PopupMenuButton(
        padding: EdgeInsets.zero,
        icon: const Icon(RemixIcon.moreLine, size: 22),
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
                const Icon(RemixIcon.toolsLine, size: 16),
                8.w,
                Text(s.advance_settings),
              ],
            ),
          ),
          PopupMenuItem(
            value: 2,
            child: Row(
              children: [
                const Icon(RemixIcon.equalizerLine, size: 16),
                8.w,
                Text(s.session_configuration),
              ],
            ),
          ),
          PopupMenuItem(
            value: 3,
            child: Row(
              children: [
                const Icon(RemixIcon.fileTextLine, size: 16),
                8.w,
                Text(s.open_debug_log_panel),
              ],
            ),
          ),
          PopupMenuItem(
            value: 4,
            child: Row(
              children: [
                const Icon(RemixIcon.radarLine, size: 16),
                8.w,
                Text(s.open_state_panel),
              ],
            ),
          ),
        ];
      },
    ),
    );
  }
}

class _NewConversationButton extends ConsumerWidget {
  final DemoType preferredDemoType;

  const _NewConversationButton({required this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    late final Widget icon;

    icon = Builder(
      builder: (context) {
        final iconTheme = IconTheme.of(context);
        final color = iconTheme.color ?? Colors.black;
        return SvgPicture.string(
          _chatAi3LineSvg,
          width: 22,
          height: 22,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      },
    );
    final isEmpty = ref.watch(P.msg.list.select((v) => v.isEmpty));

    return SizedBox(
      width: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: !isEmpty
            ? () {
                if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;
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
