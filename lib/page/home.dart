import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
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

    final widgets = const [
      _ChatButton(),
      _CompletionButton(),
      _VisualButton(),
      _TTSButton(),
      _RolePlayButton(),
      _TranslatorButton(),
      _NekoButton(),
      _BenchmarkButton(),
    ];

    final appTheme = ref.watch(P.app.theme);

    return Scaffold(
      backgroundColor: appTheme.setting,
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
                bottom: 48,
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
                itemCount: 8,
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

    double opacity = (-10 - pixelsFromBottom) / 40;
    if (opacity < 0) opacity = 0;
    if (opacity > 1) opacity = 1;
    opacity = opacity * 0.5;

    final bottomOffset = -25 + (-10 - pixelsFromBottom) / 40 * 15;

    return Positioned(
      bottom: bottomOffset,
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

class _ChatButton extends ConsumerWidget {
  const _ChatButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return InkWell(
      onTap: () {
        P.chat.startNewChat();
        push(.chat);
      },
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Align(
              alignment: .topLeft,
              child: Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: .circle,
                ),
                alignment: .center,
                child: const FaIcon(FontAwesomeIcons.comments, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(s.chat, style: const TextStyle(fontSize: 16, fontWeight: .bold, height: 1.375)),
            const SizedBox(height: 8),
            Text(s.chat_with_rwkv_model, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.375)),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _TTSButton extends ConsumerWidget {
  const _TTSButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return InkWell(
      onTap: () {
        P.chat.startNewChat();
        push(.talk);
      },
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: .centerLeft,
                child: Container(
                  height: 48,
                  width: 48,
                  alignment: .center,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: .circle,
                  ),
                  child: const Icon(
                    Icons.record_voice_over,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(s.tts, style: const TextStyle(fontSize: 16, fontWeight: .bold, height: 1.375)),
            const SizedBox(height: 8),
            Text(s.tts_detail, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.375)),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _VisualButton extends ConsumerWidget {
  const _VisualButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return InkWell(
      onTap: () {
        push(.see);
      },
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Align(
              alignment: .topLeft,
              child: Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  shape: .circle,
                ),
                alignment: .center,
                child: const Icon(Icons.visibility, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(s.see, style: const TextStyle(fontSize: 16, fontWeight: .bold, height: 1.375)),
            const SizedBox(height: 8),
            Text(s.visual_understanding_and_ocr, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.375)),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _NekoButton extends ConsumerWidget {
  const _NekoButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return InkWell(
      onTap: () async {
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
      },
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Align(
              alignment: .topLeft,
              child: Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  color: Colors.pinkAccent,
                  shape: .circle,
                ),
                alignment: .center,
                child: const FaIcon(FontAwesomeIcons.cat, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(s.neko, style: const TextStyle(fontSize: 16, fontWeight: .bold, height: 1.375)),
            const SizedBox(height: 8),
            Text(s.nyan_nyan, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.375)),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _CompletionButton extends ConsumerWidget {
  const _CompletionButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return InkWell(
      onTap: () {
        push(.completion);
      },
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Align(
              alignment: .topLeft,
              child: Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  color: Colors.lightGreen,
                  shape: .circle,
                ),
                alignment: .center,
                child: const FaIcon(FontAwesomeIcons.feather, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(s.completion_mode, style: const TextStyle(fontSize: 16, fontWeight: .bold, height: 1.375)),
            const SizedBox(height: 8),
            Text(s.text_completion_mode, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.375)),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _TranslatorButton extends ConsumerWidget {
  const _TranslatorButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final isDesktop = ref.watch(P.app.isDesktop);

    return InkWell(
      onTap: () {
        if (isDesktop) push(.translator);
        if (!isDesktop) push(.ocr);
      },
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Align(
              alignment: .topLeft,
              child: Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: .circle,
                ),
                alignment: .center,
                child: const Icon(Icons.translate, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.offline_translator,
              style: const TextStyle(fontSize: 16, fontWeight: .bold, height: 1.375),
            ),
            const SizedBox(height: 8),
            Text(
              s.offline_translator_detail,
              style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.375),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _BenchmarkButton extends ConsumerWidget {
  const _BenchmarkButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return InkWell(
      onTap: () {
        push(.benchmark);
      },
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Align(
              alignment: .topLeft,
              child: Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  shape: .circle,
                ),
                alignment: .center,
                child: const FaIcon(FontAwesomeIcons.gauge, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(s.performance_test, style: const TextStyle(fontSize: 16, fontWeight: .bold, height: 1.375)),
            const SizedBox(height: 8),
            Text(s.performance_test_description, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.375)),
            const SizedBox(height: 6),
          ],
        ),
      ),
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

    return InkWell(
      onTap: () {
        push(.rolePlaying);
      },
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Align(
              alignment: .topLeft,
              child: Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  color: Colors.yellow,
                  shape: .circle,
                ),
                alignment: .center,
                child: const FaIcon(Icons.emoji_emotions_outlined, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(s.role_play, style: const TextStyle(fontSize: 16, fontWeight: .bold, height: 1.375)),
            const SizedBox(height: 8),
            Text(s.role_play_intro, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.375)),
            const SizedBox(height: 6),
          ],
        ),
      ),
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
