import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dreamy_background.dart';
import '../../widgets/auth/dreamy_form_widgets.dart';
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
      if (!mounted) return; // navigation may have disposed us already
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

                    // Cherry blossom icon
                    const _BlossomIcon(size: 48),
                    const SizedBox(height: 24),

                    ShaderMask(
                      shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                      child: const Text('Mira',
                        style: TextStyle(fontSize: 52, fontWeight: FontWeight.w200,
                          color: Colors.white, letterSpacing: 8)),
                    ),
                    const SizedBox(height: 8),
                    Text('your companion awaits',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary,
                        letterSpacing: 3)),
                    const SizedBox(height: 64),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Welcome Back',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300,
                              color: AppTheme.moonWhite, letterSpacing: 1),
                            textAlign: TextAlign.center),
                          const SizedBox(height: 6),
                          const Text("I've been waiting for you.",
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic,
                              color: AppTheme.textSecondary, letterSpacing: 0.5),
                            textAlign: TextAlign.center),
                          const SizedBox(height: 28),

                          DreamyTextField(
                            controller: _emailController,
                            hint: 'Email',
                            icon: Icons.mail_outline_rounded,
                            validator: (v) => v!.isEmpty ? 'Enter email' : null,
                          ),
                          const SizedBox(height: 16),
                          DreamyTextField(
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

                          GlowButton(
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

                          const DividerRow(),
                          const SizedBox(height: 16),

                          GoogleButton(onPressed: () =>
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

/// Stylised cherry blossom icon — five soft pink petals around a magenta
/// center. Used on auth screens as the brand mark.
class _BlossomIcon extends StatelessWidget {
  final double size;
  const _BlossomIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BlossomPainter(size)),
    );
  }
}

class _BlossomPainter extends CustomPainter {
  final double size;
  _BlossomPainter(this.size);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final petalRadius = canvasSize.width * 0.22;
    final distance = canvasSize.width * 0.22;

    final petalPaint = Paint()
      ..color = AppTheme.moonRose
      ..style = PaintingStyle.fill;

    final centerPaint = Paint()
      ..color = AppTheme.magentaAccent
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * 3.14159265 - 3.14159265 / 2;
      final dx = center.dx + distance * cos(angle);
      final dy = center.dy + distance * sin(angle);
      canvas.drawCircle(Offset(dx, dy), petalRadius, petalPaint);
    }
    canvas.drawCircle(center, canvasSize.width * 0.08, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
