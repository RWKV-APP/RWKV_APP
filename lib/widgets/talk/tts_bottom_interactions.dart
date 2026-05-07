// Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path/path.dart' as path;

// Project imports:
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/func/extensions/num.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/language.dart';
import 'package:zone/model/tts_instruction.dart';
import 'package:zone/store/p.dart';

class TTSInteractions extends ConsumerWidget {
  const TTSInteractions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final audioInteractorShown = ref.watch(P.talk.audioInteractorShown);
    final intonationShown = ref.watch(P.talk.intonationShown);
    final spkShown = ref.watch(P.talk.spkShown);
    final selectedSpkName = ref.watch(P.talk.selectedSpkName);
    final selectedLanguage = ref.watch(P.talk.selectedLanguage);
    final primary = Theme.of(context).colorScheme.primary;
    final selectSourceAudioPath = ref.watch(P.talk.selectSourceAudioPath);
    final sourceWavName = selectSourceAudioPath != null ? path.basename(selectSourceAudioPath) : null;
    final pairs = ref.watch(P.talk.spkPairs);
    final paddingBottom = ref.watch(P.app.paddingBottom);

    String target = "";

    if (selectedSpkName != null) {
      target = s.imitate_target + ": " + (P.talk.safe(selectedSpkName));
      target += " " + pairs[selectedSpkName];
      final flag = selectedLanguage.flag;
      if (flag != null) target += " " + flag;
    }

    return GestureDetector(
      onTap: P.talk.dismissAllShown,
      child: Container(
        padding: .only(bottom: paddingBottom, left: 12, right: 12),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            if (selectedSpkName != null)
              Container(
                padding: const .symmetric(vertical: 4),
                child: Text(
                  target,
                  style: TS(c: primary, w: .w600),
                ),
              ),
            if (selectSourceAudioPath != null)
              Container(
                padding: const .symmetric(vertical: 4),
                child: Text(
                  s.imitate_target + ": " + (sourceWavName ?? ""),
                  style: TS(c: primary, w: .w600),
                ),
              ),
            const _Actions(),
            if (audioInteractorShown) const _AudioInteractor(),
            if (spkShown) const _SpkPanel(),
            if (intonationShown) const _IntonationPanel(),
          ],
        ),
      ),
    );
  }
}

class _AudioInteractor extends ConsumerWidget {
  const _AudioInteractor();

