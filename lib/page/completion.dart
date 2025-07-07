import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/store/p.dart';
import 'package:zone/widgets/chat/completion_mode.dart';
import 'package:zone/widgets/model_selector.dart';

import '../gen/l10n.dart' show S;

class CompletionPage extends ConsumerWidget {
  const CompletionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentModel = ref.watch(P.rwkv.currentModel);
    final modelDisplay = currentModel?.name ?? S.current.click_to_select_model;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(S.current.completion_mode, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Ink(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                splashColor: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  ModelSelector.show();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(modelDisplay, style: TextStyle(color: primary, fontSize: 12, height: 1)),
                      Icon(Icons.arrow_drop_down, color: primary, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Completion(),
    );
  }
}
