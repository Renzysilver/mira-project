import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/assistant/command_registry.dart';
import '../../core/assistant/reminder_service.dart';
import '../../providers/mira_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/atmosphere/atmospheric_background.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/shell/main_shell.dart';

class MiraAssistantScreen extends ConsumerStatefulWidget {
  const MiraAssistantScreen({super.key});

  @override
  ConsumerState<MiraAssistantScreen> createState() => _MiraAssistantScreenState();
}

class _MiraAssistantScreenState extends ConsumerState<MiraAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  StreamSubscription<Reminder>? _reminderSub;

  @override
  void initState() {
    super.initState();
    _reminderSub =
        ref.read(reminderServiceProvider).firedReminders.listen((reminder) {
      _showSystemMessage('Reminder: ${reminder.text}');
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

    if (CommandRegistry.isCommand(text)) {
      final result = await CommandRegistry.execute(text);
      if (result.sideEffect != null) await result.sideEffect!();
      if (result.displayText != null) {
        _showSystemMessage(result.displayText!, isError: result.isError);
      }
      return;
    }

    final user = ref.read(authProvider).user;
    ref.read(miraChatProvider.notifier).sendMessage(text, userName: user?.displayName);
    _scrollToBottom();
  }

  void _showSystemMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text,
            style: TextStyle(
              color: isError ? AppTheme.errorRed : AppTheme.moonWhite,
              fontSize: 12, height: 1.4)),
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

  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _sendMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(miraChatProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = bottomInset > 0 ? 8.0 : 72.0;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: MainShell(
        currentIndex: 2,
        child: AtmosphericBackground(
          child: SafeArea(
            bottom: bottomInset == 0,
            child: Column(
              children: [
                // Header — Mira AI Assistant (NOT a companion)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.auroraGradient,
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Mira',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.moonWhite,
                                  letterSpacing: 1,
                                )),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.successGreen,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('AI Assistant',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary
                                          .withOpacity(0.8),
                                      letterSpacing: 0.5,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Messages or empty state
                Expanded(
                  child: chatState.messages.isEmpty &&
                          !chatState.isTyping
                      ? _buildEmptyState()
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

                if (chatState.error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(chatState.error!,
                        style: const TextStyle(color: AppTheme.errorRed))),

                // Input area
                SafeArea(
                  bottom: bottomInset == 0,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
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
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              decoration: const InputDecoration(
                                hintText: 'Ask Mira anything...',
                                hintStyle: TextStyle(
                                    color: AppTheme.mistGray, fontSize: 13),
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
                            gradient: AppTheme.auroraGradient,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x665A189A),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send,
                                color: Colors.white, size: 20),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.auroraGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.magentaAccent.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(height: 14),
            const Text(
              'How can I help you?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: AppTheme.moonWhite,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'I am Mira, your AI assistant. Ask me anything or try a command:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary.withOpacity(0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                _CommandChip('/help'),
                _CommandChip('/time'),
                _CommandChip('/joke'),
                _CommandChip('/remind 5m ...'),
              ],
            ),
            const SizedBox(height: 14),
            const Text('SUGGESTIONS',
                style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                'What can you do?',
                'Tell me a fun fact',
                'Help me write something',
                'What is the meaning of life?',
              ].map((s) {
                return GestureDetector(
                  onTap: () {
                    _messageController.text = s;
                    _sendMessage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Text(s,
                        style: const TextStyle(
                          color: AppTheme.moonWhite,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        )),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandChip extends StatelessWidget {
  final String text;
  const _CommandChip(this.text);

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
      child: Text(text,
          style: const TextStyle(
              color: AppTheme.moonRose,
              fontSize: 10,
              fontFamily: 'monospace',
              letterSpacing: 0.5)),
    );
  }
}
