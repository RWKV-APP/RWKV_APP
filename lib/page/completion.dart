import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/func/check_model_selection.dart';
import 'package:zone/widgets/arguments_panel.dart';
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
        actions: [
          IconButton(
            onPressed: () async {
              if (!checkModelSelection()) return;
              await ArgumentsPanel.show(context);
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Completion(),
    );
  }
}
