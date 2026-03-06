// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:dio/dio.dart';
import 'package:halo/halo.dart';
import 'package:halo_alert/halo_alert.dart';
import 'package:halo_state/halo_state.dart';
import 'package:rwkv_mobile_flutter/from_rwkv.dart';
import 'package:rwkv_mobile_flutter/types.dart';

// Project imports:
import 'package:zone/model/argument.dart';
import 'package:zone/model/file_info.dart';
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
  }

  Future load(FileInfo fileInfo) async {
    if (!P.rwkv.enableAlbatross.q) {
      return;
    }
    final local = P.remote.locals(fileInfo).q;
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
        P.rwkv.setModelConfig(thinkingMode: .free);
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

  Future<void> release() async {
    return;
  }

  Future stop() async {
    _cancelToken?.cancel('user cancel');
    _cancelToken = null;
    P.rwkv.generating.q = false;
  }

  Stream<FromRWKV> chat(List<String> messages, {int batchSize = 1}) async* {
    await _updateDecodeParam();
    final enableThink = P.rwkv.thinkingMode.q != .none;
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
