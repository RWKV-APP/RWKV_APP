part of 'p.dart';

class _Conversation {
  final conversations = qs<List<Conversation>>([]);
  final current = qs<Conversation?>(null);

  final sorted = qp<List<Conversation>>((ref) {
    final conversations = ref.watch(P.conversation.conversations);
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return conversations;
  });
}

/// Private methods
extension _$Conversation on _Conversation {
  FV _init() async {
    if (!Config.enableConversation) return;
    qq;
    await load();
  }

  String _getConversationPath(Conversation conversation) {
    if (!Config.enableConversation) return "";
    final dirPath = P.app.documentsDir.q?.path;
    if (dirPath == null) return "";
    return "$dirPath/conversation_${conversation.id}.json";
  }
}

/// Public methods
extension $Conversation on _Conversation {
  FV load() async {
    if (!Config.enableConversation) return;
    final dir = P.app.documentsDir.q;
    if (dir == null) {
      qqe("Failed to load conversations: No documents directory found");
      return;
    }

    final files = await dir.list().toList();
    final conversationFiles = files.where((file) => file.path.contains('conversation_')).toList();

    final loadedConversations = <Conversation>[];
    for (final file in conversationFiles) {
      try {
        final content = await File(file.path).readAsString();
        final json = jsonDecode(content);
        final conversation = Conversation.fromJson(json);
        if (kDebugMode) {
          for (final msg in conversation.messages) {
            qqq(msg.content.length);
          }
        }
        loadedConversations.add(conversation);
      } catch (e) {
        qqe("Failed to load conversation");
        qqe(e);
      }
    }

    // Sort conversations by id in descending order (newest first)
    loadedConversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    conversations.q = loadedConversations;
  }

  FV delete(Conversation conversation) async {
    if (!Config.enableConversation) return;
    // Remove from memory
    conversations.q = conversations.q.where((c) => c.id != conversation.id).toList();
    if (current.q?.id == conversation.id) {
      current.q = null;
    }

    // Delete file
    final file = File(_getConversationPath(conversation));
    if (await file.exists()) {
      await file.delete();
    }
  }

  FV addMessage(Message message, [Conversation? conversation]) async {
    if (!Config.enableConversation) return;
    final now = HF.debugShorterMS;
    if (conversation == null) {
      // Create new conversation
      final newId = conversations.q.isEmpty ? 1 : (conversations.q.firstOrNull?.id ?? 0) + 1;
      conversation = Conversation(
        id: newId,
        name: message.content.substring(0, message.content.length.clamp(0, 30)) + (message.content.length > 30 ? "..." : ""),
        messages: [message],
        createdAt: now,
        updatedAt: now,
      );
    } else {
      // Add message to existing conversation
      conversation = Conversation(
        id: conversation.id,
        name: conversation.name,
        messages: [...conversation.messages, message],
        createdAt: conversation.createdAt,
        updatedAt: now,
      );
    }

    // Update memory
    if (conversations.q.any((c) => c.id == conversation!.id)) {
      final updatedConversations = conversations.q.map((c) {
        if (c.id == conversation!.id) {
          return conversation;
        }
        return c;
      }).toList();
      conversations.q = updatedConversations;
    } else {
      conversations.q = [conversation, ...conversations.q];
    }
    current.q = conversation;

    // Save to file
    final file = File(_getConversationPath(conversation));
    if (!await file.exists()) await file.create(recursive: true);
    await file.writeAsString(jsonEncode(conversation.toJson()));
  }

  FV removeMessage(Message message, {required Conversation conversation}) async {}

  FV updateMessage(Message message, {required Conversation conversation}) async {}

  FV onTapInList(Conversation conversation) async {
    if (!Config.enableConversation) return;
    current.q = conversation;
    Pager.toggle();
  }

  FV updateMessages(List<Message> messages) async {
    if (!Config.enableConversation) return;
    final conversation = current.q;
    if (conversation == null) return;
    final updatedConversation = Conversation(
      id: conversation.id,
      name: conversation.name,
      messages: messages,
      createdAt: conversation.createdAt,
      updatedAt: HF.debugShorterMS,
    );

    conversations.q = [
      ...conversations.q.where((c) => c.id != conversation.id),
      updatedConversation,
    ];

    // Save to file
    final file = File(_getConversationPath(conversation));
    if (!await file.exists()) await file.create(recursive: true);
    await file.writeAsString(jsonEncode(updatedConversation.toJson()));
  }
}
