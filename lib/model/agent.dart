// Package imports:
import 'package:meta/meta.dart';

typedef AgentJson = Map<String, Object?>;

enum AgentEvaluationMode {
  strict,
  assisted,
}

enum AgentInterventionKind {
  jsonRepair,
  jsonContainerCompletion,
  fencedJsonExtraction,
  trailingTextExtraction,
  envelopeNormalization,
  argumentTypeCoercion,
  argumentDropped,
  repeatedThinkTruncation,
  repeatedTextTruncation,
  generationBudgetStop,
  forcedToolCall,
  transportContinuation,
  schemaGuidance,
}

extension AgentInterventionKindX on AgentInterventionKind {
  bool get invalidatesStrictScore {
    return switch (this) {
      .transportContinuation || .schemaGuidance => false,
      _ => true,
    };
  }
}

@immutable
final class AgentToolDefinition {
  final String name;
  final String description;
  final AgentJson parameters;

  const AgentToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  AgentJson toJson() {
    return <String, Object?>{
      "type": "function",
      "function": <String, Object?>{
        "name": name,
        "description": description,
        "parameters": parameters,
      },
    };
  }
}

@immutable
final class AgentToolCall {
  final String id;
  final String name;
  final AgentJson arguments;
  final String raw;
  final List<AgentInterventionKind> interventions;

  const AgentToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    required this.raw,
    this.interventions = const <AgentInterventionKind>[],
  });

  AgentJson toJson() {
    return <String, Object?>{
      "id": id,
      "name": name,
      "arguments": arguments,
      "raw": raw,
      "interventions": interventions.map((value) => value.name).toList(),
    };
  }
}

@immutable
final class AgentToolResult {
  final String callId;
  final String toolName;
  final String content;
  final bool isError;

  const AgentToolResult({
    required this.callId,
    required this.toolName,
    required this.content,
    required this.isError,
  });

  AgentJson toJson() {
    return <String, Object?>{
      "callId": callId,
      "toolName": toolName,
      "content": content,
      "isError": isError,
    };
  }
}

@immutable
final class AgentGeneration {
  final String rawOutput;
  final String output;
  final List<AgentInterventionKind> interventions;
  final String stopReason;
  final int durationMs;

  const AgentGeneration({
    required this.rawOutput,
    required this.output,
    this.interventions = const <AgentInterventionKind>[],
    this.stopReason = "",
    this.durationMs = 0,
  });

  const AgentGeneration.raw(String output)
    : rawOutput = output,
      output = output,
      interventions = const <AgentInterventionKind>[],
      stopReason = "",
      durationMs = 0;

  AgentJson toJson() {
    return <String, Object?>{
      "rawOutput": rawOutput,
      "output": output,
      "interventions": interventions.map((value) => value.name).toList(),
      "stopReason": stopReason,
      "durationMs": durationMs,
    };
  }
}

enum AgentEventKind {
  modelOutput,
  toolCall,
  toolResult,
  finalAnswer,
  error,
}

@immutable
final class AgentEvent {
  final AgentEventKind kind;
  final int turn;
  final String title;
  final String content;
  final String? rawContent;
  final List<AgentInterventionKind> interventions;
  final int durationMs;
  final AgentToolCall? toolCall;
  final AgentToolResult? toolResult;

  const AgentEvent({
    required this.kind,
    required this.turn,
    required this.title,
    required this.content,
    this.rawContent,
    this.interventions = const <AgentInterventionKind>[],
    this.durationMs = 0,
    this.toolCall,
    this.toolResult,
  });

  AgentJson toJson() {
    return <String, Object?>{
      "kind": kind.name,
      "turn": turn,
      "title": title,
      "content": content,
      if (rawContent != null) "rawContent": rawContent,
      "interventions": interventions.map((value) => value.name).toList(),
      "durationMs": durationMs,
      if (toolCall != null) "toolCall": toolCall!.toJson(),
      if (toolResult != null) "toolResult": toolResult!.toJson(),
    };
  }
}

enum AgentRunStatus {
  completed,
  submitted,
  cancelled,
  maxTurnsReached,
  failed,
  infrastructureFailed,
}

@immutable
final class AgentRunResult {
  final AgentRunStatus status;
  final String finalAnswer;
  final String prompt;
  final List<AgentEvent> events;
  final int turns;
  final bool validForModelScore;

  const AgentRunResult({
    required this.status,
    required this.finalAnswer,
    required this.prompt,
    required this.events,
    required this.turns,
    this.validForModelScore = true,
  });

  bool get succeeded => status == .completed || status == .submitted;

  bool get usedStrictInvalidatingIntervention {
    for (final event in events) {
      for (final intervention in event.interventions) {
        if (intervention.invalidatesStrictScore) return true;
      }
      final toolCall = event.toolCall;
      if (toolCall == null) continue;
      for (final intervention in toolCall.interventions) {
        if (intervention.invalidatesStrictScore) return true;
      }
    }
    return false;
  }

