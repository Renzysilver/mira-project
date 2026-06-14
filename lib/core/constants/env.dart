import 'package:flutter_dotenv/flutter_dotenv.dart';
class Env {
  Env._();
  static String get backendUrl => dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000';
  static String get wsUrl => dotenv.env['WS_URL'] ?? 'http://10.0.2.2:3000';
  static String get agoraAppId => dotenv.env['AGORA_APP_ID'] ?? '';
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get firebaseApiKey => dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_ANDROID_PROJECT_ID'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_ANDROID_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseStorageBucket => dotenv.env['FIREBASE_ANDROID_STORAGE_BUCKET'] ?? '';
  static String get elevenLabsApiKey => dotenv.env['ELEVENLABS_API_KEY'] ?? ''; // NEW
}