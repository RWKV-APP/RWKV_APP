// Dart imports:
import 'dart:io';
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/app_presentation.dart';
import 'package:zone/page/layout/themed_launcher.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/measure_size.dart';

class PageHome extends ConsumerWidget {
  const PageHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = ref.watch(P.app.screenWidth);
    final height = ref.watch(P.app.screenHeight);
    final paddingTop = ref.watch(P.app.paddingTop);
    final paddingBottom = ref.watch(P.app.paddingBottom);
    final appTheme = ref.watch(P.app.theme);
    final style = ref.watch(P.preference.appStyle);
    final presentation = AppPresentation.forStyle(style);
    final isDesktop = ref.watch(P.app.isDesktop);
    final showAlbatross = ref.watch(P.albatrossRuntime.canShowHomeEntry);
    final features = [
      const _CompletionButton(),
      if (isDesktop) const _WebDemoButton(),
      const _VisualButton(),
      const _TTSButton(),
      const _RolePlayButton(),
      const _TranslatorButton(),
      const _NekoButton(),
    ];
    final utilities = [
      const _BenchmarkButton(),
      if (isDesktop || Platform.isAndroid) const _ApiServerButton(),
      if (showAlbatross) const _AlbatrossButton(),
    ];
    if (presentation != null) {
      return ThemedLauncher(
        presentation: presentation,
        style: style,
        chat: const _ChatButton(),
        features: features,
        utilities: utilities,
      );
    }

    final tabBarHeight = appTheme.tabBarHeight;
    final ratio = width / height;

    late final int crossAxisCount;

    if (ratio > 1.2 && width > 1024) {
      crossAxisCount = 4;
    } else if (ratio < 1.0 && width < 900) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }

    final isLandscape = ratio > 1;
    double maxWidth = width / crossAxisCount - (isLandscape ? 60 : 24);
    final containerPaddingTop = 300 - paddingTop;
    final containerPaddingHorizontal = crossAxisCount == 3 ? 24.0 : 12.0;

    if (maxWidth < 0) maxWidth = .infinity;

    final widgets = [const _ChatButton(), ...features, ...utilities];
    final grid = MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: style.gap,
      crossAxisSpacing: style.gap,
      itemBuilder: (context, index) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: widgets[index],
        );
      },
      itemCount: widgets.length,
    );

    return Scaffold(
      backgroundColor: appTheme.settingBg,
      body: Stack(
        children: [
          const _Welcome(),
          Positioned.fill(
            child: SingleChildScrollView(
              controller: P.ui.homeController,
              padding: .only(
                top: containerPaddingTop,
                left: containerPaddingHorizontal,
                right: containerPaddingHorizontal,
                bottom: max(paddingBottom, 12) + tabBarHeight + 12,
              ),
              physics: const BouncingScrollPhysics(),
              child: grid,
            ),
          ),
          const _NoMore(),
        ],
      ),
    );
  }
}

class _NoMore extends ConsumerWidget {
  const _NoMore();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final pixelsFromBottom = ref.watch(P.ui.homePixelsFromBottom);

    final paddingBottom = ref.watch(P.app.paddingBottom);
    final tabBarHeight = ref.watch(P.app.theme).tabBarHeight;

    double opacity = (-10 - pixelsFromBottom) / 40;
    if (opacity < 0) opacity = 0;
    if (opacity > 1) opacity = 1;
    opacity = opacity * 0.5;

    final bottomOffset = -25 + (-10 - pixelsFromBottom) / 40 * 15;

    return Positioned(
      bottom: bottomOffset + paddingBottom + tabBarHeight,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: opacity,
            child: Text("- " + s.reached_bottom + " -"),
          ),
        ),
      ),
    );
  }
}

const _homeCardTitleTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: .bold,
  height: 1.375,
);

const _homeCardDescriptionTextStyle = TextStyle(
  fontSize: 12,
  height: 1.375,
);

class _HomeCard extends ConsumerWidget {
  final VoidCallback onTap;
  final Color color;
  final Widget icon;
  final String title;
  final String description;
  final String heightsKey;

