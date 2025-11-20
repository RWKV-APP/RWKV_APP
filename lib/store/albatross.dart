import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:halo/halo.dart';
import 'package:halo_state/halo_state.dart';
import 'package:path/path.dart';
import 'package:rwkv_mobile_flutter/from_rwkv.dart';
import 'package:zone/model/argument.dart';
import 'package:zone/model/demo_type.dart';
import 'package:zone/model/file_info.dart';
import 'package:zone/model/thinking_mode.dart';
import 'package:zone/store/p.dart';

class Albatross {
  static const _port = 9527;
  late final _dio = Dio(BaseOptions(baseUrl: 'http://localhost:$_port'));
  CancelToken? _cancelToken;

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
    if (Platform.isWindows) {
      //
    } else if (Platform.isLinux) {
      //
    } else {
      // return;
    }
    final pwd = await Process.run('pwd', []);
    final dir = pwd.stdout.toString().trim();
    final albatross = File(join(dir, 'albatross'));
    if (await albatross.exists()) {
      P.rwkv.enableAlbatross.q = true;
    }
  }

  Future load(FileInfo fileInfo) async {
    await _Service.kill();
    P.app.demoType.q = DemoType.chat;
    P.rwkv.supportedBatchSizes.q = [2, 4, 6, 8, 10];
    P.rwkv.currentModel.q = fileInfo;
    P.rwkv.setModelConfig(thinkingMode: Free());
    final local = P.fileManager.locals(fileInfo).q;
    try {
      await _Service.run(address: '127.0.0.1', port: _port, modelPath: local.targetPath);
    } catch (e) {
      qqe(e);
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
      "chunk_size": 3,
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
      "chunk_size": 3,
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
    required String address,
    required int port,
    required String modelPath,
  }) async {
    final receivePort = ReceivePort();
    final startup = _Startup(sendPort: receivePort.sendPort, port: 8000, modelPath: modelPath);
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
      if (event is Exception) {
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
      await _startup(startup);
    } catch (e) {
      qqe(e);
      port.send(Exception(e));
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
    final res = Process.runSync('python main_robyn.py --model-path ${message.modelPath} --port ${message.port}', []);
  }

  static Future _shutdown() async {
    //
  }
}

class _Startup {
  final String modelPath;
  final SendPort sendPort;
  final int port;

  _Startup({required this.sendPort, required this.port, required this.modelPath});

  _Startup copyWith({
    String? modelPath,
    SendPort? sendPort,
    int? port,
  }) {
    return _Startup(
      modelPath: modelPath ?? this.modelPath,
      sendPort: sendPort ?? this.sendPort,
      port: port ?? this.port,
    );
  }
}

class _Shutdown {}
