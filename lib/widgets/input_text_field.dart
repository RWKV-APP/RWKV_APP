// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path/path.dart' as path;

// Project imports:
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/func/extensions/num.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/sending_interaction.dart';
import 'package:zone/widgets/talk/tts_voice_source_panels.dart';

class InputTextField extends ConsumerWidget {
  final DemoType? preferredDemoType;

  const InputTextField({super.key, this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final loaded = ref.watch(P.rwkv.loaded);
    final loading = ref.watch(P.rwkv.loading);
    final DemoType demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    final isChat = demoType == .chat;
    final isTalk = demoType == .tts;
    final isSee = demoType == .see;
    final int? editingOrRegeneratingIndex = isChat ? ref.watch(P.msg.editingOrRegeneratingIndex) : null;
    final bool editingMessage = editingOrRegeneratingIndex != null;

    final imagePath = isSee ? ref.watch(P.see.imagePath) : null;
    final hasAtLeastOneImage = isSee ? ref.watch(P.msg.hasAtLeastOneImage) : false;
    final hasCurrentImage = imagePath != null && imagePath.isNotEmpty;
    final shouldGuideImageSelection = isSee && !hasCurrentImage && !hasAtLeastOneImage;
    final String? selectedSourceWavPath = isTalk ? ref.watch(P.talk.selectSourceAudioPath) : null;
    final String? selectedSpkName = isTalk ? ref.watch(P.talk.selectedSpkName) : null;
    final String? sourceWavName = selectedSourceWavPath == null ? null : path.basename(selectedSourceWavPath);
    final bool hasSourceWav = sourceWavName != null && sourceWavName.isNotEmpty;
    final bool hasSelectedSpk = selectedSpkName != null && selectedSpkName.isNotEmpty;
    final String selectedSpkDisplay = hasSelectedSpk ? _buildSpkDisplay(selectedSpkName) : "";
    final String selectedVoiceDisplayName = hasSourceWav ? sourceWavName : selectedSpkDisplay;
    final bool hasSelectedVoice = selectedVoiceDisplayName.isNotEmpty;

    String hintText;
    switch (demoType) {
      case .chat:
        hintText = s.ask_me_anything;
      case .fifthteenPuzzle:
      case .othello:
      case .sudoku:
      case .see:
        hintText = s.send_message_to_rwkv;
        if (shouldGuideImageSelection) hintText = s.please_select_an_image_first;
      case .tts:
        hintText = s.i_want_rwkv_to_say;
    }

    final textFieldEnabled = loaded && !loading;
    final qw = ref.watch(P.app.qw);
    final isDesktop = ref.watch(P.app.isDesktop);
    final appTheme = ref.watch(P.app.theme);

    final inputBarHorizontalPadding = appTheme.inputBarHorizontalPadding;
    final paddingBottom = ref.watch(P.app.paddingBottom) + appTheme.inputBarMinPaddingBottom;

    final inputBarShadowColor = appTheme.textInputShadowC;
    final inputBarBorderColor = appTheme.textInputBorderC;
    final inputBarBorderRadius = appTheme.inputBarBorderRadius;
    final inputBarBgColor = appTheme.textInputBgC;
    final inputBarShadowRadius = appTheme.inputBarShadowRadius;
    final inputBarShadowOffset = appTheme.inputBarShadowOffset;

    final textFieldWidget = Container(
      padding: .only(
        top: isTalk ? 0 : appTheme.inputBarTopDistance,
        left: inputBarHorizontalPadding,
        right: inputBarHorizontalPadding,
        bottom: paddingBottom,
      ),
      child: GestureDetector(
        onTap: textFieldEnabled ? null : _onTapTextFieldWhenItsDisabled,
        child: Container(
          decoration: BoxDecoration(
            color: inputBarBgColor,
            borderRadius: .circular(inputBarBorderRadius),
            border: Border.all(color: inputBarBorderColor, width: .5),
            boxShadow: [
              BoxShadow(
                color: inputBarShadowColor,
                blurRadius: inputBarShadowRadius,
                offset: inputBarShadowOffset,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              AnimatedSwitcher(
                duration: 250.ms,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      axisAlignment: -1,
                      sizeFactor: animation,
                      child: child,
                    ),
                  );
                },
                child: editingMessage
                    ? const _EditingMessageBanner(
                        key: ValueKey("editing-message-banner"),
                      )
                    : const SizedBox(
                        key: ValueKey("editing-message-banner-empty"),
                      ),
              ),
              if (isSee)
                AnimatedSwitcher(
                  duration: 250.ms,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        axisAlignment: -1,
                        sizeFactor: animation,
                        child: child,
                      ),
                    );
                  },
                  child: hasCurrentImage
                      ? _SeeImageSection(
                          key: const ValueKey("see-image-selected"),
                          imagePath: imagePath,
                          textFieldEnabled: textFieldEnabled,
                        )
                      : const SizedBox(
                          key: ValueKey("see-image-empty"),
                        ),
                ),
              if (isTalk)
                AnimatedSwitcher(
                  duration: 250.ms,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        axisAlignment: -1,
                        sizeFactor: animation,
                        child: child,
                      ),
                    );
                  },
                  child: hasSelectedVoice
                      ? _TalkSourceVoiceSection(
                          key: const ValueKey("talk-source-wav-selected"),
                          sourceVoiceName: selectedVoiceDisplayName,
                          textFieldEnabled: textFieldEnabled,
                          onTapPlayVoice: () async {
                            await _onTapPlaySelectedVoice(
                              selectedSourceWavPath: selectedSourceWavPath,
                              selectedSpkName: selectedSpkName,
                            );
                          },
                          onTapSetSourceWav: () {
                            TTSVoiceSourcePanels.showVoiceSourceTypePanel();
                          },
                        )
                      : const SizedBox(
                          key: ValueKey("talk-source-wav-empty"),
                        ),
                ),
              Row(
                crossAxisAlignment: .end,
                children: [
                  if (isSee)
                    _SeeImageQuickButton(
                      hasImage: hasCurrentImage,
                      shouldGuideImageSelection: shouldGuideImageSelection,
                      textFieldEnabled: textFieldEnabled,
                    ),
                  if (isTalk)
                    _TalkSourceQuickButton(
                      hasSelectedVoice: hasSelectedVoice,
                      textFieldEnabled: textFieldEnabled,
                      onTapSetSourceWav: () {
                        TTSVoiceSourcePanels.showVoiceSourceTypePanel();
                      },
                    ),
                  Expanded(
                    child: TextField(
                      focusNode: P.chat.focusNode,
                      enabled: textFieldEnabled,
                      controller: P.chat.textEditingController,
                      onSubmitted: P.chat.onKeyboardSubmitted,
                      onChanged: _onChanged,
                      onEditingComplete: P.chat.onEditingComplete,
                      onAppPrivateCommand: _onAppPrivateCommand,
                      onTap: _onTap,
                      onTapOutside: _onTapOutside,
                      keyboardType: TextInputType.multiline,
                      enableSuggestions: true,
                      textInputAction: TextInputAction.newline,
                      maxLines: 10,
                      minLines: 1,
                      decoration: InputDecoration(
                        contentPadding: isSee
                            ? .only(left: hasCurrentImage ? 12 : 8, top: 8, right: 8, bottom: 8)
                            : isTalk
                            ? .only(left: hasSelectedVoice ? 12 : 8, top: 8, right: 8, bottom: 8)
                            : const .only(left: 12, top: 4, right: 12, bottom: 4),
                        fillColor: qw,
                        focusColor: qw,
                        hoverColor: qw,
                        iconColor: qw,
                        border: .none,
                        enabledBorder: .none,
                        focusedBorder: .none,
                        focusedErrorBorder: .none,
                        hintText: hintText,
                        hintStyle: !isChat ? null : TextStyle(color: theme.colorScheme.onSurface.q(.5)),
                      ),
                    ),
                  ),
                  SendingInteraction(preferredDemoType: preferredDemoType ?? .chat),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!isDesktop) return textFieldWidget;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            return KeyEventResult.ignored;
          } else {
            P.chat.onSendButtonPressed(preferredDemoType: preferredDemoType ?? .chat);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: textFieldWidget,
    );
  }

  void _onChanged(String value) {}

  void _onTap() async {
    qq;
    await 300.msLater;
    await P.chat.scrollToBottom();
  }

  void _onAppPrivateCommand(String action, Map<String, dynamic> data) {}

  void _onTapOutside(PointerDownEvent event) {}

  void _onTapTextFieldWhenItsDisabled() {
    qq;
    if (!checkModelSelection(preferredDemoType: preferredDemoType ?? .chat)) return;
  }

  String _buildSpkDisplay(String? selectedSpkName) {
    if (selectedSpkName == null || selectedSpkName.isEmpty) return "";
    final (String flag, String nameCN, String nameEN) = P.talk.getSpkInfo(selectedSpkName);
    final List<String> displayParts = <String>[
      if (flag.isNotEmpty) flag,
      if (nameCN.isNotEmpty) nameCN,
      if (nameEN.isNotEmpty) nameEN,
    ];
    if (displayParts.isNotEmpty) return displayParts.join(" ");
    return P.talk.safe(selectedSpkName);
  }

  Future<void> _onTapPlaySelectedVoice({
    required String? selectedSourceWavPath,
    required String? selectedSpkName,
  }) async {
    String? targetPath;
    if (selectedSourceWavPath != null && selectedSourceWavPath.isNotEmpty) {
      targetPath = selectedSourceWavPath;
    } else if (selectedSpkName != null && selectedSpkName.isNotEmpty) {
      targetPath = await P.talk.getPrebuiltSpkAudioPathFromTemp(selectedSpkName);
    }

    if (targetPath == null || targetPath.isEmpty) return;

    P.msg.latestClicked.q = null;
    await P.see.play(path: targetPath);
  }
}

