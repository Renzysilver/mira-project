import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/logger.dart';
import 'core/assistant/command_registry.dart';
import 'core/assistant/local_commands.dart';
import 'core/assistant/ai_commands.dart';
import 'core/assistant/reminder_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env is optional — defaults are baked into Env class. Continue.
    AppLogger.warning('Failed to load .env: $e');
  }

  // Firebase init failure (missing google-services.json, network error, etc.)
  // must not crash the whole app — show a red-screen-style error instead.
  FirebaseOptions? firebaseOptions;
  try {
    firebaseOptions = DefaultFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e, stack) {
    AppLogger.error('Firebase init failed — running without Firebase', e, stack);
  }

  try {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(AppConstants.userBox),
      Hive.openBox(AppConstants.messagesBox),
      Hive.openBox(AppConstants.personaBox),
      Hive.openBox(AppConstants.settingsBox),
      Hive.openBox(AppConstants.memoriesBox),
      Hive.openBox(AppConstants.callLogsBox),
      Hive.openBox('reminders'),
    ]);
  } catch (e, stack) {
    AppLogger.error('Hive init failed', e, stack);
  }

  // Register assistant commands (slash commands).
  // Local commands work offline; AI commands need a configured AI provider.
  CommandRegistry.register(HelpCommand());
  CommandRegistry.register(TimeCommand());
  CommandRegistry.register(DateCommand());
  CommandRegistry.register(JokeCommand());
  CommandRegistry.register(QuoteCommand());
  CommandRegistry.register(SummarizeCommand());
  CommandRegistry.register(TranslateCommand());
  CommandRegistry.register(DraftCommand());
  // RemindCommand is registered by the reminderServiceProvider consumer
  // in app.dart — it needs the service instance.

  AppLogger.info('Mirabel initialized');

  // Pre-load onboardingComplete from Hive cache so the router
  // doesn't redirect to onboarding on every cold start before
  // the auth listener fires.
  try {
    final userBox = Hive.box(AppConstants.userBox);
    final cachedUser = userBox.get('current_user');
    if (cachedUser != null) {
      final map = Map<String, dynamic>.from(cachedUser as Map);
      final onboardingDone = map['onboardingComplete'] as bool? ?? false;
      // We can't access providers here (no container yet), but we
      // can set a static flag that the router reads.
      _cachedOnboardingComplete = onboardingDone;
    }
  } catch (_) {}

  runApp(const ProviderScope(child: MiraApp()));
}

/// Set during main() from Hive cache — read by the router before
/// the auth listener has a chance to fire.
bool _cachedOnboardingComplete = false;
