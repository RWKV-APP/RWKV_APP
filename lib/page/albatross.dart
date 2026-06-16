// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:desktop_drop/desktop_drop.dart' as desktop_drop;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path/path.dart' as path;

// Project imports:
import 'package:zone/func/format_bytes.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/store/p.dart';

class PageAlbatross extends ConsumerStatefulWidget {
  const PageAlbatross({super.key});

  @override
  ConsumerState<PageAlbatross> createState() => _PageAlbatrossState();
}

class _PageAlbatrossState extends ConsumerState<PageAlbatross> {
  late final TextEditingController _hostController = TextEditingController(text: P.albatrossRuntime.host.q);
  late final TextEditingController _portController = TextEditingController(text: P.albatrossRuntime.port.q.toString());
  bool _dragging = false;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _setDragging(bool dragging) {
    if (_dragging == dragging) return;
    setState(() {
      _dragging = dragging;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final paddingBottom = ref.watch(P.app.paddingBottom);

    return Scaffold(
      backgroundColor: appTheme.settingBg,
      appBar: AppBar(
        title: Text(s.albatross_chat),
        backgroundColor: appTheme.settingBg,
        surfaceTintColor: Colors.transparent,
      ),
      body: desktop_drop.DropTarget(
        onDragEntered: (_) => _setDragging(true),
        onDragUpdated: (_) => _setDragging(true),
        onDragExited: (_) => _setDragging(false),
        onDragDone: (detail) async {
          _setDragging(false);
          await P.albatrossRuntime.handleDroppedItems(detail.files);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, paddingBottom + 24),
          children: [
            _AlbatrossOverviewSection(theme: theme),
            const SizedBox(height: 16),
            _AlbatrossSystemInfoSection(theme: theme),
            const SizedBox(height: 16),
            _AlbatrossEndpointSection(
              hostController: _hostController,
              portController: _portController,
            ),
            const SizedBox(height: 16),
            _AlbatrossAssetsSection(theme: theme),
            const SizedBox(height: 16),
            _AlbatrossModelSection(theme: theme),
            const SizedBox(height: 16),
            _AlbatrossParametersSection(theme: theme),
            const SizedBox(height: 16),
            _AlbatrossDropSection(dragging: _dragging),
            const SizedBox(height: 16),
            _AlbatrossLogsSection(theme: theme),
          ],
        ),
      ),
    );
  }
}

class _AlbatrossSection extends ConsumerWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _AlbatrossSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);

    return Container(
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: .w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: qb.q(.18)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _AlbatrossOverviewSection extends ConsumerWidget {
  final ThemeData theme;

  const _AlbatrossOverviewSection({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final running = ref.watch(P.albatrossRuntime.running);
    final connecting = ref.watch(P.albatrossRuntime.connecting);
    final checkingService = ref.watch(P.albatrossRuntime.checkingService);
    final launchedByApp = ref.watch(P.albatrossRuntime.launchedByApp);
    final processId = ref.watch(P.albatrossRuntime.processId);
    final exitCode = ref.watch(P.albatrossRuntime.processExitCode);
    final lastError = ref.watch(P.albatrossRuntime.lastError);
    final baseUrl = ref.watch(P.albatrossRuntime.baseUrl);
    final busy = connecting || checkingService;

    return _AlbatrossSection(
      icon: Icons.bolt,
      title: s.albatross_runtime_management,
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.albatross_early_stage_notice,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusChip(
              color: running ? Colors.green : theme.colorScheme.outline,
              label: connecting
                  ? s.albatross_connecting
                  : running
                  ? s.albatross_connected
                  : s.albatross_not_connected,
            ),
            _StatusChip(
              color: launchedByApp ? Colors.blue : theme.colorScheme.outline,
              label: launchedByApp ? s.albatross_launched_by_app : s.albatross_external_service,
            ),
            if (processId != null) _StatusChip(color: Colors.indigo, label: "PID $processId"),
            if (exitCode != null) _StatusChip(color: theme.colorScheme.error, label: "${s.albatross_exit_code}: $exitCode"),
          ],
        ),
        const SizedBox(height: 12),
        _ValueRow(label: s.albatross_endpoint, value: baseUrl),
        if (lastError.isNotEmpty) _ValueRow(label: s.albatross_last_error, value: lastError, error: true),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : P.albatrossRuntime.startChat,
              icon: Icon(running ? Icons.chat_bubble_outline : Icons.play_arrow),
              label: Text(running ? s.albatross_enter_chat : s.albatross_start_chat),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : P.albatrossRuntime.probeAndNotify,
              icon: checkingService
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.health_and_safety_outlined),
              label: Text(checkingService ? s.albatross_checking_service : s.albatross_probe_service),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : P.albatrossRuntime.restartRuntime,
              icon: const Icon(Icons.restart_alt),
              label: Text(s.albatross_restart_runtime),
            ),
            OutlinedButton.icon(
              onPressed: running || launchedByApp ? P.albatrossRuntime.stopRuntime : null,
              icon: const Icon(Icons.stop),
              label: Text(s.albatross_stop_runtime),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlbatrossSystemInfoSection extends ConsumerWidget {
  final ThemeData theme;

  const _AlbatrossSystemInfoSection({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final info = ref.watch(P.albatrossRuntime.displaySystemInfo);
    final canShow = ref.watch(P.albatrossRuntime.canShowHomeEntry);

    return _AlbatrossSection(
      icon: Icons.memory,
      title: s.albatross_system_info,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusChip(
              color: canShow ? Colors.green : theme.colorScheme.error,
              label: canShow ? s.albatross_compatibility_ok : s.albatross_compatibility_warning,
            ),
            OutlinedButton.icon(
              onPressed: P.albatrossRuntime.refreshCudaInfo,
              icon: const Icon(Icons.refresh),
              label: Text(s.albatross_refresh_cuda_info),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (info.isEmpty)
          Text(
            s.albatross_cuda_not_detected,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          )
        else
          _InfoGrid(info: info),
      ],
    );
  }
}

class _AlbatrossEndpointSection extends ConsumerWidget {
  final TextEditingController hostController;
  final TextEditingController portController;

  const _AlbatrossEndpointSection({
    required this.hostController,
    required this.portController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final running = ref.watch(P.albatrossRuntime.running);

    return _AlbatrossSection(
      icon: Icons.settings_ethernet,
      title: s.albatross_launch_config,
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: hostController,
                enabled: !running,
                decoration: InputDecoration(
                  labelText: s.albatross_host,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => unawaited(P.albatrossRuntime.setHost(value)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: portController,
                enabled: !running,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: s.albatross_port,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => unawaited(P.albatrossRuntime.setPortFromText(value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          s.albatross_launch_config_hint,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.q(.6)),
        ),
      ],
    );
  }
}

class _AlbatrossAssetsSection extends ConsumerWidget {
  final ThemeData theme;

  const _AlbatrossAssetsSection({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final executablePath = ref.watch(P.albatrossRuntime.executablePath);
    final tokenizerPath = ref.watch(P.albatrossRuntime.tokenizerPath);
    final downloading = ref.watch(P.albatrossRuntime.downloading);

    return _AlbatrossSection(
      icon: Icons.developer_board,
      title: s.albatross_runtime_assets,
      children: [
        _PathRow(label: s.albatross_binary, value: executablePath),
        _PathRow(label: s.albatross_tokenizer, value: tokenizerPath),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: downloading ? null : P.albatrossRuntime.downloadConfiguredBinary,
              icon: const Icon(Icons.download),
              label: Text(s.albatross_download_binary),
            ),
            OutlinedButton.icon(
              onPressed: P.albatrossRuntime.pickExecutable,
              icon: const Icon(Icons.file_open),
              label: Text(s.albatross_pick_binary),
            ),
            OutlinedButton.icon(
              onPressed: downloading ? null : P.albatrossRuntime.downloadConfiguredTokenizer,
              icon: const Icon(Icons.download),
              label: Text(s.albatross_download_tokenizer),
            ),
            OutlinedButton.icon(
              onPressed: P.albatrossRuntime.pickTokenizer,
              icon: const Icon(Icons.text_snippet_outlined),
              label: Text(s.albatross_pick_tokenizer),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          s.albatross_runtime_assets_hint,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.q(.6)),
        ),
      ],
    );
  }
}

class _AlbatrossModelSection extends ConsumerWidget {
  final ThemeData theme;

  const _AlbatrossModelSection({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final modelPath = ref.watch(P.albatrossRuntime.modelPath);
    final candidates = ref.watch(P.albatrossRuntime.pthCandidates);

    return _AlbatrossSection(
      icon: Icons.storage,
      title: s.albatross_model_management,
      children: [
        _PathRow(label: s.albatross_model, value: modelPath),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: P.albatrossRuntime.pickModelPth,
              icon: const Icon(Icons.description_outlined),
              label: Text(s.albatross_pick_pth),
            ),
            OutlinedButton.icon(
              onPressed: P.albatrossRuntime.pickModelFolder,
              icon: const Icon(Icons.folder_open),
              label: Text(s.albatross_pick_model_folder),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (candidates.isEmpty)
          Text(
            s.albatross_no_pth_candidates,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.q(.62)),
          )
        else
          ...candidates.map((fileInfo) => _PthCandidateRow(fileInfo: fileInfo)),
      ],
    );
  }
}

class _PthCandidateRow extends ConsumerWidget {
  final FileInfo fileInfo;

  const _PthCandidateRow({required this.fileInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final selectedPath = ref.watch(P.albatrossRuntime.modelPath);
    final localFile = fileInfo.fromPthFile ? null : ref.watch(P.remote.locals(fileInfo));
    final effectivePath = fileInfo.fromPthFile ? fileInfo.raw : localFile?.targetPath ?? "";
    final selected = selectedPath.isNotEmpty && path.equals(path.normalize(selectedPath), path.normalize(effectivePath));
    final hasFile = fileInfo.fromPthFile || localFile?.hasFile == true;
    final downloading = localFile?.downloading == true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: qb.q(.14), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(fileInfo.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: .w600)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SmallTag(text: formatBytes(fileInfo.fileSize)),
                    if (fileInfo.fromPthFile) const _SmallTag(text: "LOCAL"),
                    if (!fileInfo.fromPthFile) const _SmallTag(text: "REMOTE"),
                    if (downloading) _SmallTag(text: "${(localFile?.progress ?? 0).toStringAsFixed(0)}%"),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  path.basename(effectivePath.isEmpty ? fileInfo.fileName : effectivePath),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.q(.55)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (selected)
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check),
              label: Text(s.albatross_selected_model),
            )
          else if (hasFile)
            OutlinedButton.icon(
              onPressed: () => P.albatrossRuntime.selectPthModel(fileInfo),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(s.albatross_select_this_model),
            )
          else
            OutlinedButton.icon(
              onPressed: downloading ? null : () => P.albatrossRuntime.downloadPthModel(fileInfo),
              icon: const Icon(Icons.download),
              label: Text(s.download_model),
            ),
        ],
      ),
    );
  }
}

