import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/auth/login');
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _controller,
                child: const Text('Mira', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _controller,
                child: const Text('Your AI Companion', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
