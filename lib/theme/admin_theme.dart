import 'package:flutter/material.dart';

class AdminColors {
  const AdminColors._();

  static const black = Color(0xFF000000);
  static const surface = Color(0xFFFFFFFF);
  static const page = Color(0xFFF8F9FA);
  static const line = Color(0xFFE5E7EB);
  static const softLine = Color(0xFFF3F4F6);
  static const muted = Color(0xFF99A1AF);
  static const textMuted = Color(0xFF6A7282);
  static const badgeText = Color(0xFF4A5565);
  static const disabled = Color(0xFFE5E7EB);
  static const yellow = Color(0xFFFED318);
}

class AdminTheme {
  const AdminTheme._();

  static ThemeData data() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AdminColors.yellow,
        surface: AdminColors.surface,
      ),
      fontFamily: 'Noto Sans KR',
      scaffoldBackgroundColor: AdminColors.page,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AdminColors.black,
        displayColor: AdminColors.black,
        fontFamily: 'Noto Sans KR',
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
