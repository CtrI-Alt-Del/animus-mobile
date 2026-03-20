import 'package:flutter/material.dart';

final class AppTheme {
  const AppTheme._();

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
    scaffoldBackgroundColor: const Color(0xFFF6F8FB),
  );
}
