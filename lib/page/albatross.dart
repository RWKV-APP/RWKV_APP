// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:desktop_drop/desktop_drop.dart' as desktop_drop;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:zone/func/albatross_endpoint_input.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

const String _albatrossRuntimeSourceUrl = "https://github.com/Alic-Li/rwkv_lightning_cuda";
const String _albatrossPthSourceUrl = "https://huggingface.co/BlinkDL/rwkv7-g1/tree/main";

class PageAlbatross extends ConsumerStatefulWidget {
  const PageAlbatross({super.key});

  @override
  ConsumerState<PageAlbatross> createState() => _PageAlbatrossState();
}

class _PageAlbatrossState extends ConsumerState<PageAlbatross> {
  late final TextEditingController _hostController = TextEditingController(text: P.albatrossRuntime.host.q);
  late final TextEditingController _portController = TextEditingController(text: P.albatrossRuntime.port.q.toString());

  @override
  void initState() {
    super.initState();
    P.albatrossRuntime.clearSetupHighlights();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
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
        onDragDone: (detail) async {
          await P.albatrossRuntime.handleDroppedItems(detail.files);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, paddingBottom + 24),
          children: [
            _AlbatrossOverviewSection(
              theme: theme,
              onStartChat: () => P.albatrossRuntime.startChat(
                hostText: _hostController.text,
                portText: _portController.text,
              ),
            ),
            const SizedBox(height: 16),
            _AlbatrossSystemInfoSection(theme: theme),
            const SizedBox(height: 16),
            _AlbatrossEndpointSection(
              hostController: _hostController,
              portController: _portController,
            ),
            const SizedBox(height: 16),
            _AlbatrossRuntimeFilesSection(theme: theme),
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
  final bool highlighted;

  const _AlbatrossSection({
    required this.icon,
    required this.title,
    required this.children,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(P.app.theme);
    final qb = ref.watch(P.app.qb);
    final highlightColor = Colors.amber;

    return Container(
      decoration: BoxDecoration(
        color: highlighted ? Color.lerp(appTheme.settingItem, highlightColor, .08) : appTheme.settingItem,
        borderRadius: BorderRadius.circular(12),
        border: highlighted ? Border.all(color: highlightColor.withValues(alpha: .8), width: 1.25) : null,
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
          Container(height: 0.5, color: qb.withValues(alpha: .18)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _AlbatrossOverviewSection extends ConsumerWidget {
  final ThemeData theme;
  final Future<void> Function() onStartChat;

  const _AlbatrossOverviewSection({
    required this.theme,
    required this.onStartChat,
  });

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
              onPressed: busy ? null : () => unawaited(onStartChat()),
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
  static const double _controlHeight = 40;

  const _AlbatrossSystemInfoSection({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final info = ref.watch(P.albatrossRuntime.displaySystemInfo);
    final cudaBackendAvailable = ref.watch(P.albatrossRuntime.cudaBackendAvailable);
    final highlighted = ref.watch(P.albatrossRuntime.highlightedSetupPanels).contains(AlbatrossSetupPanel.computer);

    return _AlbatrossSection(
      icon: Icons.memory,
      title: s.albatross_system_info,
      highlighted: highlighted,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              height: _controlHeight,
              child: _StatusChip(
                color: cudaBackendAvailable ? Colors.green : theme.colorScheme.error,
                label: cudaBackendAvailable ? s.albatross_compatibility_ok : s.albatross_compatibility_warning,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            SizedBox(
              height: _controlHeight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: P.albatrossRuntime.refreshCudaInfo,
                icon: const Icon(Icons.refresh),
                label: Text(s.albatross_refresh_cuda_info),
              ),
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
    final highlighted = ref.watch(P.albatrossRuntime.highlightedSetupPanels).contains(AlbatrossSetupPanel.endpoint);

    return _AlbatrossSection(
      icon: Icons.settings_ethernet,
      title: s.albatross_launch_config,
      highlighted: highlighted,
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: hostController,
                enabled: !running,
                inputFormatters: buildAlbatrossHostInputFormatters(),
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
                inputFormatters: buildAlbatrossPortInputFormatters(),
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
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: .6)),
        ),
      ],
    );
  }
}

class _AlbatrossRuntimeFilesSection extends ConsumerWidget {
  final ThemeData theme;

  const _AlbatrossRuntimeFilesSection({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final executablePath = ref.watch(P.albatrossRuntime.executablePath);
    final tokenizerPath = ref.watch(P.albatrossRuntime.tokenizerPath);
    final modelPath = ref.watch(P.albatrossRuntime.modelPath);
    final highlightedPanels = ref.watch(P.albatrossRuntime.highlightedSetupPanels);
    final highlighted =
        highlightedPanels.contains(AlbatrossSetupPanel.runtimeAssets) || highlightedPanels.contains(AlbatrossSetupPanel.model);

    return _AlbatrossSection(
      icon: Icons.developer_board,
      title: s.albatross_runtime_assets,
      highlighted: highlighted,
      children: [
        _PathRow(label: s.albatross_binary, value: executablePath),
        _PathRow(label: s.albatross_tokenizer, value: tokenizerPath),
        _PathRow(label: s.albatross_model, value: modelPath),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: P.albatrossRuntime.pickExecutable,
              icon: const Icon(Icons.file_open),
              label: Text(s.albatross_pick_binary),
            ),
            OutlinedButton.icon(
              onPressed: P.albatrossRuntime.pickTokenizer,
              icon: const Icon(Icons.text_snippet_outlined),
              label: Text(s.albatross_pick_tokenizer),
            ),
            OutlinedButton.icon(
              onPressed: P.albatrossRuntime.pickModelPth,
              icon: const Icon(Icons.description_outlined),
              label: Text(s.albatross_pick_pth),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          s.albatross_runtime_assets_hint,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: .6)),
        ),
        const SizedBox(height: 8),
        Text(
          s.albatross_binary_compile_hint,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: .72), height: 1.35),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExternalResourceLink(
                icon: Icons.code,
                label: s.albatross_binary_tokenizer_source,
                url: _albatrossRuntimeSourceUrl,
              ),
              _ExternalResourceLink(
                icon: Icons.cloud_outlined,
                label: s.albatross_pth_source,
                url: _albatrossPthSourceUrl,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExternalResourceLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _ExternalResourceLink({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => unawaited(_openAlbatrossExternalUrl(context, url)),
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: .w600),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: .55)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.open_in_new, size: 16),
        ],
      ),
    );
  }
}

Future<void> _openAlbatrossExternalUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) return;
  } catch (_) {
    //
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(S.of(context).albatross_open_resource_failed)),
  );
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
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Text(
                  entry.key,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: .62)),
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
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: .62), fontWeight: .w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              display,
              style: theme.textTheme.bodySmall?.copyWith(
                color: error ? theme.colorScheme.error : theme.colorScheme.onSurface.withValues(alpha: .82),
              ),
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
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: .62), fontWeight: .w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              display,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: value.isEmpty ? .45 : .82)),
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
  final EdgeInsetsGeometry padding;

  const _StatusChip({
    required this.color,
    required this.label,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .55), width: 0.5),
      ),
      child: Align(
        alignment: Alignment.center,
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: .w600),
        ),
      ),
    );
  }
}
