// ignore: unused_import

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/func/extensions/num.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/sending_interaction.dart';

class InputTextField extends ConsumerWidget {
  final DemoType? preferredDemoType;

  const InputTextField({super.key, this.preferredDemoType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final loaded = ref.watch(P.rwkv.loaded);
    final loading = ref.watch(P.rwkv.loading);
    final DemoType demoType = preferredDemoType ?? ref.watch(P.app.demoType);
    final isChat = demoType == .chat;
    final isTTS = demoType == .tts;
    final isSee = demoType == .see;

    final imagePath = isSee ? ref.watch(P.see.imagePath) : null;
    final hasAtLeastOneImage = isSee ? ref.watch(P.msg.hasAtLeastOneImage) : false;
    final hasCurrentImage = imagePath != null && imagePath.isNotEmpty;
    final shouldGuideImageSelection = isSee && !hasCurrentImage && !hasAtLeastOneImage;

    String hintText;
    switch (demoType) {
      case .chat:
      case .fifthteenPuzzle:
      case .othello:
      case .sudoku:
      case .see:
        hintText = s.send_message_to_rwkv;
      case .tts:
        hintText = s.i_want_rwkv_to_say;
    }
    if (isChat) {
      hintText = s.ask_me_anything;
    }
    if (shouldGuideImageSelection) {
      hintText = s.please_select_an_image_first;
    }

    final textFieldEnabled = loaded && !loading;
    final intonationShown = ref.watch(P.talk.intonationShown);
    final keyboardType = intonationShown ? TextInputType.none : TextInputType.multiline;
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
        top: isTTS ? 0 : appTheme.inputBarTopDistance,
        left: inputBarHorizontalPadding,
        right: inputBarHorizontalPadding,
        bottom: isTTS ? 0 : paddingBottom,
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
              if (isSee)
                _SeeImageSection(
                  imagePath: imagePath,
                  shouldGuideImageSelection: shouldGuideImageSelection,
                  textFieldEnabled: textFieldEnabled,
                ),
              Row(
                crossAxisAlignment: .end,
                children: [
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
                      keyboardType: keyboardType,
                      enableSuggestions: true,
                      textInputAction: TextInputAction.newline,
                      maxLines: 10,
                      minLines: 1,
                      decoration: InputDecoration(
                        contentPadding: isSee
                            ? const .only(left: 12, top: 8, right: 8, bottom: 8)
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
                        hintStyle: !isChat ? null : const TextStyle(color: Colors.grey),
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
}

class _SeeImageSection extends ConsumerWidget {
  final String? imagePath;
  final bool shouldGuideImageSelection;
  final bool textFieldEnabled;

  const _SeeImageSection({
    required this.imagePath,
    required this.shouldGuideImageSelection,
    required this.textFieldEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surfaceContainer = theme.colorScheme.surfaceContainer;
    final onSurface = theme.colorScheme.onSurface;
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Padding(
      padding: const .fromLTRB(8, 8, 8, 6),
      child: AnimatedSwitcher(
        duration: 180.ms,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: hasImage
            ? Material(
                key: const ValueKey("see-image-selected"),
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
                              File(imagePath!),
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
                                imagePath!.split(Platform.pathSeparator).last,
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
              )
            : Material(
                key: const ValueKey("see-image-empty"),
                color: Colors.transparent,
                child: InkWell(
                  onTap: textFieldEnabled ? P.see.selectImage : null,
                  borderRadius: .circular(14),
                  child: AnimatedContainer(
                    duration: 180.ms,
                    curve: Curves.easeOutCubic,
                    padding: const .symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: shouldGuideImageSelection ? primary.q(.1) : surfaceContainer.q(.5),
                      borderRadius: .circular(14),
                      border: Border.all(color: shouldGuideImageSelection ? primary.q(.32) : primary.q(.14)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 18,
                          color: shouldGuideImageSelection ? primary : onSurface.q(.8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            shouldGuideImageSelection ? s.please_select_an_image_first : s.select_new_image,
                            maxLines: 1,
                            overflow: .ellipsis,
                            style: TS(c: shouldGuideImageSelection ? primary.q(.95) : onSurface.q(.8), w: .w500),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.select_new_image,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: TS(c: primary.q(.88), s: 13, w: .w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
