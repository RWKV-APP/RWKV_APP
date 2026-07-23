part of '../benchmark.dart';

class _AgentTest extends ConsumerWidget {
  const _AgentTest();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cases = ref.watch(P.agent.cases);
    final selectedCaseIndex = ref.watch(P.agent.selectedCaseIndex);
    final records = ref.watch(P.agent.records);
    final reportRecords = ref.watch(P.agent.reportRecords);
    final report = ref.watch(P.agent.report);
    final model = ref.watch(P.rwkvModel.latest);
    final events = ref.watch(P.agent.events);
    final running = ref.watch(P.agent.running);
    final runningAll = ref.watch(P.agent.runningAll);
    final currentCaseName = ref.watch(P.agent.currentCaseName);
    final currentCaseOrdinal = ref.watch(P.agent.currentCaseOrdinal);
    final runModelName = ref.watch(P.agent.runModelName);
    final liveModelOutput = ref.watch(P.agent.liveModelOutput);
    final verdict = ref.watch(P.agent.verdict);
    final error = ref.watch(P.agent.error);
    final evaluationMode = ref.watch(P.agent.evaluationMode);
    final repeatCount = ref.watch(P.agent.repeatCount);
    final selectedCase = selectedCaseIndex >= 0 && selectedCaseIndex < cases.length ? cases[selectedCaseIndex] : null;
    final selectedRecord = selectedCase == null ? null : records[selectedCase.name];
    final selectedCaseIsRunning = (running || runningAll) && currentCaseName == selectedCase?.name;
    final selectedCaseOwnsUnrecordedState = selectedRecord == null && currentCaseName == selectedCase?.name;
    final displayedVerdict = selectedCaseIsRunning || selectedCaseOwnsUnrecordedState ? verdict : selectedRecord?.verdict;
    final displayedError = selectedCaseOwnsUnrecordedState ? error : null;
    final displayedEvents = selectedCaseIsRunning || selectedCaseOwnsUnrecordedState
        ? events
        : selectedRecord?.result.events ?? <AgentEvent>[];

