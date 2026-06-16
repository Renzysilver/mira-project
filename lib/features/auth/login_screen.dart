import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dreamy_background.dart';
import '../../app/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();
  bool _obscure = true;
  late AnimationController _fadeIn;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _fadeIn, curve: Curves.easeOut);
    _fadeIn.forward();
  }

  @override
  void dispose() {
    _emailController.dispose(); _passwordController.dispose();
    _fadeIn.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: AppTheme.errorRed));
      }
    });

    return Scaffold(
      body: DreamyBackground(
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // Logo / title
                    ShaderMask(
                      shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
                      child: const Text('Mira',
                        style: TextStyle(fontSize: 52, fontWeight: FontWeight.w200,
                          color: Colors.white, letterSpacing: 8)),
                    ),
                    const SizedBox(height: 8),
                    Text('your companion awaits',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary,
                        letterSpacing: 3)),
                    const SizedBox(height: 64),

                    // Glass card
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Welcome Back',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300,
                              color: AppTheme.moonWhite, letterSpacing: 1),
                            textAlign: TextAlign.center),
                          const SizedBox(height: 28),

                          _DreamyTextField(
                            controller: _emailController,
                            hint: 'Email',
                            icon: Icons.mail_outline_rounded,
                            validator: (v) => v!.isEmpty ? 'Enter email' : null,
                          ),
                          const SizedBox(height: 16),
                          _DreamyTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppTheme.textSecondary, size: 20),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) => v!.isEmpty ? 'Enter password' : null,
                          ),
                          const SizedBox(height: 28),

                          _GlowButton(
                            text: 'Sign In',
                            isLoading: authState.isLoading,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                ref.read(authProvider.notifier)
                                    .signIn(_emailController.text, _passwordController.text);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          _DividerRow(),
                          const SizedBox(height: 16),

                          _GoogleButton(onPressed: () =>
                              ref.read(authProvider.notifier).signInWithGoogle()),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => context.go('/signup'),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account?  ",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(text: 'Create one',
                              style: TextStyle(color: AppTheme.softLavender,
                                fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared dreamy widgets ──────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DreamyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _DreamyTextField({
    required this.controller, required this.hint, required this.icon,
    this.obscure = false, this.suffixIcon, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: AppTheme.moonWhite, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.softLavender, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
  const _GlowButton({required this.text, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(color: AppTheme.softLavender.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(fontSize: 15, letterSpacing: 2,
                fontWeight: FontWeight.w400, color: Colors.white)),
      ),
    );
  }
}

class _DividerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('or', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
    ]);
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.g_mobiledata_rounded, color: AppTheme.moonRose, size: 24),
      label: const Text('Continue with Google',
        style: TextStyle(color: AppTheme.moonWhite, fontSize: 13, letterSpacing: 0.5)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
    );
  }
}
