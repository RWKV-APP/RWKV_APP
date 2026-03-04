// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PageTest2 extends ConsumerWidget {
  const PageTest2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Input bar style config"),
      ),
      body: const Center(
        child: Text("Test 2"),
      ),
    );
  }
}
