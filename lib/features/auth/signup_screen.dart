import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../app/theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() { _nameController.dispose(); _emailController.dispose(); _passwordController.dispose(); super.dispose(); }

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
                  const Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  CustomTextField(hintText: 'Display Name', controller: _nameController, prefixIcon: const Icon(Icons.person, color: AppTheme.textSecondary), validator: (v) => v!.isEmpty ? 'Enter name' : null),
                  const SizedBox(height: 16),
                  CustomTextField(hintText: 'Email', controller: _emailController, prefixIcon: const Icon(Icons.email, color: AppTheme.textSecondary), validator: (v) => v!.isEmpty ? 'Enter email' : null),
                  const SizedBox(height: 16),
                  CustomTextField(hintText: 'Password (6+ characters)', controller: _passwordController, obscureText: true, prefixIcon: const Icon(Icons.lock, color: AppTheme.textSecondary), validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
                  const SizedBox(height: 24),
                  CustomButton(text: 'Sign Up', isLoading: authState.isLoading, onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ref.read(authProvider.notifier).signUp(_emailController.text, _passwordController.text, _nameController.text);
                    }
                  }),
                  const SizedBox(height: 24),
                  TextButton(onPressed: () => context.go('/auth/login'), child: const Text("Already have an account? Sign In", style: TextStyle(color: AppTheme.primaryPurple))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
