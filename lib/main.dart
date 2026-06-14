import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/logger.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  await Hive.initFlutter();
  await Hive.openBox(AppConstants.userBox);
  await Hive.openBox(AppConstants.messagesBox);
  await Hive.openBox(AppConstants.personaBox);
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox(AppConstants.memoriesBox);
  await Hive.openBox(AppConstants.callLogsBox);

  AppLogger.info('Mira initialized successfully');

  runApp(const ProviderScope(child: MiraApp()));
}
