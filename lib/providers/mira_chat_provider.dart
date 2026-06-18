import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/ai/ai_provider_registry.dart';
import '../core/storage/firebase_storage.dart';
import '../core/utils/logger.dart';
import '../models/message_model.dart';
import '../services/ai_service.dart';
import 'auth_provider.dart';

/// Mira's system prompt — she's a balanced AI assistant, NOT a companion.
/// No romantic persona, no endearing terms, no flirt mode. Professional
/// but friendly, like ChatGPT or Claude.
const _miraSystemPrompt = '''
You are Mira, a helpful AI assistant. You are NOT a companion or girlfriend — you are a productivity assistant like Siri, Google Assistant, or ChatGPT.

Rules:
- Be helpful, concise, and direct
- Use a balanced, professional but friendly tone
- Do NOT use endearing terms or romantic language
- Do NOT roleplay as a companion
- Keep responses focused and actionable
- If the user asks you to do something you can't, explain why clearly
- You can help with: writing, research, planning, reminders, general questions, productivity
''';

/// Chat state for the Mira assistant.
class MiraChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isTyping;
  final String? error;
  final String streamingContent;

  const MiraChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.error,
    this.streamingContent = '',
  });

  MiraChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isTyping,
    String? error,
    String? streamingContent,
  }) {
    return MiraChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      error: error,
      streamingContent: streamingContent ?? this.streamingContent,
    );
  }
}

/// Mira assistant chat provider. Completely separate from the companion
/// chat system. Reads/writes to users/{uid}/mira_messages/.
final miraChatProvider =
    StateNotifierProvider<MiraChatNotifier, MiraChatState>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  return MiraChatNotifier(storage);
});

class MiraChatNotifier extends StateNotifier<MiraChatState> {
  final FirestoreStorage? _storage;
  final _uuid = const Uuid();
  StreamSubscription? _sub;

  MiraChatNotifier(this._storage) : super(const MiraChatState()) {
    if (_storage != null) _subscribe();
  }

  void _subscribe() {
    _sub = _storage!.watchMiraMessages().listen(
      (maps) {
        state = state.copyWith(
          messages: maps.map((m) => MessageModel.fromJson(m)).toList(),
          isLoading: false,
        );
      },
      onError: (e) {
        AppLogger.error('Mira chat stream error', e);
        state = state.copyWith(isLoading: false);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> sendMessage(String content, {String? userName}) async {
    if (content.trim().isEmpty || _storage == null) return;

    final userMessage = MessageModel(
      id: _uuid.v4(),
      role: 'user',
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    await _storage.addMiraMessage(userMessage.toJson());

    state = state.copyWith(
      isLoading: true,
      isTyping: true,
      error: null,
    );

    try {
      // Use rawCompletion with Mira's custom system prompt so she
      // sounds like a balanced AI assistant (like ChatGPT/Claude),
      // NOT a companion with a romantic persona.
      final response = await AiProviderRegistry.active.rawCompletion(
        systemPrompt: _miraSystemPrompt,
        messages: [...state.messages, userMessage]
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
        temperature: 0.5,
      );

      final aiMessage = MessageModel(
        id: _uuid.v4(),
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );

      await _storage.addMiraMessage(aiMessage.toJson());
      state = state.copyWith(isLoading: false, isTyping: false);
    } catch (e) {
      AppLogger.error('Mira AI error', e);
      state = state.copyWith(
        error: 'Something went wrong.',
        isLoading: false,
        isTyping: false,
      );
    }
  }

  Future<void> clearMessages() async {
    if (_storage == null) return;
    await _storage.clearMiraMessages();
    state = const MiraChatState();
  }
}
