import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/page/panel/settings.dart';
import 'package:zone/widgets/app_scaffold.dart';

class PageSettings extends ConsumerWidget {
  const PageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppGradientBackground(child: Settings(isInDrawerMenu: true));
  }
}
