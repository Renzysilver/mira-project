import 'package:flutter/material.dart';
import '../app/theme.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;

  const CustomTextField({super.key, required this.hintText, required this.controller, this.obscureText = false, this.prefixIcon, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(hintText: hintText, prefixIcon: prefixIcon),
    );
  }
}
