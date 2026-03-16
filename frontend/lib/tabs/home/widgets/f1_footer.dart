import 'package:flutter/material.dart';
import 'f1_theme.dart';

class F1Footer extends StatelessWidget {
  const F1Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: F1Theme.divider)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: const Center(
          child: Text(
            "© Manish • F1 Portfolio",
            style: TextStyle(
              color: F1Theme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
