import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path/path.dart';
import 'package:rwkv_mobile_flutter/from_rwkv.dart';
import 'package:rwkv_mobile_flutter/types.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/thinking_mode.dart';
import 'package:zone/store/p.dart';

class Albatross {
  static const _chunkSize = 3;

  late final _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:9527',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  CancelToken? _cancelToken;

  String get host => _dio.options.baseUrl.replaceFirst('http://', '');

  set host(String host) {
    _dio.options.baseUrl = 'http://$host';
    qqq('set service host to $host');
  }

  final _decodeParam = {
    "temperature": 1.0,
    "top_k": 1,
    "top_p": 0.3,
    "alpha_presence": 0.5,
    "alpha_frequency": 0.5,
    "alpha_decay": 0.996,
    "max_tokens": 1000,
  };

  static final instance = Albatross._();

  Albatross._();

  Future _updateDecodeParam() async {
    _decodeParam['temperature'] = P.rwkv.arguments(Argument.temperature).q;
    _decodeParam['top_k'] = P.rwkv.arguments(Argument.topK).q;
    _decodeParam['top_p'] = P.rwkv.arguments(Argument.topP).q;
    _decodeParam['alpha_presence'] = P.rwkv.arguments(Argument.presencePenalty).q;
    _decodeParam['alpha_frequency'] = P.rwkv.arguments(Argument.frequencyPenalty).q;
    _decodeParam['alpha_decay'] = P.rwkv.arguments(Argument.penaltyDecay).q;
    _decodeParam['max_tokens'] = P.rwkv.arguments(Argument.maxLength).q;
  }

  Future init() async {
    bool available = false;

    try {
      final status = await _dio.get('/status');
      available = status.statusCode == 200;
    } catch (_) {
      //
    }

    P.rwkv.enableAlbatross.q = available;
    qqq('>> albatross is ${available ? 'enabled' : 'disabled'}');
    return;

    final cwd = Platform.resolvedExecutable;
    final albatross = Directory(join(dirname(cwd), 'albatross'));
    if (await albatross.exists()) {
      await _Service.run(cwd: cwd, port: 9527);
      P.rwkv.enableAlbatross.q = true;
      qqq('albatross is enabled');
    } else {
      P.rwkv.enableAlbatross.q = false;
      qqq('albatross not found, disabled');
    }
  }

  Future load(FileInfo fileInfo) async {
    if (!P.rwkv.enableAlbatross.q) {
      return;
    }
    final local = P.weights.locals(fileInfo).q;
    try {
      P.rwkv.loadingStatus.q = {...P.rwkv.loadingStatus.q, fileInfo: LoadingStatus.loading};
      final r = await _dio.post(
        '/load-model',
        data: {'model_path': local.targetPath},
      );
      if (r.statusCode == 200) {
        P.app.demoType.q = .chat;
        P.rwkv.supportedBatchSizes.q = [2, 4, 6, 8, 10];
        P.rwkv.loadedModels.q = {...P.rwkv.loadedModels.q, fileInfo: -1};
        P.rwkv.setModelConfig(thinkingMode: const Free());
      } else {
        final body = r.data['error'];
        Alert.error("${r.statusCode}: $body");
      }
    } catch (e) {
      qqe(e);
    } finally {
      P.rwkv.loadingStatus.q = {...P.rwkv.loadingStatus.q, fileInfo: LoadingStatus.none};
    }
  }

  Future release() async {
    await _Service.kill();
  }

  Future stop() async {
    _cancelToken?.cancel('user cancel');
    _cancelToken = null;
    P.rwkv.generating.q = false;
  }

