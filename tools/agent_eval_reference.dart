// Dart imports:
import 'dart:convert';
import 'dart:io';

// Package imports:
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

// Project imports:
import 'package:zone/func/agent_runtime.dart';
import 'package:zone/func/agent_sandboxed_lua.dart';
import 'package:zone/model/agent.dart';
import 'package:zone/model/agent_case.dart';
import 'package:zone/model/agent_evaluation.dart';

Future<void> main(List<String> arguments) async {
  final options = _ReferenceOptions.parse(arguments);
  if (options.help) {
    stdout.write(_referenceUsage);
    return;
  }
  options.validate();

  final assetFile = File(options.casesPath);
  final rawCases = await assetFile.readAsString();
  final decodedCases = jsonDecode(rawCases);
  if (decodedCases is! List) {
    throw const FormatException("Primitive Bench cases must be a JSON array");
  }
  final cases = <AgentCase>[];
  for (final value in decodedCases) {
    cases.add(AgentCase.fromJson(_dynamicMap(value)));
  }

  final startedAt = DateTime.now();
  final runId = "${startedAt.toUtc().toIso8601String().replaceAll(RegExp(r"[^0-9]"), "")}-reference";
  final manifest = AgentEvaluationManifest(
    schemaVersion: agentEvaluationSchemaVersion,
    benchmarkId: agentEvaluationBenchmarkId,
    benchmarkVersion: agentEvaluationBenchmarkVersion,
    benchmarkSha256: sha256.convert(utf8.encode(rawCases)).toString(),
    caseCount: cases.length,
    runId: runId,
    mode: options.mode,
    repeatCount: options.repeats,
    selectedCases: cases.map((value) => value.name).toList(),
    plannedRuns: cases.length * options.repeats,
    app: <String, Object?>{
      "runner": "tools/agent_eval_reference.dart",
      "sourceRevision": options.sourceRevision,
    },
    device: <String, Object?>{
      "os": Platform.operatingSystem,
      "osVersion": Platform.operatingSystemVersion,
      "host": Platform.localHostname,
    },
    model: <String, Object?>{
      "name": options.model,
      "sha256": options.modelSha256,
      "precision": options.precision,
      "backend": "remote-reference",
      "endpointOrigin": options.endpoint.origin,
      "apiProtocol": options.protocol,
    },
    sampler: const <String, Object?>{
      "seed": agentEvaluationSeed,
      "temperature": 0,
      "topK": 0,
      "topP": 1,
      "presencePenalty": 0,
      "frequencyPenalty": 0,
      "penaltyDecay": .99,
    },
  );
  final records = <AgentCaseRunRecord>[];
  final model = _ReferenceAgentModel(options);
  final lua = AgentSandboxedLua();

  for (int attempt = 1; attempt <= options.repeats; attempt++) {
    for (final entry in cases.indexed) {
      final agentCase = entry.$2;
      final caseStartedAt = DateTime.now();
      stdout.writeln(
        "[${records.length + 1}/${cases.length * options.repeats}] ${agentCase.name} (attempt $attempt)",
      );
      final sandbox = agentCase.createSandbox(luaRunner: lua.run);
      final runtime = AgentRuntime(
        model: model,
        toolHost: sandbox,
        mode: options.mode,
        maxTurns: agentCase.maxTurns,
      );
      final result = await runtime.run(
        system: agentCase.system,
        user: agentCase.prompt,
      );
      final verdict = agentCase.score(result: result, sandbox: sandbox);
      records.add(
        AgentCaseRunRecord(
          agentCase: agentCase,
          result: result,
          verdict: verdict,
          runId: runId,
          attempt: attempt,
          startedAt: caseStartedAt,
          completedAt: DateTime.now(),
        ),
      );
      await _writeReport(
        outputPath: options.outputPath,
        report: AgentEvaluationReport(
          manifest: manifest,
          startedAt: startedAt,
          completedAt: null,
          records: List<AgentCaseRunRecord>.unmodifiable(records),
        ),
      );
      if (result.status == .infrastructureFailed) {
        await _writeReport(
          outputPath: options.outputPath,
          report: AgentEvaluationReport(
            manifest: manifest,
            startedAt: startedAt,
            completedAt: DateTime.now(),
            records: List<AgentCaseRunRecord>.unmodifiable(records),
            error: result.events.isEmpty ? "Infrastructure failure" : result.events.last.content,
          ),
        );
        stderr.writeln("Infrastructure failure detected; the batch was stopped.");
        exitCode = 2;
        return;
      }
    }
  }

  await _writeReport(
    outputPath: options.outputPath,
    report: AgentEvaluationReport(
      manifest: manifest,
      startedAt: startedAt,
      completedAt: DateTime.now(),
      records: List<AgentCaseRunRecord>.unmodifiable(records),
    ),
  );
  stdout.writeln(options.outputPath);
}

