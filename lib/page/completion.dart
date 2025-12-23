import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:halo_state/halo_state.dart';
import 'package:zone/model/decode_param_type.dart';
import 'package:zone/store/p.dart' show P, $RWKV;
import 'package:zone/widgets/chat/completion_mode.dart';
import 'package:zone/widgets/model_select_button.dart';

import 'package:zone/gen/l10n.dart' show S;

class CompletionPage extends ConsumerWidget {
  static final _showTips = qs(true);

  const CompletionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTips = ref.watch(_showTips);
    final mode = ref.watch(P.rwkv.decodeParamType);
    final modelLoaded = ref.watch(P.rwkv.loaded);

    final showBanner = showTips && mode != DecodeParamType.creative && modelLoaded;

    return Scaffold(
      appBar: AppBar(
        bottom: !showBanner
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(38),
                child: _TipsBanner(() {
                  _showTips.q = false;
                }),
              ),
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

class _TipsBanner extends StatelessWidget {
  final VoidCallback onClose;

  const _TipsBanner(this.onClose);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF9D3B1) : const Color(0xFFDE851B);
    return Container(
      color: isDark ? const Color(0xFFAB825C) : const Color(0xFFF8DFC2),
      height: 38,
      padding: const .only(left: 8),
      width: double.infinity,
      alignment: .centerLeft,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: textColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              S.current.switch_to_creative_mode_for_better_exp,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, size: 16, color: textColor),
          ),
        ],
      ),
    );
  }
}
