import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/store/p.dart' show P, $RWKV;
import 'package:zone/widgets/chat/completion_mode.dart';
import 'package:zone/widgets/model_select_button.dart';

import '../gen/l10n.dart' show S;

class CompletionPage extends ConsumerWidget {
  const CompletionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(P.preference.userType);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(S.current.completion_mode, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            const ModelSelectButton(),
          ],
        ),
        centerTitle: true,
      ),
      body: PopScope(
        child: const Completion(),
        onPopInvokedWithResult: (pop, _) {
          if (pop & P.rwkv.generating.q) {
            P.rwkv.stop();
          }
        },
      ),
    );
  }
}
