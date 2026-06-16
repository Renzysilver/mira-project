import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/env.dart';
import '../storage/secure_storage.dart';
import '../utils/logger.dart';

final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  return WebSocketClient(ref.read(secureStorageProvider));
});

class WebSocketClient {
  final SecureStorage _secureStorage;
  io.Socket? _socket;
  bool _isConnected = false;

  Function(String token, bool done)? onStreamToken;
  Function(bool)? onTyping;
  Function(String)? onError;
  Function()? onConnect;
  Function()? onDisconnect;

  WebSocketClient(this._secureStorage);
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected && _socket != null) return;
    final token = await _secureStorage.getAuthToken();

    _socket = io.io(Env.wsUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token ?? 'guest'},
    });

    _socket!.on('connect', (_) { _isConnected = true; AppLogger.info('WebSocket connected'); onConnect?.call(); });
    _socket!.on('disconnect', (_) { _isConnected = false; AppLogger.info('WebSocket disconnected'); onDisconnect?.call(); });
    _socket!.on('chat:stream', (data) { onStreamToken?.call(data['token'] ?? '', data['done'] ?? false); });
    _socket!.on('chat:typing', (data) { onTyping?.call(data ?? false); });
    _socket!.on('chat:error', (data) { onError?.call(data['message'] ?? 'Unknown error'); });

    _socket!.connect();
  }

  void sendMessage({required List<Map<String, String>> messages, required Map<String, dynamic> persona, String? userId}) {
    _socket?.emit('chat:message', {'messages': messages, 'persona': persona, 'userId': userId});
  }

  void disconnect() { _socket?.disconnect(); _socket = null; _isConnected = false; }
  void dispose() { disconnect(); onStreamToken = null; onTyping = null; onError = null; onConnect = null; onDisconnect = null; }
}
