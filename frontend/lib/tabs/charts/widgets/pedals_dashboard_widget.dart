import 'package:flutter/material.dart';
import 'telemetry_helpers.dart';
import 'telemetry_card.dart';

class PedalsDashboardWidget extends StatelessWidget {
  final dynamic payload;
  final List<dynamic> x;
  final Map<String, dynamic> series;
  final List<String> enabledCodes;
  final int? indexOverride;

  const PedalsDashboardWidget({
    super.key,
    required this.payload,
    required this.x,
    required this.series,
    required this.enabledCodes,
    this.indexOverride,
  });

  @override
  Widget build(BuildContext context) {
    final idx = indexOverride ?? (x.isEmpty ? 0 : x.length - 1);

    final rows = <Widget>[];
    for (final code in enabledCodes) {
      final d = asMap(series[code]);
      final thrArr = asList(d["throttle"]);
      final brkArr = asList(d["brake"]);

      final thr = valueAt(thrArr, idx);
      final brk = valueAt(brkArr, idx);
      if (thr == null && brk == null) continue;

      final c = driverColor(payload, code);

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              _chip(code, c),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    _bar(label: "THR", value: (thr ?? 0) / 100.0, color: Colors.greenAccent),
                    const SizedBox(height: 8),
                    _bar(label: "BRK", value: (brk ?? 0) / 100.0, color: Colors.redAccent),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${(thr ?? 0).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text("${(brk ?? 0).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return const TelemetryCard(
        icon: Icons.show_chart,
        title: "Pedals",
        child: Text("No throttle/brake data.", style: TextStyle(color: Colors.white70)),
      );
    }

    return TelemetryCard(
      icon: Icons.show_chart,
      title: "Pedals",
      child: Column(children: rows),
    );
  }

  Widget _bar({required String label, required double value, required Color color}) {
    final v = clampDouble(value, 0, 1);
    return Row(
      children: [
        SizedBox(width: 42, child: Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.85)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String code, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.45)),
      ),
      child: Text(code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    );
  }
}