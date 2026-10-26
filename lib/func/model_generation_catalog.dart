typedef CatalogGeneration = ({
  String family,
  double size,
  String backend,
  int revision,
});

List<String> _strings(dynamic value) =>
    value is List ? value.map((e) => e.toString()).toList() : [];

CatalogGeneration? catalogModelGeneration(Map<String, dynamic> row) {
  final name = (row['name'] ?? '').toString().toLowerCase();
  final source = '$name ${(row['url'] ?? '').toString().toLowerCase()}';
  final backends = _strings(row['backends']);
  if (backends.length != 1) return null;
  final rawSize = row['modelSize'];
  final size = rawSize is num
      ? rawSize.toDouble()
      : double.tryParse(
          RegExp(r'(\d+(?:\.\d+)?)\s*b\b').firstMatch(source)?.group(1) ?? '',
        );
  if (size == null) return null;
  final tags = _strings(row['tags']);
  if (source.contains('rwkv-vl')) {
    final date = RegExp(r'\b(\d{8}|\d{6})\b').firstMatch(name)?.group(1);
    if (date == null) return null;
    final component =
        tags.contains('encoder') || name.contains('vision encoder')
        ? 'encoder'
        : tags.contains('adapter') || name.contains('vision adapter')
        ? 'adapter'
        : 'core';
    return (
      family: 'rwkv-vl:$component',
      size: size,
      backend: backends.single.toLowerCase(),
      revision: int.parse(date.length == 6 ? '20$date' : date),
    );
  }
  final match = RegExp(r'\b(rwkv\d+[a-z]?)[-_ ]+g(\d+)([a-z]*)\b')
      .firstMatch(source);
  if (match == null) return null;
  int suffix = 0;
  for (final letter in match.group(3)!.codeUnits) {
    suffix = suffix * 26 + letter - 96;
  }
  final variant = tags.contains('translate') || name.contains('translate')
      ? 'translate'
      : name.contains('neko')
      ? 'neko'
      : name.contains('roleplay')
      ? 'roleplay'
      : 'base';
  return (
    family: '${match.group(1)}:$variant',
    size: size,
    backend: backends.single.toLowerCase(),
    revision: int.parse(match.group(2)!) * 1000000 + suffix,
  );
}

List<T> latestModelGenerations<T>(
  Iterable<T> values,
  Map<String, dynamic> Function(T) metadata,
) {
  final candidates = values
      .map(
        (value) =>
            (value: value, generation: catalogModelGeneration(metadata(value))),
      )
      .toList();
  final newest = <(String, double, String), int>{};
  for (final candidate in candidates) {
    final generation = candidate.generation;
    if (generation == null) continue;
    final key = (generation.family, generation.size, generation.backend);
    if ((newest[key] ?? -1) < generation.revision)
      newest[key] = generation.revision;
  }
  return [
    for (final candidate in candidates)
      if (candidate.generation == null ||
          newest[(
                candidate.generation!.family,
                candidate.generation!.size,
                candidate.generation!.backend,
              )] ==
              candidate.generation!.revision)
        candidate.value,
  ];
}

List<Map<String, dynamic>> normalizeModelGenerationConsumers(
  List<Map<String, dynamic>> rows,
) {
  final generations = rows.map(catalogModelGeneration).toList();
  final result = <Map<String, dynamic>>[];
  for (int index = 0; index < rows.length; index++) {
    final row = rows[index];
    final generation = generations[index];
    final platforms = _strings(row['platforms']);
    if (generation == null || platforms.isEmpty) {
      result.add(row);
      continue;
    }
    final newer = <Map<String, dynamic>>[];
    for (int other = 0; other < rows.length; other++) {
      final next = generations[other];
      if (next == null ||
          next.family != generation.family ||
          next.size != generation.size ||
          next.backend != generation.backend ||
          next.revision <= generation.revision)
        continue;
      if (rows[other]['isDebug'] == true && row['isDebug'] != true) continue;
      newer.add(rows[other]);
    }
    final oldSocs = _strings(row['socLimitations']);
    final oldExcludedBrands = _strings(row['unsupportedSocBrand']).toSet();
    final remaining = <String, ({List<String> platforms, List<String> socs})>{};
    for (final platform in platforms) {
      bool covered(String? soc) => newer.any((next) {
        if (!_strings(next['platforms']).contains(platform)) return false;
        if (!oldExcludedBrands.containsAll(
          _strings(next['unsupportedSocBrand']),
        ))
          return false;
        final nextSocs = _strings(next['socLimitations']);
        return nextSocs.isEmpty || soc != null && nextSocs.contains(soc);
      });
      if (oldSocs.isEmpty && covered(null)) continue;
      final socs = oldSocs.where((soc) => !covered(soc)).toList();
      if (oldSocs.isNotEmpty && socs.isEmpty) continue;
      final key = socs.join('\u0000');
      remaining
          .putIfAbsent(key, () => (platforms: [], socs: socs))
          .platforms
          .add(platform);
    }
    for (final group in remaining.values) {
      result.add({
        ...row,
        'platforms': group.platforms,
        if (oldSocs.isNotEmpty) 'socLimitations': group.socs,
      });
    }
  }
  final retained = result.map(catalogModelGeneration).toList();
  for (int index = 0; index < result.length; index++) {
    for (int other = index + 1; other < result.length; other++) {
      final left = retained[index];
      final right = retained[other];
      if (left == null ||
          right == null ||
          left.revision == right.revision ||
          (left.family, left.size, left.backend) !=
              (right.family, right.size, right.backend))
        continue;
      final older = left.revision < right.revision
          ? result[index]
          : result[other];
      final newer = left.revision > right.revision
          ? result[index]
          : result[other];
      if (newer['isDebug'] == true && older['isDebug'] != true) continue;
      final oldSocs = _strings(older['socLimitations']);
      final newSocs = _strings(newer['socLimitations']);
      final overlap =
          _strings(older['platforms'])
              .any(_strings(newer['platforms']).contains) &&
          (oldSocs.isEmpty || newSocs.isEmpty || oldSocs.any(newSocs.contains));
      if (overlap) {
        throw StateError(
          'Overlapping generations: ${older['name']} and ${newer['name']}. '
          'Declare the remaining platform/SoC consumers explicitly before publishing.',
        );
      }
    }
  }
  return result;
}

Map<String, dynamic> normalizeModelGenerationCatalog(
  Map<String, dynamic> config,
) => {
  for (final entry in config.entries)
    entry.key: entry.value is Map && entry.value['model_config'] is List
        ? {
            ...Map<String, dynamic>.from(entry.value as Map),
            'model_config': normalizeModelGenerationConsumers(
              (entry.value['model_config'] as List)
                  .map((row) => Map<String, dynamic>.from(row as Map))
                  .toList(),
            ),
          }
        : entry.value,
};
