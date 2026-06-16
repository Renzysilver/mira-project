import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/chat_provider.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/mira_avatar.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    // Only show character on wide screens (mobile gets full-width chat)
    final showCharacter = _characterVisible && screenWidth > 700;

    return MainShell(
      currentIndex: 0,
      child: Stack(
        children: [
          // ── Layer 1: Base background gradient ───────────────────────────
          Positioned.fill(
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
            ),
          ),

          // ── Layer 2: Character on the RIGHT, fills its column ───────────
          // Use Align + FractionallySizedBox so the Rive widget has a
          // definite size to render into. BoxFit.cover inside MiraAvatarWidget
          // would crop, so we let it contain but constrain the box itself.
          if (showCharacter)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: screenWidth * 0.42,
                child: IgnorePointer(
                  child: const MiraAvatarWidget(),
                ),
              ),
            ),

          // ── Layer 3: Soft left-biased gradient overlay ──────────────────
          // Lighter than before — just enough to keep chat readable on
          // the left while the character shows through on the right.
          if (showCharacter)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.midnightBlue.withOpacity(0.92),
                        AppTheme.midnightBlue.withOpacity(0.55),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 0.85],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),

          // ── Layer 4: Chat UI (full width) ───────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Floating header — NO border, just content on a soft blur
                _ChatHeader(
                  personaName: personaState.persona.name,
                  isTyping: chatState.isTyping,
                  characterVisible: showCharacter,
                  onToggleCharacter: () => setState(
                      () => _characterVisible = !_characterVisible),
                ),

                // Chat messages — full width
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                        top: 8, bottom: 8, left: 16, right: 16),
                    itemCount: chatState.messages.length +
                        (chatState.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length &&
                          chatState.isTyping) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 8, left: 8),
                          child: TypingIndicator(),
                        );
                      }
                      final message = chatState.messages[index];
                      return ChatBubble(
                        message: message.content,
                        isUser: message.role == 'user',
                        time: DateFormat('h:mm a')
                            .format(message.timestamp),
                      );
                    },
                  ),
                ),

                if (chatState.streamingContent.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
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
                        style:
                            const TextStyle(color: AppTheme.errorRed))),

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
                icon:
                    const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Beautiful floating header (no border) ───────────────────────────────

class _ChatHeader extends StatelessWidget {
  final String personaName;
  final bool isTyping;
  final bool characterVisible;
  final VoidCallback onToggleCharacter;

  const _ChatHeader({
    required this.personaName,
    required this.isTyping,
    required this.characterVisible,
    required this.onToggleCharacter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Avatar circle with online dot
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.pinkGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.magentaAccent.withOpacity(0.35),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 20),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.successGreen,
                    border: Border.all(
                        color: AppTheme.midnightBlue, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(personaName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.moonWhite,
                      letterSpacing: 1,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (isTyping) ...[
                      const _TypingDots(),
                      const SizedBox(width: 6),
                      Text('typing...',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                AppTheme.moonRose.withOpacity(0.9),
                            fontStyle: FontStyle.italic,
                          )),
                    ] else ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('online',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary
                                .withOpacity(0.8),
                            letterSpacing: 0.5,
                          )),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Toggle character visibility (only on wide screens)
          if (MediaQuery.of(context).size.width > 700)
            GestureDetector(
              onTap: onToggleCharacter,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  characterVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Three pulsing dots for the 'typing...' indicator.
class _TypingDots extends StatelessWidget {
  const _TypingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.moonRose.withOpacity(0.6 + (i * 0.15)),
          ),
        ),
      ),
    );
  }
}
