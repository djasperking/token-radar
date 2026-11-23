import 'package:flutter/material.dart';

class AppColors {
  static const orange = Color(0xFFF47321);
  static const orangeSoft = Color(0xFFFBA65D);
  static const peach = Color(0xFFFFE9DA);
  static const peachLight = Color(0xFFFFF4EC);
  static const ink = Color(0xFF16161A);
  static const muted = Color(0xFF8A8A94);
  static const field = Color(0xFFF3F3F6);
  static const card = Color(0xFFF5F5F7);
  static const border = Color(0xFFE8E8EC);
  static const green = Color(0xFF2EAD6B);
  static const greenSoft = Color(0xFFDDF5E7);
  static const red = Color(0xFFE5484D);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.orange,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.4),
      ),
    ),
  );
}
