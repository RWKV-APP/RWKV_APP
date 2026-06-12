import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/albatross_protocol.dart';

void main() {
  group('shouldShowAlbatrossEntry', () {
    test('requires Windows x64 and NVIDIA GPU name', () {
      expect(
        shouldShowAlbatrossEntry(
          isWindows: true,
          isWindowsX64: true,
          gpuName: 'NVIDIA GeForce RTX 4090',
        ),
        isTrue,
      );
      expect(
        shouldShowAlbatrossEntry(
          isWindows: true,
          isWindowsX64: false,
          gpuName: 'NVIDIA GeForce RTX 4090',
        ),
        isFalse,
      );
      expect(
        shouldShowAlbatrossEntry(
          isWindows: true,
          isWindowsX64: true,
          gpuName: 'AMD Radeon',
        ),
        isFalse,
      );
    });
  });

  group('albatrossProbePaths', () {
    test('uses the current server models endpoint as primary readiness check', () {
      expect(albatrossProbePaths.first, '/v1/models');
      expect(albatrossProbePaths, contains('/status'));
      expect(albatrossProbePaths, contains('/v1/server/status'));
    });
  });

  group('buildAlbatrossLaunchArgs', () {
    test('uses current CUDA server argument names by default', () {
      final args = buildAlbatrossLaunchArgs(
        modelPath: r'E:\model.pth',
        tokenizerPath: r'D:\bundle\rwkv_vocab_v20230424.txt',
        host: '127.0.0.1',
        port: 9527,
      );

      expect(args, <String>[
        '--model-path',
        r'E:\model.pth',
        '--vocab-path',
        r'D:\bundle\rwkv_vocab_v20230424.txt',
        '--port',
        '9527',
      ]);
    });

    test('keeps explicitly configured args compatible with older configs', () {
      final args = buildAlbatrossLaunchArgs(
        modelPath: 'model.pth',
        tokenizerPath: 'vocab.txt',
        host: '127.0.0.1',
        port: 9527,
        rawArgs: const <String>['--model', '{model_path}', '--tokenizer', '{tokenizer_path}', '--host', '{host}', '--port', '{port}'],
      );

      expect(args, <String>['--model', 'model.pth', '--tokenizer', 'vocab.txt', '--host', '127.0.0.1', '--port', '9527']);
    });
  });

  group('buildAlbatrossDisplaySystemInfo', () {
    test('hides SoC fields on desktop and avoids duplicate NVIDIA GPU fields', () {
      final info = buildAlbatrossDisplaySystemInfo(
        telemetryInfo: const <String, String>{
          'AppVersion': '4.5.5 (736)',
          'SocName': 'Intel CPU',
          'SocBrand': 'nvidia',
          'CPUName': 'Intel CPU',
          'GPUName': 'NVIDIA GeForce RTX 3080',
          'TotalVRAM': '10 GB',
        },
        cudaInfo: const <String, String>{
          'NVIDIA GPU': 'NVIDIA GeForce RTX 3080',
          'NVIDIA VRAM': '10240 MB',
          'CUDA Driver API': '12.9',
        },
        isDesktop: true,
      );

      expect(info.containsKey('SocName'), isFalse);
      expect(info.containsKey('SocBrand'), isFalse);
      expect(info['GPUName'], 'NVIDIA GeForce RTX 3080');
      expect(info.containsKey('NVIDIA GPU'), isFalse);
      expect(info['TotalVRAM'], '10 GB');
      expect(info.containsKey('NVIDIA VRAM'), isFalse);
      expect(info['CUDA Driver API'], '12.9');
    });
  });

  group('missingAlbatrossRuntimeDlls', () {
    test('accepts a complete bundle lib directory', () {
      final existingFiles = <String>{
        for (final dll in albatrossWindowsRuntimeDlls) r'D:\bundle\lib\' + dll,
      };

      final missing = missingAlbatrossRuntimeDlls(
        executablePath: r'D:\bundle\rwkv_lighting_cuda.exe',
        isWindows: true,
        fileExists: existingFiles.contains,
      );

      expect(missing, isEmpty);
    });

    test('reports missing CUDA runtime DLLs from a plain Release directory', () {
      final existingFiles = <String>{
        r'D:\build\Release\drogon.dll',
        r'D:\build\Release\trantor.dll',
        r'D:\build\Release\jsoncpp.dll',
        r'D:\build\Release\sqlite3.dll',
      };

      final missing = missingAlbatrossRuntimeDlls(
        executablePath: r'D:\build\Release\rwkv_lighting_cuda.exe',
        isWindows: true,
        fileExists: existingFiles.contains,
      );

      expect(missing, contains('cudart64_12.dll'));
      expect(missing, contains('cublas64_12.dll'));
      expect(missing, contains('cublasLt64_12.dll'));
      expect(missing, contains('msvcp140.dll'));
      expect(missing, contains('vcruntime140.dll'));
    });
  });

  group('buildAlbatrossRuntimeLogExportContent', () {
    test('includes launch command and logs', () {
      final content = buildAlbatrossRuntimeLogExportContent(
        launchCommandTitle: 'Launch Command',
        runtimeLogsTitle: 'Runtime Logs',
        launchCommand: 'rwkv_lighting_cuda.exe --port 9527',
        logs: const <String>[
          '[14:05:59] start',
          '[14:06:00] probe failed',
        ],
      );

      expect(content, contains('===== Launch Command ====='));
      expect(content, contains('rwkv_lighting_cuda.exe --port 9527'));
      expect(content, contains('===== Runtime Logs ====='));
      expect(content, contains('[14:05:59] start'));
      expect(content, contains('[14:06:00] probe failed'));
    });

    test('returns empty content when logs are empty', () {
      final content = buildAlbatrossRuntimeLogExportContent(
        launchCommandTitle: 'Launch Command',
        runtimeLogsTitle: 'Runtime Logs',
        launchCommand: 'rwkv_lighting_cuda.exe --port 9527',
        logs: const <String>[],
      );

      expect(content, isEmpty);
    });
  });

  group('buildAlbatrossRuntimeLogExportFileName', () {
    test('uses stable timestamp format', () {
      final fileName = buildAlbatrossRuntimeLogExportFileName(
        now: DateTime(2026, 6, 12, 14, 6, 7),
      );

      expect(fileName, 'rwkv_albatross_logs_20260612_140607.txt');
    });
  });

  group('buildAlbatrossCompletionPrompt', () {
    test('renders alternating chat history for continuation', () {
      final prompt = buildAlbatrossCompletionPrompt(const <String>[
        'Hello',
        'Hi',
        'How are you?',
      ]);

      expect(prompt, 'User: Hello\n\nAssistant: Hi\n\nUser: How are you?\n\nAssistant:');
    });

    test('strips thinking content from assistant history', () {
      final prompt = buildAlbatrossCompletionPrompt(const <String>[
        'Solve it',
        '<think>hidden</think>\nVisible answer',
      ]);

      expect(prompt, 'User: Solve it\n\nAssistant: Visible answer\n\nAssistant:');
    });
  });

  group('AlbatrossSseParser', () {
    test('parses split SSE chunks and done marker', () {
      final parser = AlbatrossSseParser();

      final first = parser.add('data: {"choices":[{"index":0,"delta":{"content":"你"}}]');
      expect(first, isEmpty);

      final second = parser.add('}\n\ndata: [DONE]\n\n');
      expect(second.length, 2);
      expect(second.first.done, isFalse);
      expect(second.first.choices.single.index, 0);
      expect(second.first.choices.single.content, '你');
      expect(second.last.done, isTrue);
    });

    test('keeps batch choice indexes', () {
      final parser = AlbatrossSseParser();
      final events = parser.add(
        'data: {"choices":[{"index":0,"delta":{"content":"A"}},{"index":2,"delta":{"content":"C"}}]}\n\n',
      );

      expect(events.single.choices.map((choice) => choice.index), <int>[0, 2]);
      expect(events.single.choices.map((choice) => choice.content), <String>['A', 'C']);
    });
  });
}
