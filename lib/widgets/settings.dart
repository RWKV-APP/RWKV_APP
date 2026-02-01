// ignore: unused_import
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/router.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/dev_options_dialog.dart';
import 'package:zone/widgets/form_item.dart';
import 'package:zone/page/weight_manager.dart';

class Settings extends ConsumerWidget {
  static final _shown = qs(false);

  static String _getTotalUsage(WidgetRef ref) {
    final chatWeights = P.remote.chatWeights.q;
    final ttsWeights = P.remote.ttsWeights.q;
    final roleplayWeights = P.remote.roleplayWeights.q;
    final seeWeights = P.remote.seeWeights.q;
    final sudokuWeights = P.remote.sudokuWeights.q;
    final othelloWeights = P.remote.othelloWeights.q;

    final allWeights = [
      ...chatWeights,
      ...ttsWeights,
      ...roleplayWeights,
      ...seeWeights,
      ...sudokuWeights,
      ...othelloWeights,
    ];

    final totalBytes = WeightManagerUtils.calculateTotalUsage(allWeights, ref);
    return WeightManagerUtils.formatBytes(totalBytes);
  }

  static Future<void> show() async {
    qq;
    if (_shown.q) return;
    _shown.q = true;
    final context = getContext();
    if (context == null || !context.mounted) {
      _shown.q = false;
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: .75,
          maxChildSize: .85,
          minChildSize: .5,
          expand: false,
          snap: false,
          builder: (context, scrollController) {
            return Settings(scrollController: scrollController, noBorderRadiusAndAppBar: false);
          },
        );
      },
    );
    _shown.q = false;
  }

  final ScrollController? scrollController;

  final bool noBorderRadiusAndAppBar;

  const Settings({
    super.key,
    this.scrollController,
    required this.noBorderRadiusAndAppBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final paddingTop = ref.watch(P.app.paddingTop);
    final demoType = ref.watch(P.app.demoType);
    final iconPath = "assets/img/chat/icon.png";
    final version = ref.watch(P.app.version);
    final buildNumber = ref.watch(P.app.buildNumber);
    final preferredTextScaleFactor = ref.watch(P.preference.preferredTextScaleFactor);
    final userType = ref.watch(P.preference.userType);
    final preferredLanguage = ref.watch(P.preference.preferredLanguage);
    final paddingLeft = ref.watch(P.app.paddingLeft);
    final qb = ref.watch(P.app.qb);
    final customTheme = ref.watch(P.app.customTheme);
    final isLightMode = customTheme.light;
    final preferredThemeMode = ref.watch(P.app.preferredThemeMode);
    final isChat = demoType == .chat;
    final checkingLatestVersion = ref.watch(P.app.checkingLatestVersion);

    final totalUsage = _getTotalUsage(ref);

    final iconWidget = SizedBox(
      width: 64,
      height: 64,
      child: ClipRRect(
        borderRadius: 12.r,
        child: WithDevOption(child: Image.asset(iconPath)),
      ),
    );

    return ClipRRect(
      borderRadius: noBorderRadiusAndAppBar
          ? .zero
          : const .only(
              topLeft: .circular(16),
              topRight: .circular(16),
            ),
      child: Scaffold(
        backgroundColor: demoType == .chat ? Colors.transparent : customTheme.setting,
        appBar: noBorderRadiusAndAppBar
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                title: Text(s.settings),
                centerTitle: false,
                backgroundColor: customTheme.setting,
                actions: [
                  Padding(
                    padding: const .only(right: 8),
                    child: IconButton(
                      onPressed: () {
                        pop();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
        body: ListView(
          padding: .only(left: 12 + paddingLeft, top: paddingTop, right: 12, bottom: math.max(paddingBottom, 12)),
          controller: scrollController,
          children: [
            if (isChat) const SizedBox(height: 40),
            Row(
              mainAxisAlignment: .center,
              children: [iconWidget],
            ),
            16.h,
            const Row(
              mainAxisAlignment: .center,
              children: [
                Expanded(
                  child: Text(
                    Config.appTitle,
                    style: TS(s: 24),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            4.h,
            Row(
              mainAxisAlignment: .center,
              children: [
                Text(version, style: const TS(s: 12)),
                Text(" ($buildNumber)", style: const TS(s: 12)),
              ],
            ),
            16.h,
            Row(
              mainAxisAlignment: .start,
              children: [
                Expanded(
                  child: Text(
                    s.application_settings,
                    style: TS(w: .w500, c: qb.q(.8), s: 12),
                  ),
                ),
              ],
            ),
            8.h,
            FormItem(
              isSectionStart: true,
              icon: Icon(Icons.manage_accounts, color: qb.q(.667), size: 16),
              title: s.application_mode,
              infoText: userType.displayName(),
              onTap: P.preference.showUserTypeDialog,
            ),
            FormItem(
              icon: Icon(Icons.format_size_outlined, color: qb.q(.667), size: 16),
              title: s.font_setting,
              infoText: "${P.preference.textScalePairs[preferredTextScaleFactor]}",
              onTap: P.preference.goToFontSettings,
            ),
            FormItem(
              icon: Icon(Icons.language_outlined, color: qb.q(.667), size: 16),
              title: s.application_language,
              infoText: preferredLanguage.display ?? s.follow_system,
              onTap: P.preference.showLocaleDialog,
            ),
            if (isChat && userType.isGreaterThan(.user))
              FormItem(
                icon: Icon(Icons.settings_applications, color: qb.q(.667), size: 16),
                title: S.current.advance_settings,
                onTap: () => push(.advancedSettings),
              ),
            FormItem(
              isSectionEnd: false,
              icon: Icon(isLightMode ? Icons.light_mode : Icons.dark_mode, color: qb.q(.667), size: 16),
              title: s.appearance,
              infoText: preferredThemeMode.displayName,
              onTap: P.preference.showThemeSettings,
            ),
            FormItem(
              isSectionEnd: true,
              icon: Icon(Icons.storage, color: qb.q(.667), size: 16),
              title: s.weights_mangement,
              infoText: totalUsage,
              onTap: () => push(.weightManager),
            ),
            12.h,
            Row(
              mainAxisAlignment: .start,
              children: [
                Expanded(
                  child: Text(
                    s.join_the_community,
                    style: TS(w: .w500, c: qb.q(.8), s: 12),
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
              mainAxisAlignment: .start,
              children: [
                Text(
                  s.about,
                  style: TS(w: .w500, c: qb.q(.8), s: 12),
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
            FormItem(
              title: S.current.check_for_updates,
              trailing: Row(
                children: [
                  Text("$version($buildNumber)"),
                  AnimatedSize(
                    duration: 200.ms,
                    curve: Curves.easeOutCubic,
                    child: Row(
                      mainAxisSize: .min,
                      children: [
                        if (checkingLatestVersion) 8.w,
                        if (checkingLatestVersion)
                          const SB(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              icon: Icon(Icons.update, color: qb.q(.667), size: 16),
              onTap: () => P.app.checkUpdates(manually: true),
            ),
            FormItem(
              title: s.github_repository,
              icon: Icon(Icons.code, color: qb.q(.667), size: 16),
              onTap: () => launchUrlString("https://github.com/RWKV-APP/RWKV_APP", mode: LaunchMode.externalApplication),
            ),
            FormItem(
              title: s.report_an_issue_on_github,
              icon: Icon(Icons.bug_report, color: qb.q(.667), size: 16),
              onTap: () => launchUrlString("https://github.com/RWKV-APP/RWKV_APP/issues/new", mode: LaunchMode.externalApplication),
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
      applicationIcon: Container(
        margin: const .only(top: 12, bottom: 12),
        child: iconWidget,
      ),
      useRootNavigator: true,
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
