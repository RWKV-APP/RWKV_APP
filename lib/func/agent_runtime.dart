// Dart imports:
import 'dart:convert';

// Project imports:
import 'package:zone/func/g1h_agent_protocol.dart';
import 'package:zone/model/agent.dart';

typedef AgentCancelled = bool Function();
typedef AgentEventCallback = Future<void> Function(AgentEvent event);

final class AgentRuntime {
  final AgentModel model;
  final AgentToolHost toolHost;
  final G1hAgentProtocol protocol;
  final AgentEvaluationMode mode;
  final int maxTurns;
  final int maxRepeatedCalls;

  const AgentRuntime({
    required this.model,
    required this.toolHost,
    this.protocol = const G1hAgentProtocol(),
    this.mode = .strict,
    this.maxTurns = 20,
    this.maxRepeatedCalls = 0,
  });

  Future<AgentRunResult> run({
    required String system,
    required String user,
    AgentCancelled? isCancelled,
    AgentEventCallback? onEvent,
  }) async {
    final events = <AgentEvent>[];
    final repeatedCalls = <String, int>{};
    String prompt = protocol.buildPrompt(
      system: system,
      user: user,
      tools: toolHost.tools,
    );

    for (int turn = 1; turn <= maxTurns; turn++) {
      if (isCancelled?.call() ?? false) {
        return AgentRunResult(
          status: .cancelled,
          finalAnswer: "",
          prompt: prompt,
          events: List<AgentEvent>.unmodifiable(events),
          turns: turn - 1,
        );
      }

      AgentGeneration generation;
      try {
        generation = await model.generate(prompt, mode: mode);
      } on AgentInfrastructureException catch (error) {
        final event = AgentEvent(
          kind: .error,
          turn: turn,
          title: "Infrastructure error",
          content: error.toString(),
        );
        await _record(events: events, event: event, onEvent: onEvent);
        return AgentRunResult(
          status: .infrastructureFailed,
          finalAnswer: "",
          prompt: prompt,
          events: List<AgentEvent>.unmodifiable(events),
          turns: turn,
          validForModelScore: false,
        );
      } catch (error) {
        if (isCancelled?.call() ?? false) {
          return AgentRunResult(
            status: .cancelled,
            finalAnswer: "",
            prompt: prompt,
            events: List<AgentEvent>.unmodifiable(events),
            turns: turn - 1,
          );
        }
        final event = AgentEvent(
          kind: .error,
          turn: turn,
          title: "Model error",
          content: error.toString(),
        );
        await _record(events: events, event: event, onEvent: onEvent);
        return AgentRunResult(
          status: .failed,
          finalAnswer: "",
          prompt: prompt,
          events: List<AgentEvent>.unmodifiable(events),
          turns: turn,
        );
      }
      String modelOutput = generation.output;

      await _record(
        events: events,
        event: AgentEvent(
          kind: .modelOutput,
          turn: turn,
          title: "Model output",
          content: modelOutput,
          rawContent: generation.rawOutput,
          interventions: generation.interventions,
          durationMs: generation.durationMs,
        ),
        onEvent: onEvent,
      );

      G1hAgentOutput parsed = protocol.parse(
        modelOutput,
        callOrdinal: events.where((event) => event.kind == .toolCall).length + 1,
        mode: mode,
      );

      if (parsed.kind == .incompleteToolCall) {
        final continuationPrompt = prompt + modelOutput;
        AgentGeneration? continuationGeneration;
        try {
          continuationGeneration = await model.generate(
            continuationPrompt,
            mode: mode,
          );
        } on AgentInfrastructureException catch (error) {
          final event = AgentEvent(
            kind: .error,
            turn: turn,
            title: "Infrastructure error",
            content: error.toString(),
          );
          await _record(events: events, event: event, onEvent: onEvent);
          return AgentRunResult(
            status: .infrastructureFailed,
            finalAnswer: "",
            prompt: continuationPrompt,
            events: List<AgentEvent>.unmodifiable(events),
            turns: turn,
            validForModelScore: false,
          );
        } catch (error) {
          if (isCancelled?.call() ?? false) {
            return AgentRunResult(
              status: .cancelled,
              finalAnswer: "",
              prompt: continuationPrompt,
              events: List<AgentEvent>.unmodifiable(events),
              turns: turn - 1,
            );
          }
          final event = AgentEvent(
            kind: .error,
            turn: turn,
            title: "Tool call continuation error",
            content: error.toString(),
          );
          await _record(events: events, event: event, onEvent: onEvent);
        }
        final continuation = continuationGeneration?.output ?? "";
        if (continuation.isNotEmpty) {
          final rawContinuation = continuationGeneration?.rawOutput ?? continuation;
          final continuationInterventions = <AgentInterventionKind>[
            .transportContinuation,
            ...?continuationGeneration?.interventions,
          ];
          await _record(
            events: events,
            event: AgentEvent(
              kind: .modelOutput,
              turn: turn,
              title: "Tool call continuation",
              content: continuation,
              rawContent: rawContinuation,
              interventions: continuationInterventions,
              durationMs: continuationGeneration?.durationMs ?? 0,
            ),
            onEvent: onEvent,
          );
        }
        modelOutput += continuation;
        parsed = protocol.parse(
          modelOutput,
          callOrdinal: events.where((event) => event.kind == .toolCall).length + 1,
          mode: mode,
        );
      }

      if (parsed.kind == .incompleteToolCall) {
        final errorResult = AgentToolResult(
          callId: "incomplete_$turn",
          toolName: "",
          content: "ERROR: Tool call ended before its JSON object was complete. Retry with one shorter valid tool call.",
          isError: true,
        );
        await _record(
          events: events,
          event: AgentEvent(
            kind: .error,
            turn: turn,
            title: "Incomplete tool call",
            content: errorResult.content,
            toolResult: errorResult,
          ),
          onEvent: onEvent,
        );
        prompt = protocol.appendToolExchange(
          prompt: prompt,
          modelOutput: modelOutput,
          result: errorResult,
        );
        continue;
      }

      if (parsed.kind == .finalAnswer) {
        final answer = parsed.finalAnswer;
        final event = AgentEvent(
          kind: .finalAnswer,
          turn: turn,
          title: "Final answer",
          content: answer,
        );
        await _record(events: events, event: event, onEvent: onEvent);
        return AgentRunResult(
          status: .completed,
          finalAnswer: answer,
          prompt: prompt + modelOutput,
          events: List<AgentEvent>.unmodifiable(events),
          turns: turn,
        );
      }

      if (parsed.kind == .malformedToolCall) {
        final errorResult = AgentToolResult(
          callId: "malformed_$turn",
          toolName: "",
          content: "ERROR: ${parsed.error}",
          isError: true,
        );
        await _record(
          events: events,
          event: AgentEvent(
            kind: .error,
            turn: turn,
            title: "Malformed tool call",
            content: parsed.error,
            toolResult: errorResult,
          ),
          onEvent: onEvent,
        );
        prompt = protocol.appendToolExchange(
          prompt: prompt,
          modelOutput: modelOutput,
          result: errorResult,
        );
        continue;
      }

      final parsedCall = parsed.toolCall;
      if (parsedCall == null) {
        final event = AgentEvent(
          kind: .error,
          turn: turn,
          title: "Protocol error",
          content: "Tool call parser returned no call",
        );
        await _record(events: events, event: event, onEvent: onEvent);
        return AgentRunResult(
          status: .failed,
          finalAnswer: "",
          prompt: prompt + modelOutput,
          events: List<AgentEvent>.unmodifiable(events),
          turns: turn,
        );
      }
      final call = _normalizeToolCall(parsedCall);

      if (maxRepeatedCalls > 0) {
        final callFingerprint = "${call.name}:${jsonEncode(call.arguments)}";
        final repeatCount = (repeatedCalls[callFingerprint] ?? 0) + 1;
        repeatedCalls[callFingerprint] = repeatCount;
        if (repeatCount > maxRepeatedCalls) {
          final content = "Repeated identical tool call more than $maxRepeatedCalls times";
          final event = AgentEvent(
            kind: .error,
            turn: turn,
            title: "Repeated tool call",
            content: content,
            toolCall: call,
          );
          await _record(events: events, event: event, onEvent: onEvent);
          return AgentRunResult(
            status: .failed,
            finalAnswer: "",
            prompt: prompt + modelOutput,
            events: List<AgentEvent>.unmodifiable(events),
            turns: turn,
          );
        }
      }

      await _record(
        events: events,
        event: AgentEvent(
          kind: .toolCall,
          turn: turn,
          title: "Tool call: ${call.name}",
          content: call.raw,
          toolCall: call,
        ),
        onEvent: onEvent,
      );

      final rawResult = await toolHost.call(call);
      final result = _addSchemaGuidance(
        call: call,
        result: rawResult,
      );
      final resultInterventions = rawResult.content == result.content
          ? const <AgentInterventionKind>[]
          : const <AgentInterventionKind>[.schemaGuidance];
      await _record(
        events: events,
        event: AgentEvent(
          kind: .toolResult,
          turn: turn,
          title: "Tool result: ${call.name}",
          content: result.content,
          interventions: resultInterventions,
          toolCall: call,
          toolResult: result,
        ),
        onEvent: onEvent,
      );

      if (call.name == "submit" && !result.isError) {
        final answer = call.arguments["answer"]?.toString() ?? "";
        return AgentRunResult(
          status: .submitted,
          finalAnswer: answer,
          prompt: prompt + modelOutput,
          events: List<AgentEvent>.unmodifiable(events),
          turns: turn,
        );
      }

      prompt = protocol.appendToolExchange(
        prompt: prompt,
        modelOutput: modelOutput,
        result: result,
      );
    }

    final event = AgentEvent(
      kind: .error,
      turn: maxTurns,
      title: "Maximum turns reached",
      content: "The agent reached the maximum of $maxTurns turns",
    );
    await _record(events: events, event: event, onEvent: onEvent);
    return AgentRunResult(
      status: .maxTurnsReached,
      finalAnswer: "",
      prompt: prompt,
      events: List<AgentEvent>.unmodifiable(events),
      turns: maxTurns,
    );
  }