  Map<String, int> get interventionCounts {
    final counts = <String, int>{};
    for (final event in events) {
      for (final intervention in event.interventions) {
        counts[intervention.name] = (counts[intervention.name] ?? 0) + 1;
      }
      if (event.kind != .toolCall) continue;
      for (final intervention in event.toolCall?.interventions ?? const <AgentInterventionKind>[]) {
        counts[intervention.name] = (counts[intervention.name] ?? 0) + 1;
      }
    }
    return counts;
  }

  AgentJson toJson() {
    return <String, Object?>{
      "status": status.name,
      "finalAnswer": finalAnswer,
      "prompt": prompt,
      "events": events.map((event) => event.toJson()).toList(),
      "turns": turns,
      "validForModelScore": validForModelScore,
      "interventionCounts": interventionCounts,
    };
  }
}

abstract interface class AgentModel {
  Future<AgentGeneration> generate(
    String prompt, {
    required AgentEvaluationMode mode,
  });
}

abstract interface class AgentToolHost {
  List<AgentToolDefinition> get tools;

  Future<AgentToolResult> call(AgentToolCall call);
}

@immutable
final class AgentSamplerConfig {
  final double temperature;
  final int topK;
  final double topP;
  final double presencePenalty;
  final double frequencyPenalty;
  final double penaltyDecay;

  const AgentSamplerConfig({
    required this.temperature,
    required this.topK,
    required this.topP,
    required this.presencePenalty,
    required this.frequencyPenalty,
    required this.penaltyDecay,
  });

  void validate() {
    if (temperature < .2 || temperature > 2) {
      throw AgentInfrastructureException(
        code: "invalid_sampler_config",
        message: "Agent temperature must be between 0.2 and 2.0, got $temperature",
      );
    }
    if (topK <= 0) {
      throw AgentInfrastructureException(
        code: "invalid_sampler_config",
        message: "Agent topK must be greater than zero, got $topK",
      );
    }
    if (topP < 0 || topP > 1) {
      throw AgentInfrastructureException(
        code: "invalid_sampler_config",
        message: "Agent topP must be between 0 and 1, got $topP",
      );
    }
    if (presencePenalty < 0 || presencePenalty > 2) {
      throw AgentInfrastructureException(
        code: "invalid_sampler_config",
        message: "Agent presence penalty must be between 0 and 2, got $presencePenalty",
      );
    }
    if (frequencyPenalty < 0 || frequencyPenalty > 1) {
      throw AgentInfrastructureException(
        code: "invalid_sampler_config",
        message: "Agent frequency penalty must be between 0 and 1, got $frequencyPenalty",
      );
    }
    if (penaltyDecay < .99 || penaltyDecay > .999) {
      throw AgentInfrastructureException(
        code: "invalid_sampler_config",
        message: "Agent penalty decay must be between 0.99 and 0.999, got $penaltyDecay",
      );
    }
  }

  AgentJson toManifest({required int seed}) {
    return <String, Object?>{
      "seed": seed,
      "temperature": temperature,
      "topK": topK,
      "topP": topP,
      "presencePenalty": presencePenalty,
      "frequencyPenalty": frequencyPenalty,
      "penaltyDecay": penaltyDecay,
    };
  }
}

const AgentSamplerConfig agentEvaluationSamplerConfig = AgentSamplerConfig(
  temperature: .2,
  topK: 500,
  topP: 0,
  presencePenalty: 0,
  frequencyPenalty: 0,
  penaltyDecay: .99,
);

final class AgentResponseBufferGate {
  final String _staleContent;
  final String replacementPrefix;
  bool _staleBufferReset;

  AgentResponseBufferGate({
    required String staleContent,
    this.replacementPrefix = "",
  }) : _staleContent = staleContent,
       _staleBufferReset = staleContent.isEmpty;

  String freshContent(String full) {
    if (_staleBufferReset) return full;
    if (full.isEmpty) {
      _staleBufferReset = true;
      return "";
    }
    if (full == _staleContent) return "";
    if (full.startsWith(_staleContent)) {
      final fresh = full.substring(_staleContent.length);
      if (replacementPrefix.isEmpty || fresh.startsWith(replacementPrefix)) {
        return fresh;
      }
      return "$replacementPrefix$fresh";
    }
    _staleBufferReset = true;
    return full;
  }
}

final class AgentResponsePollTracker {
  final int modelID;
  final Set<int> _requestIds = <int>{};

  AgentResponsePollTracker({required this.modelID});

  void register(int requestId) {
    _requestIds.add(requestId);
  }

  bool consume({
    required int modelID,
    required int requestId,
  }) {
    if (modelID != this.modelID) return false;
    return _requestIds.remove(requestId);
  }
}

final class AgentInfrastructureException implements Exception {
  final String code;
  final String message;

  const AgentInfrastructureException({
    required this.code,
    required this.message,
  });

  @override
  String toString() {
    return "$code: $message";
  }
}
