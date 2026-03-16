import 'package:flutter/material.dart';
import 'feature_flags.dart';

class PredictionsTab extends StatelessWidget {
  const PredictionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.enableFutureTabs) {
      return const SizedBox.shrink();
    }
    return const Center(child: Text("Predictions (ML) - future hook"));
  }
}