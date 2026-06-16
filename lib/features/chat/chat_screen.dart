import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/chat_provider.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/mira_avatar.dart';
import '../../widgets/dreamy_background.dart';
import '../../widgets/shell/main_shell.dart';
import '../../app/theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showAvatar = true;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final personaState = ref.watch(personaProvider);

    return MainShell(
      currentIndex: 0,
      child: DreamyBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    // Online dot + name
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(personaState.persona.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.moonWhite,
                        letterSpacing: 1.5,
                      )),
                    const Spacer(),
                    // Toggle avatar visibility (collapse to focus on chat)
                    GestureDetector(
                      onTap: () => setState(() => _showAvatar = !_showAvatar),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.glassWhite,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Icon(
                          _showAvatar
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Chat + avatar area
              Expanded(
                child: Row(
                  children: [
                    // Chat column
                    Expanded(
                      flex: _showAvatar ? 3 : 1,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                          top: 8, bottom: 8, left: 12, right: 12),
                        itemCount:
                            chatState.messages.length + (chatState.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatState.messages.length &&
                              chatState.isTyping) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: TypingIndicator());
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
                    // Avatar column (Rive character)
                    if (_showAvatar) ...[
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 60),
                              const Expanded(
                                child: MiraAvatarWidget(),
                              ),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Streaming content (assistant message being received)
              if (chatState.streamingContent.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ChatBubble(
                    message: chatState.streamingContent,
                    isUser: false,
                    time: DateFormat('h:mm a').format(DateTime.now()),
                  ),
                ),

              if (chatState.error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(chatState.error!,
                    style: const TextStyle(color: AppTheme.errorRed))),

              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.glassWhite,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppTheme.mistGray, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.pinkGradient,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66E83E8C),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
