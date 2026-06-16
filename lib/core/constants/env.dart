import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised access to environment variables loaded from `.env`.
///
/// Firebase configuration is intentionally NOT here — it is generated
/// into `lib/firebase_options.dart` by `flutterfire configure` and
/// read directly from `DefaultFirebaseOptions.currentPlatform`.
class Env {
  Env._();

  static String get backendUrl => dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000';
  static String get wsUrl => dotenv.env['WS_URL'] ?? 'http://10.0.2.2:3000';
  static String get agoraAppId => dotenv.env['AGORA_APP_ID'] ?? '';
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
}
