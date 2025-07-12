// ignore_for_file: dead_code

import 'package:flutter/foundation.dart';
import 'package:zone/args.dart';
import 'package:zone/model/demo_type.dart';
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

    final qw = ref.watch(P.app.qw);

    switch (demoType) {
      case DemoType.sudoku:
        return const _SudokuDebugger();
      case DemoType.tts:
        return const _TTSDebugger();
      case DemoType.chat:
      case DemoType.fifthteenPuzzle:
      case DemoType.othello:
      case DemoType.world:
    }

    final currentWorldType = ref.watch(P.rwkv.currentWorldType);
    final currentModel = ref.watch(P.rwkv.currentModel);
    final visualFloatHeight = ref.watch(P.world.visualFloatHeight);
    final loading = ref.watch(P.rwkv.loading);
    final playing = ref.watch(P.world.playing);
    final latestClickedMessage = ref.watch(P.msg.latestClicked);
    final inputHeight = ref.watch(P.chat.inputHeight);
    final hasFocus = ref.watch(P.chat.hasFocus);
    final isOthello = demoType == DemoType.othello;
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
    final availableModels = ref.watch(P.fileManager.availableModels);
    final unavailableModels = ref.watch(P.fileManager.unavailableModels);
    final disableRemoteConfig = Args.disableRemoteConfig;
    final preferredThemeMode = ref.watch(P.app.preferredThemeMode);
    final customTheme = ref.watch(P.app.customTheme);
    final themeMode = ref.watch(P.preference.themeMode);
    final preferredDarkCustomTheme = ref.watch(P.preference.preferredDarkCustomTheme);
    final checkingLatency = ref.watch(P.guard.checkingLatency);
    final msgNode = ref.watch(P.msg.msgNode);
    final pool = ref.watch(P.msg.pool);
    final pageKey = ref.watch(P.app.pageKey);
    final source = ref.watch(P.translator.source);
    final result = ref.watch(P.translator.result);
    final pageKey = ref.watch(P.app.pageKey);
    final runningTaskKey = ref.watch(P.translator.runningTaskKey);
    final translations = ref.watch(P.translator.translations);
    final runningTasks = ref.watch(P.backend.runningTasks);
    final completerPool = ref.watch(P.translator.completerPool);
    final isGenerating = ref.watch(P.translator.isGenerating);
    final taskHandledCount = ref.watch(P.backend.taskHandledCount);
    final taskReceivedCount = ref.watch(P.backend.taskReceivedCount);

    const showDrawerWidth = false;
    const showEditingBotMessage = false;
    const showAvailableModels = false;
    const showUnavailableModels = false;
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
    const showCurrentModel = false;
    const showLoading = false;
    const showMsgNode = true;

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
          color: kC,
          child: SB(
            child: C(
              decoration: const BD(color: kC),
              child: Column(
                mainAxisAlignment: MAA.start,
                crossAxisAlignment: CAA.end,
                children:
                    [
                      paddingTop.h,
                      if (currentWorldType != null && !isOthello) T("currentWorldType".codeToName),
                      if (currentWorldType != null && !isOthello) T(currentWorldType.toString()),
                      if (currentWorldType != null && !isOthello) T("visualFloatHeight".codeToName),
                      if (currentWorldType != null) T(visualFloatHeight.toString()),
                      if (showCurrentModel) ...[T("currentModel".codeToName), T(currentModel?.fileName ?? "null")],
                      if (showLoading) ...[T("loading".codeToName), T(loading.toString())],
                      if (currentWorldType != null) T("playing".codeToName),
                      if (currentWorldType != null) T(playing.toString()),
                      if (!isOthello) T("latestClickedMessage".codeToName),
                      T((latestClickedMessage?.id.toString() ?? "null")),
                      if (!isOthello) T("inputHeight".codeToName),
                      T(inputHeight.toString()),
                      if (!isOthello) T("hasFocus".codeToName),
                      T(hasFocus.toString()),
                      if (showAtMainPage) ...[T("atMainPage".codeToName), T(atMainPage.toString())],
                      if (showPage) ...[T("page".codeToName), T(page.toString())],

                      T("receiveId".codeToName),
                      T(receiveId.toString()),
                      if (showEditingIndex) ...[T("editingIndex".codeToName), T(editingIndex.toString())],
                      if (showDrawerWidth) ...[T("drawerWidth".codeToName), T(drawerWidth.toString())],
                      if (showScreenWidth) ...[T("screenWidth".codeToName), T(screenWidth.toString())],
                      if (showThinkingMode) ...[T("thinkingMode".codeToName), T(thinkingMode.toString())],
                      if (showEditingBotMessage) ...[T("editingBotMessage".codeToName), T(editingBotMessage.toString())],
                      if (showMessages) ...[T("messages length".codeToName), T(messages.length.toString())],
                      if (showMessages) ...[T("messages changing".codeToName), T(messages.m((e) => e.changing).join(", "))],
                      if (showIds) ...[T("ids".codeToName), T(ids.toString())],
                      if (showSocName) ...[T("socName".codeToName), T(socName)],
                      if (showSocBrand) ...[T("socBrand".codeToName), T(socBrand.toString())],
                      if (showAvailableModels) ...[T("availableModels".codeToName), T(availableModels.map((e) => e.name).join("\n"))],
                      if (showUnavailableModels) ...[T("unavailableModels".codeToName), T(unavailableModels.map((e) => e.name).join("\n"))],
                      if (showDisableRemoteConfig) ...[T("disableRemoteConfig".codeToName), T(disableRemoteConfig.toString())],
                      if (showPreferredThemeMode) ...[T("preferredThemeMode".codeToName), T(preferredThemeMode.toString())],
                      if (showCustomTheme) ...[T("customTheme".codeToName), T(customTheme.runtimeType.toString())],
                      if (showThemeMode) ...[T("themeMode".codeToName), T(themeMode.toString())],
                      if (showPreferredDarkCustomTheme) ...[
                        T("preferredDarkCustomTheme".codeToName),
                        T(preferredDarkCustomTheme.runtimeType.toString()),
                      ],
                      if (showCheckingLatency) ...[T("checkingLatency".codeToName), T(checkingLatency.toString())],
                      if (showConversation) ...[T("currentCreatedAtUS".codeToName), T(currentCreatedAtUS.toString())],
                      if (showMsgNode) ...[T("msgNode.createAtInUS".codeToName), T(msgNode.createAtInUS.toString())],
                      if (showPool) ...[T("pool".codeToName), T((pool.values.m((e) => e.id)).toString())],
                      T("pageKey".codeToName),
                      T(pageKey.toString()),
                      T("source".codeToName),
                      T(source),
                      T("result".codeToName),
                      T(result),
                      T("pageKey".codeToName),
                      T(pageKey.toString()),
                      T("runningTaskKey".codeToName),
                      T(runningTaskKey.toString()),
                      T("translations.length".codeToName),
                      T(translations.length.toString()),
                      T("runningTasks.length".codeToName),
                      T(runningTasks.length.toString()),
                      T("completerPool.length".codeToName),
                      T(completerPool.length.toString()),
                      T("isGenerating".codeToName),
                      T(isGenerating.toString()),
                      T("taskHandledCount".codeToName),
                      T(taskHandledCount.toString()),
                      T("taskReceivedCount".codeToName),
                      T(taskReceivedCount.toString()),
                    ].indexMap((index, e) {
                      return C(
                        margin: EI.o(t: index % 2 == 0 ? 0 : 1),
                        decoration: BD(color: qb.q(.55)),
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
          color: kC,
          child: SB(
            child: C(
              decoration: const BD(color: kC),
              child: Column(
                mainAxisAlignment: MAA.start,
                crossAxisAlignment: CAA.end,
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
                      return C(
                        margin: EI.o(t: index % 2 == 0 ? 0 : 1),
                        decoration: BD(color: qb.q(.66)),
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
    final audioInteractorShown = ref.watch(P.tts.audioInteractorShown);
    final endTime = ref.watch(P.world.endTime);
    final filePaths = ref.watch(P.tts.filePaths);
    final interactingInstruction = ref.watch(P.tts.interactingInstruction);
    final intonationShown = ref.watch(P.tts.intonationShown);
    final qb = ref.watch(P.app.qb);
    final overallProgress = ref.watch(P.tts.overallProgress);
    final paddingTop = ref.watch(P.app.paddingTop);
    final perWavProgress = ref.watch(P.tts.perWavProgress);
    final receiveId = ref.watch(P.chat.receiveId);
    final recording = ref.watch(P.world.recording);
    final selectSourceAudioPath = ref.watch(P.tts.selectSourceAudioPath);
    final selectSpkName = ref.watch(P.tts.selectedSpkName);
    final selectedIndex = ref.watch(P.tts.instructions(interactingInstruction));
    final selectedInstruction = selectedIndex != null ? interactingInstruction.options[selectedIndex] : null;
    final selectedLanguage = ref.watch(P.tts.selectedLanguage);
    final selectedSpkName = ref.watch(P.tts.selectedSpkName);
    final selectedSpkPanelFilter = ref.watch(P.tts.selectedSpkPanelFilter);
    final spkNames = ref.watch(P.tts.spkPairs);
    final spkShown = ref.watch(P.tts.spkShown);
    final startTime = ref.watch(P.world.startTime);
    final textInInput = ref.watch(P.tts.textInInput);
    final ttsDone = ref.watch(P.tts.ttsDone);
    final qw = ref.watch(P.app.qw);

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
          color: kC,
          child: SB(
            child: C(
              decoration: const BD(color: kC),
              child: Column(
                mainAxisAlignment: MAA.start,
                crossAxisAlignment: CAA.end,
                children:
                    [
                      paddingTop.h,
                      T("paddingTop".codeToName),
                      T(paddingTop.toString()),
                      T("overallProgress".codeToName),
                      T(overallProgress.toString()),
                      T("perWavProgress".codeToName),
                      T(perWavProgress.toString()),
                      T("filePaths".codeToName),
                      Column(
                        children: filePaths.map((e) => T(e)).toList(),
                      ),
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
                      T("selectedSpkName".codeToName),
                      T(selectedSpkName.toString()),
                      T("selectSourceAudioPath".codeToName),
                      T(selectSourceAudioPath.toString()),
                      T("ttsDone".codeToName),
                      T(ttsDone.toString()),
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
                    ].indexMap((index, e) {
                      return C(
                        margin: EI.o(t: index % 2 == 0 ? 0 : 1),
                        decoration: BD(color: qb.q(.66)),
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
