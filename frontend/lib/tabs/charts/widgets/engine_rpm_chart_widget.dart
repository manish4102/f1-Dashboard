import 'package:flutter/material.dart';
import 'telemetry_line_chart_base.dart';

class EngineRPMChartWidget extends StatelessWidget {
  final dynamic payload;
  final List<dynamic> x;
  final String xType;
  final Map<String, dynamic> series;
  final List<String> enabledCodes;

  const EngineRPMChartWidget({
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
      title: "Engine RPM",
      icon: Icons.electric_bolt,
      factorKey: "engine_rpm",
      getValues: (driverObj) => (driverObj["engine_rpm"] as List?) ?? const [],
      formatValue: (v) => v.toStringAsFixed(0),
      isStep: false,
      sparkHeight: 75,
      expandedHeight: 240,
    );
  }
}
