import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/page/panel/settings2.dart';

class PageSettings extends ConsumerWidget {
  const PageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Settings2(isInDrawerMenu: true);
  }
}
