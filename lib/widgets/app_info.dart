// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:zone/config.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/route/method.dart';
import 'package:zone/state/p.dart';

// TODO: @wangce move it to pages/panel
class AppInfo extends ConsumerWidget {
  static final _shown = qs(false);

  static Future<void> show(BuildContext context) async {
    qqq(_shown.q);
    if (_shown.q) return;
    _shown.q = true;
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
          builder: (BuildContext context, ScrollController scrollController) {
            return AppInfo(scrollController: scrollController);
          },
        );
      },
    );
    _shown.q = false;
  }

  final ScrollController? scrollController;

  const AppInfo({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final paddingBottom = ref.watch(P.app.quantizedIntPaddingBottom);
    final demoType = ref.watch(P.app.demoType);
    final iconPath = "assets/img/${demoType.name}/icon.png";
    final version = ref.watch(P.app.version);
    final buildNumber = ref.watch(P.app.buildNumber);

    final iconWidget = SB(
      width: 64,
      height: 64,
      child: ClipRRect(
        borderRadius: 12.r,
        child: Image.asset(iconPath),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: 16.r,
        child: ListView(
          shrinkWrap: true,
          controller: scrollController,
          children: [
            12.h,
            Row(
              mainAxisAlignment: MAA.end,
              children: [
                IconButton(
                  onPressed: () {
                    pop();
                  },
                  icon: const Icon(Icons.close),
                ),
                12.w,
              ],
            ),
            12.h,
            Row(
              mainAxisAlignment: MAA.center,
              children: [iconWidget],
            ),
            16.h,
            const Row(
              mainAxisAlignment: MAA.center,
              children: [
                T(
                  Config.appTitle,
                  s: TS(s: 24),
                ),
              ],
            ),
            4.h,
            Row(
              mainAxisAlignment: MAA.center,
              children: [
                T(
                  version,
                  s: const TS(s: 12),
                ),
                T(
                  " ($buildNumber)",
                  s: const TS(s: 12),
                ),
              ],
            ),
            16.h,
            const Row(
              mainAxisAlignment: MAA.center,
              children: [
                T(
                  "Join the community",
                  s: TS(s: 16, w: FontWeight.bold),
                ),
              ],
            ),
            16.h,
            Column(
              children: [
                _buildCommunityLink(
                  icon: Icons.chat,
                  title: "QQ group 1",
                  subtitle: "应用内测群: 332381861",
                  onTap: _openQQGroup1,
                ),
                _buildCommunityLink(
                  icon: Icons.chat,
                  title: "QQ group 2",
                  subtitle: "技术研发群: 325154699",
                  onTap: _openQQGroup2,
                ),
                _buildCommunityLink(
                  icon: Icons.discord,
                  title: s.discord,
                  subtitle: s.join_our_discord_server,
                  onTap: _openDiscord,
                ),
                _buildCommunityLink(
                  icon: Icons.flutter_dash,
                  title: "Twitter",
                  subtitle: "@BlinkDL_AI",
                  onTap: _openTwitter,
                ),
              ],
            ),
            12.h,
            TextButton(
              onPressed: _openFeedback,
              child: T(
                s.feedback,
              ),
            ),
            12.h,
            TextButton(
              onPressed: () => _showLicensePage(context, version, buildNumber, iconWidget),
              child: T(
                s.license,
              ),
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
      applicationIcon: C(
        margin: const EI.o(t: 12, b: 12),
        child: iconWidget,
      ),
      useRootNavigator: true,
    );
  }

  Widget _buildCommunityLink({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          6.h,
          Row(
            children: [
              16.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CAA.start,
                  children: [
                    T(title, s: const TS(s: 14, w: FontWeight.bold)),
                    4.h,
                    T(subtitle, s: const TS(s: 12, c: Colors.grey)),
                  ],
                ),
              ),
              8.w,
              const Icon(Icons.arrow_forward_ios, size: 16),
              16.w,
            ],
          ),
          6.h,
        ],
      ),
    );
  }
}
