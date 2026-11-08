import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:zone/model/web_search_provider.dart';

class WebSearchProviderIcon extends StatelessWidget {
  final WebSearchProvider provider;
  final double size;
  final Color? color;
  final bool useButtonForeground;

  const WebSearchProviderIcon({super.key, required this.provider, this.size = 24, this.color, this.useButtonForeground = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = switch (provider) {
      .deepseek => 'assets/img/chat/search_deepseek.png',
      .zhihuGlobal || .zhihuSite => 'assets/img/chat/search_zhihu.png',
      .anysearch => 'assets/img/chat/search_anysearch.png',
      .browser => null,
      _ => 'assets/img/chat/search_${provider.name}.png',
    };
    if (asset == null) return Icon(Symbols.travel_explore, size: size, color: color);

    // Official favicons are bundled so opening the chooser never requests them online.
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: .contain,
      color: provider == .anysearch || (provider == .deepseek && useButtonForeground) ? color ?? theme.colorScheme.onSurface : null,
      excludeFromSemantics: true,
    );
  }
}
