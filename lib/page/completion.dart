import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/widgets/chat/completion_mode.dart';
import 'package:zone/widgets/model_select_button.dart';

import '../gen/l10n.dart' show S;

class CompletionPage extends ConsumerWidget {
  const CompletionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(S.current.completion_mode, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            ModelSelectButton(),
          ],
        ),
        centerTitle: true,
      ),
      body: Completion(),
    );
  }
}
