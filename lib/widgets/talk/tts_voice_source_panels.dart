// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path/path.dart' as path;

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/language.dart';
import 'package:zone/store/p.dart';

class TTSVoiceSourcePanels {
  static const String sourceTypePanelKey = 'TTSVoiceSourceTypePanel';
  static const String prebuiltVoicesPanelKey = 'TTSPrebuiltVoicesPanel';
  static const String recordVoicePanelKey = 'TTSRecordVoicePanel';

  static Future<void> showVoiceSourceTypePanel() async {
    await P.ui.showPanel(
      key: sourceTypePanelKey,
      beforeShow: () async {
        if (P.chat.focusNode.hasFocus) P.chat.focusNode.unfocus();
      },
      initialChildSize: .56,
      maxChildSize: .7,
      builder: (ScrollController scrollController) {
        return _TTSVoiceSourceTypePanel(scrollController: scrollController);
      },
    );
  }

  static Future<void> showPrebuiltVoicesPanel() async {
    await P.ui.showPanel(
      key: prebuiltVoicesPanelKey,
      beforeShow: () async {
        P.talk.spkShown.q = true;
        P.talk.audioInteractorShown.q = false;
        P.talk.intonationShown.q = false;
        if (P.chat.focusNode.hasFocus) P.chat.focusNode.unfocus();
      },
      afterHide: (_) async {
        P.talk.spkShown.q = false;
      },
      initialChildSize: .72,
      maxChildSize: .92,
      builder: (ScrollController scrollController) {
        return _TTSPrebuiltVoicesPanel(scrollController: scrollController);
      },
    );
  }

  static Future<void> showRecordVoicePanel() async {
    final previousAudioInteractorShown = P.talk.audioInteractorShown.q;
    await P.ui.showPanel(
      key: recordVoicePanelKey,
      beforeShow: () async {
        P.talk.audioInteractorShown.q = true;
        P.talk.spkShown.q = false;
        P.talk.intonationShown.q = false;
        if (P.chat.focusNode.hasFocus) P.chat.focusNode.unfocus();
      },
      afterHide: (_) async {
        await P.see.stopRecord(isCancel: true);
        P.talk.audioInteractorShown.q = previousAudioInteractorShown;
      },
      initialChildSize: .48,
      maxChildSize: .64,
      builder: (ScrollController scrollController) {
        return _TTSRecordVoicePanel(scrollController: scrollController);
      },
    );
  }

  static Future<void> pickWavFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['wav'],
      allowMultiple: false,
    );
    if (result == null) return;

    final selectedPath = result.files.single.path;
    if (selectedPath == null) {
      Alert.error('File path not found');
      return;
    }

    final extension = path.extension(selectedPath).replaceFirst('.', '').toLowerCase();
    if (extension != 'wav') {
      Alert.error('File extension must be wav');
      return;
    }

    P.talk.selectSourceAudioPath.q = selectedPath;
    P.talk.selectedSpkName.q = null;
    P.app.hapticLight();
  }
}

class _TTSVoiceSourceTypePanel extends ConsumerWidget {
  final ScrollController scrollController;

