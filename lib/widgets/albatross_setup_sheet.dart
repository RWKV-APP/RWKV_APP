// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:desktop_drop/desktop_drop.dart' as desktop_drop;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/func/shortcuts.dart';

// Project imports:
import 'package:zone/func/albatross_endpoint_input.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

class AlbatrossSetupSheet extends ConsumerStatefulWidget {
  const AlbatrossSetupSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const AlbatrossSetupSheet(),
    );
    return result == true;
  }

  @override
  ConsumerState<AlbatrossSetupSheet> createState() => _AlbatrossSetupSheetState();
}

class _AlbatrossSetupSheetState extends ConsumerState<AlbatrossSetupSheet> {
  late final TextEditingController _hostController = TextEditingController(text: P.albatrossRuntime.host.q);
  late final TextEditingController _portController = TextEditingController(text: P.albatrossRuntime.port.q.toString());

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _syncEndpoint() {
    P.albatrossRuntime.host.q = _hostController.text.trim().isEmpty ? "127.0.0.1" : _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (port == null || port <= 0) return;
    P.albatrossRuntime.port.q = port;
  }

  Future<void> _prepare() async {
    _syncEndpoint();
    final ok = await P.albatrossRuntime.prepareForChat();
    if (!ok || !mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final qb = ref.watch(P.app.qb);
    final connecting = ref.watch(P.albatrossRuntime.connecting);
    final running = ref.watch(P.albatrossRuntime.running);
    final executablePath = ref.watch(P.albatrossRuntime.executablePath);
    final modelPath = ref.watch(P.albatrossRuntime.modelPath);
    final tokenizerPath = ref.watch(P.albatrossRuntime.tokenizerPath);
    final lastError = ref.watch(P.albatrossRuntime.lastError);

    return desktop_drop.DropTarget(
      onDragDone: (detail) async {
        for (final item in detail.files) {
          await P.albatrossRuntime.handleDroppedPath(item.path);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.albatross_chat,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: .bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _hostController,
                      inputFormatters: buildAlbatrossHostInputFormatters(),
                      decoration: InputDecoration(labelText: s.albatross_host),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      inputFormatters: buildAlbatrossPortInputFormatters(),
                      decoration: InputDecoration(labelText: s.albatross_port),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PathRow(label: s.albatross_binary, value: executablePath),
              _PathRow(label: s.albatross_model, value: modelPath),
              _PathRow(label: s.albatross_tokenizer, value: tokenizerPath),
              if (lastError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(lastError, style: TS(c: theme.colorScheme.error, s: 12)),
              ],
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
                    onPressed: P.albatrossRuntime.pickModelPth,
                    icon: const Icon(Icons.description_outlined),
                    label: Text(s.albatross_pick_pth),
                  ),
                  OutlinedButton.icon(
                    onPressed: P.albatrossRuntime.pickTokenizer,
                    icon: const Icon(Icons.text_snippet_outlined),
                    label: Text(s.albatross_pick_tokenizer),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: connecting ? null : _prepare,
                icon: Icon(running ? Icons.check_circle_outline : Icons.play_arrow),
                label: Text(connecting ? s.albatross_connecting : s.albatross_start_chat),
              ),
              const SizedBox(height: 8),
              Text(
                running ? s.albatross_connected : s.albatross_not_connected,
                textAlign: .center,
                style: TS(c: qb.q(.65), s: 12),
              ),
            ],
          ),
        ),
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
      padding: const .only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TS(c: theme.colorScheme.onSurface.q(.7), s: 12, w: .w500),
            ),
          ),
          Expanded(
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TS(c: theme.colorScheme.onSurface.q(value.isEmpty ? .45 : .82), s: 12),
            ),
          ),
        ],
      ),
    );
  }
}
