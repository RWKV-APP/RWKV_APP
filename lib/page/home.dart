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

class PageHome extends ConsumerStatefulWidget {
  const PageHome({super.key});

  @override
  ConsumerState<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends ConsumerState<PageHome> {
  static ScrollController? controller;
  static final _pixels = qs(0.0);
  static final _pixelsFromBottom = qs(1.0);

  @override
  void initState() {
    super.initState();
    controller = ScrollController(initialScrollOffset: _pixels.q);
    controller?.addListener(_onScroll);
  }

  @override
  void dispose() {
    controller?.removeListener(_onScroll);
    controller?.dispose();
    controller = null;
    super.dispose();
  }

  void _onScroll() async {
    final position = controller?.position;
    if (position == null) return;
    final pixels = position.pixels;
    final pixelsFromBottom = position.maxScrollExtent - pixels;
    if ((_pixels.q - pixels).abs() > 1) _pixels.q = pixels;
    if ((_pixelsFromBottom.q - pixelsFromBottom).abs() > 1) _pixelsFromBottom.q = pixelsFromBottom;
  }

  @override
  Widget build(BuildContext context) {
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
    if (maxWidth < 0) maxWidth = double.infinity;

    if (maxWidth < 0) maxWidth = double.infinity;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1C1C1E) // Apple System Background (Dark)
          : const Color(0xFFFFFFFF), // Pure white
      body: Stack(
          children: [
            const _Welcome(),
            Positioned.fill(
              child: SingleChildScrollView(
                controller: controller,
                padding: .only(
                  top: containerPaddingTop,
                  left: containerPaddingHorizontal,
                  right: containerPaddingHorizontal,
                  bottom: 100,
                ),
                physics: const BouncingScrollPhysics(),
                child: MasonryGridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemBuilder: (context, index) {
                    final widgets = [
                      const _ChatButton(),
                      const _CompletionButton(),
                      const _VisualButton(),
                      const _TTSButton(),
                      const _RolePlayButton(),
                      const _TranslatorButton(),
                      const _NekoButton(),
                      const _BenchmarkButton(),
                    ];
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
    final pixelsFromBottom = ref.watch(_PageHomeState._pixelsFromBottom);

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
            child: T("- " + s.reached_bottom + " -"),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7), // Apple Secondary Background
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: InkWell(
        onTap: () {
          P.chat.startNewChat();
          push(.chat);
        },
        child: Padding(
          padding: const .all(16),
          child: Column(
            crossAxisAlignment: .center,
            children: [
              const SizedBox(height: 8),
              FaIcon(
                FontAwesomeIcons.comments,
                color: const Color(0xFF007AFF), // Apple Blue
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(s.chat, style: const TextStyle(fontSize: 17, fontWeight: .w600)),
              const SizedBox(height: 4),
              Text(
                s.chat_with_rwkv_model,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: .center,
              ),
              const SizedBox(height: 8),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7), // Apple Secondary Background
      clipBehavior: .antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: InkWell(
        onTap: () {
          P.chat.startNewChat();
          push(.talk);
        },
        child: Padding(
          padding: const .all(16),
          child: Column(
            crossAxisAlignment: .center,
            children: [
              const SizedBox(height: 8),
              Icon(
                Icons.record_voice_over,
                color: const Color(0xFFFF9500), // Apple Orange
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(s.tts, style: const TextStyle(fontSize: 17, fontWeight: .w600)),
              const SizedBox(height: 4),
              Text(
                s.tts_detail,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: .center,
              ),
              const SizedBox(height: 8),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7), // Apple Secondary Background
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: InkWell(
        onTap: () {
          push(.see);
        },
        child: Padding(
          padding: const .all(16),
          child: Column(
            crossAxisAlignment: .center,
            children: [
              const SizedBox(height: 8),
              Icon(
                Icons.visibility,
                color: const Color(0xFFAF52DE), // Apple Purple
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(s.see, style: const TextStyle(fontSize: 17, fontWeight: .w600)),
              const SizedBox(height: 4),
              Text(
                s.visual_understanding_and_ocr,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: .center,
              ),
              const SizedBox(height: 8),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7), // Apple Secondary Background
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: InkWell(
        onTap: () async {
          final current = P.rwkv.latestModel.q;
          if (current == null || !current.isNeko) {
            final nekoList = P.fileManager.getNekoModel();
            final downloaded = nekoList.where((e) => P.fileManager.locals(e).q.hasFile).toList();
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
            crossAxisAlignment: .center,
            children: [
              const SizedBox(height: 8),
              FaIcon(
                FontAwesomeIcons.cat,
                color: const Color(0xFFFF2D55), // Apple Pink
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(s.neko, style: const TextStyle(fontSize: 17, fontWeight: .w600)),
              const SizedBox(height: 4),
              Text(
                s.nyan_nyan,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: .center,
              ),
              const SizedBox(height: 8),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7), // Apple Secondary Background
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: InkWell(
        onTap: () {
          push(.completion);
        },
        child: Padding(
          padding: const .all(16),
          child: Column(
            crossAxisAlignment: .center,
            children: [
              const SizedBox(height: 8),
              FaIcon(
                FontAwesomeIcons.feather,
                color: const Color(0xFF34C759), // Apple Green
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(s.completion_mode, style: const TextStyle(fontSize: 17, fontWeight: .w600)),
              const SizedBox(height: 4),
              Text(
                s.text_completion_mode,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: .center,
              ),
              const SizedBox(height: 8),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7), // Apple Secondary Background
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: InkWell(
        onTap: () {
          if (isDesktop) push(.translator);
          if (!isDesktop) push(.ocr);
        },
        child: Padding(
          padding: const .all(16),
          child: Column(
            crossAxisAlignment: .center,
            children: [
              const SizedBox(height: 8),
              Icon(
                Icons.translate,
                color: const Color(0xFF5AC8FA), // Apple Cyan
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                s.offline_translator,
                style: const TextStyle(fontSize: 17, fontWeight: .w600),
                textAlign: .center,
              ),
              const SizedBox(height: 4),
              Text(
                s.offline_translator_detail,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: .center,
              ),
              const SizedBox(height: 8),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7), // Apple Secondary Background
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: InkWell(
        onTap: () {
          push(.benchmark);
        },
        child: Padding(
          padding: const .all(16),
          child: Column(
            crossAxisAlignment: .center,
            children: [
              const SizedBox(height: 8),
              FaIcon(
                FontAwesomeIcons.gauge,
                color: const Color(0xFF5856D6), // Apple Indigo
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                s.performance_test,
                style: const TextStyle(fontSize: 17, fontWeight: .w600),
                textAlign: .center,
              ),
              const SizedBox(height: 4),
              Text(
                s.performance_test_description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: .center,
              ),
              const SizedBox(height: 8),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7), // Apple Secondary Background
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      child: InkWell(
        onTap: () {
          push(.rolePlaying);
        },
        child: Padding(
          padding: const .all(16),
          child: Column(
            crossAxisAlignment: .center,
            children: [
              const SizedBox(height: 8),
              Icon(
                Icons.emoji_emotions_outlined,
                color: const Color(0xFFFFCC00), // Apple Yellow
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                s.role_play,
                style: const TextStyle(fontSize: 17, fontWeight: .w600),
                textAlign: .center,
              ),
              const SizedBox(height: 4),
              Text(
                s.role_play_intro,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: .center,
              ),
              const SizedBox(height: 8),
            ],
          ),
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
    final pixels = ref.watch(_PageHomeState._pixels);
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
                borderRadius: .circular(50),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/img/chat/rwkv.png',
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
              "v$version",
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
