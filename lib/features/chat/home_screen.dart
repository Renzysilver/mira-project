import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mira', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                    IconButton(
                      onPressed: () => context.go('/settings'),
                      icon: const Icon(Icons.settings, color: AppTheme.textSecondary, size: 28),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              const Text('Welcome back!', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
              const SizedBox(height: 40),
              
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionCard(
                    context: context,
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    color: AppTheme.primaryPurple,
                    onTap: () => context.go('/chat'),
                  ),
                  _buildActionCard(
                    context: context,
                    icon: Icons.phone_rounded,
                    label: 'Call',
                    color: AppTheme.primaryPink,
                    onTap: () => context.go('/call'),
                  ),
                ],
              ),
              
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha:0.6),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withValues(alpha:0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha:0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
