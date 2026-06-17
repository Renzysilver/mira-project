import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'routes.dart';
import 'theme.dart';
import '../core/assistant/command_registry.dart';
import '../core/assistant/reminder_service.dart';
import '../providers/auth_provider.dart';

class MiraApp extends ConsumerStatefulWidget {
  const MiraApp({super.key});

  @override
  ConsumerState<MiraApp> createState() => _MiraAppState();
}

class _MiraAppState extends ConsumerState<MiraApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Register the remind command now that the service is available,
    // and start polling for due reminders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reminderService = ref.read(reminderServiceProvider);
      CommandRegistry.register(RemindCommand(reminderService));
      reminderService.start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(reminderServiceProvider).stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause reminder polling when app is backgrounded (saves battery);
    // resume when foregrounded.
    final reminderService = ref.read(reminderServiceProvider);
    if (state == AppLifecycleState.resumed) {
      reminderService.start();
    } else {
      reminderService.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final router = ref.watch(routerProvider(authState.isAuthenticated));

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp.router(
      title: 'Mira',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
