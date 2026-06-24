import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import 'theme.dart';
import '../core/assistant/command_registry.dart';
import '../core/assistant/reminder_service.dart';
import '../core/utils/logger.dart';
import '../providers/auth_provider.dart';
import '../services/wakeword_service.dart';

class MiraApp extends ConsumerStatefulWidget {
  const MiraApp({super.key});

  @override
  ConsumerState<MiraApp> createState() => _MiraAppState();
}

class _MiraAppState extends ConsumerState<MiraApp> with WidgetsBindingObserver {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Register the wake word callback. The native side (onResume / onNewIntent)
    // calls invokeMethod("wakeWordDetected") and this fires _launchCall().
    WakeWordBridge.init();
    WakeWordBridge.onWakeWordDetected = () {
      AppLogger.info('Wake word callback received — launching call screen');
      _launchCall();
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reminderService = ref.read(reminderServiceProvider);
      CommandRegistry.register(RemindCommand(reminderService));
      reminderService.start();
    });
  }

  void _launchCall() {
    AppLogger.info('_launchCall: mounted=$mounted router=${_router != null}');
    if (!mounted) return;
    if (_router == null) {
      // Router not ready yet — retry in 300 ms.
      AppLogger.warning('_launchCall: router null, retrying in 300ms');
      Future.delayed(const Duration(milliseconds: 300), _launchCall);
      return;
    }
    _router!.go('/call');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(reminderServiceProvider).stop();
    WakeWordBridge.onWakeWordDetected = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
    _router = router;

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