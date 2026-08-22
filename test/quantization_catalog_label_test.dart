import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled catalogs normalize generic aliases and preserve named formats', () {
    const canonicalNamedLabels = <String, String>{
      'q4_k_m': 'Q4_K_M',
      'nf4': 'NF4',
      'q6_k': 'Q6_K',
      'q8_0': 'Q8_0',
      'lut4': 'LUT4',
      'lut6': 'LUT6',
      'lut8': 'LUT8',
      'fp16': 'FP16',
      'bf16': 'BF16',
    };
    final genericAlias = RegExp(
      r'^(?:int(?:4|6|8)|w(?:4|6|8)a16|a16w(?:4|6|8)|(?:4|6|8)[ -]?bit)$',
      caseSensitive: false,
    );
    final catalogName = RegExp(r'^(latest|\d+)\.json$');
    final catalogFiles =
        Directory('remote').listSync().whereType<File>().where((file) => catalogName.hasMatch(file.uri.pathSegments.last)).toList()
          ..sort((left, right) => left.path.compareTo(right.path));
    final observedLabels = <String>{};

    expect(catalogFiles, isNotEmpty);

    for (final file in catalogFiles) {
      final root = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final sectionValue in root.values) {
        if (sectionValue is! Map<String, dynamic>) continue;
        final modelConfig = sectionValue['model_config'];
        if (modelConfig is! List<dynamic>) continue;

        for (final modelValue in modelConfig) {
          final model = modelValue as Map<String, dynamic>;
          final quantization = model['quantization'];
          if (quantization == null) continue;

          expect(
            quantization,
            isA<String>(),
            reason: '${file.path}: ${model['name']} has a non-string quantization label',
          );
          final label = quantization as String;
          observedLabels.add(label);
          expect(genericAlias.hasMatch(label), isFalse, reason: '${file.path}: ${model['name']} keeps generic alias $label');
          final canonicalNamedLabel = canonicalNamedLabels[label.toLowerCase()];
          if (canonicalNamedLabel != null) {
            expect(label, canonicalNamedLabel, reason: '${file.path}: ${model['name']} uses non-canonical spelling $label');
          }
        }
      }
    }

    expect(observedLabels, containsAll(<String>['W4', 'W6', 'W8', 'Q4_K_M', 'NF4', 'Q6_K', 'Q8_0', 'FP16']));
  });
}
