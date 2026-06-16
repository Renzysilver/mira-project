import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/dreamy_background.dart';
import '../../providers/persona_provider.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaProvider).persona;
    final user    = ref.watch(authProvider).user;
    final name    = user?.displayName?.split(' ').first ?? 'you';

    return Scaffold(
      body: DreamyBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('hello, $name',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary,
                            letterSpacing: 1.5)),
                        ShaderMask(
                          shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                          child: const Text('Mira',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w200,
                              color: Colors.white, letterSpacing: 4)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _TopIconBtn(icon: Icons.notifications_none_rounded,
                          onTap: () {}),
                        const SizedBox(width: 8),
                        _TopIconBtn(icon: Icons.settings_outlined,
                          onTap: () => context.go('/settings')),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Avatar / companion card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _CompanionCard(persona: persona, onCallTap: () => context.go('/call')),
              ),

              const SizedBox(height: 28),

              // Action grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(child: _ActionCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chat',
                      sublabel: 'Send a message',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A2080), Color(0xFF9B6DFF)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      onTap: () => context.go('/chat'),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _ActionCard(
                      icon: Icons.phone_outlined,
                      label: 'Call',
                      sublabel: 'Hear her voice',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF80204A), Color(0xFFFFB7C5)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      onTap: () => context.go('/call'),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(child: _ActionCard(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Persona',
                      sublabel: 'Her character',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF204080), Color(0xFFA7C4FF)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      onTap: () => context.go('/persona'),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _ActionCard(
                      icon: Icons.people_outline_rounded,
                      label: 'Companions',
                      sublabel: 'Meet others',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A4020), Color(0xFF98F5C4)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      onTap: () {},
                    )),
                  ],
                ),
              ),

              const Spacer(),

              // Floating bottom hint
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('she\'s waiting for you  ✦',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.6),
                    letterSpacing: 2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Icon(icon, color: AppTheme.textSecondary, size: 20),
          ),
        ),
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  final dynamic persona;
  final VoidCallback onCallTap;
  const _CompanionCard({required this.persona, required this.onCallTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.softLavender.withOpacity(0.1),
                AppTheme.moonRose.withOpacity(0.08),
              ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              // Avatar circle
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(color: AppTheme.softLavender.withOpacity(0.4),
                      blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(persona?.name ?? 'Mira',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300,
                        color: AppTheme.moonWhite, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(persona?.personalityType ?? 'Sweet & caring',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _PillTag(label: '● online', color: AppTheme.successGreen),
                        const SizedBox(width: 8),
                        _PillTag(label: 'thinking of you', color: AppTheme.softLavender),
                      ],
                    ),
                  ],
                ),
              ),
              // Call button
              GestureDetector(
                onTap: onCallTap,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.moonRose, AppTheme.softLavender],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: AppTheme.moonRose.withOpacity(0.4),
                        blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.phone_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  final String label;
  final Color color;
  const _PillTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, letterSpacing: 0.5)),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon, required this.label,
    required this.sublabel, required this.gradient, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradient.colors.first.withOpacity(0.3),
                         gradient.colors.last.withOpacity(0.15)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => gradient.createShader(b),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400,
                    color: AppTheme.moonWhite)),
                const SizedBox(height: 2),
                Text(sublabel,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
