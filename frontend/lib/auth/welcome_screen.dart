import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  const WelcomeScreen({super.key, required this.onLogin, required this.onSignup});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("F1 DASH", style: t.titleLarge?.copyWith(fontSize: 34, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Text(
                    "Compact telemetry-style dashboard\nwith lap charts, strategy, and replay.",
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 26),
                  FilledButton(
                    onPressed: onLogin,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Text("Login"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onSignup,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Text("Sign Up"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}