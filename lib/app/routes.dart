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
import '../features/companions/companions_screen.dart';
import '../features/companion_creator/companion_creator_screen.dart';
import '../features/settings/settings_screen.dart';

final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider.family<GoRouter, bool>((ref, isAuthenticated) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final onboardingComplete = ref.read(onboardingCompleteProvider);
      final loc = state.matchedLocation;
      final isOnboardingRoute = loc.startsWith('/onboarding');
      final isAuthRoute = loc.startsWith('/auth');
      final isSplashRoute = loc == '/';

      // Splash is always allowed — never redirect away from it.
      // Splash handles its own navigation after the branding delay.
      if (isSplashRoute) return null;

      if (!isAuthenticated && !isAuthRoute && !isOnboardingRoute) {
        return '/auth/login';
      }
      // Authenticated users land on the magnificent Mira home screen.
      if (isAuthenticated && isAuthRoute) {
        if (!onboardingComplete) return '/onboarding';
        return '/home';
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
      GoRoute(path: '/companions', builder: (context, state) => const CompanionsScreen()),
      GoRoute(path: '/companion/new', builder: (context, state) => const CompanionCreatorScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
});