class _AlbatrossParametersSection extends ConsumerWidget {
  final ThemeData theme;

  const _AlbatrossParametersSection({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final temperature = ref.watch(P.rwkvParams.arguments(Argument.temperature));
    final topP = ref.watch(P.rwkvParams.arguments(Argument.topP));
    final topK = ref.watch(P.rwkvParams.arguments(Argument.topK));
    final presence = ref.watch(P.rwkvParams.arguments(Argument.presencePenalty));
    final frequency = ref.watch(P.rwkvParams.arguments(Argument.frequencyPenalty));
    final maxTokens = ref.watch(P.rwkvParams.arguments(Argument.maxLength));

    return _AlbatrossSection(
      icon: Icons.tune,
      title: s.albatross_parameters,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ParameterTag(label: "temperature", value: temperature.toStringAsFixed(2)),
            _ParameterTag(label: "top_p", value: topP.toStringAsFixed(2)),
            _ParameterTag(label: "top_k", value: topK.toStringAsFixed(0)),
            _ParameterTag(label: "presence", value: presence.toStringAsFixed(2)),
            _ParameterTag(label: "frequency", value: frequency.toStringAsFixed(2)),
            _ParameterTag(label: "max_tokens", value: maxTokens.toStringAsFixed(0)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          s.albatross_parameter_hint,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.q(.6)),
        ),
      ],
    );
  }
}

