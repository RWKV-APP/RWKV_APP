// ignore_for_file: dead_code, unused_local_variable, unused_element

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:zone/args.dart';
import 'package:zone/store/p.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:zone/widgets/pager.dart';

class Debugger extends ConsumerWidget {
  const Debugger({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Args.showHaloDebugger) return const SizedBox.shrink();
    if (!kDebugMode) return const SizedBox.shrink();

    final demoType = ref.watch(P.app.demoType);
    final pageKey = ref.watch(P.app.pageKey);

    final qw = ref.watch(P.app.qw);

    final currentWorldType = ref.watch(P.rwkv.currentWorldType);
    final currentModel = ref.watch(P.rwkv.latestModel);
    final visualFloatHeight = ref.watch(P.see.visualFloatHeight);
    final loading = ref.watch(P.rwkv.loading);
    final playing = ref.watch(P.see.playing);
    final latestClickedMessage = ref.watch(P.msg.latestClicked);
    final inputHeight = ref.watch(P.chat.inputHeight);
    final hasFocus = ref.watch(P.chat.hasFocus);
    final isOthello = demoType == .othello;
    final paddingTop = ref.watch(P.app.paddingTop);
    final page = ref.watch(Pager.page);
    final atMainPage = ref.watch(Pager.atMainPage);
    final currentCreatedAtUS = ref.watch(P.conversation.currentCreatedAtUS);
    final editingIndex = ref.watch(P.msg.editingOrRegeneratingIndex);
    final receiveId = ref.watch(P.chat.receiveId);
    final qb = ref.watch(P.app.qb);
    final drawerWidth = ref.watch(Pager.drawerWidth);
    final screenWidth = ref.watch(P.app.screenWidth);
    final thinkingMode = ref.watch(P.rwkv.thinkingMode);
    final editingBotMessage = ref.watch(P.msg.editingBotMessage);
    final messages = ref.watch(P.msg.list);
    final ids = ref.watch(P.msg.ids);
    final socName = ref.watch(P.rwkv.socName);
    final socBrand = ref.watch(P.rwkv.socBrand);
    final availableModels = ref.watch(P.fileManager.chatWeights);
    final disableRemoteConfig = Args.disableRemoteConfig;
    final preferredThemeMode = ref.watch(P.app.preferredThemeMode);
    final customTheme = ref.watch(P.app.customTheme);
    final themeMode = ref.watch(P.preference.themeMode);
    final preferredDarkCustomTheme = ref.watch(P.preference.preferredDarkCustomTheme);
    final checkingLatency = ref.watch(P.guard.checkingLatency);
    final msgNode = ref.watch(P.msg.msgNode);
    final pool = ref.watch(P.msg.pool);
    final conversations = ref.watch(P.conversation.conversations);
    final supportedBatchSizes = ref.watch(P.rwkv.supportedBatchSizes);
    final receivingTokens = ref.watch(P.chat.receivingTokens);

    final loadedModels = ref.watch(P.rwkv.loadedModels);
    final loadingStatus = ref.watch(P.rwkv.loadingStatus);

    final unzipping = ref.watch(P.rwkv.unzipping);

    final currentGroupInfo = ref.watch(P.rwkv.currentGroupInfo);

    final latestModel = ref.watch(P.rwkv.latestModel);

    const showDrawerWidth = false;
    const showEditingBotMessage = false;
    const showAvailableModels = false;
    const showSocName = false;
    const showSocBrand = false;
    const showIds = false;
    const showPool = false;
    const showMessages = false;
    const showEditingIndex = false;
    const showAtMainPage = false;
    const showPage = true;
    const showScreenWidth = false;
    const showThinkingMode = true;
    const showDisableRemoteConfig = false;
    const showPreferredThemeMode = false;
    const showCustomTheme = false;
    const showThemeMode = false;
    const showPreferredDarkCustomTheme = false;
    const showCheckingLatency = false;
    const showConversation = true;
    const showCurrentModel = true;
    const showLoading = false;
    const showMsgNode = true;
    const showSupportedBatchSizes = true;

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Material(
          textStyle: TS(
            ff: "Monospace",
            c: qw,
            s: 8,
          ),
          color: Colors.transparent,
          child: SizedBox(
            child: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: .start,
                crossAxisAlignment: .end,
                children:
                    [
                      (max(paddingTop, 40)).h,
                      T("loadedModels".codeToName),
                      T(loadedModels.entries.map((e) => "${e.key.name} id: ${e.value}").join("\n")),
                      T("loadingStatus".codeToName),
                      T(loadingStatus.entries.map((e) => "${e.key.name} ${e.value.toString().replaceAll("LoadingStatus", "")}").join("\n")),
                      T("unzipping".codeToName),
                      T(unzipping.toString()),
                      T("demoType".codeToName),
                      T(demoType.toString()),
                      T("currentGroupInfo".codeToName),
                      T(currentGroupInfo?.displayName ?? "null"),
                      T("latestModel".codeToName),
                      T(latestModel?.name ?? "null"),
                    ].indexMap((index, e) {
                      return Container(
                        margin: .only(top: index % 2 == 0 ? 0 : 1),
                        decoration: BoxDecoration(color: qb.q(.55)),
                        child: e,
                      );
                    }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SudokuDebugger extends ConsumerWidget {
  const _SudokuDebugger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingTop = ref.watch(P.app.paddingTop);
    final loaded = ref.watch(P.rwkv.loaded);
    final running = ref.watch(P.sudoku.running);
    final page = ref.watch(Pager.page);
    final mainPageNotIgnoring = ref.watch(Pager.atMainPage);

    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);

    final modelSelectorShown = ref.watch(P.fileManager.modelSelectorShown);

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Material(
          textStyle: TS(
            ff: "Monospace",
            c: qw,
            s: 8,
          ),
          color: Colors.transparent,
          child: SizedBox(
            child: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: .start,
                crossAxisAlignment: .end,
                children:
                    [
                      paddingTop.h,
                      T("paddingTop".codeToName),
                      T(paddingTop.toString()),
                      T("loaded".codeToName),
                      T(loaded.toString()),
                      T("running".codeToName),
                      T(running.toString()),
                      T("page".codeToName),
                      T(page.toString()),
                      T("mainPageNotIgnoring".codeToName),
                      T(mainPageNotIgnoring.toString()),
                      T("modelSelectorShown".codeToName),
                      T(modelSelectorShown.toString()),
                    ].indexMap((index, e) {
                      return Container(
                        margin: .only(top: index % 2 == 0 ? 0 : 1),
                        decoration: BoxDecoration(color: qb.q(.66)),
                        child: e,
                      );
                    }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TTSDebugger extends ConsumerWidget {
  const _TTSDebugger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioInteractorShown = ref.watch(P.talk.audioInteractorShown);
    final endTime = ref.watch(P.see.endTime);
    final interactingInstruction = ref.watch(P.talk.interactingInstruction);
    final intonationShown = ref.watch(P.talk.intonationShown);
    final qb = ref.watch(P.app.qb);
    final paddingTop = ref.watch(P.app.paddingTop);
    final receiveId = ref.watch(P.chat.receiveId);
    final recording = ref.watch(P.see.recording);
    final selectSourceAudioPath = ref.watch(P.talk.selectSourceAudioPath);
    final selectSpkName = ref.watch(P.talk.selectedSpkName);
    final selectedIndex = ref.watch(P.talk.instructions(interactingInstruction));
    final selectedInstruction = selectedIndex != null ? interactingInstruction.options[selectedIndex] : null;
    final selectedLanguage = ref.watch(P.talk.selectedLanguage);
    final selectedSpkName = ref.watch(P.talk.selectedSpkName);
    final selectedSpkPanelFilter = ref.watch(P.talk.selectedSpkPanelFilter);
    final spkNames = ref.watch(P.talk.spkPairs);
    final spkShown = ref.watch(P.talk.spkShown);
    final startTime = ref.watch(P.see.startTime);
    final textInInput = ref.watch(P.talk.textInInput);
    final qw = ref.watch(P.app.qw);
    final isDesktop = ref.watch(P.app.isDesktop);
    final generating = ref.watch(P.talk.generating);
    final asFull = ref.watch(P.talk.asFull);
    final asExhaust = ref.watch(P.talk.asExhaust);
    final currentModel = ref.watch(P.rwkv.latestModel);

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Material(
          textStyle: TS(
            ff: "Monospace",
            c: qw,
            s: isDesktop ? 20 : 8,
          ),
          color: Colors.transparent,
          child: SizedBox(
            child: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: .start,
                crossAxisAlignment: .end,
                children:
                    [
                      paddingTop.h,
                      T("currentModel".codeToName),
                      T(currentModel?.fileName ?? "null"),
                      T("receiveId".codeToName),
                      T(receiveId.toString()),
                      T("selectedSpkPanelFilter".codeToName),
                      T(selectedSpkPanelFilter.toString()),
                      T("selectedLanguage".codeToName),
                      T(selectedLanguage.toString()),
                      T("startTime".codeToName),
                      T(startTime.toString()),
                      T("endTime".codeToName),
                      T(endTime.toString()),
                      T("selectSourceAudioPath".codeToName),
                      T(selectSourceAudioPath.toString()),
                      T("spkNames length".codeToName),
                      T(spkNames.length.toString()),
                      T("spkShown".codeToName),
                      T(spkShown.toString()),
                      T("audioInteractorShown".codeToName),
                      T(audioInteractorShown.toString()),
                      T("intonationShown".codeToName),
                      T(intonationShown.toString()),
                      T("selectSpkName".codeToName),
                      T(selectSpkName.toString()),
                      T("selectSourceAudioPath".codeToName),
                      T(selectSourceAudioPath.toString()),
                      T("textInInput".codeToName),
                      T(textInInput.toString()),
                      // T("ttsCores".codeToName),
                      // T(ttsCores.map((e) => e.name).join("\n")),
                      T("interactingInstruction".codeToName),
                      T(interactingInstruction.toString()),
                      T("selectedInstruction".codeToName),
                      T(selectedInstruction.toString()),
                      T("recording".codeToName),
                      T(recording.toString()),
                      T("generating".codeToName),
                      T(generating.toString()),
                      T("asFull".codeToName),
                      T(asFull.toString()),
                      T("asExhaust".codeToName),
                      T(asExhaust.toString()),
                    ].indexMap((index, e) {
                      return Container(
                        margin: .only(top: index % 2 == 0 ? 0 : 1),
                        decoration: BoxDecoration(color: qb.q(.66)),
                        child: e,
                      );
                    }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