  const _HomeCard({
    required this.heightsKey,
    required this.onTap,
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final style = ref.watch(P.preference.appStyle);
    final arrangement = AppPresentation.forStyle(style)?.launcher;
    if (arrangement != null) {
      final primary = heightsKey == 'chat';
      final row = switch (arrangement) {
        .editorial || .ledger || .console || .directory => true,
        _ => primary,
      };
      final flat = arrangement == .console || arrangement == .directory;
      final featured = primary && !flat;
      final center = style.centered && !row;
      final ink = featured ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
      final corners = BorderRadius.circular(style.radius);
      final badge = Container(
        width: flat ? 34 : 44,
        height: flat ? 34 : 44,
        alignment: .center,
        decoration: style
            .box(
              appTheme,
              .circular(style.centered ? 22 : style.radius),
              fill: featured ? theme.colorScheme.onPrimary.withValues(alpha: .16) : appTheme.primary,
            )
            .copyWith(boxShadow: const []),
        child: IconTheme(
          data: const IconThemeData(size: 20),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(featured ? ink : theme.colorScheme.onPrimary, BlendMode.srcIn),
            child: icon,
          ),
        ),
      );
      final label = Column(
        crossAxisAlignment: center ? .center : .start,
        children: [
          Text(
            title,
            style: (featured ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(color: ink),
            textAlign: center ? .center : .start,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(color: featured ? ink : appTheme.qb6),
            textAlign: center ? .center : .start,
          ),
        ],
      );
      return DecoratedBox(
        decoration: flat
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: appTheme.qb12)),
              )
            : style.box(appTheme, corners, fill: featured ? appTheme.primary : null),
        child: Material(
          type: .transparency,
          child: InkWell(
            borderRadius: corners,
            onTap: onTap,
            child: Padding(
              padding: .all(featured ? 18 : style.rowInset),
              child: row
                  ? Row(
                      children: [
                        badge,
                        SizedBox(width: style.gap),
                        Expanded(child: label),
                        if (featured || flat) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 17, color: ink),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: center ? .center : .start,
                      children: [
                        badge,
                        SizedBox(height: style.gap),
                        label,
                      ],
                    ),
            ),
          ),
        ),
      );
    }
    final maxHeightOfTitle = ref.watch(P.ui.maxHeightsOfHomeItemTitle);
    final maxHeightOfDescription = ref.watch(P.ui.maxHeightsOfHomeItemDescription);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.settingItem,
          borderRadius: .circular(12),
        ),
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .center,
          children: [
            Align(
              alignment: .center,
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: .circle,
                ),
                alignment: .center,
                child: icon,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: maxHeightOfTitle ?? 0,
              ),
              child: Center(
                child: MeasureSize(
                  onChange: (size) {
                    P.ui.homeItemTitleHeights.q = {
                      ...P.ui.homeItemTitleHeights.q,
                      heightsKey: size.height,
                    };
                  },
                  child: Text(
                    title,
                    style: _homeCardTitleTextStyle.copyWith(color: theme.colorScheme.onSurface),
                    textAlign: .center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: maxHeightOfDescription ?? 0,
              ),
              child: Center(
                child: MeasureSize(
                  onChange: (size) {
                    P.ui.homeItemDescriptionHeights.q = {
                      ...P.ui.homeItemDescriptionHeights.q,
                      heightsKey: size.height,
                    };
                  },
                  child: Text(
                    description,
                    style: _homeCardDescriptionTextStyle.copyWith(color: appTheme.qb6),
                    textAlign: .center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _ChatButton extends ConsumerWidget {
  const _ChatButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return _HomeCard(
      heightsKey: 'chat',
      onTap: () {
        P.albatrossRuntime.disableExternalMode();
        P.chat.startNewChat();
        push(.chat);
      },
      color: Colors.blueAccent,
      icon: const FaIcon(FontAwesomeIcons.comments, color: Colors.white),
      title: s.chat,
      description: s.chat_with_rwkv_model,
    );
  }
}

class _AlbatrossButton extends ConsumerWidget {
  const _AlbatrossButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final iconFillColor = appTheme.isLight ? theme.colorScheme.primary : appTheme.qb15;
    final iconBorder = appTheme.isLight ? null : Border.all(color: Colors.white, width: 1);

    return _HomeCard(
      heightsKey: 'albatrossChat',
      onTap: () {
        push(.albatross);
      },
      color: iconFillColor,
      icon: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          shape: .circle,
          border: iconBorder,
        ),
        alignment: .center,
        child: const Icon(Icons.bolt, color: Colors.white),
      ),
      title: s.albatross_chat,
      description: s.albatross_chat_description,
    );
  }
}

class _WebDemoButton extends ConsumerWidget {
  const _WebDemoButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final _ = theme;

    return _HomeCard(
      heightsKey: 'webDemo',
      onTap: () {
        P.chat.startNewChat();
        push(.webDemo);
      },
      color: Colors.indigoAccent,
      icon: const Icon(Icons.web_asset_rounded, color: Colors.white),
      title: "Web Demo",
      description: "Generate and preview HTML pages with RWKV",
    );
  }
}

