// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:zone/widgets/chat_layout_metrics.dart';

class ChatHistoryWidthLimit extends StatelessWidget {
  final Widget child;

  const ChatHistoryWidthLimit({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme;

    return Align(
      alignment: .topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: chatNonBatchMessageMaxWidth),
        child: SizedBox(
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}
