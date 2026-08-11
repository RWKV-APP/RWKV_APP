part of 'p.dart';

extension $ChatLocalAgent on _Chat {
  Future<bool> _trySendLocalFileAgent({
    required String raw,
    required MessageType type,
    required bool isRegenerate,
    required MsgNode parentNode,
    required String modelName,
  }) async {
    if (P.app.pageKey.q != .chat) return false;
    if (type != .text || isRegenerate) return false;
    if (!P.agent.localFileActionsSupported) return false;
    if (!isExplicitLocalFileActionRequest(raw)) return false;

    if (P.agent.running.q || P.agent.localRunning.q) {
      Alert.info(S.current.please_wait_for_the_model_to_finish_generating);
      return true;
    }

    final authorized = await P.agent.ensureLocalWorkspace();
    if (!authorized) return true;

    final userMessageId = _nextLocalAgentMessageId();
    final userMessage = Message(
      id: userMessageId,
      content: raw,
      isMine: true,
      paused: false,
    );
    await P.msg._syncMsg(userMessageId, userMessage);
    final userNode = parentNode.add(MsgNode(userMessageId));

    final assistantMessageId = _nextLocalAgentMessageId(
      after: userMessageId,
    );
    final assistantMessage = Message(
      id: assistantMessageId,
      content: S.current.agent_local_chat_running,
      isMine: false,
      paused: false,
      modelName: modelName,
      runningMode: "local-agent",
    );
    await P.msg._syncMsg(assistantMessageId, assistantMessage);
    userNode.add(MsgNode(assistantMessageId));
    P.msg.ids.q = P.msg.msgNode.q.latestMsgIdsWithoutRoot;
    P.conversation._syncNode();
    _scheduleScrollToBottom();

    final runResult = await P.agent.runLocalFileTask(
      raw,
      diagnosticSessionVisible: false,
    );
    final finalContent = _localAgentFinalContent(runResult);
    await P.msg._syncMsg(
      assistantMessageId,
      assistantMessage.copyWith(
        content: finalContent,
        paused: runResult?.status == .cancelled,
      ),
    );
    P.conversation._syncNode();
    _scheduleScrollToBottom();
    return true;
  }

  int _nextLocalAgentMessageId({int? after}) {
    int candidate = DateTime.now().millisecondsSinceEpoch;
    if (after != null && candidate <= after) {
      candidate = after + 1;
    }
    while (P.msg.pool.q.containsKey(candidate)) {
      candidate += 1;
    }
    return candidate;
  }

  String _localAgentFinalContent(AgentRunResult? runResult) {
    final answer = runResult?.finalAnswer.trim() ?? "";
    if (answer.isNotEmpty) return answer;
    if (runResult?.status == .cancelled) {
      return S.current.agent_local_chat_cancelled;
    }
    final taskError = P.agent.error.q?.trim() ?? "";
    if (taskError.isEmpty) return S.current.agent_local_chat_failed;
    return "${S.current.agent_local_chat_failed}\n\n$taskError";
  }
}
