// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:zone/gen/l10n.dart';
import 'package:zone/model/backend_state.dart';
import 'package:zone/store/p.dart';
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
    final s = S.current;
    final text = _chatController.text.trim();
    if (text.isEmpty || _chatSending) return;

    final port = P.apiServer.port.q;
    final url = 'http://127.0.0.1:$port/v1/chat/completions';

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
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorText = await response.stream.bytesToString();
        throw Exception(errorText.isEmpty ? 'HTTP ${response.statusCode}' : 'HTTP ${response.statusCode}: $errorText');
      }
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
        _chatMessages.add(_ChatMsg('assistant', s.api_server_chat_error(e)));
        _streamingContent = '';
        _chatSending = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _stopChatMessage() async {
    await P.apiServer.stopActiveRequest(showAlert: false);
  }

  String _logsToText(List<String> logs) {
    if (logs.isEmpty) return '';
    return logs.join('\n');
  }

  Future<void> _copyAllLogs(S s, List<String> logs) async {
    if (logs.isEmpty) {
      Alert.warning(s.no_data);
      return;
    }
    final text = _logsToText(logs);
    await Clipboard.setData(ClipboardData(text: text));
    Alert.success(s.code_copied_to_clipboard);
  }

  Future<void> _shareLogFile(S s, List<String> logs) async {
    if (logs.isEmpty) {
      Alert.warning(s.no_data);
      return;
    }

    try {
      final text = _logsToText(logs);
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'rwkv_api_server_logs_$timestamp.txt';
      final filePath = path.join(dir.path, fileName);
      final file = File(filePath);
      await file.writeAsString(text);

      final xFile = XFile(file.path, mimeType: 'text/plain');
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'RWKV API Server Logs',
          subject: fileName,
        ),
      );
    } catch (e) {
      Alert.error(s.api_server_chat_error(e));
    }
  }

  String _chatRoleLabel(S s, String role) {
    return switch (role) {
      'user' => s.user,
      'assistant' => s.assistant,
      _ => '$role:',
    };
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
    final latestModel = ref.watch(P.rwkvModel.latest);
    final isDesktop = ref.watch(P.app.isDesktop);
    final isRunning = serverState == BackendState.running;
    final logs = ref.watch(P.apiServer.logs);
    final accessibleUrls = ref.watch(P.apiServer.accessibleUrls);

    final loopbackUrl = 'http://127.0.0.1:$serverPort';
    final lanUrl = accessibleUrls.isEmpty ? null : accessibleUrls.first;
    final curlUrl = lanUrl ?? loopbackUrl;
    final showLanAddresses = isDesktop || Platform.isAndroid;

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
            _buildStatusSection(s, loopbackUrl, accessibleUrls, reqCount, activeRequest, showLanAddresses),
            const SizedBox(height: 16),
            _buildChatSection(s, theme, activeRequest),
            const SizedBox(height: 16),
            _buildCurlHint(s, curlUrl),
            const SizedBox(height: 16),
            _buildDashboardButton(s, loopbackUrl),
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
      BackendState.stopping => s.stopping,
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

  Widget _buildStatusSection(
    S s,
    String loopbackUrl,
    List<String> accessibleUrls,
    int reqCount,
    bool activeRequest,
    bool showLanAddresses,
  ) {
    return _buildSectionCard(
      children: [
        if (Platform.isAndroid) ...[
          Text(
            s.api_server_android_foreground_hint,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Text('${s.api_server_url}:', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                loopbackUrl,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: loopbackUrl));
                Alert.success(s.chat_copied_to_clipboard);
              },
              tooltip: s.copy_text,
            ),
          ],
        ),
        if (showLanAddresses) ...[
          const SizedBox(height: 12),
          Text(
            '${s.lan_server}:',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (accessibleUrls.isEmpty)
            Text(
              s.api_server_no_lan_address,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          for (final url in accessibleUrls)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      url,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      Alert.success(s.chat_copied_to_clipboard);
                    },
                    tooltip: s.copy_text,
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 8),
        Text('${s.api_server_request_count}: $reqCount', style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          activeRequest ? s.api_server_active_request_yes : s.api_server_active_request_no,
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
        Text(s.api_server_chat_test, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                    s.api_server_chat_empty_hint,
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
                    final roleLabel = _chatRoleLabel(s, msg.role);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roleLabel,
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
                  hintText: s.api_server_chat_input_hint,
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
              child: Text(s.api_server_send),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: activeRequest ? _stopChatMessage : null,
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(s.stop),
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
        Text(
          s.api_server_curl_hint,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'monospace'),
        ),
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
                    Alert.success(s.code_copied_to_clipboard);
                  },
                  tooltip: s.copy_code,
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
                label: Text(s.api_server_docs),
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
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              s.api_server_logs,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'monospace'),
            ),
            TextButton.icon(
              onPressed: logs.isEmpty ? null : () => _copyAllLogs(s, logs),
              icon: const Icon(Icons.copy_all, size: 18),
              label: Text(s.copy_text),
            ),
            TextButton.icon(
              onPressed: logs.isEmpty ? null : () => _shareLogFile(s, logs),
              icon: const Icon(Icons.ios_share, size: 18),
              label: Text(s.share),
            ),
            TextButton.icon(
              onPressed: logs.isEmpty ? null : P.apiServer.clearLogs,
              icon: const Icon(Icons.clear_all, size: 18),
              label: Text(s.clear),
            ),
          ],
        ),
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
