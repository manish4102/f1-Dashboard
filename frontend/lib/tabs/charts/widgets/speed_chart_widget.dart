import 'package:flutter/material.dart';
import 'telemetry_line_chart_base.dart';

class SpeedChartWidget extends StatelessWidget {
  final dynamic payload;
  final List<dynamic> x;
  final String xType;
  final Map<String, dynamic> series;
  final List<String> enabledCodes;

  const SpeedChartWidget({
    super.key,
    required this.payload,
    required this.x,
    required this.xType,
    required this.series,
    required this.enabledCodes,
  });

  @override
  Widget build(BuildContext context) {
    return TelemetryLineChartBase(
      payload: payload,
      x: x,
      xType: xType,
      series: series,
      enabledCodes: enabledCodes,
      title: "Speed",
      icon: Icons.speed,
      factorKey: "speed",
      getValues: (driverObj) => (driverObj["speed"] as List?) ?? const [],
      formatValue: (v) => "${v.toStringAsFixed(0)} km/h",
      isStep: false,
      sparkHeight: 75,
      expandedHeight: 240,
    );
  }
}
