import 'package:flutter/material.dart';
import 'feature_flags.dart';

class AiRagTab extends StatelessWidget {
  const AiRagTab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.enableFutureTabs) {
      return const SizedBox.shrink();
    }
    return const Center(child: Text("AI (RAG) - future hook"));
  }
}