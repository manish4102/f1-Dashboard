import 'package:flutter/material.dart';
import 'telemetry_line_chart_base.dart';

class DRSChartWidget extends StatelessWidget {
  final dynamic payload;
  final List<dynamic> x;
  final String xType;
  final Map<String, dynamic> series;
  final List<String> enabledCodes;

  const DRSChartWidget({
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
      title: "DRS",
      icon: Icons.flag_outlined,
      factorKey: "drs",
      getValues: (driverObj) => (driverObj["drs"] as List?) ?? const [],
      formatValue: (v) => v >= 0.5 ? "ON" : "OFF",
      badgeForValue: (v) {
        if (v == null) return null;
        return v >= 0.5 ? "DRS ON" : "DRS OFF";
      },
      isStep: true,
      sparkHeight: 75,
      expandedHeight: 240,
    );
  }
}
