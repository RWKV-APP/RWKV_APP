import 'package:rwkv_mobile_flutter/to_rwkv.dart' as to_rwkv;
import 'package:zone/func/web_search_report.dart';
import 'package:zone/model/web_search_trace.dart';

Map<String, dynamic>? webSearchModelRequest(to_rwkv.ToRWKV request) {
  final Map<String, dynamic> input;
  switch (request) {
    case to_rwkv.ChatAsync req:
      input = {
        'type': 'ChatAsync',
        'messages': List<String>.of(req.messages),
        'enableReasoning': req.enableReasoning,
        'forceReasoning': req.forceReasoning,
        'addGenerationPrompt': req.addGenerationPrompt,
        'forceLang': req.forceLang,
        'maxLength': req.maxLength,
        'modelID': req.modelID,
      };
    case to_rwkv.ChatBatchAsync req:
      input = {
        'type': 'ChatBatchAsync',
        'messages': [for (final messages in req.messages) List<String>.of(messages)],
        'enableReasoning': req.enableReasoning,
        'forceReasoning': req.forceReasoning,
        'addGenerationPrompt': req.addGenerationPrompt,
        'forceLang': req.forceLang,
        'forceLangs': req.forceLangs == null ? null : List<int>.of(req.forceLangs!),
        'maxLength': req.maxLength,
        'modelID': req.modelID,
        'batchSize': req.batchSize,
        if (req.slotConfigs != null)
          'slotConfigs': [
            for (final slot in req.slotConfigs!)
              {
                'messages': List<String>.of(slot.messages),
                'enableReasoning': slot.enableReasoning,
                'forceReasoning': slot.forceReasoning,
                'forceLang': slot.forceLang,
              },
          ],
      };
    default:
      return null;
  }
  return {...input, 'requestId': request.requestId};
}

WebSearchTrace appendWebSearchModelRequest({
  required WebSearchTrace trace,
  required Map<String, dynamic> request,
  Iterable<String> redactions = const [],
}) {
  final previous = trace.modelInput['requests'];
  final requests = <dynamic>[
    if (previous is List) ...previous,
    request,
  ];
  final input = <String, dynamic>{'requests': requests};
  return WebSearchTrace.fromJson(redactWebSearchPayload(trace.copyWith(modelInput: input).toJson(), redactions));
}

dynamic redactWebSearchPayload(dynamic value, Iterable<String> redactions) {
  if (value is String) return redactWebSearchReport(value, redactions);
  if (value is List) return [for (final item in value) redactWebSearchPayload(item, redactions)];
  if (value is Map) return {for (final entry in value.entries) entry.key.toString(): redactWebSearchPayload(entry.value, redactions)};
  return value;
}
