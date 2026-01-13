import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/widgets/settings.dart';
import 'package:zone/widgets/gradient_background.dart';

class PageSettings extends ConsumerWidget {
  const PageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const GradientBackground(child: Settings(noBorderRadiusAndAppBar: true));
  }
}
