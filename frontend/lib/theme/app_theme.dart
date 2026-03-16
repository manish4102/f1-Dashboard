import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF0000),
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF10131B),
        background: const Color(0xFF070A10),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.background,
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
      titleMedium: TextStyle(fontWeight: FontWeight.w800),
      bodyMedium: TextStyle(height: 1.25),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF111827).withOpacity(0.85),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colorScheme.primary.withOpacity(0.7),
          width: 1.2,
        ),
      ),
    ),
  );
}

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.6, -0.8),
          radius: 1.2,
          colors: [c.primary.withOpacity(0.22), c.background.withOpacity(1.0)],
        ),
      ),
      child: child,
    );
  }
}