    return Theme(
      data: theme,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 112 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            const _AgentSafetyCard(),
            const SizedBox(height: 12),
            _AgentCaseSelector(
              cases: cases,
              selectedCaseIndex: selectedCaseIndex,
              enabled: !running && !runningAll,
            ),
            const SizedBox(height: 12),
            _AgentEvaluationSettings(
              mode: evaluationMode,
              repeatCount: repeatCount,
              enabled: !running && !runningAll,
            ),
            const SizedBox(height: 12),
            _AgentRunSummary(
              total: report?.manifest.plannedRuns ?? cases.length * repeatCount,
              records: records,
              reportRecords: reportRecords,
              running: running || runningAll,
              runningAll: runningAll,
              currentCaseName: currentCaseName,
              currentCaseOrdinal: currentCaseOrdinal,
              runModelName: runModelName,
              reportAvailable: report != null,
              onRunAll: cases.isEmpty || running || runningAll || model == null
                  ? null
                  : () {
                      unawaited(P.agent.runAllCases());
                    },
              onExport: report == null || running || runningAll
                  ? null
                  : () {
                      unawaited(P.agent.exportLatestReport());
                    },
            ),
            if (selectedCase != null) ...[
              const SizedBox(height: 12),
              _AgentCaseDetails(agentCase: selectedCase),
            ],
            if (displayedVerdict != null || displayedError != null) ...[
              const SizedBox(height: 12),
              _AgentVerdictCard(
                verdict: displayedVerdict,
                error: displayedError,
              ),
            ],
            if (selectedCaseIsRunning && liveModelOutput.isNotEmpty) ...[
              const SizedBox(height: 12),
              _AgentLiveOutput(content: liveModelOutput),
            ],
            if (displayedEvents.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final event in displayedEvents) ...[
                _AgentEventCard(event: event),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _AgentSafetyCard extends ConsumerWidget {
  const _AgentSafetyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Material(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: qb.withValues(alpha: .14), width: .5),
      ),
      child: Padding(
        padding: const .all(12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Icon(Icons.security, size: 18, color: qb.withValues(alpha: .78)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.agent_eval_sandbox_title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: .w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.agent_eval_sandbox_description,
              style: theme.textTheme.bodyMedium?.copyWith(color: qb.withValues(alpha: .72)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentCaseSelector extends ConsumerWidget {
  final List<AgentCase> cases;
  final int selectedCaseIndex;
  final bool enabled;

  const _AgentCaseSelector({
    required this.cases,
    required this.selectedCaseIndex,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final safeIndex = selectedCaseIndex >= 0 && selectedCaseIndex < cases.length ? selectedCaseIndex : null;

    return Material(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: qb.withValues(alpha: .14), width: .5),
      ),
      child: Padding(
        padding: const .symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text(s.agent_eval_case, style: theme.textTheme.bodyMedium),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: safeIndex,
                  isExpanded: true,
                  items: <DropdownMenuItem<int>>[
                    for (final entry in cases.indexed)
                      DropdownMenuItem<int>(
                        value: entry.$1,
                        child: Text(
                          "${entry.$1 + 1}. ${entry.$2.title}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: enabled
                      ? (value) {
                          if (value == null) return;
                          P.agent.selectCase(value);
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentEvaluationSettings extends ConsumerWidget {
  final AgentEvaluationMode mode;
  final int repeatCount;
  final bool enabled;

  const _AgentEvaluationSettings({
    required this.mode,
    required this.repeatCount,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final description = mode == .strict ? s.agent_eval_mode_strict_description : s.agent_eval_mode_assisted_description;

    return Material(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: qb.withValues(alpha: .14), width: .5),
      ),
      child: Padding(
        padding: const .all(12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Text(s.agent_eval_mode, style: theme.textTheme.bodyMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AgentEvaluationMode>(
                      value: mode,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: AgentEvaluationMode.strict,
                          child: Text(s.agent_eval_mode_strict),
                        ),
                        DropdownMenuItem(
                          value: AgentEvaluationMode.assisted,
                          child: Text(s.agent_eval_mode_assisted),
                        ),
                      ],
                      onChanged: enabled
                          ? (value) {
                              if (value == null) return;
                              P.agent.setEvaluationMode(value);
                            }
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(s.agent_eval_repeats, style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: repeatCount,
                    items: [
                      for (int value = 1; value <= 3; value++)
                        DropdownMenuItem<int>(
                          value: value,
                          child: Text("$value×"),
                        ),
                    ],
                    onChanged: enabled
                        ? (value) {
                            if (value == null) return;
                            P.agent.setRepeatCount(value);
                          }
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: qb.withValues(alpha: .64),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentRunSummary extends ConsumerWidget {
  final int total;
  final Map<String, AgentCaseRunRecord> records;
  final List<AgentCaseRunRecord> reportRecords;
  final bool running;
  final bool runningAll;
  final String? currentCaseName;
  final int currentCaseOrdinal;
  final String? runModelName;
  final bool reportAvailable;
  final VoidCallback? onRunAll;
  final VoidCallback? onExport;

  const _AgentRunSummary({
    required this.total,
    required this.records,
    required this.reportRecords,
    required this.running,
    required this.runningAll,
    required this.currentCaseName,
    required this.currentCaseOrdinal,
    required this.runModelName,
    required this.reportAvailable,
    required this.onRunAll,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final passed = reportRecords.where((record) => record.verdict.passed).length;
    final invalid = reportRecords.where((record) => !record.verdict.validForModelScore).length;
    final failed = reportRecords.length - passed - invalid;

    return Material(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: qb.withValues(alpha: .14), width: .5),
      ),
      child: Padding(
        padding: const .all(12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        running
                            ? s.agent_eval_running(currentCaseOrdinal, total, currentCaseName ?? "")
                            : s.agent_eval_completed(reportRecords.length, total, passed, failed, invalid),
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (runModelName != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          runModelName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: qb.withValues(alpha: .58),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onRunAll,
                      icon: runningAll
                          ? SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: qb,
                              ),
                            )
                          : const Icon(Icons.playlist_play),
                      label: Text(s.agent_eval_run_all),
                    ),
                    if (reportAvailable) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: onExport,
                        icon: const Icon(Icons.ios_share, size: 17),
                        label: Text(s.agent_eval_export),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (records.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final entry in records.entries)
                    _AgentResultChip(
                      index: entry.value.agentCase.name,
                      verdict: entry.value.verdict,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AgentResultChip extends ConsumerWidget {
  final String index;
  final AgentCaseVerdict verdict;

  const _AgentResultChip({
    required this.index,
    required this.verdict,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final invalid = !verdict.validForModelScore;
    final assisted = !verdict.passed && verdict.assistedPassed;
    final color = invalid
        ? Colors.orange
        : verdict.passed || assisted
        ? Colors.green
        : theme.colorScheme.error;
    final label = invalid
        ? s.agent_eval_invalid
        : verdict.passed
        ? s.agent_eval_strict_pass
        : assisted
        ? s.agent_eval_assisted_pass
        : s.agent_eval_fail;

    return Container(
      padding: const .symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .28), width: .5),
      ),
      child: Text(
        "$label · $index",
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

class _AgentCaseDetails extends ConsumerWidget {
  final AgentCase agentCase;

  const _AgentCaseDetails({required this.agentCase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Material(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: qb.withValues(alpha: .14), width: .5),
      ),
      child: Padding(
        padding: const .all(12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(
              agentCase.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: .w500),
            ),
            const SizedBox(height: 6),
            Text(
              agentCase.prompt,
              style: theme.textTheme.bodyMedium?.copyWith(color: qb.withValues(alpha: .76)),
            ),
            const SizedBox(height: 8),
            Text(
              s.agent_eval_tools(agentCase.toolNames.join(", ")),
              style: theme.textTheme.bodySmall?.copyWith(color: qb.withValues(alpha: .6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentVerdictCard extends ConsumerWidget {
  final AgentCaseVerdict? verdict;
  final String? error;

  const _AgentVerdictCard({
    required this.verdict,
    required this.error,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final invalid = verdict != null && !verdict!.validForModelScore;
    final passed = verdict?.passed ?? false;
    final assisted = !passed && (verdict?.assistedPassed ?? false);
    final color = invalid
        ? Colors.orange
        : passed || assisted
        ? Colors.green
        : theme.colorScheme.error;
    final failures = verdict?.failures ?? <String>[];
    final label = invalid
        ? s.agent_eval_invalid
        : passed
        ? s.agent_eval_strict_pass
        : assisted
        ? s.agent_eval_assisted_pass
        : s.agent_eval_fail;

    return Material(
      color: appTheme.settingItem,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: .3), width: .5),
      ),
      child: Padding(
        padding: const .all(12),
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: .w600,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(error!, style: theme.textTheme.bodyMedium),
            ],
            for (final failure in failures) ...[
              const SizedBox(height: 4),
              Text("• $failure", style: theme.textTheme.bodyMedium?.copyWith(color: qb.withValues(alpha: .76))),
            ],
          ],
        ),
      ),
    );
  }
}

class _AgentLiveOutput extends ConsumerWidget {
  final String content;

  const _AgentLiveOutput({required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);

    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: qb.withValues(alpha: .14), width: .5),
      ),
      child: Text(
        content,
        maxLines: 12,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: "monospace",
          color: qb.withValues(alpha: .72),
        ),
      ),
    );
  }
}

class _AgentEventCard extends ConsumerWidget {
  final AgentEvent event;

  const _AgentEventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final appTheme = ref.watch(P.app.theme);
    final color = switch (event.kind) {
      .toolCall => Colors.orange,
      .toolResult => Colors.green,
      .error => theme.colorScheme.error,
      .finalAnswer => theme.colorScheme.primary,
      .modelOutput => qb,
    };

    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .24), width: .5),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            s.agent_eval_turn(event.turn, event.title),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: .w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.content,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: "monospace",
              color: qb.withValues(alpha: .72),
            ),
          ),
        ],
      ),
    );
  }
}
