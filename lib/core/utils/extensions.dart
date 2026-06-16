import 'package:flutter/material.dart';

extension StringExtensions on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String truncate(int maxLength) => length <= maxLength ? this : '${substring(0, maxLength)}...';
}

extension ContextExtensions on BuildContext {
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red.shade800 : null, behavior: SnackBarBehavior.floating),
    );
  }
}
