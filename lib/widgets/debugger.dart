// ignore_for_file: dead_code, unused_local_variable, unused_element

// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';

// Project imports:
import 'package:zone/args.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/pager.dart';

class Debugger extends ConsumerWidget {
  const Debugger({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!false) return const SizedBox.shrink();
    final theme = Theme.of(context);
    if (!kDebugMode) return const SizedBox.shrink();

    final demoType = ref.watch(P.app.demoType);
    final pageKey = ref.watch(P.app.pageKey);

    final qw = ref.watch(P.app.qw);

    final currentWorldType = ref.watch(P.rwkvContext.currentWorldType);
    final currentModel = ref.watch(P.rwkvModel.latest);
    final visualFloatHeight = ref.watch(P.see.visualFloatHeight);
    final loading = ref.watch(P.rwkvModel.loading);
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
    final thinkingMode = ref.watch(P.rwkvParams.thinkingMode);
    final editingBotMessage = ref.watch(P.msg.editingBotMessage);
    final messages = ref.watch(P.msg.list);
    final ids = ref.watch(P.msg.ids);
    final socName = ref.watch(P.rwkvBackend.socName);
    final socBrand = ref.watch(P.rwkvBackend.socBrand);
    final frontendSocName = ref.watch(P.rwkvBackend.frontendSocName);
    final frontendSocBrand = ref.watch(P.rwkvBackend.frontendSocBrand);
    final availableModels = ref.watch(P.remote.chatWeights);
    final disableRemoteConfig = Args.disableRemoteConfig;
    final preferredThemeMode = ref.watch(P.app.preferredThemeMode);
    final appTheme = ref.watch(P.app.theme);
    final themeMode = ref.watch(P.preference.themeMode);
    final preferredDarkCustomTheme = ref.watch(P.preference.preferredDarkCustomTheme);
    final checkingLatency = ref.watch(P.guard.checkingLatency);
    final msgNode = ref.watch(P.msg.msgNode);
    final pool = ref.watch(P.msg.pool);
    final conversations = ref.watch(P.conversation.conversations);
    final supportedBatchSizes = ref.watch(P.rwkvParams.supportedBatchSizes);
    final receivingTokens = ref.watch(P.rwkvGeneration.generating);

    final batcbatchEnabledhCount = ref.watch(P.chat.batchEnabled);
    final batchEnabled = ref.watch(P.chat.batchEnabled);
    final batchViewportWidth = ref.watch(P.ui.batchViewportWidth);
    final batchCount = ref.watch(P.chat.batchCount);
    final batchViewportSlotIndexes = ref.watch(P.chat.batchViewportSlotIndexes);

    final loadedModels = ref.watch(P.rwkvModel.allLoaded);
    final loadingStatus = ref.watch(P.rwkvModel.loadingStatus);

    final unzipping = ref.watch(P.rwkvModel.unzipping);

    final currentGroupInfo = ref.watch(P.rwkvContext.currentGroupInfo);

    final latestModel = ref.watch(P.rwkvModel.latest);

    final generating = ref.watch(P.rwkvGeneration.generating);
    final generatingId = ref.watch(P.rwkvGeneration.generatingId);
    final hiddenPrefilling = ref.watch(P.rwkvGeneration.hiddenPrefilling);

    final preferredUIFont = ref.watch(P.preference.preferredUIFont);
    final preferredMonospaceFont = ref.watch(P.preference.preferredMonospaceFont);

    final pthFolderEntries = ref.watch(P.preference.pthFolderEntries);
    final pthFolders = ref.watch(P.pth.folders);
    final effectiveModelsDir = ref.watch(P.remote.effectiveModelsDir);
    final defaultModelsDir = ref.watch(P.remote.defaultModelsDir);
    final usingCustomModelsDir = ref.watch(P.remote.usingCustomModelsDir);
    final customModelsDir = ref.watch(P.preference.customModelsDir);

    final loadingProgress = ref.watch(P.rwkvModel.loadingProgress);

    final isMobile = ref.watch(P.app.isMobile);

    final maxWidthAllowedForLayout = ref.watch(P.ui.maxWidthAllowedForLayout);
    final widthRequiredForLayout = ref.watch(P.ui.widthRequiredForLayout);
    final shouldUseWrapRatherThanRow = ref.watch(P.ui.shouldUseWrapRatherThanRow);

    final messageListLayoutKeys = ref.watch(P.ui.messageListLayoutKeys);

    final homeItemTitleHeights = ref.watch(P.ui.homeItemTitleHeights);
    final homeItemDescriptionHeights = ref.watch(P.ui.homeItemDescriptionHeights);
    final maxHeightsOfHomeItemTitle = ref.watch(P.ui.maxHeightsOfHomeItemTitle);
    final maxHeightsOfHomeItemDescription = ref.watch(P.ui.maxHeightsOfHomeItemDescription);

    final questions = ref.watch(P.askQuestion.questions);

    // final supportedBatchSizes = ref.watch(P.rwkvParams.supportedBatchSizes);

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
    const showPage = false;
    const showScreenWidth = false;
    const showThinkingMode = false;
    const showDisableRemoteConfig = false;
    const showPreferredThemeMode = false;
    const showCustomTheme = false;
    const showThemeMode = false;
    const showPreferredDarkCustomTheme = false;
    const showCheckingLatency = false;
    const showConversation = false;
    const showCurrentModel = false;
    const showLoading = false;
    const showMsgNode = false;
    const showSupportedBatchSizes = true;
    const showBatchEnabled = true;
    const showBatchViewportWidth = true;
    const showBatchCount = true;
    const showBatchViewportSlotIndexes = true;
    const showLoadingProgress = false;
    const showMaxWidthAllowedForLayout = false;
    const showWidthRequiredForLayout = false;
    const showShouldUseWrapRatherThanRow = false;
    const showMessageListLayoutKeys = false;
    const showHomeItemTitleHeights = false;
    const showHomeItemDescriptionHeights = false;
    const showMaxHeightsOfHomeItemTitle = false;
    const showMaxHeightsOfHomeItemDescription = false;
    const showLoadedModels = false;
    const showLoadingStatus = false;
    const showUnzipping = false;
    const showDemoType = false;
    const showCurrentGroupInfo = false;
    const showLatestModel = false;
    const showGeneratingId = false;
    const showHiddenPrefilling = false;
    const showFrontendSocName = false;
    const showFrontendSocBrand = false;
    const showPreferredUIFont = false;
    const showPreferredMonospaceFont = false;
    const showPthFolderEntries = false;
    const showPthFolders = false;
    const showEffectiveModelsDir = false;
    const showDefaultModelsDir = false;
    const showUsingCustomModelsDir = false;
    const showCustomModelsDir = false;
    const showQuestions = true;
    const showGenerating = true;

    final children =
        [
          (max(paddingTop, 40)).h,
          if (showLoadedModels) ...[
            Text("loadedModels".codeToName),
            Text(loadedModels.entries.map((e) => "${e.key.name} id: ${e.value}").join("\n")),
          ],
          if (showLoadingStatus) ...[
            Text("loadingStatus".codeToName),
            Text(
              loadingStatus.entries.map((e) => "${e.key.name} ${e.value.toString().replaceAll("LoadingStatus", "")}").join("\n"),
            ),
          ],
          if (showUnzipping) ...[Text("unzipping".codeToName), Text(unzipping.toString())],
          if (showDemoType) ...[Text("demoType".codeToName), Text(demoType.toString())],
          if (showCurrentGroupInfo) ...[Text("currentGroupInfo".codeToName), Text(currentGroupInfo?.displayName ?? "null")],
          if (showLatestModel) ...[Text("latestModel".codeToName), Text(latestModel?.name ?? "null")],
          if (showGeneratingId) ...[Text("generatingId".codeToName), Text(generatingId?.toString() ?? "null")],
          if (showGenerating) ...[Text("generating".codeToName), Text(generating.toString())],
          if (showHiddenPrefilling) ...[Text("hiddenPrefilling".codeToName), Text(hiddenPrefilling.toString())],
          if (showSocName) ...[Text("socName".codeToName), Text(socName)],
          if (showSocBrand) ...[Text("socBrand".codeToName), Text(socBrand.toString())],
          if (showFrontendSocName) ...[Text("frontendSocName".codeToName), Text(frontendSocName ?? "null")],
          if (showFrontendSocBrand) ...[Text("frontendSocBrand".codeToName), Text(frontendSocBrand.toString())],
          if (showPreferredUIFont) ...[Text("preferredUIFont".codeToName), Text(preferredUIFont ?? "null")],
          if (showPreferredMonospaceFont) ...[Text("preferredMonospaceFont".codeToName), Text(preferredMonospaceFont ?? "null")],
          ...[
            if (!isMobile) ...[
              Text("pthFolderEntries".codeToName),
              Text(pthFolderEntries.map((e) => e.path + (e.bookmark != null ? " [bookmark]" : "")).join("\n")),
            ],
            if (!isMobile) ...[
              Text("pthFolders".codeToName),
              Text(pthFolders.map((e) => "${e.path} ${e.state.toString()} ${e.files.length}").join("\n")),
            ],
            if (!isMobile) ...[Text("effectiveModelsDir".codeToName), Text(effectiveModelsDir)],
            if (!isMobile) ...[Text("defaultModelsDir".codeToName), Text(defaultModelsDir)],
            if (!isMobile) ...[Text("usingCustomModelsDir".codeToName), Text(usingCustomModelsDir.toString())],
            if (!isMobile) ...[Text("customModelsDir".codeToName), Text(customModelsDir ?? "null")],
          ],
          if (showLoadingProgress) ...[
            Text("loadingProgress".codeToName),
            Text(loadingProgress.entries.map((e) => "${e.key.name} ${e.value}").join("\n")),
          ],
          if (showMaxWidthAllowedForLayout) ...[Text("maxWidthAllowedForLayout".codeToName), Text(maxWidthAllowedForLayout.toString())],
          if (showWidthRequiredForLayout) ...[Text("widthRequiredForLayout".codeToName), Text(widthRequiredForLayout.toString())],
          if (showShouldUseWrapRatherThanRow) ...[
            Text("shouldUseWrapRatherThanRow".codeToName),
            Text(shouldUseWrapRatherThanRow.toString()),
          ],
          if (showMessageListLayoutKeys) ...[
            Text("messageListLayoutKeys".codeToName),
            Text(messageListLayoutKeys.entries.map((e) => "${e.key}: ${e.value}").join("\n")),
          ],
          if (showWidthRequiredForLayout) ...[Text("widthRequiredForLayout".codeToName), Text(widthRequiredForLayout.toString())],
          if (showHomeItemTitleHeights) ...[
            Text("homeItemTitleHeights".codeToName),
            Text(homeItemTitleHeights.entries.map((e) => "${e.key}: ${e.value}").join("\n")),
          ],
          if (showHomeItemDescriptionHeights) ...[
            Text("homeItemDescriptionHeights".codeToName),
            Text(homeItemDescriptionHeights.entries.map((e) => "${e.key}: ${e.value}").join("\n")),
          ],
          if (showMaxHeightsOfHomeItemTitle) ...[Text("maxHeightsOfHomeItemTitle".codeToName), Text(maxHeightsOfHomeItemTitle.toString())],
          if (showMaxHeightsOfHomeItemDescription) ...[
            Text("maxHeightsOfHomeItemDescription".codeToName),
            Text(maxHeightsOfHomeItemDescription.toString()),
          ],
          if (showQuestions) ...[Text("questions".codeToName), Text(questions.join("\n"))],
          if (showSupportedBatchSizes) ...[Text("supportedBatchSizes".codeToName), Text(supportedBatchSizes.join(", "))],
          if (showBatchViewportWidth) ...[Text("batchViewportWidth".codeToName), Text(batchViewportWidth.toString())],
          if (showBatchEnabled) ...[Text("batchEnabled".codeToName), Text(batchEnabled.toString())],
          if (showBatchCount) ...[Text("batchCount".codeToName), Text(batchCount.toString())],
          if (showBatchViewportSlotIndexes) ...[
            Text("batchViewportSlotIndexes".codeToName),
            Text(_formatBatchViewportSlotIndexes(batchViewportSlotIndexes)),
          ],
        ].indexMap((index, e) {
          return Container(
            margin: .only(top: index % 2 == 0 ? 0 : 1),
            decoration: BoxDecoration(color: qb.q(.55)),
            child: e,
          );
        });

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
          child: Column(
            mainAxisAlignment: .start,
            crossAxisAlignment: .end,
            children: children,
          ),
        ),
      ),
    );
  }
}

