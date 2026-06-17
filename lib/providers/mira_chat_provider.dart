import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/storage/firebase_storage.dart';
import '../core/utils/logger.dart';
import '../models/message_model.dart';
import '../models/persona_model.dart';
import '../services/ai_service.dart';
import 'auth_provider.dart';

/// Mira's fixed persona — she's the system AI assistant, NOT a companion.
/// Always sweet, always caring, always "Mira". Companion switching does
/// NOT affect her identity.
final _miraPersona = PersonaModel(
  name: 'Mira',
  personalityType: PersonalityType.sweet,
  currentMood: AvatarMood.happy,
  temperature: 0.7,
  personalityTraits: ['Helpful', 'Caring', 'Intelligent'],
);

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
  final aiService = AiService();
  return MiraChatNotifier(storage, aiService);
});

class MiraChatNotifier extends StateNotifier<MiraChatState> {
  final FirestoreStorage? _storage;
  final AiService _aiService;
  final _uuid = const Uuid();
  StreamSubscription? _sub;

  MiraChatNotifier(this._storage, this._aiService) : super(const MiraChatState()) {
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
      final response = await _aiService.sendMessage(
        messages: [...state.messages, userMessage],
        persona: _miraPersona,
        memoryFacts: const [],
        userName: userName,
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
