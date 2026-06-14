import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../app/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  const Text('Welcome Back', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Sign in to continue to Mira', style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  CustomTextField(hintText: 'Email', controller: _emailController, prefixIcon: const Icon(Icons.email, color: AppTheme.textSecondary), validator: (v) => v!.isEmpty ? 'Enter email' : null),
                  const SizedBox(height: 16),
                  CustomTextField(hintText: 'Password', controller: _passwordController, obscureText: true, prefixIcon: const Icon(Icons.lock, color: AppTheme.textSecondary), validator: (v) => v!.isEmpty ? 'Enter password' : null),
                  const SizedBox(height: 24),
                  CustomButton(text: 'Sign In', isLoading: authState.isLoading, onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ref.read(authProvider.notifier).signIn(_emailController.text, _passwordController.text);
                    }
                  }),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.surfaceLight), minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Continue with Google', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                  ),
                  const SizedBox(height: 24),
                  TextButton(onPressed: () => context.go('/auth/signup'), child: const Text("Don't have an account? Sign Up", style: TextStyle(color: AppTheme.primaryPurple))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