Future<void> _writeReport({
  required String outputPath,
  required AgentEvaluationReport report,
}) async {
  final target = File(outputPath);
  await target.parent.create(recursive: true);
  final temporary = File("$outputPath.tmp");
  final content = const JsonEncoder.withIndent("  ").convert(report.toJson());
  await temporary.writeAsString(content, flush: true);
  if (Platform.isWindows && await target.exists()) {
    await target.delete();
  }
  await temporary.rename(target.path);
}

final class _ReferenceAgentModel implements AgentModel {
  final _ReferenceOptions options;
  final http.Client _client = http.Client();

  _ReferenceAgentModel(this.options);

  @override
  Future<AgentGeneration> generate(
    String prompt, {
    required AgentEvaluationMode mode,
  }) async {
    final stopwatch = Stopwatch()..start();
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: "application/json",
    };
    final apiKey = options.apiKey;
    if (apiKey != null) {
      headers[HttpHeaders.authorizationHeader] = "Bearer $apiKey";
    }
    final body = options.protocol == "chat"
        ? <String, Object?>{
            "model": options.model,
            "messages": <Map<String, String>>[
              <String, String>{"role": "user", "content": prompt},
            ],
            "max_tokens": 10240,
            "temperature": 0,
            "top_p": 1,
            "seed": agentEvaluationSeed,
            "stream": false,
          }
        : <String, Object?>{
            "model": options.model,
            "prompt": prompt,
            "max_tokens": 10240,
            "temperature": 0,
            "top_p": 1,
            "seed": agentEvaluationSeed,
            "stream": false,
          };
    late final http.Response response;
    try {
      response = await _client
          .post(
            options.endpoint,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(options.timeout);
    } catch (error) {
      throw AgentInfrastructureException(
        code: "reference_transport_error",
        message: error.toString(),
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AgentInfrastructureException(
        code: "reference_http_${response.statusCode}",
        message: _bounded(response.body),
      );
    }
    final decoded = jsonDecode(response.body);
    final root = _dynamicMap(decoded);
    final choices = root["choices"];
    if (choices is! List || choices.isEmpty) {
      throw const AgentInfrastructureException(
        code: "reference_invalid_response",
        message: "Response did not contain choices",
      );
    }
    final choice = _dynamicMap(choices.first);
    final text = options.protocol == "chat" ? _dynamicMap(choice["message"])["content"]?.toString() : choice["text"]?.toString();
    if (text == null) {
      throw const AgentInfrastructureException(
        code: "reference_invalid_response",
        message: "Response did not contain generated text",
      );
    }
    return AgentGeneration(
      rawOutput: text,
      output: text,
      stopReason: choice["finish_reason"]?.toString() ?? "",
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  String _bounded(String value) {
    if (value.length <= 1000) return value;
    return value.substring(0, 1000);
  }
}

final class _ReferenceOptions {
  final Uri endpoint;
  final String model;
  final String modelSha256;
  final String precision;
  final String protocol;
  final String outputPath;
  final String casesPath;
  final String sourceRevision;
  final String? apiKey;
  final AgentEvaluationMode mode;
  final int repeats;
  final Duration timeout;
  final bool allowUnverifiedModel;
  final bool help;

  const _ReferenceOptions({
    required this.endpoint,
    required this.model,
    required this.modelSha256,
    required this.precision,
    required this.protocol,
    required this.outputPath,
    required this.casesPath,
    required this.sourceRevision,
    required this.apiKey,
    required this.mode,
    required this.repeats,
    required this.timeout,
    required this.allowUnverifiedModel,
    required this.help,
  });

  factory _ReferenceOptions.parse(List<String> arguments) {
    final values = <String, String>{};
    bool allowUnverifiedModel = false;
    bool help = false;
    for (int index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == "--help" || argument == "-h") {
        help = true;
        continue;
      }
      if (argument == "--allow-unverified-model") {
        allowUnverifiedModel = true;
        continue;
      }
      if (!argument.startsWith("--") || index + 1 >= arguments.length) {
        throw FormatException("Invalid argument: $argument");
      }
      index += 1;
      values[argument.substring(2)] = arguments[index];
    }
    final apiKeyEnvironment = values["api-key-env"];
    final apiKey = apiKeyEnvironment == null ? null : Platform.environment[apiKeyEnvironment];
    if (apiKeyEnvironment != null && (apiKey == null || apiKey.isEmpty)) {
      throw StateError("Environment variable $apiKeyEnvironment is empty");
    }
    return _ReferenceOptions(
      endpoint: Uri.parse(values["endpoint"] ?? "http://127.0.0.1:8000/v1/completions"),
      model: values["model"] ?? "",
      modelSha256: values["model-sha256"] ?? "unverified",
      precision: values["precision"] ?? "bf16",
      protocol: values["protocol"] ?? "completions",
      outputPath: values["output"] ?? "agent-reference-report.json",
      casesPath: values["cases"] ?? "assets/agent_cases/primitive_bench.json",
      sourceRevision: values["source-revision"] ?? "unknown",
      apiKey: apiKey,
      mode: values["mode"] == "assisted" ? .assisted : .strict,
      repeats: int.tryParse(values["repeats"] ?? "") ?? 3,
      timeout: Duration(seconds: int.tryParse(values["timeout-seconds"] ?? "") ?? 900),
      allowUnverifiedModel: allowUnverifiedModel,
      help: help,
    );
  }

  void validate() {
    if (model.isEmpty) {
      throw const FormatException("--model is required");
    }
    if (modelSha256 == "unverified" && !allowUnverifiedModel) {
      throw const FormatException(
        "--model-sha256 is required; use --allow-unverified-model only for exploratory runs",
      );
    }
    if (!const <String>{"completions", "chat"}.contains(protocol)) {
      throw FormatException("Unsupported protocol: $protocol");
    }
    if (repeats < 1 || repeats > 20) {
      throw const FormatException("--repeats must be between 1 and 20");
    }
  }
}

Map<String, dynamic> _dynamicMap(Object? value) {
  if (value is! Map) return <String, dynamic>{};
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) continue;
    result[entry.key as String] = entry.value;
  }
  return result;
}

const String _referenceUsage = """
Usage:
  dart run tools/agent_eval_reference.dart \\
    --endpoint http://HOST:PORT/v1/completions \\
    --model MODEL_ID \\
    --model-sha256 SHA256 \\
    --precision bf16 \\
    --output REPORT.json

Options:
  --protocol completions|chat   OpenAI-compatible API shape (default: completions)
  --api-key-env NAME           Read the bearer token from an environment variable
  --mode strict|assisted       Evaluation mode (default: strict)
  --repeats N                  Number of full benchmark repetitions (default: 3)
  --timeout-seconds N          Per-generation timeout (default: 900)
  --cases PATH                 Benchmark JSON path
  --source-revision REV        Evaluated source revision
  --allow-unverified-model     Permit a run without a model hash
  --help                       Show this help
""";
