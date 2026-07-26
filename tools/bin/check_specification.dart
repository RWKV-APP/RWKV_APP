import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:tools/specification/specification_checker.dart';

void main(List<String> arguments) {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    _printHelp();
    return;
  }
  final parsed = _parseArguments(arguments);
  if (parsed.error != null) {
    stderr.writeln(parsed.error);
    _printHelp(toStderr: true);
    exitCode = 2;
    return;
  }
  final explicitRoot = parsed.rootPath;
  final root = explicitRoot == null
      ? findSpecificationRepositoryRoot()
      : findSpecificationRepositoryRoot(Directory(path.absolute(explicitRoot)));
  if (root == null) {
    final start = explicitRoot == null ? Directory.current.path : path.absolute(explicitRoot);
    stderr.writeln(
      'Could not find a repository root containing AGENTS.md, pubspec.yaml, lib/, and tools/ from $start',
    );
    exitCode = 2;
    return;
  }
  if (explicitRoot != null && path.normalize(root.path) != path.normalize(path.absolute(explicitRoot))) {
    stderr.writeln('--root must point to the repository root itself: ${path.absolute(explicitRoot)}');
    exitCode = 2;
    return;
  }
  final result = SpecificationChecker(root).check();
  if (result.isValid) {
    stdout.writeln(
      'Specification $specificationProcessVersion check passed (${root.path})',
    );
    return;
  }
  stderr.writeln(
    'Specification $specificationProcessVersion check failed with ${result.issues.length} issue(s):',
  );
  for (final issue in result.issues) {
    stderr.writeln('- ${issue.formatted}');
  }
  exitCode = 1;
}

final class _ParsedArguments {
  final String? rootPath;
  final String? error;

  const _ParsedArguments({
    required this.rootPath,
    required this.error,
  });
}

_ParsedArguments _parseArguments(List<String> arguments) {
  String? rootPath;
  for (int index = 0; index < arguments.length; index += 1) {
    final argument = arguments[index];
    if (argument == '--root') {
      if (rootPath != null) {
        return const _ParsedArguments(
          rootPath: null,
          error: '--root may only be provided once',
        );
      }
      if (index + 1 >= arguments.length || arguments[index + 1].startsWith('-')) {
        return const _ParsedArguments(
          rootPath: null,
          error: '--root requires a path',
        );
      }
      rootPath = arguments[index + 1];
      index += 1;
      continue;
    }
    if (argument.startsWith('--root=')) {
      if (rootPath != null) {
        return const _ParsedArguments(
          rootPath: null,
          error: '--root may only be provided once',
        );
      }
      rootPath = argument.substring('--root='.length);
      if (rootPath.isNotEmpty) {
        continue;
      }
      return const _ParsedArguments(
        rootPath: null,
        error: '--root requires a path',
      );
    }
    return _ParsedArguments(
      rootPath: null,
      error: 'Unknown argument: $argument',
    );
  }
  return _ParsedArguments(
    rootPath: rootPath,
    error: null,
  );
}

void _printHelp({bool toStderr = false}) {
  const lines = [
    'Usage: dart run tools/bin/check_specification.dart [--root PATH]',
    '',
    'Exit codes:',
    '  0  Specification is valid',
    '  1  Specification validation failed',
    '  2  Invalid arguments or repository root discovery failed',
  ];
  for (final line in lines) {
    if (toStderr) {
      stderr.writeln(line);
      continue;
    }
    stdout.writeln(line);
  }
}
