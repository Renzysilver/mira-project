import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/assistant/command_registry.dart';
import '../../core/assistant/reminder_service.dart';
import '../../core/relationship/milestones.dart';
import '../../providers/chat_provider.dart';
import '../../providers/persona_provider.dart';
import '../../services/memory_service.dart' show memoryFactsProvider;
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
  StreamSubscription<Reminder>? _reminderSub;

  @override
  void initState() {
    super.initState();
    _reminderSub = ref.read(reminderServiceProvider).firedReminders.listen((r) {
      _showSystemMessage('\u23f0 Reminder: ${r.text}');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill input from voice transcription if passed from home screen.
    final extra = GoRouterState.of(context).extra;
    if (extra is String && extra.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _messageController.text = extra;
        }
      });
    }
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

    final persona = ref.read(personaProvider).persona;
    ref.read(chatProvider.notifier).sendMessage(text, persona);
    ref.read(personaProvider.notifier).incrementMessageCount();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 200), () async {
      if (!mounted) return;
      final memoryFacts = ref.read(memoryFactsProvider);
      final memoryCount = memoryFacts.maybeWhen(data: (l) => l.length, orElse: () => 0);
      final newlyUnlocked = await ref.read(personaProvider.notifier).checkMilestones(memoryCount: memoryCount);
      for (final m in newlyUnlocked) {
        _showMilestoneCelebration(m);
      }
    });
  }

  void _showSystemMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: TextStyle(color: isError ? AppTheme.errorRed : AppTheme.textPrimary, fontSize: 12, height: 1.4)),
        backgroundColor: isError ? Colors.red.withOpacity(0.9) : AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  void _showMilestoneCelebration(Milestone m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: m.color.withOpacity(0.2), border: Border.all(color: m.color)), child: Icon(m.icon, color: m.color, size: 14)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('Achievement unlocked!', style: TextStyle(color: m.color, fontSize: 9, fontWeight: FontWeight.w600)), Text(m.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)), Text(m.description, style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 9))])),
          ],
        ),
        backgroundColor: AppTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter && !HardwareKeyboard.instance.isShiftPressed) {
      _sendMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final personaState = ref.watch(personaProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = bottomInset > 0 ? 8.0 : 72.0;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: MainShell(
        currentIndex: 0,
        child: Container(
          color: AppTheme.background,
          child: SafeArea(
            bottom: bottomInset == 0,
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(width: 34, height: 34, decoration: BoxDecoration(color: AppTheme.glassWhite, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary, size: 14)),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.auroraGradient), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          const CompanionSwitcher(),
                          const SizedBox(height: 2),
                          Row(children: [
                            Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.successGreen)),
                            const SizedBox(width: 5),
                            Text(chatState.isTyping ? 'typing...' : 'online', style: TextStyle(fontSize: 10, color: chatState.isTyping ? AppTheme.pinkLight : AppTheme.textSecondary.withOpacity(0.7))),
                          ]),
                        ]),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/call'),
                        child: Container(width: 34, height: 34, decoration: BoxDecoration(color: AppTheme.glassWhite, shape: BoxShape.circle), child: const Icon(Icons.phone_outlined, color: AppTheme.pink, size: 16)),
                      ),
                    ],
                  ),
                ),

                // Messages
                Expanded(
                  child: chatState.messages.isEmpty && !chatState.isTyping && chatState.streamingContent.isEmpty
                      ? _buildEmptyState(personaState.persona.name)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
                          itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == chatState.messages.length && chatState.isTyping) {
                              return const Padding(padding: EdgeInsets.only(top: 8, left: 8), child: TypingIndicator());
                            }
                            final message = chatState.messages[index];
                            return ChatBubble(message: message.content, isUser: message.role == 'user', time: DateFormat('h:mm a').format(message.timestamp));
                          },
                        ),
                ),

                if (chatState.streamingContent.isNotEmpty)
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: ChatBubble(message: chatState.streamingContent, isUser: false, time: DateFormat('h:mm a').format(DateTime.now()))),

                if (chatState.error != null)
                  Padding(padding: const EdgeInsets.all(8), child: Text(chatState.error!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12))),

                // Input
                SafeArea(
                  bottom: bottomInset == 0,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: AppTheme.glassWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.glassBorder)),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Icon(Icons.emoji_emotions_outlined, color: AppTheme.textSecondary.withOpacity(0.4), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                    minLines: 1,
                                    maxLines: 4,
                                    textInputAction: TextInputAction.send,
                                    decoration: const InputDecoration(hintText: 'Type a message...', hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)),
                                    onSubmitted: (_) => _sendMessage(),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/call'),
                                  child: Padding(padding: const EdgeInsets.only(right: 12), child: Icon(Icons.mic_none_rounded, color: AppTheme.textSecondary.withOpacity(0.5), size: 18)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 44, height: 44,
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.pinkGradient),
                          child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: _sendMessage),
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

  Widget _buildEmptyState(String companionName) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.auroraGradient, boxShadow: [BoxShadow(color: AppTheme.purple.withOpacity(0.3), blurRadius: 16)]), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22)),
            const SizedBox(height: 14),
            Text('Start the conversation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: AppTheme.textPrimary.withOpacity(0.9), letterSpacing: 1)),
            const SizedBox(height: 6),
            Text('Say hi to ${companionName.isEmpty ? 'Mira' : companionName} \u2014 or try a slash command:', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withOpacity(0.7), height: 1.4)),
            const SizedBox(height: 12),
            Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: ['/help', '/time', '/joke', '/remind 5m ...'].map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppTheme.purple.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.purple.withOpacity(0.2))), child: Text(s, style: const TextStyle(color: AppTheme.purpleLight, fontSize: 10, fontFamily: 'monospace')))).toList()),
            const SizedBox(height: 16),
            const Text('SUGGESTIONS', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary, letterSpacing: 2, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: ['Hey, how are you?', 'Tell me about yourself', 'I had a long day', 'What do you like?'].map((s) {
              return GestureDetector(onTap: () {_messageController.text = s;_sendMessage();}, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: AppTheme.glassWhite, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.glassBorder)), child: Text(s, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontStyle: FontStyle.italic))));
            }).toList()),
          ],
        ),
      ),
    );
  }
}
