import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/name_setup_screen.dart';
import '../features/onboarding/personality_setup_screen.dart';
import '../features/chat/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/call/call_screen.dart';
import '../features/persona/persona_screen.dart';
import '../features/memory/memory_screen.dart';
import '../features/settings/settings_screen.dart';

final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider.family<GoRouter, bool>((ref, isAuthenticated) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final onboardingComplete = ref.read(onboardingCompleteProvider);
      final isOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute && !isOnboardingRoute) {
        return '/auth/login';
      }
      // Authenticated users land on the Chat tab (the new home),
      // not the companion card screen.
      if (isAuthenticated && state.matchedLocation == '/') {
        if (!onboardingComplete) return '/onboarding';
        return '/chat';
      }
      if (isAuthenticated && isAuthRoute) {
        if (!onboardingComplete) return '/onboarding';
        return '/chat';
      }
      if (isAuthenticated && !onboardingComplete && !isOnboardingRoute) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/auth/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen(), routes: [
        GoRoute(path: '/name', builder: (context, state) => const NameSetupScreen()),
        GoRoute(path: '/personality', builder: (context, state) => const PersonalitySetupScreen()),
      ]),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(path: '/call', builder: (context, state) => const CallScreen()),
      GoRoute(path: '/persona', builder: (context, state) => const PersonaScreen()),
      GoRoute(path: '/memory', builder: (context, state) => const MemoryScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
});