  void _onUploadFilePressed() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
      allowMultiple: false,
    );

    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) {
      Alert.error("File path not found");
      return;
    }

    final extension = path.split('.').last;

    if (extension != 'wav') {
      Alert.error("File extension must be wav");
      return;
    }

    P.talk.selectSourceAudioPath.q = path;
    P.talk.selectedSpkName.q = null;
    P.app.hapticLight();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 250,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              const SizedBox(width: 24),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: s.you_can_record_your_voice_and_let_rwkv_to_copy_it,
                        style: TS(
                          c: primary,
                          w: .w600,
                        ),
                      ),
                      TextSpan(
                        text: s.or_select_a_wav_file_to_let_rwkv_to_copy_it,
                        style: const TS(
                          c: Colors.blue,
                          w: .w600,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = _onUploadFilePressed,
                      ),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: _onUploadFilePressed,
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.transparent),
                            child: const Icon(
                              Icons.upload_file,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntonationPanel extends ConsumerWidget {
  const _IntonationPanel();

  void _onTap(String e) {
    qq;
    final controller = P.chat.textEditingController;
    final selection = controller.selection;
    final text = controller.text;
    if (!selection.isValid) {
      controller.text += e;
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      P.app.hapticLight();
      return;
    }
    final newText = text.replaceRange(selection.start, selection.end, e);
    final newOffset = selection.start + e.length;
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: newOffset);
    P.app.hapticLight();
    return;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qb = ref.watch(P.app.qb);
    return SizedBox(
      height: 250,
      child: Padding(
        padding: const .only(top: 12, bottom: 12),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: TTSInstruction.intonation.options.indexMap((index, e) {
            final emoji = TTSInstruction.intonation.emojiOptions[index];
            return GestureDetector(
              onTap: () {
                _onTap(e);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: .all(color: qb.q(.5), width: .5),
                  borderRadius: .circular(4),
                ),
                padding: const .only(left: 8, top: 4, right: 8, bottom: 4),
                child: Text(emoji + e),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AudioButton extends ConsumerWidget {
  const _AudioButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final qw = ref.watch(P.app.qw);
    final primary = Theme.of(context).colorScheme.primary;
    const demoType = DemoType.tts;
    final borderRadius = demoType != .tts ? 12.r : 6.r;
    final audioInteractorShown = ref.watch(P.talk.audioInteractorShown);
    return GestureDetector(
      onTap: P.talk.onAudioInteractorButtonPressed,
      child: Padding(
        padding: const .only(top: 2, right: 4, bottom: 6),
        child: Container(
          padding: const .only(left: 8, top: 6, right: 8, bottom: 6),
          decoration: BoxDecoration(
            color: primary.q(audioInteractorShown ? 1 : .1),
            borderRadius: borderRadius,
          ),
          child: Text(
            s.voice_cloning + (audioInteractorShown ? " ×" : ""),
            style: TS(c: audioInteractorShown ? qw : primary),
          ),
        ),
      ),
    );
  }
}

class _SpkButton extends ConsumerWidget {
  const _SpkButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final qw = ref.watch(P.app.qw);
    final primary = Theme.of(context).colorScheme.primary;
    const demoType = DemoType.tts;
    final borderRadius = demoType != .tts ? 12.r : 6.r;
    ref.watch(P.talk.intonationShown);
    ref.watch(P.talk.audioInteractorShown);
    final spkShown = ref.watch(P.talk.spkShown);
    return GestureDetector(
      onTap: P.talk.onSpkButtonPressed,
      child: Padding(
        padding: const .only(top: 2, right: 4, bottom: 6),
        child: Container(
          padding: const .only(left: 8, top: 6, right: 8, bottom: 6),
          decoration: BoxDecoration(
            color: primary.q(spkShown ? 1 : .1),
            borderRadius: borderRadius,
          ),
          child: Text(
            s.prebuilt_voices + (spkShown ? " ×" : ""),
            style: TS(c: spkShown ? qw : primary),
          ),
        ),
      ),
    );
  }
}

class _IntonationButton extends ConsumerWidget {
  const _IntonationButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qw = ref.watch(P.app.qw);
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    const demoType = DemoType.tts;
    final borderRadius = demoType != .tts ? 12.r : 6.r;
    final intonationShown = ref.watch(P.talk.intonationShown);
    return GestureDetector(
      onTap: P.talk.onIntonationButtonPressed,
      child: Padding(
        padding: const .only(top: 2, right: 4, bottom: 6),
        child: Container(
          padding: const .only(left: 8, top: 6, right: 8, bottom: 6),
          decoration: BoxDecoration(
            color: primary.q(intonationShown ? 1 : .1),
            borderRadius: borderRadius,
          ),
          child: Text(
            s.intonations + (intonationShown ? " ×" : ""),
            style: TS(c: intonationShown ? qw : primary),
          ),
        ),
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Wrap(
      crossAxisAlignment: .center,
      children: [
        _AudioButton(),
        _SpkButton(),
        _IntonationButton(),
      ],
    );
  }
}

class _SpkPanel extends ConsumerWidget {
  const _SpkPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spkPairs = ref.watch(P.talk.spkPairs);
    var spkNames = spkPairs.keys;
    final selectSpkName = ref.watch(P.talk.selectedSpkName);
    final primary = Theme.of(context).colorScheme.primary;
    final controller = ScrollController();

    final selectedLanguage = ref.watch(P.talk.selectedLanguage);
    final selectedSpkPanelFilter = ref.watch(P.talk.selectedSpkPanelFilter);

    switch (selectedSpkPanelFilter) {
      case Language.none:
      case Language.ru:
      case Language.en:
        spkNames = spkPairs.keys.where((e) => e.contains(Language.en.enName!));
      case Language.ja:
        spkNames = spkPairs.keys.where((e) => e.contains(Language.ja.enName!));
      case Language.ko:
        spkNames = spkPairs.keys.where((e) => e.contains(Language.ko.enName!));
      case Language.zh_Hans:
        spkNames = spkPairs.keys.where((e) => e.contains(Language.zh_Hans.enName!));
      case Language.zh_Hant:
        spkNames = spkPairs.keys.where((e) => e.contains(Language.zh_Hans.enName!));
    }

    final qb = ref.watch(P.app.qb);

    return SizedBox(
      height: 250,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              children: [Language.zh_Hans, Language.en, Language.ja].m((e) {
                final flag = e.flag;
                final localizedName = e.soundDisplay;
                final selected = selectedLanguage == e;
                final filtered = selectedSpkPanelFilter == e;

                return GestureDetector(
                  onTap: () {
                    P.talk.selectedSpkPanelFilter.q = e;
                    P.app.hapticLight();
                  },
                  child: Container(
                    padding: const .symmetric(horizontal: 4, vertical: 2),
                    margin: const .only(right: 4),
                    decoration: BoxDecoration(
                      color: filtered ? primary.q(.1) : Colors.transparent,
                      borderRadius: .circular(4),
                      border: .all(color: qb.q(.5), width: .5),
                    ),
                    child: Row(
                      children: [
                        Text((flag ?? "") + " " + (localizedName ?? "")),
                        if (selected) const SizedBox(width: 4),
                        if (selected) Icon(Icons.circle, color: primary, size: 8),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: RawScrollbar(
              controller: controller,
              padding: const .only(top: 12, bottom: 12),
              child: ListView.builder(
                controller: controller,
                padding: const .only(top: 12, bottom: 12),
                itemCount: spkNames.length,
                itemBuilder: (context, index) {
                  final k = spkNames.elementAt(index);
                  final v = spkPairs[k];

                  final selected = selectSpkName == k;

                  final language = Language.values.where((e) => e.enName != null).firstWhereOrNull((e) => k.contains(e.enName!));

                  final display = P.talk.safe(k) + " " + P.talk.safe(v) + " " + (language?.flag ?? "");

                  return GestureDetector(
                    onTap: () {
                      qq;
                      P.talk.selectedSpkName.q = k;
                      P.talk.selectSourceAudioPath.q = null;
                      P.app.hapticLight();
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const .only(left: 8, top: 4, right: 8, bottom: 4),
                            decoration: BoxDecoration(
                              color: selected ? primary.q(.1) : Colors.transparent,
                              borderRadius: .circular(6),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    display,
                                    style: TS(c: selected ? primary : primary.q(.8), w: selected ? .w600 : .w400),
                                  ),
                                ),
                                if (selected)
                                  Icon(
                                    Icons.check,
                                    color: primary,
                                    size: 14,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final path = await P.talk.getPrebuiltSpkAudioPathFromTemp(k);
                            P.msg.latestClicked.q = null;
                            await P.see.play(path: path);
                          },
                          child: Container(
                            padding: const .all(6.5),
                            decoration: const BoxDecoration(color: Colors.transparent),
                            child: Icon(
                              Icons.volume_up,
                              color: primary,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _Instruction extends ConsumerWidget {
  final DemoType preferredDemoType;
  const _Instruction({required this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFocus = ref.watch(P.talk.hasFocus);
    final interactingInstruction = ref.watch(P.talk.interactingInstruction);
    final selectSpkName = ref.watch(P.talk.selectedSpkName);
    return Stack(
      children: [
        if (selectSpkName == null)
          Column(
            crossAxisAlignment: .stretch,
            children: [
              _TextField(preferredDemoType: preferredDemoType),
              if (!hasFocus) const _InstructTabs(),
              if (!hasFocus && interactingInstruction != TTSInstruction.none) const _InstructOptions(),
            ],
          ),
      ],
    );
  }
}

class _InstructTabs extends ConsumerWidget {
  const _InstructTabs();

  void _onTap(TTSInstruction e) {
    qq;
    if (P.talk.interactingInstruction.q == e) {
      P.talk.interactingInstruction.q = TTSInstruction.none;
    } else {
      P.talk.interactingInstruction.q = e;
    }

    P.app.hapticLight();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(P.rwkvModel.loaded);
    final loading = ref.watch(P.rwkvModel.loading);
    bool enabled = loaded && !loading;

    final primary = Theme.of(context).colorScheme.primary;

    final i1 = ref.watch(P.talk.instructions(TTSInstruction.emotion));
    final i2 = ref.watch(P.talk.instructions(TTSInstruction.dialect));
    final i3 = ref.watch(P.talk.instructions(TTSInstruction.speed));
    final i4 = ref.watch(P.talk.instructions(TTSInstruction.role));
    final _ = ref.watch(P.talk.interactingInstruction);

    final isZh = Localizations.localeOf(context).languageCode == "zh";

    final qb = ref.watch(P.app.qb);
    return Row(
      children: [
        Expanded(
          child: Wrap(
            // runSpacing: 4,
            spacing: 4,
            children: TTSInstruction.values.where((e) => e.forInstruction).indexMap((index, e) {
              final isSelected = P.talk.interactingInstruction.q == e;
              String displayText = isZh ? e.nameCN : e.nameEN;
              if (isSelected) displayText += " ×";

              bool hasValue = false;
              switch (e) {
                case TTSInstruction.none:
                case TTSInstruction.emotion:
                  hasValue = i1 != null;
                case TTSInstruction.dialect:
                  hasValue = i2 != null;
                case TTSInstruction.speed:
                  hasValue = i3 != null;
                case TTSInstruction.role:
                  hasValue = i4 != null;
                case TTSInstruction.intonation:
              }

              return GestureDetector(
                onTap: () {
                  if (!enabled) return;
                  _onTap(e);
                },
                child: AnimatedOpacity(
                  opacity: enabled ? 1 : .333,
                  duration: 250.ms,
                  child: Container(
                    margin: const .only(top: 4),
                    padding: const .only(left: 8, top: 4, right: 8, bottom: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? primary.q(.2) : Colors.transparent,
                      border: .all(color: qb.q(.5), width: .5),
                      borderRadius: .circular(4),
                    ),
                    child: Row(
                      crossAxisAlignment: .center,
                      mainAxisSize: .min,
                      children: [
                        if (hasValue)
                          Icon(
                            Icons.circle,
                            color: primary,
                            size: 8,
                          ),
                        if (hasValue) const SizedBox(width: 4),
                        Text(displayText),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _InstructOptions extends ConsumerWidget {
  const _InstructOptions();

  void _onTap(int index) {
    qq;
    P.app.hapticLight();
    final interactingInstruction = P.talk.interactingInstruction.q;
    if (interactingInstruction == TTSInstruction.none) return;
    if (P.talk.instructions(interactingInstruction).q == index) {
      P.talk.instructions(interactingInstruction).q = null;
    } else {
      P.talk.instructions(interactingInstruction).q = index;
    }
    P.talk.syncInstruction();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactingInstruction = ref.watch(P.talk.interactingInstruction);
    final primary = Theme.of(context).colorScheme.primary;
    final options = interactingInstruction.options;
    ref.watch(P.talk.instructions(interactingInstruction));
    final qb = ref.watch(P.app.qb);
    return GestureDetector(
      onTap: () {},
      child: AnimatedContainer(
        duration: 250.ms,
        height: interactingInstruction == TTSInstruction.none ? 0 : 150,
        margin: const .only(top: 4),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: qb.q(.5), width: .5)),
        ),
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: 4,
          children: options.indexMap((index, e) {
            bool selected = false;
            if (interactingInstruction != TTSInstruction.none) {
              selected = P.talk.instructions(interactingInstruction).q == index;
            }

            return GestureDetector(
              onTap: () {
                _onTap(index);
              },
              child: Container(
                padding: const .only(left: 8, top: 4, right: 8, bottom: 4),
                margin: const .only(top: 4),
                decoration: BoxDecoration(
                  color: selected ? primary.q(.2) : Colors.transparent,
                  border: .all(color: qb.q(.5), width: .5),
                  borderRadius: .circular(4),
                ),
                child: Text(e + (selected ? " ×" : "")),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TextField extends ConsumerWidget {
  final DemoType preferredDemoType;

  const _TextField({required this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final loaded = ref.watch(P.rwkvModel.loaded);
    final loading = ref.watch(P.rwkvModel.loading);
    final demoType = ref.watch(P.app.demoType);

    late final String hintText;
    switch (demoType) {
      case .chat:
      case .fifthteenPuzzle:
      case .othello:
      case .sudoku:
      case .see:
        hintText = "";
      case .tts:
        hintText = "Enter your instruction here";
    }

    bool textFieldEnabled = loaded && !loading;

    final borderRadius = demoType != .tts ? 12.r : 6.r;

    final textInInput = ref.watch(P.talk.textInInput);

    final qw = ref.watch(P.app.qw);

    return GestureDetector(
      onTap: textFieldEnabled ? null : _onTapTextFieldWhenItsDisabled,
      child: KeyboardListener(
        onKeyEvent: _onKeyEvent,
        focusNode: P.talk.focusNode,
        child: TextField(
          enabled: textFieldEnabled,
          controller: P.talk.textEditingController,
          onSubmitted: _onSubmitted,
          onChanged: _onChanged,
          onEditingComplete: _onEditingComplete,
          onAppPrivateCommand: _onAppPrivateCommand,
          onTap: _onTap,
          onTapOutside: _onTapOutside,
          keyboardType: TextInputType.multiline,
          enableSuggestions: true,
          textInputAction: TextInputAction.send,
          maxLines: 5,
          minLines: 1,
          decoration: InputDecoration(
            suffixIcon: Row(
              mainAxisSize: .min,
              children: [
                GestureDetector(
                  onTap: P.talk.onClearButtonPressed,
                  child: AnimatedOpacity(
                    opacity: textInInput.trim().isNotEmpty ? 1 : .5,
                    duration: 250.ms,
                    child: Container(
                      padding: const .symmetric(horizontal: 4, vertical: 6),
                      child: const Icon(Icons.clear),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: P.talk.onRefreshButtonPressed,
                  child: Container(
                    padding: const .symmetric(horizontal: 4, vertical: 6),
                    child: const Icon(Icons.refresh),
                  ),
                ),
              ],
            ),
            contentPadding: const .only(left: 12, top: 4, right: 8, bottom: 4),
            fillColor: qw,
            focusColor: qw,
            hoverColor: qw,
            iconColor: qw,
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: primary.q(.33)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: primary.q(.33)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: primary.q(.33)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: primary.q(.33)),
            ),
            hintText: hintText,
          ),
        ),
      ),
    );
  }

  void _onChanged(String value) {}

  void _onSubmitted(String value) {}

  void _onEditingComplete() {}

  void _onTap() async {
    qq;
    await 300.msLater;
    await P.chat.scrollToBottom();
  }

  void _onAppPrivateCommand(String action, Map<String, dynamic> data) {}

  void _onTapOutside(PointerDownEvent event) {}

  void _onKeyEvent(KeyEvent event) {
    final character = event.character;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter && character != null;
    if (!isEnterPressed) return;
    if (isShiftPressed) {
      final currentValue = P.chat.textEditingController.value;
      if (currentValue.text.trim().isNotEmpty) {
        P.chat.textEditingController.value = TextEditingValue(text: P.chat.textEditingController.value.text);
      } else {
        Alert.warning(S.current.chat_empty_message);
        P.chat.textEditingController.value = const TextEditingValue(text: "");
      }
    } else {
      P.talk.dismissAllShown();
      P.talk.gen();
    }
  }

  void _onTapTextFieldWhenItsDisabled() {
    qq;
    if (!checkModelSelection(preferredDemoType: preferredDemoType)) return;
  }
}
