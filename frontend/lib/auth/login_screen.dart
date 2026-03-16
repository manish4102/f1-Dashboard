import 'package:f1/tabs/overview/overview_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../theme/glow.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const LoginScreen({super.key, required this.onBack});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: OverviewTab(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text("Login"),
          leading: IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GlowCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ACCESS",
                      style: t.titleLarge?.copyWith(letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: emailCtrl,
                      decoration:
                          const InputDecoration(labelText: "Email"),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: "Password"),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _goToDashboard,
                            icon: const Icon(Icons.login),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text("Login"),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Authentication disabled. Tap Login to continue.",
                      style: t.bodySmall
                          ?.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}