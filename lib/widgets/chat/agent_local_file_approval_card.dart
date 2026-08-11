// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'package:zone/func/agent_local_file_host.dart';
import 'package:zone/gen/l10n.dart';
import 'package:zone/store/p.dart';

class AgentLocalFileApprovalCard extends ConsumerWidget {
  const AgentLocalFileApprovalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final approval = ref.watch(P.agent.localApproval);
    final workspacePath = ref.watch(P.agent.localWorkspacePath);
    final inputHeight = ref.watch(P.chat.inputHeight);
    final qb = ref.watch(P.app.qb);
    final s = S.of(context);

    if (approval == null) return const SizedBox.shrink();

    return Align(
      alignment: .bottomCenter,
      child: Padding(
        padding: .only(left: 16, right: 16, bottom: inputHeight + 12),
        child: Material(
          elevation: 8,
          borderRadius: .circular(12),
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surface,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              border: Border.all(color: qb.withValues(alpha: .24)),
              borderRadius: .circular(12),
            ),
            padding: .all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(
                    s.agent_local_approval_title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: .w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _agentLocalOperationLabel(s, approval.operation),
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text("${s.agent_local_path}: ${approval.relativePath}"),
                  if (workspacePath != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${s.agent_local_workspace_authorized}: $workspacePath",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: qb.withValues(alpha: .72),
                      ),
                    ),
                  ],
                  if (approval.content != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      s.agent_local_content,
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: .all(10),
                      decoration: BoxDecoration(
                        color: qb.withValues(alpha: .06),
                        borderRadius: .circular(8),
                      ),
                      child: SelectableText(approval.content!),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => P.agent.resolveLocalFileApproval(false),
                          child: Text(s.agent_local_reject),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => P.agent.resolveLocalFileApproval(true),
                          child: Text(s.agent_local_approve),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _agentLocalOperationLabel(
  S s,
  AgentLocalFileOperation operation,
) {
  return switch (operation) {
    .create => s.agent_local_operation_create,
    .update => s.agent_local_operation_update,
    .delete => s.agent_local_operation_delete,
  };
}
