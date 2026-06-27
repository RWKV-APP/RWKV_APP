// ignore_for_file: dead_code, unused_local_variable, unused_element

// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/args.dart';
import 'package:zone/func/collection_utils.dart';
import 'package:zone/func/string_utils.dart';
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

    final children = mapIndexed(
      [
        SizedBox(height: (max(paddingTop, 40))),
        if (showLoadedModels) ...[
          Text(codeToName("loadedModels")),
          Text(loadedModels.entries.map((e) => "${e.key.name} id: ${e.value}").join("\n")),
        ],
        if (showLoadingStatus) ...[
          Text(codeToName("loadingStatus")),
          Text(
            loadingStatus.entries.map((e) => "${e.key.name} ${e.value.toString().replaceAll("LoadingStatus", "")}").join("\n"),
          ),
        ],
        if (showUnzipping) ...[Text(codeToName("unzipping")), Text(unzipping.toString())],
        if (showDemoType) ...[Text(codeToName("demoType")), Text(demoType.toString())],
        if (showCurrentGroupInfo) ...[Text(codeToName("currentGroupInfo")), Text(currentGroupInfo?.displayName ?? "null")],
        if (showLatestModel) ...[Text(codeToName("latestModel")), Text(latestModel?.name ?? "null")],
        if (showGeneratingId) ...[Text(codeToName("generatingId")), Text(generatingId?.toString() ?? "null")],
        if (showGenerating) ...[Text(codeToName("generating")), Text(generating.toString())],
        if (showHiddenPrefilling) ...[Text(codeToName("hiddenPrefilling")), Text(hiddenPrefilling.toString())],
        if (showSocName) ...[Text(codeToName("socName")), Text(socName)],
        if (showSocBrand) ...[Text(codeToName("socBrand")), Text(socBrand.toString())],
        if (showFrontendSocName) ...[Text(codeToName("frontendSocName")), Text(frontendSocName ?? "null")],
        if (showFrontendSocBrand) ...[Text(codeToName("frontendSocBrand")), Text(frontendSocBrand.toString())],
        if (showPreferredUIFont) ...[Text(codeToName("preferredUIFont")), Text(preferredUIFont ?? "null")],
        if (showPreferredMonospaceFont) ...[Text(codeToName("preferredMonospaceFont")), Text(preferredMonospaceFont ?? "null")],
        ...[
          if (!isMobile) ...[
            Text(codeToName("pthFolderEntries")),
            Text(pthFolderEntries.map((e) => e.path + (e.bookmark != null ? " [bookmark]" : "")).join("\n")),
          ],
          if (!isMobile) ...[
            Text(codeToName("pthFolders")),
            Text(pthFolders.map((e) => "${e.path} ${e.state.toString()} ${e.files.length}").join("\n")),
          ],
          if (!isMobile) ...[Text(codeToName("effectiveModelsDir")), Text(effectiveModelsDir)],
          if (!isMobile) ...[Text(codeToName("defaultModelsDir")), Text(defaultModelsDir)],
          if (!isMobile) ...[Text(codeToName("usingCustomModelsDir")), Text(usingCustomModelsDir.toString())],
          if (!isMobile) ...[Text(codeToName("customModelsDir")), Text(customModelsDir ?? "null")],
        ],
        if (showLoadingProgress) ...[
          Text(codeToName("loadingProgress")),
          Text(loadingProgress.entries.map((e) => "${e.key.name} ${e.value}").join("\n")),
        ],
        if (showMaxWidthAllowedForLayout) ...[Text(codeToName("maxWidthAllowedForLayout")), Text(maxWidthAllowedForLayout.toString())],
        if (showWidthRequiredForLayout) ...[Text(codeToName("widthRequiredForLayout")), Text(widthRequiredForLayout.toString())],
        if (showShouldUseWrapRatherThanRow) ...[
          Text(codeToName("shouldUseWrapRatherThanRow")),
          Text(shouldUseWrapRatherThanRow.toString()),
        ],
        if (showMessageListLayoutKeys) ...[
          Text(codeToName("messageListLayoutKeys")),
          Text(messageListLayoutKeys.entries.map((e) => "${e.key}: ${e.value}").join("\n")),
        ],
        if (showWidthRequiredForLayout) ...[Text(codeToName("widthRequiredForLayout")), Text(widthRequiredForLayout.toString())],
        if (showHomeItemTitleHeights) ...[
          Text(codeToName("homeItemTitleHeights")),
          Text(homeItemTitleHeights.entries.map((e) => "${e.key}: ${e.value}").join("\n")),
        ],
        if (showHomeItemDescriptionHeights) ...[
          Text(codeToName("homeItemDescriptionHeights")),
          Text(homeItemDescriptionHeights.entries.map((e) => "${e.key}: ${e.value}").join("\n")),
        ],
        if (showMaxHeightsOfHomeItemTitle) ...[Text(codeToName("maxHeightsOfHomeItemTitle")), Text(maxHeightsOfHomeItemTitle.toString())],
        if (showMaxHeightsOfHomeItemDescription) ...[
          Text(codeToName("maxHeightsOfHomeItemDescription")),
          Text(maxHeightsOfHomeItemDescription.toString()),
        ],
        if (showQuestions) ...[Text(codeToName("questions")), Text(questions.join("\n"))],
        if (showSupportedBatchSizes) ...[Text(codeToName("supportedBatchSizes")), Text(supportedBatchSizes.join(", "))],
        if (showBatchViewportWidth) ...[Text(codeToName("batchViewportWidth")), Text(batchViewportWidth.toString())],
        if (showBatchEnabled) ...[Text(codeToName("batchEnabled")), Text(batchEnabled.toString())],
        if (showBatchCount) ...[Text(codeToName("batchCount")), Text(batchCount.toString())],
        if (showBatchViewportSlotIndexes) ...[
          Text(codeToName("batchViewportSlotIndexes")),
          Text(_formatBatchViewportSlotIndexes(batchViewportSlotIndexes)),
        ],
      ],
      (index, e) {
        return Container(
          margin: .only(top: index % 2 == 0 ? 0 : 1),
          decoration: BoxDecoration(color: qb.withValues(alpha: .55)),
          child: e,
        );
      },
    );

    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Material(
          textStyle: TextStyle(
            fontFamily: "Monospace",
            color: qw,
            fontSize: 8,
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
          textStyle: TextStyle(
            fontFamily: "Monospace",
            color: qw,
            fontSize: 8,
          ),
          color: Colors.transparent,
          child: SizedBox(
            child: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: .start,
                crossAxisAlignment: .end,
                children: mapIndexed(
                  [
                    SizedBox(height: paddingTop),
                    Text(codeToName("paddingTop")),
                    Text(paddingTop.toString()),
                    Text(codeToName("loaded")),
                    Text(loaded.toString()),
                    Text(codeToName("running")),
                    Text(running.toString()),
                    Text(codeToName("page")),
                    Text(page.toString()),
                    Text(codeToName("mainPageNotIgnoring")),
                    Text(mainPageNotIgnoring.toString()),
                    Text(codeToName("modelSelectorShown")),
                    Text(modelSelectorShown.toString()),
                  ],
                  (index, e) {
                    return Container(
                      margin: .only(top: index % 2 == 0 ? 0 : 1),
                      decoration: BoxDecoration(color: qb.withValues(alpha: .66)),
                      child: e,
                    );
                  },
                ),
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
          textStyle: TextStyle(
            fontFamily: "Monospace",
            color: qw,
            fontSize: isDesktop ? 20 : 8,
          ),
          color: Colors.transparent,
          child: SizedBox(
            child: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: .start,
                crossAxisAlignment: .end,
                children: mapIndexed(
                  [
                    SizedBox(height: paddingTop),
                    Text(codeToName("currentModel")),
                    Text(currentModel?.fileName ?? "null"),
                    Text(codeToName("receiveId")),
                    Text(receiveId.toString()),
                    Text(codeToName("selectedSpkPanelFilter")),
                    Text(selectedSpkPanelFilter.toString()),
                    Text(codeToName("selectedLanguage")),
                    Text(selectedLanguage.toString()),
                    Text(codeToName("startTime")),
                    Text(startTime.toString()),
                    Text(codeToName("endTime")),
                    Text(endTime.toString()),
                    Text(codeToName("selectSourceAudioPath")),
                    Text(selectSourceAudioPath.toString()),
                    Text(codeToName("spkNames length")),
                    Text(spkNames.length.toString()),
                    Text(codeToName("spkShown")),
                    Text(spkShown.toString()),
                    Text(codeToName("audioInteractorShown")),
                    Text(audioInteractorShown.toString()),
                    Text(codeToName("intonationShown")),
                    Text(intonationShown.toString()),
                    Text(codeToName("selectSpkName")),
                    Text(selectSpkName.toString()),
                    Text(codeToName("selectSourceAudioPath")),
                    Text(selectSourceAudioPath.toString()),
                    Text(codeToName("textInInput")),
                    Text(textInInput.toString()),
                    // Text(codeToName("ttsCores")),
                    // Text(ttsCores.map((e) => e.name).join("\n")),
                    Text(codeToName("interactingInstruction")),
                    Text(interactingInstruction.toString()),
                    Text(codeToName("selectedInstruction")),
                    Text(selectedInstruction.toString()),
                    Text(codeToName("recording")),
                    Text(recording.toString()),
                    Text(codeToName("generating")),
                    Text(generating.toString()),
                    Text(codeToName("asFull")),
                    Text(asFull.toString()),
                    Text(codeToName("asExhaust")),
                    Text(asExhaust.toString()),
                  ],
                  (index, e) {
                    return Container(
                      margin: .only(top: index % 2 == 0 ? 0 : 1),
                      decoration: BoxDecoration(color: qb.withValues(alpha: .66)),
                      child: e,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