  const _TTSVoiceSourceTypePanel({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final primary = Theme.of(context).colorScheme.primary;
    final double listPadding = P.app.isMobile.q ? 8 : 12;

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Column(
        children: <Widget>[
          _TTSVoiceSourceTypePanelBar(listPadding: listPadding),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: .only(
                left: listPadding,
                top: 6,
                right: listPadding,
                bottom: 16,
              ),
              children: <Widget>[
                Text(
                  s.tts_voice_source_sheet_subtitle,
                  style: TS(c: qb.q(.7), s: 12, w: .w500),
                ),
                const SizedBox(height: 8),
                Container(height: .5, color: qb.q(.15)),
                _TTSVoiceSourceOptionItem(
                  icon: Icons.record_voice_over_rounded,
                  title: s.tts_voice_source_preset_title,
                  subtitle: s.tts_voice_source_preset_subtitle,
                  iconColor: primary,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await TTSVoiceSourcePanels.showPrebuiltVoicesPanel();
                  },
                ),
                Container(height: .5, color: qb.q(.15)),
                _TTSVoiceSourceOptionItem(
                  icon: Icons.mic_rounded,
                  title: s.tts_voice_source_my_voice_title,
                  subtitle: s.tts_voice_source_my_voice_subtitle,
                  iconColor: primary,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await TTSVoiceSourcePanels.showRecordVoicePanel();
                  },
                ),
                Container(height: .5, color: qb.q(.15)),
                _TTSVoiceSourceOptionItem(
                  icon: Icons.audio_file_rounded,
                  title: s.tts_voice_source_file_title,
                  subtitle: s.tts_voice_source_file_subtitle,
                  iconColor: primary,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await TTSVoiceSourcePanels.pickWavFile();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TTSVoiceSourceTypePanelBar extends ConsumerWidget {
  final double listPadding;

  const _TTSVoiceSourceTypePanelBar({required this.listPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);

    return Container(
      constraints: const BoxConstraints(
        minHeight: kToolbarHeight - 4,
      ),
      padding: const .only(top: 4),
      decoration: const BoxDecoration(color: kC),
      child: Row(
        crossAxisAlignment: .center,
        children: <Widget>[
          listPadding.w,
          Expanded(
            child: Text(
              s.tts_voice_source_sheet_title,
              style: const TS(s: 18, w: .w600),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TTSVoiceSourceOptionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  const _TTSVoiceSourceOptionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: .circular(12),
        child: Container(
          padding: const .only(left: 8, top: 10, right: 8, bottom: 10),
          child: Row(
            crossAxisAlignment: .center,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: .circular(1000),
                  color: iconColor.q(.12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TS(c: onSurface.q(.92), w: .w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: .ellipsis,
                      style: TS(c: onSurface.q(.56), s: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: onSurface.q(.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TTSPanelBar extends ConsumerWidget {
  final String title;

  const _TTSPanelBar({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: const BoxConstraints(minHeight: kToolbarHeight - 4),
      padding: const .only(top: 4, left: 12, right: 8),
      decoration: const BoxDecoration(
        color: kC,
      ),
      child: Row(
        crossAxisAlignment: .center,
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TS(s: 18, w: .w600),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _TTSPrebuiltVoicesPanel extends ConsumerWidget {
  final ScrollController scrollController;

  const _TTSPrebuiltVoicesPanel({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final S s = S.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color qb = ref.watch(P.app.qb);
    final Map<String, dynamic> spkPairs = ref.watch(P.talk.spkPairs);
    final String? selectedSpkName = ref.watch(P.talk.selectedSpkName);
    final Language selectedLanguage = ref.watch(P.talk.selectedLanguage);
    final Language selectedSpkPanelFilter = ref.watch(P.talk.selectedSpkPanelFilter);

    Iterable<String> spkNames = spkPairs.keys;
    switch (selectedSpkPanelFilter) {
      case Language.none:
      case Language.ru:
      case Language.en:
        spkNames = spkPairs.keys.where((String e) => e.contains(Language.en.enName!));
      case Language.ja:
        spkNames = spkPairs.keys.where((String e) => e.contains(Language.ja.enName!));
      case Language.ko:
        spkNames = spkPairs.keys.where((String e) => e.contains(Language.ko.enName!));
      case Language.zh_Hans:
        spkNames = spkPairs.keys.where((String e) => e.contains(Language.zh_Hans.enName!));
      case Language.zh_Hant:
        spkNames = spkPairs.keys.where((String e) => e.contains(Language.zh_Hans.enName!));
    }

    final spkNameList = spkNames.toList(growable: false);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Column(
        children: <Widget>[
          _TTSPanelBar(title: s.prebuilt_voices),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const .only(left: 12, top: 10, right: 12, bottom: 2),
              child: Row(
                mainAxisAlignment: .start,
                children: <Widget>[
                  for (final Language language in <Language>[Language.zh_Hans, Language.en, Language.ja])
                    Padding(
                      padding: const .only(right: 6),
                      child: _LanguageFilterChip(
                        language: language,
                        selectedLanguage: selectedLanguage,
                        selectedFilter: selectedSpkPanelFilter,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const .only(left: 12, top: 8, right: 12, bottom: 16),
              itemCount: spkNameList.length,
              itemBuilder: (BuildContext context, int index) {
                final spkName = spkNameList[index];
                final dynamic displayNameRaw = spkPairs[spkName];
                final displayName = displayNameRaw is String ? displayNameRaw : '';
                final selected = selectedSpkName == spkName;
                final language = Language.values
                    .where((Language e) => e.enName != null)
                    .firstWhereOrNull((Language e) => spkName.contains(e.enName!));
                final display = '${P.talk.safe(spkName)} $displayName ${language?.flag ?? ''}'.trim();

                return Padding(
                  padding: const .only(bottom: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? primary.q(.1) : Colors.transparent,
                      borderRadius: .circular(8),
                      border: Border.all(color: qb.q(selected ? .4 : .2), width: .5),
                    ),
                    child: InkWell(
                      onTap: () {
                        P.talk.selectedSpkName.q = spkName;
                        P.talk.selectSourceAudioPath.q = null;
                        P.app.hapticLight();
                        Navigator.of(context).pop();
                      },
                      borderRadius: .circular(8),
                      child: Padding(
                        padding: const .only(left: 10, top: 4, right: 4, bottom: 4),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      display,
                                      style: TS(c: selected ? primary : theme.colorScheme.onSurface.q(.85), w: selected ? .w600 : .w400),
                                    ),
                                  ),
                                  if (selected)
                                    Icon(
                                      Icons.check,
                                      color: primary,
                                      size: 16,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final localPath = await P.talk.getPrebuiltSpkAudioPathFromTemp(spkName);
                                P.msg.latestClicked.q = null;
                                await P.see.play(path: localPath);
                              },
                              visualDensity: .compact,
                              icon: Icon(
                                Icons.volume_up,
                                color: primary,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageFilterChip extends ConsumerWidget {
  final Language language;
  final Language selectedLanguage;
  final Language selectedFilter;

  const _LanguageFilterChip({
    required this.language,
    required this.selectedLanguage,
    required this.selectedFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final qb = ref.watch(P.app.qb);
    final label = '${language.flag ?? ''} ${language.soundDisplay ?? ''}'.trim();
    final isCurrentSelected = selectedLanguage == language;
    final isFiltered = selectedFilter == language;

    return GestureDetector(
      onTap: () {
        P.talk.selectedSpkPanelFilter.q = language;
        P.app.hapticLight();
      },
      child: Container(
        padding: const .symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isFiltered ? primary.q(.1) : Colors.transparent,
          borderRadius: .circular(6),
          border: Border.all(color: qb.q(.35), width: .5),
        ),
        child: Row(
          children: <Widget>[
            Text(label),
            if (isCurrentSelected) const SizedBox(width: 4),
            if (isCurrentSelected)
              Icon(
                Icons.circle,
                color: primary,
                size: 8,
              ),
          ],
        ),
      ),
    );
  }
}

class _TTSRecordVoicePanel extends ConsumerWidget {
  final ScrollController scrollController;

  const _TTSRecordVoicePanel({required this.scrollController});

  Future<void> _onPressStart() async {
    final receiving = P.rwkv.generating.q;
    if (receiving) return;
    if (P.see.recording.q) return;
    P.app.hapticLight();
    Alert.info(S.current.recording_your_voice);
    await P.see.startRecord();
  }

  Future<void> _onPressEnd(BuildContext context, {bool isCancel = false}) async {
    final receiving = P.rwkv.generating.q;
    if (receiving) return;
    if (!P.see.recording.q) return;
    if (isCancel) {
      P.app.hapticLight();
    } else {
      P.app.hapticMedium();
    }

    final success = await P.see.stopRecord(isCancel: isCancel);
    if (isCancel) return;
    if (!success) return;

    Alert.success(S.current.finish_recording);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _onTapDown() async {
    await _onPressStart();
  }

  Future<void> _onTapUp(BuildContext context) async {
    await _onPressEnd(context);
  }

  Future<void> _onTapCancel(BuildContext context) async {
    await _onPressEnd(context, isCancel: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final primary = theme.colorScheme.primary;
    final qb = ref.watch(P.app.qb);
    final generating = ref.watch(P.rwkv.generating);
    final recording = ref.watch(P.see.recording);
    final paddingBottom = ref.watch(P.app.paddingBottom);

    return ClipRRect(
      borderRadius: const .only(
        topLeft: .circular(16),
        topRight: .circular(16),
      ),
      child: Column(
        children: [
          _TTSPanelBar(title: s.voice_cloning),
          Expanded(
            child: Column(
              mainAxisAlignment: .center,
              children: <Widget>[
                Text(
                  s.you_can_record_your_voice_and_let_rwkv_to_copy_it,
                  style: TS(c: qb.q(.85), w: .w500),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: generating
                        ? null
                        : (PointerDownEvent _) {
                            _onTapDown();
                          },
                    onPointerUp: generating
                        ? null
                        : (PointerUpEvent _) {
                            _onTapUp(context);
                          },
                    onPointerCancel: generating
                        ? null
                        : (PointerCancelEvent _) {
                            _onTapCancel(context);
                          },
                    child: AnimatedContainer(
                      duration: 200.ms,
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: primary.q(recording ? .92 : .2),
                        borderRadius: .circular(1000),
                        border: Border.all(color: primary.q(recording ? .95 : .5), width: 1),
                      ),
                      child: Center(
                        child: Icon(
                          recording ? Icons.stop_rounded : Icons.mic,
                          size: 36,
                          color: recording ? theme.colorScheme.onPrimary : primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  s.hold_to_record_release_to_send,
                  textAlign: TextAlign.center,
                  style: TS(c: qb.q(.75), s: 13),
                ),
              ],
            ),
          ),
          paddingBottom.h,
        ],
      ),
    );
  }
}