class _AlbatrossDropSection extends ConsumerWidget {
  final bool dragging;

  const _AlbatrossDropSection({required this.dragging});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.q(dragging ? .14 : .07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.q(dragging ? .75 : .32), width: dragging ? 1 : 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.file_upload_outlined, color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.albatross_drop_files,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.q(.75)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbatrossLogsSection extends ConsumerWidget {
  final ThemeData theme;

  const _AlbatrossLogsSection({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final logs = ref.watch(P.albatrossRuntime.logs);
    final command = ref.watch(P.albatrossRuntime.launchCommand);

    return _AlbatrossSection(
      icon: Icons.terminal,
      title: s.albatross_runtime_logs,
      children: [
        if (command.isNotEmpty) ...[
          _ValueRow(label: s.albatross_launch_command, value: command),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              s.albatross_runtime_logs,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: .w600),
            ),
            TextButton.icon(
              onPressed: logs.isEmpty ? null : P.albatrossRuntime.copyLogsToClipboard,
              icon: const Icon(Icons.copy_all, size: 18),
              label: Text(s.albatross_copy_all_logs),
            ),
            TextButton.icon(
              onPressed: logs.isEmpty ? null : P.albatrossRuntime.exportLogsToTxt,
              icon: const Icon(Icons.save_alt, size: 18),
              label: Text(s.albatross_export_logs_txt),
            ),
            TextButton.icon(
              onPressed: logs.isEmpty ? null : P.albatrossRuntime.clearLogs,
              icon: const Icon(Icons.clear_all, size: 18),
              label: Text(s.clear),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          height: 220,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: logs.isEmpty
              ? Center(
                  child: Text(
                    s.albatross_no_logs,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final entry = logs[logs.length - 1 - index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(
                        entry,
                        style: const TextStyle(fontSize: 11, fontFamily: "monospace", color: Colors.white70),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final Map<String, String> info;

  const _InfoGrid({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = info.entries.toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in entries)
          Container(
            constraints: const BoxConstraints(minWidth: 160, maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.q(.45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Text(
                  entry.key,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.q(.62)),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: .w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool error;

  const _ValueRow({
    required this.label,
    required this.value,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = value.isEmpty ? S.of(context).albatross_not_selected : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.q(.62), fontWeight: .w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              display,
              style: theme.textTheme.bodySmall?.copyWith(color: error ? theme.colorScheme.error : theme.colorScheme.onSurface.q(.82)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  final String label;
  final String value;

  const _PathRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = value.isEmpty ? S.of(context).albatross_not_selected : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.q(.62), fontWeight: .w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              display,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.q(value.isEmpty ? .45 : .82)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusChip({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.q(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.q(.55), width: 0.5),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: .w600),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String text;

  const _SmallTag({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.q(.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.q(.68)),
      ),
    );
  }
}

class _ParameterTag extends StatelessWidget {
  final String label;
  final String value;

  const _ParameterTag({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.q(.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary.q(.22), width: 0.5),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: .w600),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.q(.75)),
          ),
        ],
      ),
    );
  }
}
