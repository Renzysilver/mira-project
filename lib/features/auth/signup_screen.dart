import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dreamy_background.dart';
import '../../widgets/auth/dreamy_form_widgets.dart';
import '../../app/theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController     = TextEditingController();
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
    _fade   = CurvedAnimation(parent: _fadeIn, curve: Curves.easeOut);
    _fadeIn.forward();
  }

  @override
  void dispose() {
    _nameController.dispose(); _emailController.dispose();
    _passwordController.dispose(); _fadeIn.dispose(); super.dispose();
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
                    const SizedBox(height: 40),
                    // Cherry blossom icon
                    const _BlossomIcon(size: 44),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (b) => AppTheme.auroraGradient.createShader(b),
                      child: const Text('Mira',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w200,
                          color: Colors.white, letterSpacing: 8)),
                    ),
                    const SizedBox(height: 6),
                    Text('begin your journey',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, letterSpacing: 3)),
                    const SizedBox(height: 48),

                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Create Account',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300,
                              color: AppTheme.moonWhite, letterSpacing: 1),
                            textAlign: TextAlign.center),
                          const SizedBox(height: 24),

                          DreamyTextField(
                            controller: _nameController,
                            hint: 'Your name',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 14),
                          DreamyTextField(
                            controller: _emailController,
                            hint: 'Email',
                            icon: Icons.mail_outline_rounded,
                            validator: (v) => v!.isEmpty ? 'Enter email' : null,
                          ),
                          const SizedBox(height: 14),
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
                            validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                          ),
                          const SizedBox(height: 28),

                          GlowButton(
                            text: 'Create Account',
                            isLoading: authState.isLoading,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                ref.read(authProvider.notifier).signUp(
                                  _emailController.text,
                                  _passwordController.text,
                                  _nameController.text,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => context.go('/auth/login'),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account?  ',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(text: 'Sign in',
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
      child: CustomPaint(painter: _BlossomPainter()),
    );
  }
}

class _BlossomPainter extends CustomPainter {
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