class _TTSButton extends ConsumerWidget {
  const _TTSButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return _HomeCard(
      heightsKey: 'tts',
      onTap: () {
        P.chat.startNewChat();
        push(.talk);
      },
      color: Colors.orange,
      icon: const Icon(
        Icons.record_voice_over,
        color: Colors.white,
      ),
      title: s.tts,
      description: s.tts_detail,
    );
  }
}

class _VisualButton extends ConsumerWidget {
  const _VisualButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return _HomeCard(
      heightsKey: 'see',
      onTap: () {
        push(.see);
      },
      color: Colors.deepPurpleAccent,
      icon: const Icon(Icons.visibility, color: Colors.white),
      title: s.see,
      description: s.visual_understanding_and_ocr,
    );
  }
}

class _NekoButton extends ConsumerWidget {
  const _NekoButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return _HomeCard(
      heightsKey: 'neko',
      onTap: _onTap,
      color: Colors.pinkAccent,
      icon: const FaIcon(FontAwesomeIcons.cat, color: Colors.white),
      title: s.neko,
      description: s.nyan_nyan,
    );
  }

  Future<void> _onTap() async {
    P.chat.startNewChat();
    push(.neko);
  }
}

class _CompletionButton extends ConsumerWidget {
  const _CompletionButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return _HomeCard(
      heightsKey: 'completion',
      onTap: () {
        push(.completion);
      },
      color: Colors.lightGreen,
      icon: const FaIcon(FontAwesomeIcons.feather, color: Colors.white),
      title: s.completion_mode,
      description: s.text_completion_mode,
    );
  }
}

class _TranslatorButton extends ConsumerWidget {
  const _TranslatorButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final isDesktop = ref.watch(P.app.isDesktop);

    return _HomeCard(
      heightsKey: 'translator',
      onTap: () {
        if (isDesktop) push(.translator);
        if (!isDesktop) push(.ocr);
      },
      color: Colors.blue,
      icon: const Icon(Icons.translate, color: Colors.white),
      title: s.offline_translator,
      description: s.offline_translator_detail,
    );
  }
}

class _BenchmarkButton extends ConsumerWidget {
  const _BenchmarkButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return _HomeCard(
      heightsKey: 'benchmark',
      onTap: () {
        push(.benchmark);
      },
      color: Colors.purple,
      icon: const FaIcon(FontAwesomeIcons.gauge, color: Colors.white),
      title: s.performance_test,
      description: s.performance_test_description,
    );
  }
}

class _RolePlayButton extends ConsumerWidget {
  const _RolePlayButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return _HomeCard(
      heightsKey: 'rolePlaying',
      onTap: () {
        push(.rolePlaying);
      },
      color: Colors.yellow,
      icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white),
      title: s.role_play,
      description: s.role_play_intro,
    );
  }
}

class _ApiServerButton extends ConsumerWidget {
  const _ApiServerButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return _HomeCard(
      heightsKey: 'apiServer',
      onTap: () {
        push(.apiServer);
      },
      color: Colors.teal,
      icon: const FaIcon(FontAwesomeIcons.server, color: Colors.white, size: 20),
      title: s.api_server,
      description: s.api_server_description,
    );
  }
}

class _Welcome extends ConsumerWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final version = ref.watch(P.app.version);
    final appTheme = ref.watch(P.app.theme);
    final s = S.of(context);
    final pixels = ref.watch(P.ui.homePixels);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final iconCacheSize = (80 * devicePixelRatio).ceil();
    double opacity = 1 - pixels / 150 + 0.5;

    if (opacity < 0) opacity = 0;
    if (opacity > 1) opacity = 1;
    return Positioned(
      top: -pixels / 1.5,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: opacity,
        child: Column(
          children: [
            SizedBox(height: 100 + (1 - opacity) * 25),
            Center(
              child: ClipRRect(
                borderRadius: .circular(80 / 4),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/img/chat/icon.png',
                  height: 80,
                  width: 80,
                  cacheHeight: iconCacheSize,
                  cacheWidth: iconCacheSize,
                ),
              ),
            ),
            SizedBox(height: 24 * opacity),
            Text(
              s.welcome_to_rwkv_chat,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 24 * pow(opacity, 0.1).toDouble(),
                fontWeight: .bold,
              ),
              textAlign: .center,
            ),
            SizedBox(height: 12 * opacity),
            Text(
              version,
              style: TextStyle(fontSize: 14 * pow(opacity, 0.1).toDouble(), color: appTheme.qb6),
              textAlign: .center,
            ),
            SizedBox(height: 100 * opacity),
          ],
        ),
      ),
    );
  }
}
