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
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/app_scaffold.dart';
import 'package:zone/widgets/model_selector.dart';

class PageHome extends ConsumerWidget {
  const PageHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final version = ref.watch(P.app.version);

    final width = MediaQuery.sizeOf(context).width;

    final isLandscape = width > 600;
    final crossAxisCount = isLandscape ? 3 : 2;
    final maxWidth = width / crossAxisCount - (isLandscape ? 60 : 24);

    return AppScaffold(
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: .stretch,
          mainAxisSize: .min,
          children: [
            const SizedBox(height: 100),
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
            const SizedBox(height: 24),
            Text(
              s.welcome_to_rwkv_chat,
              style: const TextStyle(fontSize: 24, fontWeight: .bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "v$version",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 100),
            Padding(
              padding: const .symmetric(horizontal: 12),
              child: MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemBuilder: (context, index) {
                  final widgets = [
                    const _ChatButton(),
                    const _VisualButton(),
                    const _TTSButton(),
                    const _RolePlayButton(),
                    const _CompletionButton(),
                    const _TranslatorButton(),
                    const _NekoButton(),
                    const _LambadaButton(),
                  ];
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: widgets[index],
                  );
                },
                itemCount: 8,
              ),
            ),
            const SizedBox(height: 20),
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

    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(10)),
      child: InkWell(
        onTap: () {
          P.chat.startNewChat();
          push(PageKey.chat);
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
              Text(s.chat, style: const TextStyle(fontSize: 16, fontWeight: .bold)),
              const SizedBox(height: 8),
              Text(s.chat_with_rwkv_model, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
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

    return Material(
      clipBehavior: .antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(10)),
      child: InkWell(
        onTap: () {
          P.chat.startNewChat();
          push(PageKey.talk);
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
              Text(s.tts, style: const TextStyle(fontSize: 16, fontWeight: .bold)),
              const SizedBox(height: 8),
              Text(s.tts_detail, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
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

    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(10)),
      child: InkWell(
        onTap: () {
          push(PageKey.see);
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
              Text(s.see, style: const TextStyle(fontSize: 16, fontWeight: .bold)),
              const SizedBox(height: 8),
              Text(s.visual_understanding_and_ocr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
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

    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(10)),
      child: InkWell(
        onTap: () async {
          final current = P.rwkv.currentModel.q;
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
          push(PageKey.neko);
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
              Text(s.neko, style: const TextStyle(fontSize: 16, fontWeight: .bold)),
              const SizedBox(height: 8),
              Text(s.nyan_nyan, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
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

    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(10)),
      child: InkWell(
        onTap: () {
          push(PageKey.completion);
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
              Text(s.completion_mode, style: const TextStyle(fontSize: 16, fontWeight: .bold)),
              const SizedBox(height: 8),
              Text(s.text_completion_mode, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
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

    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(10)),
      child: InkWell(
        onTap: () {
          push(PageKey.translator);
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
                isDesktop ? s.offline_translator_server : s.offline_translator,
                style: const TextStyle(fontSize: 16, fontWeight: .bold),
              ),
              const SizedBox(height: 8),
              Text(s.offline_translator_detail, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _LambadaButton extends ConsumerWidget {
  const _LambadaButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(10)),
      child: InkWell(
        onTap: () {
          push(PageKey.lambada);
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
                  child: const FaIcon(FontAwesomeIcons.bolt, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(s.lambada_test, style: const TextStyle(fontSize: 16, fontWeight: .bold)),
              const SizedBox(height: 8),
              Text(s.performance_test_description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
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
        // await Future<void>.delayed(const Duration(milliseconds: 10000));
        await P.rwkv.switchChatModel(widget.file).timeout(const Duration(seconds: 10));
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

    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: .circular(10)),
      child: InkWell(
        onTap: () {
          push(PageKey.rolePlaying);
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
              Text(s.role_play, style: const TextStyle(fontSize: 16, fontWeight: .bold)),
              const SizedBox(height: 8),
              Text(s.role_play_intro, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
