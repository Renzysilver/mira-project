# Mirabel

> AI companion app — Flutter frontend + Node.js/Express backend, powered by Groq (chat + Orpheus TTS), Firebase (auth + Firestore), Agora (call tokens), and Rive (animated avatars).

This is a cleaned-up fork of `mira-project` with race-condition fixes, security hardening, dead-code removal, and proper documentation.

---

## Repository layout

```
mirabel/
├── lib/                       # Flutter client
│   ├── app/                   # App entry, routing, theme
│   ├── core/
│   │   ├── constants/         # Env, app constants
│   │   ├── network/           # WebSocket client
│   │   ├── storage/           # Firestore, Hive, SecureStorage adapters
│   │   └── utils/             # Logger
│   ├── controllers/           # Rive animation controllers
│   ├── features/              # Screens grouped by feature (auth, call, chat, ...)
│   ├── models/                # Data models
│   ├── providers/             # Riverpod state notifiers
│   ├── services/              # Voice call, AI, TTS, audio, memory
│   └── widgets/               # Reusable UI (avatar, chat bubble, etc.)
├── backend/                   # Node.js + Express
│   ├── middleware/            # Firebase token verification
│   ├── routes/                # REST endpoints
│   ├── services/              # Groq, memory, personality, proactivity, token
│   └── server.js
├── assets/
│   ├── animations/            # Rive `.riv` avatar files
│   └── audio/                 # ringtone, chime, call_connected
├── android/ ios/ macos/ linux/ windows/ web/   # platform shells
└── pubspec.yaml
```

## Prerequisites

- Flutter 3.3+ (Dart SDK ≥ 3.3)
- Node.js 18+ and npm
- A Firebase project with **Authentication** (Email/Password + Google) and **Cloud Firestore** enabled
- A Groq API key — https://console.groq.com
- (Optional) An Agora project for call token generation — https://agora.io

## Setup — Flutter client

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run `flutterfire configure` to generate `lib/firebase_options.dart` and the platform-specific `google-services.json` / `GoogleService-Info.plist`. (A reference `firebase_options.dart` is committed — replace it with your own project's config.)
3. Copy `.env.example` → `.env` and fill in values:
   ```bash
   cp .env.example .env
   ```
4. Run:
   ```bash
   flutter run
   ```

## Setup — Backend

1. From `backend/`:
   ```bash
   npm install
   ```
2. Copy `backend/.env.example` → `backend/.env` and fill in values:
   ```bash
   cp .env.example .env
   ```
3. Run:
   ```bash
   npm run dev    # nodemon, hot reload
   # or
   npm start      # production
   ```
4. Health check: `curl http://localhost:3000/health` → `{"status":"ok"}`

## Architecture notes

### Voice call flow
`CallScreen` → `CallNotifier` (Riverpod) → `VoiceCallService` → (`SpeechToText` for STT, `AiService` for LLM, `ElevenLabsService` for TTS, `AudioService` for sound effects). The voice service is the single source of truth for `_isSpeaking` / `_isProcessing` guards, preventing the mic from reactivating mid-TTS.

### State management
Riverpod 2.x throughout. Top-level providers (`currentUidProvider`, `firestoreStorageProvider`) scope per-user Firestore reads/writes; downstream notifiers (`personaProvider`, `chatProvider`, `callProvider`) watch them and rebuild automatically on sign-in / sign-out.

### Persistence
- **Firestore** — source of truth for persona, settings, memories, messages, call logs.
- **Hive** — local cache for offline-first reads (user, messages, persona).
- **SecureStorage** — auth token, user id, email.

### Memory extraction
Both client (`lib/services/memory_service.dart`) and backend (`backend/services/memoryService.js`) extract facts from user messages using simple regex patterns. The backend version is the canonical one for the REST/Socket path; the client version is used in voice-call mode. Both cap stored facts at 50.

## Key fixes vs. `mira-project`

| # | Area | Fix |
|---|------|-----|
| 1 | `voice_call_service.dart` | Added `_consecutiveSttErrors` cap (5) to prevent infinite retry loops; `finally` block guarantees `_isProcessing` reset; TTS failure now propagates to caller. |
| 2 | `talking_controller.dart` | Removed — dead duplicate of `mira_talking_controller.dart`. |
| 3 | `env.dart` | Removed 6 stale unused getters (Firebase + ElevenLabs). |
| 4 | `pubspec.yaml` | Removed `flutter_tts`, `lottie`, `emoji_picker_flutter`, `shimmer`, `connectivity_plus`, `cached_network_image`, `json_annotation`, `cupertino_icons` — none were imported. Moved `audio_session` from `dev_dependencies` to `dependencies` (it's used at runtime). |
| 5 | `backend/package.json` | Removed `elevenlabs` dep — only used by the deleted `routes/voice.js`. |
| 6 | `backend/server.js` | Fixed invalid `cors({origin:'*', credentials:true})` (browsers reject). Socket auth now verifies the Firebase ID token instead of trusting it as a UID. Added graceful SIGINT/SIGTERM shutdown. |
| 7 | `proactivityService.js` | Replaced deprecated `llama3-8b-8192` model with `llama-3.1-8b-instant`. |
| 8 | `backend/memoryService.js` | Fixed `extractFact` case bug — was matching against lowercased message so "My name is Alice" was stored as "alice". Now captures from the original message. |
| 9 | `authMiddleware.js` | Dev-mode `x-user-id` bypass is now gated by `NODE_ENV !== 'production'`. |
| 10 | `routes/chat.js` | Added 4,000-character limit on incoming messages to prevent context-window DoS. |
| 11 | `main.dart` | Wrapped `Firebase.initializeApp()` and Hive opens in try/catch — app no longer crashes if `google-services.json` is missing. |
| 12 | `elevenlabs_service.dart` | Removed the broken 24kHz→44kHz header rewrite that played audio ~1.84× too fast; `just_audio` handles 24kHz natively. `speak()` return value is now meaningful. |
| 13 | `ai_service.dart` | Added 30s timeout to Groq HTTP call. |
| 14 | `mira_avatar.dart` | `_talking` controller is now properly disposed. |
| 15 | `call_provider.dart` | `endCall()` no longer writes a zero-duration call log when the call was never started. `startCall()` guards against double-invocation. |
| 16 | `.env.example` | Split into root (Flutter) and `backend/.env.example` (Node); documented every var. |
| 17 | `README.md` | Was literally empty; now has setup, architecture, and fix log. |

## License

Proprietary — all rights reserved.
