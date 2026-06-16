import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/storage/firebase_storage.dart';
import '../core/network/websocket_client.dart';
import '../core/utils/logger.dart';
import '../models/message_model.dart';
import '../models/persona_model.dart';
import '../services/ai_service.dart';
import '../services/memory_service.dart';
import '../providers/auth_provider.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService());

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final storage = ref.watch(firestoreStorageProvider);
  return ChatNotifier(
    ref.read(webSocketClientProvider),
    storage,
    ref.read(memoryServiceProvider),
    ref.read(aiServiceProvider),
  );
});

class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isTyping;
  final String? error;
  final String streamingContent;
  final DateTime? lastAiResponseAt;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.error,
    this.streamingContent = '',
    this.lastAiResponseAt,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isTyping,
    String? error,
    String? streamingContent,
    DateTime? lastAiResponseAt,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      error: error,
      streamingContent: streamingContent ?? this.streamingContent,
      lastAiResponseAt: lastAiResponseAt ?? this.lastAiResponseAt,
    );
  }
  Duration get lastResponseAge =>
      lastAiResponseAt == null
          ? const Duration(days: 999)
          : DateTime.now().difference(lastAiResponseAt!);
}

class ChatNotifier extends StateNotifier<ChatState> {
  final WebSocketClient _wsClient;
  final FirestoreStorage? _storage;
  final MemoryService _memoryService;
  final AiService _aiService;
  final _uuid = const Uuid();
  StreamSubscription? _messagesSub;
  static const String _conversationId = 'main';

  ChatNotifier(this._wsClient, this._storage, this._memoryService, this._aiService)
      : super(const ChatState()) {
    if (_storage != null) _subscribe();
    _setupWebSocket();
  }

  void _subscribe() {
    _messagesSub = _storage!.watchMessages(_conversationId).listen(
          (maps) {
        state = state.copyWith(
          messages: maps.map((m) => MessageModel.fromJson(m)).toList(),
        );
      },
      onError: (e) {
        AppLogger.error('chatProvider stream error', e);
      },
    );
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }

  void _setupWebSocket() {
    _wsClient.onStreamToken = (token, done) {
      if (done) {
        final fullContent = state.streamingContent;
        if (fullContent.isNotEmpty) {
          final aiMessage = MessageModel(
            id: _uuid.v4(),
            role: 'assistant',
            content: fullContent,
            timestamp: DateTime.now(),
          );
          // Write to Firestore — stream listener updates state automatically
          _storage?.addMessage(
            aiMessage.toJson(),
            _conversationId,
          );
          state = state.copyWith(streamingContent: '', isTyping: false, isLoading: false, lastAiResponseAt: DateTime.now());
        }
      } else {
        state = state.copyWith(
          streamingContent: state.streamingContent + token,
          isTyping: true,
        );
      }
    };

    _wsClient.onTyping = (isTyping) => state = state.copyWith(isTyping: isTyping);

    _wsClient.onError = (error) {
      AppLogger.error('WebSocket chat error', error);
      state = state.copyWith(error: error, isTyping: false, streamingContent: '');
    };
  }

  Future<void> sendMessage(String content, PersonaModel persona) async {
    if (content.trim().isEmpty || _storage == null) return;

    final userMessage = MessageModel(
      id: _uuid.v4(),
      role: 'user',
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    // Write to Firestore — stream updates state, no manual copyWith needed
    await _storage.addMessage(
        userMessage.toJson(),
      _conversationId);

    state = state.copyWith(
      isLoading: true,
      isTyping: true,
      streamingContent: '',
      error: null,
    );

    await _memoryService.processMessage(content);

    final allMessages = [...state.messages, userMessage];

    if (_wsClient.isConnected) {
      _wsClient.sendMessage(
        messages: allMessages.map((m) => m.toApiFormat()).toList(),
        persona: persona.toApiFormat(),
      );
    } else {
      await _sendViaApi(allMessages, persona);
    }
  }

  Future<void> _sendViaApi(List<MessageModel> messages, PersonaModel persona) async {
    try {
      final memoryFacts = await _memoryService.getMemoryFacts();
      final response = await _aiService.sendMessage(
        messages: messages,
        persona: persona,
        memoryFacts: memoryFacts,
      );
      final aiMessage = MessageModel(
        id: _uuid.v4(),
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );
      await _storage?.addMessage(
          aiMessage.toJson(),
        _conversationId);
      state = state.copyWith(isLoading: false, isTyping: false, lastAiResponseAt: DateTime.now());
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to get response.',
        isLoading: false,
        isTyping: false,
      );
    }
  }

  Future<void> clearMessages() async {
    if (_storage == null) return;
    await _storage.clearMessages(_conversationId);
    state = const ChatState();
  }
}