String _formatBatchViewportSlotIndexes(({int messageId, Set<int> indexes})? value) {
  if (value == null) return "null";
  final indexes = value.indexes.toList()..sort();
  return "msg ${value.messageId}: ${indexes.join(", ")}";
}

class _SudokuDebugger extends ConsumerWidget {
  const _SudokuDebugger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paddingTop = ref.watch(P.app.paddingTop);
    final loaded = ref.watch(P.rwkvModel.loaded);
    final running = ref.watch(P.sudoku.running);
    final page = ref.watch(Pager.page);
    final mainPageNotIgnoring = ref.watch(Pager.atMainPage);

    final qw = ref.watch(P.app.qw);
    final qb = ref.watch(P.app.qb);

    final modelSelectorShown = ref.watch(P.remote.modelSelectorShown);

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
                      Text("paddingTop".codeToName),
                      Text(paddingTop.toString()),
                      Text("loaded".codeToName),
                      Text(loaded.toString()),
                      Text("running".codeToName),
                      Text(running.toString()),
                      Text("page".codeToName),
                      Text(page.toString()),
                      Text("mainPageNotIgnoring".codeToName),
                      Text(mainPageNotIgnoring.toString()),
                      Text("modelSelectorShown".codeToName),
                      Text(modelSelectorShown.toString()),
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
    final theme = Theme.of(context);
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
    final currentModel = ref.watch(P.rwkvModel.latest);

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
                      Text("currentModel".codeToName),
                      Text(currentModel?.fileName ?? "null"),
                      Text("receiveId".codeToName),
                      Text(receiveId.toString()),
                      Text("selectedSpkPanelFilter".codeToName),
                      Text(selectedSpkPanelFilter.toString()),
                      Text("selectedLanguage".codeToName),
                      Text(selectedLanguage.toString()),
                      Text("startTime".codeToName),
                      Text(startTime.toString()),
                      Text("endTime".codeToName),
                      Text(endTime.toString()),
                      Text("selectSourceAudioPath".codeToName),
                      Text(selectSourceAudioPath.toString()),
                      Text("spkNames length".codeToName),
                      Text(spkNames.length.toString()),
                      Text("spkShown".codeToName),
                      Text(spkShown.toString()),
                      Text("audioInteractorShown".codeToName),
                      Text(audioInteractorShown.toString()),
                      Text("intonationShown".codeToName),
                      Text(intonationShown.toString()),
                      Text("selectSpkName".codeToName),
                      Text(selectSpkName.toString()),
                      Text("selectSourceAudioPath".codeToName),
                      Text(selectSourceAudioPath.toString()),
                      Text("textInInput".codeToName),
                      Text(textInInput.toString()),
                      // Text("ttsCores".codeToName),
                      // Text(ttsCores.map((e) => e.name).join("\n")),
                      Text("interactingInstruction".codeToName),
                      Text(interactingInstruction.toString()),
                      Text("selectedInstruction".codeToName),
                      Text(selectedInstruction.toString()),
                      Text("recording".codeToName),
                      Text(recording.toString()),
                      Text("generating".codeToName),
                      Text(generating.toString()),
                      Text("asFull".codeToName),
                      Text(asFull.toString()),
                      Text("asExhaust".codeToName),
                      Text(asExhaust.toString()),
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
