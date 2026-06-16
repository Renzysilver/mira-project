import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/chat_provider.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/animated_avatar.dart';
import '../../app/theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() { _messageController.dispose(); _scrollController.dispose(); super.dispose(); }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final persona = ref.read(personaProvider).persona;
    ref.read(chatProvider.notifier).sendMessage(text, persona);
    ref.read(personaProvider.notifier).incrementMessageCount();
    ref.read(personaProvider.notifier).updateAffection(1);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final personaState = ref.watch(personaProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/home'), icon: const Icon(Icons.arrow_back)),
        title: Row(
          children: [
            AnimatedAvatar(mood: personaState.persona.currentMood, size: 40),
            const SizedBox(width: 12),
            Text(personaState.persona.name),
          ],
        ),
        actions: [IconButton(onPressed: () => context.go('/persona'), icon: const Icon(Icons.person))],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chatState.messages.length && chatState.isTyping) {
                    return const TypingIndicator();
                  }
                  final message = chatState.messages[index];
                  return ChatBubble(
                    message: message.content,
                    isUser: message.role == 'user',
                    time: DateFormat('h:mm a').format(message.timestamp),
                  );
                },
              ),
            ),
            if (chatState.streamingContent.isNotEmpty)
              Align(alignment: Alignment.centerLeft, child: ChatBubble(message: chatState.streamingContent, isUser: false, time: DateFormat('h:mm a').format(DateTime.now()))),
            if (chatState.error != null)
              Padding(padding: const EdgeInsets.all(8.0), child: Text(chatState.error!, style: const TextStyle(color: AppTheme.errorRed))),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(hintText: 'Type a message...', filled: true, fillColor: AppTheme.surfaceDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryPurple,
              child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
            ),
          ],
        ),
      ),
    );
  }
}