class _EditingMessageBanner extends StatelessWidget {
  const _EditingMessageBanner({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = S.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color onSurface = theme.colorScheme.onSurface;
    final Color bgColor = theme.colorScheme.surfaceContainer.q(.72);

    return Padding(
      padding: const .fromLTRB(8, 8, 8, 2),
      child: Container(
        padding: const .only(left: 10, top: 6, right: 6, bottom: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: .circular(12),
          border: Border.all(color: primary.q(.16), width: .5),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: primary.q(.88),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                s.editing,
                maxLines: 1,
                overflow: .ellipsis,
                style: TS(c: onSurface.q(.88), w: .w600, s: 13),
              ),
            ),
            Tooltip(
              message: s.cancel,
              child: GestureDetector(
                onTap: _onCancelEditingPressed,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: .circular(1000),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: onSurface.q(.78),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCancelEditingPressed() {
    P.app.hapticLight();
    P.chat.cancelEditing(clearInput: true);
  }
}

class _SeeImageSection extends StatelessWidget {
  final String imagePath;
  final bool textFieldEnabled;

  const _SeeImageSection({
    super.key,
    required this.imagePath,
    required this.textFieldEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surfaceContainer = theme.colorScheme.surfaceContainer;
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const .fromLTRB(8, 8, 8, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: textFieldEnabled ? P.see.selectImage : null,
          borderRadius: .circular(14),
          child: Container(
            padding: const .only(left: 8, top: 8, right: 4, bottom: 8),
            decoration: BoxDecoration(
              color: surfaceContainer.q(.7),
              borderRadius: .circular(14),
              border: Border.all(color: primary.q(.16)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: .circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return ColoredBox(
                          color: surfaceContainer,
                          child: Icon(Icons.broken_image_outlined, color: onSurface.q(.45)),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisAlignment: .center,
                    children: [
                      Text(
                        s.change_selected_image,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TS(c: onSurface.q(.88), w: .w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        imagePath.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TS(c: onSurface.q(.56), s: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: textFieldEnabled ? P.see.selectImage : null,
                  visualDensity: .compact,
                  tooltip: s.change_selected_image,
                  icon: Icon(Icons.swap_horiz_rounded, size: 18, color: onSurface.q(.75)),
                ),
                IconButton(
                  onPressed: textFieldEnabled
                      ? () {
                          P.see.imagePath.q = null;
                        }
                      : null,
                  visualDensity: .compact,
                  tooltip: s.clear,
                  icon: Icon(Icons.close_rounded, size: 18, color: onSurface.q(.75)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeeImageQuickButton extends ConsumerWidget {
  final bool hasImage;
  final bool shouldGuideImageSelection;
  final bool textFieldEnabled;

  const _SeeImageQuickButton({
    required this.hasImage,
    required this.shouldGuideImageSelection,
    required this.textFieldEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final appTheme = ref.watch(P.app.theme);
    final sendingButtonTouchMinSize = appTheme.sendingButtonTouchMinSize;

    return AnimatedSwitcher(
      duration: 250.ms,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            axis: Axis.horizontal,
            axisAlignment: -1,
            sizeFactor: animation,
            child: child,
          ),
        );
      },
      child: hasImage
          ? const SizedBox(
              key: ValueKey("see-image-quick-button-hidden"),
            )
          : C(
              key: const ValueKey("see-image-quick-button"),
              child: Material(
                color: Colors.transparent,
                child: Tooltip(
                  message: s.select_new_image,
                  child: GD(
                    onTap: textFieldEnabled ? P.see.selectImage : null,
                    child: Container(
                      width: sendingButtonTouchMinSize.width,
                      height: sendingButtonTouchMinSize.height,
                      decoration: BoxDecoration(
                        borderRadius: .circular(1000),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 22,
                          color: shouldGuideImageSelection ? primary : onSurface.q(.82),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _TalkSourceVoiceSection extends StatelessWidget {
  final String sourceVoiceName;
  final bool textFieldEnabled;
  final VoidCallback? onTapPlayVoice;
  final VoidCallback? onTapSetSourceWav;

  const _TalkSourceVoiceSection({
    super.key,
    required this.sourceVoiceName,
    required this.textFieldEnabled,
    required this.onTapPlayVoice,
    required this.onTapSetSourceWav,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color surfaceContainer = theme.colorScheme.surfaceContainer;
    final Color onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const .fromLTRB(8, 8, 8, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: textFieldEnabled ? onTapPlayVoice : null,
          borderRadius: .circular(14),
          child: Container(
            padding: const .only(left: 10, top: 4, right: 4, bottom: 4),
            decoration: BoxDecoration(
              color: surfaceContainer.q(.7),
              borderRadius: .circular(14),
              border: Border.all(color: primary.q(.16)),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.volume_up_rounded,
                  size: 20,
                  color: primary.q(.85),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisAlignment: .center,
                    children: <Widget>[
                      Text(
                        s.mimic + s.colon + sourceVoiceName,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TS(c: onSurface.q(.74), s: 14, w: .w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: textFieldEnabled ? onTapSetSourceWav : null,
                  visualDensity: .compact,
                  tooltip: s.voice_cloning,
                  icon: Icon(Icons.swap_horiz_rounded, size: 18, color: onSurface.q(.75)),
                ),
                IconButton(
                  onPressed: textFieldEnabled
                      ? () {
                          P.talk.selectSourceAudioPath.q = null;
                          P.talk.selectedSpkName.q = null;
                        }
                      : null,
                  visualDensity: .compact,
                  tooltip: s.clear,
                  icon: Icon(Icons.close_rounded, size: 18, color: onSurface.q(.75)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TalkSourceQuickButton extends ConsumerWidget {
  final bool hasSelectedVoice;
  final bool textFieldEnabled;
  final VoidCallback? onTapSetSourceWav;

  const _TalkSourceQuickButton({
    required this.hasSelectedVoice,
    required this.textFieldEnabled,
    required this.onTapSetSourceWav,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color onSurface = theme.colorScheme.onSurface;
    final appTheme = ref.watch(P.app.theme);
    final sendingButtonTouchMinSize = appTheme.sendingButtonTouchMinSize;

    return AnimatedSwitcher(
      duration: 250.ms,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            axis: Axis.horizontal,
            axisAlignment: -1,
            sizeFactor: animation,
            child: child,
          ),
        );
      },
      child: hasSelectedVoice
          ? const SizedBox(
              key: ValueKey("talk-source-wav-quick-button-hidden"),
            )
          : C(
              key: const ValueKey("talk-source-wav-quick-button"),
              child: Material(
                color: Colors.transparent,
                child: Tooltip(
                  message: s.voice_cloning,
                  child: GD(
                    onTap: textFieldEnabled ? onTapSetSourceWav : null,
                    child: Container(
                      width: sendingButtonTouchMinSize.width,
                      height: sendingButtonTouchMinSize.height,
                      decoration: BoxDecoration(
                        borderRadius: .circular(1000),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 22,
                          color: textFieldEnabled ? primary : onSurface.q(.82),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
