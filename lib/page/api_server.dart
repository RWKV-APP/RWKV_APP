// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:zone/gen/l10n.dart' show S;
import 'package:zone/model/backend_state.dart';
import 'package:zone/store/p.dart' show P, $ApiServer;
import 'package:zone/widgets/model_selector.dart';

class _ChatMsg {
  final String role;
  final String content;
  _ChatMsg(this.role, this.content);
}

class PageApiServer extends ConsumerStatefulWidget {
  const PageApiServer({super.key});

  @override
  ConsumerState<PageApiServer> createState() => _PageApiServerState();
}

class _PageApiServerState extends ConsumerState<PageApiServer> {
  late final TextEditingController _portController;
  late final TextEditingController _chatController;
  final ScrollController _chatScrollController = ScrollController();
  final List<_ChatMsg> _chatMessages = [];
  bool _chatSending = false;
  String _streamingContent = '';

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController(text: P.apiServer.port.q.toString());
    _chatController = TextEditingController();
  }

  @override
  void dispose() {
    _portController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _chatSending) return;

    final port = P.apiServer.port.q;
    final url = 'http://localhost:$port/v1/chat/completions';

    setState(() {
      _chatMessages.add(_ChatMsg('user', text));
      _chatController.clear();
      _chatSending = true;
      _streamingContent = '';
    });
    _scrollToBottom();

    final requestMessages = _chatMessages.map((m) => {'role': m.role, 'content': m.content}).toList();

    try {
      final request = http.Request('POST', Uri.parse(url));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': 'rwkv',
        'messages': requestMessages,
        'stream': true,
      });

      final response = await request.send();
      final stream = response.stream.transform(utf8.decoder);
      String buffer = '';

      await for (final chunk in stream) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (!line.startsWith('data: ')) continue;
          final payload = line.substring(6).trim();
          if (payload == '[DONE]') continue;
          try {
            final data = jsonDecode(payload);
            final delta = data['choices']?[0]?['delta']?['content'] as String? ?? '';
            if (delta.isNotEmpty) {
              setState(() {
                _streamingContent += delta;
              });
              _scrollToBottom();
            }
          } catch (_) {}
        }
      }

      setState(() {
        if (_streamingContent.isNotEmpty) {
          _chatMessages.add(_ChatMsg('assistant', _streamingContent));
        }
        _streamingContent = '';
        _chatSending = false;
      });
    } catch (e) {
      setState(() {
        _chatMessages.add(_ChatMsg('assistant', 'Error: $e'));
        _streamingContent = '';
        _chatSending = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _stopChatMessage() async {
    await P.apiServer.stopActiveRequest(showAlert: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final appTheme = ref.watch(P.app.theme);
    final serverState = ref.watch(P.apiServer.state);
    final serverPort = ref.watch(P.apiServer.port);
    final reqCount = ref.watch(P.apiServer.requestCount);
    final activeRequest = ref.watch(P.apiServer.activeRequest);
    final latestModel = ref.watch(P.rwkv.latestModel);
    final isRunning = serverState == BackendState.running;
    final logs = ref.watch(P.apiServer.logs);

    final serverUrl = 'http://localhost:$serverPort';

    return Scaffold(
      backgroundColor: appTheme.settingBg,
      appBar: AppBar(
        title: Text(s.api_server),
        backgroundColor: appTheme.settingBg,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildModelSection(s, latestModel),
          const SizedBox(height: 16),
          _buildPortSection(s, serverState),
          const SizedBox(height: 16),
          _buildControlSection(s, serverState),
          const SizedBox(height: 16),
          if (isRunning) ...[
            _buildStatusSection(s, serverUrl, reqCount, activeRequest),
            const SizedBox(height: 16),
            _buildChatSection(s, theme, activeRequest),
            const SizedBox(height: 16),
            _buildCurlHint(s, serverUrl),
            const SizedBox(height: 16),
            _buildDashboardButton(s, serverUrl),
            const SizedBox(height: 16),
          ],
          _buildLogsSection(s, logs),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    final appTheme = ref.watch(P.app.theme);
    return Container(
      decoration: BoxDecoration(
        color: appTheme.settingItem,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildModelSection(S s, dynamic latestModel) {
    final modelName = latestModel?.name ?? s.api_server_no_model;
    return _buildSectionCard(
      children: [
        Row(
          children: [
            const FaIcon(FontAwesomeIcons.microchip, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                modelName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: () => ModelSelector.show(),
              child: Text(latestModel != null ? S.current.reselect_model : S.current.select_model),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortSection(S s, BackendState serverState) {
    final isRunning = serverState == BackendState.running;
    return _buildSectionCard(
      children: [
        Row(
          children: [
            Text(s.api_server_port, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                enabled: !isRunning,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (value) {
                  final port = int.tryParse(value);
                  if (port != null && port > 0 && port < 65536) {
                    P.apiServer.port.q = port;
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlSection(S s, BackendState serverState) {
    final isRunning = serverState == BackendState.running;
    final isStopped = serverState == BackendState.stopped;
    final stateLabel = switch (serverState) {
      BackendState.running => s.api_server_running,
      BackendState.stopped => s.api_server_stopped,
      BackendState.starting => s.api_server_starting,
      BackendState.stopping => s.api_server_starting,
    };

    return _buildSectionCard(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRunning ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 10),
            Text(stateLabel, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            FilledButton.icon(
              onPressed: isStopped
                  ? () => P.apiServer.start()
                  : isRunning
                  ? () => P.apiServer.stop()
                  : null,
              icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
              label: Text(isRunning ? s.api_server_stop : s.api_server_start),
              style: FilledButton.styleFrom(
                backgroundColor: isRunning ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(S s, String serverUrl, int reqCount, bool activeRequest) {
    return _buildSectionCard(
      children: [
        Row(
          children: [
            Text('${s.api_server_url}:', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                serverUrl,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: serverUrl));
                Alert.success('Copied');
              },
              tooltip: 'Copy',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('${s.api_server_request_count}: $reqCount', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          'Active Request: ${activeRequest ? 'Yes' : 'No'}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildChatSection(S s, ThemeData theme, bool activeRequest) {
    final allMessages = [
      ..._chatMessages,
      if (_chatSending && _streamingContent.isNotEmpty) _ChatMsg('assistant', _streamingContent),
    ];

    return _buildSectionCard(
      children: [
        const Text('Chat Test', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? Colors.black54 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: allMessages.isEmpty
              ? Center(
                  child: Text(
                    'Send a message to test the API',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final msg = allMessages[index];
                    final isUser = msg.role == 'user';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${msg.role}: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isUser ? Colors.teal : Colors.grey,
                            ),
                          ),
                          Expanded(
                            child: SelectableText(
                              msg.content,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                enabled: !_chatSending && !activeRequest,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: (_) => _sendChatMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _chatSending || activeRequest ? null : _sendChatMessage,
              child: const Text('Send'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: activeRequest ? _stopChatMessage : null,
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Stop'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurlHint(S s, String serverUrl) {
    final curlCmd =
        'curl $serverUrl/v1/chat/completions \\\n  -H "Content-Type: application/json" \\\n  -d \'{"model":"rwkv","messages":[{"role":"user","content":"Hello"}],"stream":true}\'';
    return _buildSectionCard(
      children: [
        Text(s.api_server_curl_hint, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              SelectableText(
                curlCmd,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.greenAccent),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: curlCmd));
                    Alert.success('Copied');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardButton(S s, String serverUrl) {
    return _buildSectionCard(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse('$serverUrl/dashboard')),
                icon: const Icon(Icons.dashboard),
                label: Text(s.api_server_open_dashboard),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse('$serverUrl/docs')),
                icon: const Icon(Icons.description),
                label: const Text('API Docs'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogsSection(S s, List<String> logs) {
    return _buildSectionCard(
      children: [
        Text(s.api_server_logs, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: logs.isEmpty
              ? const Center(
                  child: Text('—', style: TextStyle(color: Colors.white38)),
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
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white70),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
