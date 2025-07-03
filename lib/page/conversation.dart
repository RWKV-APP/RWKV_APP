import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zone/widgets/chat/conversation_list.dart';

class PageConversation extends ConsumerWidget {
  const PageConversation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
      ),
      body: ConversationList(),
    );
  }
}
