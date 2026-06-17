import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/assistant/command_registry.dart';
import '../../core/assistant/reminder_service.dart';
import '../../providers/chat_provider.dart';
import '../../providers/persona_provider.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/mira_avatar.dart';
import '../../widgets/shell/main_shell.dart';
import '../../widgets/shell/companion_switcher.dart';
import '../../app/theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _characterVisible = true;
  StreamSubscription<Reminder>? _reminderSub;

  @override
  void initState() {
    super.initState();
    // Show fired reminders as system messages in chat.
    _reminderSub =
        ref.read(reminderServiceProvider).firedReminders.listen((reminder) {
      _showSystemMessage('⏰ Reminder: ${reminder.text}');
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _reminderSub?.cancel();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    // Slash-command handling — bypasses companion AI, returns a system
    // message instead.
    if (CommandRegistry.isCommand(text)) {
      final result = await CommandRegistry.execute(text);
      if (result.sideEffect != null) await result.sideEffect!();
      if (result.displayText != null) {
        _showSystemMessage(result.displayText!, isError: result.isError);
      }
      return;
    }

    final persona = ref.read(personaProvider).persona;
    ref.read(chatProvider.notifier).sendMessage(text, persona);
    ref.read(personaProvider.notifier).incrementMessageCount();
    ref.read(personaProvider.notifier).updateAffection(1);
    _scrollToBottom();
  }

  /// Display a system message as a SnackBar — temporary, doesn't pollute
  /// the chat history. (Could be promoted to a real system message bubble
  /// in a future iteration.)
  void _showSystemMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: TextStyle(
            color: isError ? AppTheme.errorRed : AppTheme.moonWhite,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        backgroundColor:
            isError ? Colors.red.withOpacity(0.9) : AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
      ),
    );
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

  /// Handle Enter key — send on Enter, newline on Shift+Enter.
  /// On web, this is wired via KeyboardEventHandler below.
  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _sendMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final personaState = ref.watch(personaProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final showCharacter = _characterVisible && screenWidth > 700;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: MainShell(
        currentIndex: 0,
        child: Stack(
          children: [
            // ── Layer 1: Base background gradient (aurora palette) ───────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4A1C8A),
                      Color(0xFF1A1A3A),
                      Color(0xFF2A2A5A),
                      Color(0xFF050510),
                    ],
                    stops: [0.0, 0.4, 0.7, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── Layer 2: Full-screen character background ────────────────
            if (showCharacter)
              Positioned.fill(
                child: IgnorePointer(
                  child: const MiraAvatarWidget(),
                ),
              ),

            // ── Layer 3: Left-biased gradient overlay ────────────────────
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

            // ── Layer 4: Chat UI ─────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  _ChatHeader(
                    isTyping: chatState.isTyping,
                    characterVisible: showCharacter,
                    onToggleCharacter: () => setState(
                        () => _characterVisible = !_characterVisible),
                  ),

                  // Chat messages — or empty state if no messages
                  Expanded(
                    child: chatState.messages.isEmpty &&
                            !chatState.isTyping &&
                            chatState.streamingContent.isEmpty
                        ? _buildEmptyState(personaState.persona.name)
                        : ListView.builder(
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
      ),
    );
  }

  /// Empty state — shown when a companion has no chat history yet.
  Widget _buildEmptyState(String companionName) {
    final suggestions = [
      'Hey ${companionName.isEmpty ? 'Mira' : companionName}, how are you?',
      'Tell me about yourself',
      'I had a long day. Can we talk?',
      'What do you like to do for fun?',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sparkle icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.pinkGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.magentaAccent.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: AppTheme.moonWhite.withOpacity(0.9),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Say hi to ${companionName.isEmpty ? 'Mira' : companionName} — or try a slash command:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            // Command hints
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                _CommandHint('/help'),
                _CommandHint('/time'),
                _CommandHint('/joke'),
                _CommandHint('/remind 5m ...'),
              ],
            ),
            const SizedBox(height: 24),
            // Suggested opening lines
            const Text(
              'SUGGESTIONS',
              style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((s) {
                return GestureDetector(
                  onTap: () {
                    _messageController.text = s;
                    _sendMessage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        color: AppTheme.moonWhite,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
                child: KeyboardListener(
                  focusNode: FocusNode(), // Local focus for the field
                  onKeyEvent: _onKey,
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Type a message... (Enter to send, Shift+Enter for newline)',
                      hintStyle: TextStyle(
                          color: AppTheme.mistGray, fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
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

class _CommandHint extends StatelessWidget {
  final String text;
  const _CommandHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.magentaAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.magentaAccent.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: AppTheme.moonRose,
            fontSize: 10,
            fontFamily: 'monospace',
            letterSpacing: 0.5),
      ),
    );
  }
}

// ── Beautiful floating header (no border) ───────────────────────────────

class _ChatHeader extends ConsumerWidget {
  final bool isTyping;
  final bool characterVisible;
  final VoidCallback onToggleCharacter;

  const _ChatHeader({
    required this.isTyping,
    required this.characterVisible,
    required this.onToggleCharacter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          // Companion switcher (replaces static name) + online/typing status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const CompanionSwitcher(),
                const SizedBox(height: 4),
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
