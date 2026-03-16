import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../theme/glow.dart';
import 'auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const SignupScreen({super.key, required this.onBack});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final t = Theme.of(context).textTheme;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text("Sign Up"),
          leading: IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
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
                    Text("CREATE ACCOUNT", style: t.titleLarge?.copyWith(letterSpacing: 0.8)),
                    const SizedBox(height: 12),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
                    const SizedBox(height: 12),
                    TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
                    const SizedBox(height: 12),
                    TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Confirm Password")),
                    const SizedBox(height: 18),
                    if (auth.error != null)
                      Text(auth.error!, style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: auth.loading
                                ? null
                                : () => ref.read(authProvider.notifier).signup(
                                      emailCtrl.text,
                                      passCtrl.text,
                                      confirmCtrl.text,
                                    ),
                            icon: auth.loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.person_add),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text("Create Account"),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Dev bypass: leave fields empty and tap Create Account.",
                      style: t.bodySmall?.copyWith(color: Colors.white54),
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