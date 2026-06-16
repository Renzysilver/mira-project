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
  bool _characterVisible = true;

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
      child: Stack(
        children: [
          // ── Layer 1: Full-screen Rive character background ──────────────
          // The character fills the entire screen behind everything else.
          if (_characterVisible)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0A0518),
                        Color(0xFF1A0B2E),
                        Color(0xFF0D0820),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: MiraAvatarWidget(),
                ),
              ),
            ),

          // ── Layer 2: Dark gradient overlay for readability ──────────────
          // Left-biased gradient so chat bubbles on the left stay readable
          // while the character remains visible on the right.
          if (_characterVisible)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.midnightBlue.withOpacity(0.92),
                        AppTheme.midnightBlue.withOpacity(0.6),
                        AppTheme.midnightBlue.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),

          // ── Layer 3: Chat UI on top ─────────────────────────────────────
          SafeArea(
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
                      const SizedBox(width: 8),
                      Text('online',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary.withOpacity(0.7),
                          letterSpacing: 1)),
                      const Spacer(),
                      // Toggle character visibility
                      GestureDetector(
                        onTap: () =>
                            setState(() => _characterVisible = !_characterVisible),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.glassWhite,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Icon(
                            _characterVisible
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

                // Chat messages — left-aligned panel
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      // Constrain chat to ~55% width on wide screens so the
                      // character remains visible on the right. On narrow
                      // screens (mobile), it fills the width.
                      constraints: const BoxConstraints(maxWidth: 560),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                          top: 8, bottom: 8, left: 8, right: 8),
                        itemCount: chatState.messages.length +
                            (chatState.isTyping ? 1 : 0),
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
                  ),
                ),

                // Streaming content
                if (chatState.streamingContent.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ChatBubble(
                          message: chatState.streamingContent,
                          isUser: false,
                          time: DateFormat('h:mm a').format(DateTime.now()),
                        ),
                      ),
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
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                        hintStyle:
                            TextStyle(color: AppTheme.mistGray, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
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
        ),
      ),
    );
  }
}
