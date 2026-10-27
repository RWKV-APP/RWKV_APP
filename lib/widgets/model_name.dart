// Flutter imports:
import 'package:flutter/material.dart';

class ModelName extends StatelessWidget {
  final String name;
  final TextStyle? style;

  const ModelName(this.name, {super.key, this.style});

  static final _generation = RegExp(r'(?<![a-z0-9])G1[a-z]+(?![a-z0-9])', caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = _generation.allMatches(name).toList();
    final emphasis = TextStyle(
      fontWeight: .w900,
      color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
    );

    return Text.rich(
      TextSpan(
        children: [
          for (final (index, match) in matches.indexed) ...[
            TextSpan(text: name.substring(index == 0 ? 0 : matches[index - 1].end, match.start)),
            TextSpan(text: match[0], style: emphasis),
          ],
          TextSpan(text: name.substring(matches.isEmpty ? 0 : matches.last.end)),
        ],
      ),
      style: style ?? const TextStyle(fontWeight: .w600),
    );
  }
}