  Stream<FromRWKV> chat(List<String> messages, {int batchSize = 1}) async* {
    await _updateDecodeParam();
    final enableThink = P.rwkv.thinkingMode.q is! None;
    final data = {
      "messages": [
        for (var i = 0; i < messages.length; i++) //
          {
            "role": i % 2 == 0 ? "user" : "assistant", //
            "content": messages[i].trim(),
          },
      ],
      "stop_tokens": [0, 261, 24281],
      "pad_zero": true,
      "chunk_size": _chunkSize,
      "stream": true,
      "enable_think": enableThink,
      ..._decodeParam,
    };
    try {
      qqq('starting...');
      P.rwkv.generating.q = true;
      _cancelToken = CancelToken();
      final resp = await _dio.post(
        '/v3/chat/completions',
        cancelToken: _cancelToken,
        data: data,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      final body = resp.data as ResponseBody;
      List<String> buffer = List.filled(batchSize, '');
      await for (final chunk in body.stream) {
        final data = utf8.decode(chunk).trim().replaceFirst('data: ', '');
        if (data == '[DONE]') {
          qqq('done');
          break;
        }
        final map = jsonDecode(data);
        final choices = map['choices'];
        for (final c in choices) {
          final index = c['index'];
          final content = c['delta']['content'] as String;
          buffer[index] += content;
          if (enableThink && !buffer[index].startsWith('<think')) {
            buffer[index] = '<think${buffer[index]}';
          }
          if (batchSize == 1) {
            yield ResponseBufferContent(responseBufferContent: buffer[0], eosFound: false);
          } else {
            yield ResponseBatchBufferContent(
              responseBufferContent: buffer,
              eosFound: [for (var i in buffer) i.endsWith('\n\n')],
              batchSize: batchSize,
            );
          }
        }
      }
      if (batchSize == 1) {
        yield ResponseBufferContent(responseBufferContent: buffer[0], eosFound: true);
      } else {
        yield ResponseBatchBufferContent(responseBufferContent: buffer, eosFound: List.filled(batchSize, true), batchSize: batchSize);
      }
    } catch (e) {
      qqe(e);
      rethrow;
    } finally {
      qqq('stopped');
      P.rwkv.generating.q = false;
      _cancelToken = null;
    }
  }

  Stream<ResponseBatchBufferContent> completion(String prompt, {int batchSize = 1}) async* {
    _updateDecodeParam();
    final data = {
      "contents": List.filled(batchSize, prompt),
      "stop_tokens": [0, 261, 24281],
      "pad_zero": true,
      "chunk_size": _chunkSize,
      "stream": true,
      "enable_think": false,
      ..._decodeParam,
    };
    var result = ResponseBatchBufferContent(
      responseBufferContent: List.filled(batchSize, prompt),
      eosFound: List.filled(batchSize, false),
      batchSize: batchSize,
    );
    try {
      qqq('starting...');
      P.rwkv.generating.q = true;
      _cancelToken = CancelToken();
      final resp = await _dio.post(
        '/v2/chat/completions',
        cancelToken: _cancelToken,
        data: data,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      final body = resp.data as ResponseBody;
      await for (final chunk in body.stream) {
        final data = utf8.decode(chunk).trim().replaceFirst('data: ', '');
        if (data == '[DONE]') {
          qqq('done');
          result = ResponseBatchBufferContent(
            responseBufferContent: result.responseBufferContent,
            eosFound: List.filled(batchSize, true),
            batchSize: batchSize,
          );
          yield result;
          break;
        }
        final map = jsonDecode(data);
        final choices = map['choices'];
        for (final c in choices) {
          final index = c['index'];
          final content = c['delta']['content'] as String;
          result.responseBufferContent[index] += content;
          result.eosFound[index] = content.endsWith('\n\n');
        }
        yield result;
      }
    } catch (e) {
      qqe(e);
      rethrow;
    } finally {
      qqq('stopped');
      P.rwkv.generating.q = false;
      _cancelToken = null;
    }
  }
}

class _Service {
  _Service._();

  static SendPort? _port;
  static Isolate? _isolate;

  static Future run({
    required String cwd,
    required int port,
  }) async {
    final receivePort = ReceivePort();
    final startup = _Startup(cwd: cwd, sendPort: receivePort.sendPort, port: port);
    _isolate = await Isolate.spawn(_Service._main, startup);

    final events = receivePort.asBroadcastStream();
    final message = await events.first;
    if (message is _Startup) {
      _port = message.sendPort;
      qqq('Albatross is running');
    } else if (message is Exception) {
      qqe('Failed to startup albatross\n$message');
      return;
    }

    /// listen to status changes
    () async {
      final event = await events.first;
      if (event is String) {
        qqe('Exception in albatross: $event');
      } else if (event is _Shutdown) {
        receivePort.close();
        qqq('Albatross is stopped');
      }
    }();
  }

  static Future kill() async {
    _port?.send(_Shutdown());
    _port = null;
    _isolate?.kill();
    _isolate = null;
  }

  static Future _main(_Startup startup) async {
    SendPort port = startup.sendPort;
    try {
      _startup(startup);
    } catch (e) {
      qqe(e);
      port.send(e.toString());
      return;
    }

    ReceivePort rcv = ReceivePort();
    port.send(startup.copyWith(sendPort: rcv.sendPort));

    await for (final cmd in rcv) {
      if (cmd is _Shutdown) {
        break;
      }
    }
    await _shutdown();
    port.send(_Shutdown());
    rcv.close();
  }

  static Future _startup(_Startup message) async {
    final python = await _findPython();
    if (python == null) throw Exception('No python executable found');

    final res = await _run(
      executable: '$python ${message.cwd}/main_robyn.py',
      args: ["--port ${message.port}"],
    );
    qqq(res.stdout);
    qqq(res.stderr);
  }

  static Future _shutdown() async {
    //
  }

  static Future<String?> _findPython() async {
    for (final envVar in ['VIRTUAL_ENV', 'CONDA_PREFIX']) {
      final base = Platform.environment[envVar];
      if (base != null && base.isNotEmpty) {
        final exe = Platform.isWindows ? '$base\\Scripts\\python.exe' : '$base/bin/python';
        if (await File(exe).exists()) return exe;
      }
    }
    final candidates = Platform.isWindows ? ['python.exe', 'py.exe', r'C:\Windows\py.exe'] : ['python3', 'python'];
    for (final name in candidates) {
      try {
        final r = await Process.run(name, ['-c', 'print("ok")']);
        if (r.exitCode == 0 && (r.stdout as String).contains('ok')) {
          if (name == 'py.exe') {
            final p = await Process.run('py', ['-3', '-c', 'import sys;print(sys.executable)']);
            if (p.exitCode == 0) return (p.stdout as String).trim();
          }
          return name;
        }
      } catch (_) {}
    }
    if (Platform.isWindows) return null;
    final which = await Process.run('which', ['python3']);
    return which.exitCode == 0 ? (which.stdout as String).toString().trim() : null;
  }

  static Future<ProcessResult> _run({
    required String executable,
    List<String> args = const [],
    String? cwd,
  }) async {
    final env = Map<String, String>.from(Platform.environment);

    final conda = Platform.environment['CONDA_PREFIX'];

    env['PATH'] = '${env['PATH']}:$conda/bin';
    if (conda != null) {
      env['LD_LIBRARY_PATH'] = [
        "$conda/lib",
        if (env['LD_LIBRARY_PATH'] != null) env['LD_LIBRARY_PATH']!,
      ].where((e) => e.isNotEmpty).join(':');
    }

    final useShellForPipes = Platform.isWindows || Platform.isMacOS;
    if (useShellForPipes) {
      if (Platform.isWindows) {
        return Process.run(
          'powershell',
          [
            '-NoProfile',
            '-ExecutionPolicy',
            'Bypass',
            '-Command',
            ([executable, ...args].map((e) => '"$e"').join(' ')),
          ],
          workingDirectory: cwd,
          environment: env,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        ).timeout(const Duration(days: 365));
      } else {
        final cmd = ([executable, ...args].map((e) => '"$e"').join(' '));
        return Process.run(
          '/bin/bash',
          ['-lc', cmd],
          workingDirectory: cwd,
          environment: env,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        ).timeout(const Duration(days: 365));
      }
    } else {
      return Process.run(
        executable,
        args,
        workingDirectory: cwd,
        environment: env,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(days: 365));
    }
  }
}

class _Startup {
  final String cwd;
  final SendPort sendPort;
  final int port;

  _Startup({required this.sendPort, required this.port, required this.cwd});

  _Startup copyWith({
    String? modelPath,
    SendPort? sendPort,
    int? port,
    String? cwd,
  }) {
    return _Startup(
      sendPort: sendPort ?? this.sendPort,
      port: port ?? this.port,
      cwd: cwd ?? this.cwd,
    );
  }
}

class _Shutdown {}
