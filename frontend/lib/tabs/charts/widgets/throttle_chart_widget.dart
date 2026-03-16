import 'package:flutter/material.dart';
import 'telemetry_line_chart_base.dart';

class ThrottleChartWidget extends StatelessWidget {
  final dynamic payload;
  final List<dynamic> x;
  final String xType;
  final Map<String, dynamic> series;
  final List<String> enabledCodes;

  const ThrottleChartWidget({
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
      title: "Throttle",
      icon: Icons.trending_up,
      factorKey: "throttle",
      getValues: (driverObj) => (driverObj["throttle"] as List?) ?? const [],
      formatValue: (v) => "${v.toStringAsFixed(0)}%",
      clamp0to100: true,
      isStep: false,
      sparkHeight: 75,
      expandedHeight: 240,
    );
  }
}
