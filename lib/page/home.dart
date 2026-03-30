// Dart imports:
import 'dart:io';
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/router/method.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/model_selector.dart';

class PageHome extends ConsumerWidget {
  const PageHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = ref.watch(P.app.screenWidth);
    final height = ref.watch(P.app.screenHeight);
    final paddingTop = ref.watch(P.app.paddingTop);
    final paddingBottom = ref.watch(P.app.paddingBottom);
    final appTheme = ref.watch(P.app.theme);
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

    final isDesktop = ref.watch(P.app.isDesktop);
    final showApiServer = isDesktop || Platform.isAndroid;

    final widgets = [
      const _ChatButton(),
      const _CompletionButton(),
      const _VisualButton(),
      const _TTSButton(),
      const _RolePlayButton(),
      const _TranslatorButton(),
      const _NekoButton(),
      const _BenchmarkButton(),
      if (showApiServer) const _ApiServerButton(),
    ];

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
              child: MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemBuilder: (context, index) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: widgets[index],
                  );
                },
                itemCount: widgets.length,
              ),
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
  color: Colors.grey,
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
    final appTheme = ref.watch(P.app.theme);
    final maxHeightOfTitle = ref.watch(P.ui.maxHeightsOfHomeItemTitle);
    final maxHeightOfDescription = ref.watch(P.ui.maxHeightsOfHomeItemDescription);
    return GD(
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
                    style: _homeCardTitleTextStyle,
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
                    style: _homeCardDescriptionTextStyle,
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
      onTap: () => _onTap(context),
      color: Colors.pinkAccent,
      icon: const FaIcon(FontAwesomeIcons.cat, color: Colors.white),
      title: s.neko,
      description: s.nyan_nyan,
    );
  }

  Future<void> _onTap(BuildContext context) async {
    final current = P.rwkv.latestModel.q;
    if (current == null || !current.isNeko) {
      final nekoList = P.remote.getNekoModel();
      final downloaded = nekoList.where((e) => P.remote.locals(e).q.hasFile).toList();
      if (downloaded.isNotEmpty) {
        final loaded = await _ModelLoadingDialog.show(context, downloaded.first);
        if (!loaded) return;
      } else if (nekoList.isNotEmpty) {
        Alert.warning(S.current.chat_you_need_download_model_if_you_want_to_use_it);
        ModelSelector.show(showNeko: true);
        return;
      } else {
        Alert.error('Neko is not available');
        return;
      }
    }
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

class _ModelLoadingDialog extends StatefulWidget {
  final FileInfo file;

  const _ModelLoadingDialog({required this.file});

  static Future<bool> show(BuildContext context, FileInfo file) async {
    final r = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ModelLoadingDialog(file: file),
    );
    return r ?? false;
  }

  @override
  State<_ModelLoadingDialog> createState() => _ModelLoadingDialogState();
}

class _ModelLoadingDialogState extends State<_ModelLoadingDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await P.rwkv.loadChat(fileInfo: widget.file).timeout(const Duration(seconds: 10));
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        qqe('load model failed: $e');
        if (mounted) Navigator.pop(context, false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        borderRadius: .circular(16),
        child: Padding(
          padding: const .symmetric(horizontal: 36, vertical: 24),
          child: Column(
            mainAxisSize: .min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(S.current.model_loading),
            ],
          ),
        ),
      ),
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
    final version = ref.watch(P.app.version);
    final s = S.of(context);
    final pixels = ref.watch(P.ui.homePixels);
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
                ),
              ),
            ),
            SizedBox(height: 24 * opacity),
            Text(
              s.welcome_to_rwkv_chat,
              style: TextStyle(fontSize: 24 * pow(opacity, 0.1).toDouble(), fontWeight: .bold),
              textAlign: .center,
            ),
            SizedBox(height: 12 * opacity),
            Text(
              version,
              style: TextStyle(fontSize: 14 * pow(opacity, 0.1).toDouble(), color: Colors.grey),
              textAlign: .center,
            ),
            SizedBox(height: 100 * opacity),
          ],
        ),
      ),
    );
  }
}
