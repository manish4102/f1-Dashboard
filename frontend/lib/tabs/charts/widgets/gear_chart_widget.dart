import 'package:flutter/material.dart';
import 'telemetry_line_chart_base.dart';

class GearChartWidget extends StatelessWidget {
  final dynamic payload;
  final List<dynamic> x;
  final String xType;
  final Map<String, dynamic> series;
  final List<String> enabledCodes;

  const GearChartWidget({
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
      title: "Gear",
      icon: Icons.settings,
      factorKey: "gear",
      getValues: (driverObj) => (driverObj["gear"] as List?) ?? const [],
      formatValue: (v) => "G${v.toStringAsFixed(0)}",
      isStep: true,
      sparkHeight: 75,
      expandedHeight: 240,
    );
  }
}
