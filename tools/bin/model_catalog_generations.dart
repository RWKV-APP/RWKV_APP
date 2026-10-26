import 'dart:convert';
import 'dart:io';

import 'package:zone/func/model_generation_catalog.dart';

void main(List<String> arguments) {
  if (arguments.length != 2)
    throw ArgumentError('Expected input JSON and output JSON paths');
  final source =
      jsonDecode(File(arguments[0]).readAsStringSync()) as Map<String, dynamic>;
  final normalized = normalizeModelGenerationCatalog(source);
  File(arguments[1]).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(normalized)}\n',
  );
  stdout.writeln('Catalog generation policy applied: ${arguments[1]}');
}