  Future<void> _record({
    required List<AgentEvent> events,
    required AgentEvent event,
    required AgentEventCallback? onEvent,
  }) async {
    events.add(event);
    if (onEvent == null) return;
    await onEvent(event);
  }

  AgentToolCall _normalizeToolCall(AgentToolCall call) {
    if (mode == .strict) return call;
    final definition = _toolDefinition(call.name);
    if (definition == null) return call;

    final properties = definition.parameters["properties"];
    if (properties is! Map) return call;
    final normalized = <String, Object?>{};
    final interventions = <AgentInterventionKind>[
      ...call.interventions,
    ];
    bool changed = false;
    for (final entry in call.arguments.entries) {
      final property = properties[entry.key];
      if (property is! Map) {
        changed = true;
        interventions.add(.argumentDropped);
        continue;
      }
      final type = property["type"];
      final value = entry.value;
      if (type == "integer" && value is String) {
        final parsed = int.tryParse(value.trim());
        final normalizedValue = parsed ?? value;
        normalized[entry.key] = normalizedValue;
        changed = changed || normalizedValue != value;
        if (normalizedValue != value) {
          interventions.add(.argumentTypeCoercion);
        }
        continue;
      }
      if (type == "string" && (value is num || value is bool)) {
        normalized[entry.key] = value.toString();
        changed = true;
        interventions.add(.argumentTypeCoercion);
        continue;
      }
      normalized[entry.key] = value;
    }
    if (!changed) return call;
    return AgentToolCall(
      id: call.id,
      name: call.name,
      arguments: normalized,
      raw: jsonEncode(<String, Object?>{
        "name": call.name,
        "arguments": normalized,
      }),
      interventions: List<AgentInterventionKind>.unmodifiable(interventions),
    );
  }

  AgentToolResult _addSchemaGuidance({
    required AgentToolCall call,
    required AgentToolResult result,
  }) {
    if (!result.isError) return result;
    final definition = _toolDefinition(call.name);
    if (definition == null) return result;
    final guidedContent = StringBuffer(result.content)
      ..write("\nCorrect argument schema: ")
      ..write(jsonEncode(definition.parameters))
      ..write("\nRetry with all required arguments and do not repeat the unchanged invalid call.");
    return AgentToolResult(
      callId: result.callId,
      toolName: result.toolName,
      content: guidedContent.toString(),
      isError: true,
    );
  }

  AgentToolDefinition? _toolDefinition(String name) {
    for (final candidate in toolHost.tools) {
      if (candidate.name == name) return candidate;
    }
    return null;
  }
}
