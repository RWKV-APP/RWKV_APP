// ignore: unused_import
import 'dart:developer';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/state/p.dart';
import 'package:zone/widgets/form_item.dart';

// TODO: @wangce move it to pages
class Settings extends ConsumerWidget {
  final ScrollController? scrollController;

  const Settings({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final paddingTop = ref.watch(P.app.paddingTop);
    final demoType = ref.watch(P.app.demoType);
    final iconPath = "assets/img/${demoType.name}/icon.png";
    final version = ref.watch(P.app.version);
    final buildNumber = ref.watch(P.app.buildNumber);
    final preferredTextScaleFactor = ref.watch(P.preference.preferredTextScaleFactor);
    final preferredLanguage = ref.watch(P.preference.preferredLanguage);
    final paddingLeft = ref.watch(P.app.paddingLeft);
    final qb = ref.watch(P.app.qb);
    final customTheme = ref.watch(P.app.customTheme);
    final isLightMode = customTheme.light;
    final preferredThemeMode = ref.watch(P.app.preferredThemeMode);

    final iconWidget = SB(
      width: 64,
      height: 64,
      child: ClipRRect(
        borderRadius: 12.r,
        child: Image.asset(iconPath),
      ),
    );

    return Scaffold(
      backgroundColor: customTheme.setting,
      body: ListView(
        padding: EI.o(
          t: paddingTop,
          b: max(paddingBottom, 12),
          l: 12 + paddingLeft,
          r: 12,
        ),
        controller: scrollController,
        children: [
          12.h,
          Row(
            mainAxisAlignment: MAA.center,
            children: [iconWidget],
          ),
          16.h,
          const Row(
            mainAxisAlignment: MAA.center,
            children: [
              Expanded(
                child: T(
                  Config.appTitle,
                  s: TS(s: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          4.h,
          Row(
            mainAxisAlignment: MAA.center,
            children: [
              T(version, s: const TS(s: 12)),
              T(" ($buildNumber)", s: const TS(s: 12)),
            ],
          ),
          16.h,
          Row(
            mainAxisAlignment: MAA.start,
            children: [
              Expanded(
                child: T(
                  s.application_settings,
                  s: TS(w: FW.w500, c: qb.q(.8), s: 12),
                ),
              ),
            ],
          ),
          8.h,
          FormItem(
            isSectionStart: true,
            icon: Icon(Icons.format_size_outlined, color: qb.q(.667), size: 16),
            title: s.font_size,
            info: "${P.preference.textScalePairs[preferredTextScaleFactor]}",
            onTap: P.preference.showTextScaleFactorDialog,
          ),
          FormItem(
            icon: Icon(Icons.language_outlined, color: qb.q(.667), size: 16),
            title: s.application_language,
            info: preferredLanguage.display ?? s.follow_system,
            onTap: P.preference.showLocaleDialog,
          ),
          FormItem(
            isSectionEnd: true,
            icon: Icon(isLightMode ? Icons.light_mode : Icons.dark_mode, color: qb.q(.667), size: 16),
            title: s.appearance,
            info: preferredThemeMode.displayName,
            onTap: P.preference.showThemeSettings,
          ),
          12.h,
          Row(
            mainAxisAlignment: MAA.start,
            children: [
              Expanded(
                child: T(
                  s.join_the_community,
                  s: TS(w: FW.w500, c: qb.q(.8), s: 12),
                ),
              ),
            ],
          ),
          8.h,
          FormItem(
            icon: Icon(Icons.chat_bubble_outline, color: qb.q(.667), size: 16),
            isSectionStart: true,
            title: s.qq_group_1,
            subtitle: "${s.application_internal_test_group}: 332381861",
            onTap: _openQQGroup1,
          ),
          FormItem(
            icon: Icon(Icons.chat_bubble_outline, color: qb.q(.667), size: 16),
            title: s.qq_group_2,
            subtitle: "${s.technical_research_group}: 325154699",
            onTap: _openQQGroup2,
          ),
          FormItem(
            icon: Icon(Icons.chat_bubble_outline, color: qb.q(.667), size: 16),
            title: s.discord,
            subtitle: s.join_our_discord_server,
            onTap: _openDiscord,
          ),
          FormItem(
            isSectionEnd: true,
            icon: Icon(Icons.tag, color: qb.q(.667), size: 16),
            title: s.twitter,
            subtitle: "@BlinkDL_AI",
            onTap: _openTwitter,
          ),
          12.h,
          Row(
            mainAxisAlignment: MAA.start,
            children: [
              T(
                s.about,
                s: TS(w: FW.w500, c: qb.q(.8), s: 12),
              ),
            ],
          ),
          8.h,
          FormItem(
            isSectionStart: true,
            title: s.feedback,
            icon: Icon(Icons.feedback_outlined, color: qb.q(.667), size: 16),
            onTap: _openFeedback,
          ),
          if (demoType == DemoType.world && Platform.isAndroid)
            FormItem(
              isSectionStart: false,
              title: S.current.dump_see_files,
              subtitle: S.current.dump_see_files_subtitle,
              icon: Icon(Icons.bug_report, color: qb.q(.667), size: 16),
              trailing: const _DumpSwitch(),
              onTap: () {
                if (P.preference.dumpping.q == true) {
                  P.dump.stopDump();
                } else {
                  P.dump.startDump();
                }
              },
              showArrow: false,
            ),
          FormItem(
            isSectionEnd: true,
            title: s.license,
            icon: Icon(Icons.contact_page_outlined, color: qb.q(.667), size: 16),
            onTap: () => _showLicensePage(context, version, buildNumber, iconWidget),
          ),
          paddingBottom.h,
        ],
      ),
    );
  }

  void _openQQGroup1() async {
    qq;
    final mqqapiString = "mqqapi://card/show_pslcard?src_type=internal&version=1&uin=332381861&card_type=group";
    if (await canLaunchUrl(Uri.parse(mqqapiString))) {
      launchUrl(Uri.parse(mqqapiString));
    } else {
      launchUrlString("https://qm.qq.com/q/y0gOHcguty", mode: LaunchMode.externalApplication);
    }
  }

  void _openQQGroup2() async {
    final mqqapiString = "mqqapi://card/show_pslcard?src_type=internal&version=1&uin=325154699&card_type=group";
    if (await canLaunchUrl(Uri.parse(mqqapiString))) {
      launchUrl(Uri.parse(mqqapiString));
    } else {
      launchUrlString("https://qm.qq.com/q/YqveLmzFYG", mode: LaunchMode.externalApplication);
    }
  }

  void _openDiscord() {
    launchUrlString("https://discord.gg/8NvyXcAP5W", mode: LaunchMode.externalApplication);
  }

  void _openTwitter() {
    launchUrlString("https://x.com/BlinkDL_AI?mx=2", mode: LaunchMode.externalApplication);
  }

  void _openFeedback() {
    launchUrlString("https://community.rwkv.cn/", mode: LaunchMode.externalApplication);
  }

  void _showLicensePage(
    BuildContext context,
    String version,
    String buildNumber,
    Widget iconWidget,
  ) {
    showLicensePage(
      context: context,
      applicationName: Config.appTitle,
      applicationVersion: "$version ($buildNumber)",
      applicationIcon: C(
        margin: const EI.o(t: 12, b: 12),
        child: iconWidget,
      ),
      useRootNavigator: true,
    );
  }
}

class _DumpSwitch extends ConsumerWidget {
  const _DumpSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dumpping = ref.watch(P.preference.dumpping);
    return SizedBox(
      height: 24,
      child: Switch.adaptive(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        value: dumpping,
        onChanged: (value) async {
          if (value) {
            await P.dump.startDump();
          } else {
            await P.dump.stopDump();
          }
        },
      ),
    );
  }
}

extension _LocalizedThemeMode on ThemeMode {
  String get displayName => switch (this) {
    ThemeMode.light => S.current.light_mode,
    ThemeMode.dark => S.current.dark_mode,
    ThemeMode.system => S.current.follow_system,
  };
}
