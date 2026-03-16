import 'package:flutter/material.dart';

class TelemetryCursorSlider extends StatelessWidget {
  final int index;
  final int maxIndex;
  final ValueChanged<int> onChanged;
  final String label;

  const TelemetryCursorSlider({
    super.key,
    required this.index,
    required this.maxIndex,
    required this.onChanged,
    this.label = "Cursor",
  });

  @override
  Widget build(BuildContext context) {
    if (maxIndex <= 0) return const SizedBox.shrink();

    return Row(
      children: [
        Text("$label:", style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(width: 10),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: index.toDouble(),
              min: 0,
              max: maxIndex.toDouble(),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text("${index + 1}/${maxIndex + 1}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}