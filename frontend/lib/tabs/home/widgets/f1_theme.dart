import 'package:flutter/material.dart';

class F1Theme {
  static const Color bg = Color(0xFF0B0B0F);
  static const Color surface1 = Color(0xFF14141A);
  static const Color surface2 = Color(0xFF1A1A20);
  static const Color f1Red = Color(0xFFE10600);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCFCFD6);
  static const Color divider = Color(0xFF2A2A33);

  static TextStyle get h1 => const TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w900,
    height: 1.05,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get h2 => const TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    height: 1.0,
    color: textPrimary,
    letterSpacing: -0.6,
  );

  static TextStyle get h3 => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get body =>
      const TextStyle(fontSize: 16, height: 1.7, color: textSecondary);

  static BoxDecoration cardDecoration({bool redBorder = false}) {
    return BoxDecoration(
      color: surface1,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: redBorder ? f1Red : divider, width: 1),
      boxShadow: const [
        BoxShadow(
          blurRadius: 22,
          offset: Offset(0, 10),
          color: Color(0x55000000),
        ),
      ],
    );
  }

  static BoxDecoration get backgroundGradient => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bg, const Color(0xFF0E0E12), bg],
    ),
  );
}
