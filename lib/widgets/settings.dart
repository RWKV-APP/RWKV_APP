// Dart imports:
import 'dart:math' as math;

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

// Project imports:
import 'package:zone/config.dart';
import 'package:zone/func/format_bytes.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/dev_options_panel.dart';
import 'package:zone/widgets/form_item.dart';

class Settings extends ConsumerWidget {
  final ScrollController? scrollController;

  final bool noBorderRadiusAndAppBar;

  const Settings({
    super.key,
    this.scrollController,
    required this.noBorderRadiusAndAppBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final paddingTop = ref.watch(P.app.paddingTop);
    final iconPath = "assets/img/chat/icon.png";
    final version = ref.watch(P.app.version);
    final buildNumber = ref.watch(P.app.buildNumber);
    final commitId = ref.watch(P.rwkvBackend.commitId);
    final normalizedCommitId = commitId.trim();
    final shortCommitId = normalizedCommitId.length > 7 ? normalizedCommitId.substring(0, 7) : normalizedCommitId;
    final preferredTextScaleFactor = ref.watch(P.preference.preferredTextScaleFactor);
    final userType = ref.watch(P.preference.userType);
    final preferredLanguage = ref.watch(P.preference.preferredLanguage);
    final paddingLeft = ref.watch(P.app.paddingLeft);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final isLightMode = appTheme.isLight;
    final preferredThemeMode = ref.watch(P.app.preferredThemeMode);
    final checkingLatestVersion = ref.watch(P.app.checkingLatestVersion);
    final tabBarHeight = appTheme.tabBarHeight;

    final totalUsage = formatBytes(ref.watch(P.remote.totalSizeInModelsDir));

    final iconWidget = SizedBox(
      width: 64,
      height: 64,
      child: ClipRRect(
        borderRadius: .circular(12),
        child: DevOptionsPanel.trigger(child: Image.asset(iconPath)),
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
        backgroundColor: appTheme.settingBg,
        appBar: noBorderRadiusAndAppBar
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                title: Text(s.settings),
                centerTitle: false,
                backgroundColor: appTheme.settingBg,
                actions: [
                  Padding(
                    padding: const .only(right: 8),
                    child: IconButton(
                      onPressed: () {
                        pop();
                      },
                      style: theme.iconButtonTheme.style,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
        body: ListView(
          padding: .only(
            left: 12 + paddingLeft,
            top: paddingTop + 12,
            right: 12,
            bottom: math.max(paddingBottom, 12) + tabBarHeight + 12,
          ),
          controller: scrollController,
          children: [
            Row(
              mainAxisAlignment: .center,
              children: [iconWidget],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: .center,
              children: [
                Expanded(
                  child: Text(
                    Config.appTitle,
                    style: TS(s: 24, w: .w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Opacity(
              opacity: appTheme.settingVersionOpacity,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: .center,
                    children: [
                      Text(version, style: const TS(s: 12)),
                      Text(" ($buildNumber)", style: const TS(s: 12)),
                    ],
                  ),
                  if (shortCommitId.isNotEmpty)
                    Tooltip(
                      message: normalizedCommitId,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openRWKVMobileCommit(normalizedCommitId),
                          child: Container(
                            decoration: const BD(
                              color: kC,
                            ),
                            padding: const EI.a(4),
                            child: Text(
                              s.inference_engine_version(shortCommitId),
                              style: const TS(s: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            appTheme.settingsSectionTitleBottomSpace.h,
            Row(
              mainAxisAlignment: .start,
              children: [
                appTheme.settingsSectionTitleLeftSpace.w,
                Expanded(
                  child: Text(
                    s.application_settings,
                    style: TS(w: .w500, c: qb.q(.8), s: 12),
                  ),
                ),
              ],
            ),
            appTheme.settingsSectionTitleTopSpace.h,
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
            if (userType.isGreaterThan(.user))
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
              icon: Icon(Icons.file_download_outlined, color: qb.q(.667), size: 16),
              title: s.export_data,
              onTap: () => P.dataExport.showExportDataSheet(context),
            ),
            FormItem(
              isSectionEnd: true,
              icon: Icon(Icons.storage, color: qb.q(.667), size: 16),
              title: s.weights_mangement,
              infoText: totalUsage,
              onTap: () => push(.weightManager),
            ),
            appTheme.settingsSectionTitleBottomSpace.h,
            Row(
              mainAxisAlignment: .start,
              children: [
                appTheme.settingsSectionTitleLeftSpace.w,
                Expanded(
                  child: Text(
                    s.join_the_community,
                    style: TS(w: .w500, c: qb.q(.8), s: 12),
                  ),
                ),
              ],
            ),
            appTheme.settingsSectionTitleTopSpace.h,
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
            if (kDebugMode)
              FormItem(
                icon: Icon(Icons.chat_bubble_outline, color: qb.q(.667), size: 16),
                title: "Test Page",
                subtitle: "Test Page",
                onTap: _onTestPageClicked,
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
            appTheme.settingsSectionTitleBottomSpace.h,
            Row(
              mainAxisAlignment: .start,
              children: [
                appTheme.settingsSectionTitleLeftSpace.w,
                Expanded(
                  child: Text(
                    s.about,
                    style: TS(w: .w500, c: qb.q(.8), s: 12),
                  ),
                ),
              ],
            ),
            appTheme.settingsSectionTitleTopSpace.h,
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
                        if (checkingLatestVersion) const SizedBox(width: 8),
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

  void _onTestPageClicked() async {
    qq;
    push(PageKey.test);
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

  void _openRWKVMobileCommit(String commitId) {
    if (commitId.isEmpty) return;
    launchUrlString(
      "https://github.com/MollySophia/rwkv-mobile/commit/$commitId".replaceAll("-dirty", ""),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _showLicensePage(
    BuildContext context,
    String version,
    String buildNumber,
    Widget iconWidget,
  ) async {
    final locale = P.preference.preferredLanguage.q.resolved.locale;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return LicensePage(
            applicationName: Config.appTitle,
            applicationVersion: "$version ($buildNumber)",
            applicationIcon: Container(
              margin: const .only(top: 12, bottom: 12),
              child: iconWidget,
            ),
          );
        },
      ),
    );
    if (!context.mounted) return;
    await S.load(locale);
  }
}

extension _LocalizedThemeMode on ThemeMode {
  String get displayName => switch (this) {
    ThemeMode.light => S.current.light_mode,
    ThemeMode.dark => S.current.dark_mode,
    ThemeMode.system => S.current.follow_system,
  };
}
