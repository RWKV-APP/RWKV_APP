import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/model/file_info.dart';
import 'package:zone/router/method.dart';
import 'package:zone/router/page_key.dart';
import 'package:zone/store/p.dart' show P, $Chat, $FileManager, $RWKVLoad;
import 'package:zone/widgets/app_scaffold.dart';
import 'package:zone/widgets/model_selector.dart';

class PageHome extends ConsumerWidget {
  const PageHome({super.key});

  void onNekoTap(BuildContext context) async {
    final current = P.rwkv.currentModel.q;
    if (current == null || !current.isNeko) {
      final nekoList = P.fileManager.getNekoModel();
      final downloaded = nekoList.where((e) => P.fileManager.locals(e).q.hasFile).toList();
      if (downloaded.isNotEmpty) {
        final loaded = await _ModelLoadingDialog.show(context, downloaded.first);
        if (!loaded) return;
      } else if (nekoList.isNotEmpty) {
        Alert.warning(S.current.chat_you_need_download_model_if_you_want_to_use_it);
        ModelSelector.show(nekoOnly: true);
        return;
      } else {
        Alert.error('Neko is not available');
        return;
      }
    }
    P.chat.startNewChat();
    push(PageKey.chat);
  }

  void _onChatTap() async {
    final isTTS = P.rwkv.currentModel.q?.isTTS ?? false;
    if (isTTS) P.rwkv.currentModel.q = null;
    P.chat.startNewChat();
    push(PageKey.chat);
  }

  void _onTtsTap() async {
    P.chat.startNewChat();
    final isTTS = P.rwkv.currentModel.q?.isTTS ?? false;
    if (!isTTS) {
      P.rwkv.currentGroupInfo.q = null;
      P.rwkv.currentModel.q = null;
    }
    push(PageKey.talk);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(P.app.version);
    final isDesktop = ref.watch(P.app.isDesktop);

    final width = MediaQuery.of(context).size.width;

    final isLandscape = width > 600;
    final maxWidth = width / (isLandscape ? 3 : 2) - (isLandscape ? 60 : 24);

    final s = S.of(context);

    return AppScaffold(
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 100),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
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
              S.of(context).welcome_to_rwkv_chat,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "v$version",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 100),

            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.center,
                children:
                    [
                          buildButton(
                            title: s.chat,
                            subtitle: s.chat_with_rwkv_model,
                            onTap: _onChatTap,
                            iconColor: Colors.blueAccent,
                            iconData: FontAwesomeIcons.comments,
                          ),
                          buildButton(
                            title: s.tts,
                            subtitle: s.tts_detail,
                            onTap: _onTtsTap,
                            icon: Container(
                              height: 48,
                              width: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.record_voice_over,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          buildButton(
                            title: s.neko,
                            subtitle: s.nyan_nyan,
                            onTap: () => onNekoTap(context),
                            iconColor: Colors.pinkAccent,
                            iconData: FontAwesomeIcons.cat,
                          ),
                          buildButton(
                            title: s.completion_mode,
                            subtitle: s.text_completion_mode,
                            onTap: () {
                              push(PageKey.completion);
                            },
                            iconColor: Colors.lightGreen,
                            iconData: FontAwesomeIcons.feather,
                          ),
                          buildButton(
                            title: isDesktop ? s.offline_translator_server : s.offline_translator,
                            subtitle: s.offline_translator_detail,
                            onTap: () {
                              push(PageKey.translator);
                            },
                            iconColor: Colors.blue,
                            iconData: Icons.translate,
                          ),
                        ]
                        .map(
                          (e) => ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: e,
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildButton({
    String? title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    IconData? iconData,
    Widget? icon,
  }) {
    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (iconData != null)
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: FaIcon(iconData, color: Colors.white),
                  ),
                ),
              if (icon != null)
                SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: icon,
                  ),
                ),
              if (title != null) const SizedBox(height: 12),
              if (title != null) Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (subtitle != null) const SizedBox(height: 8),
              if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
