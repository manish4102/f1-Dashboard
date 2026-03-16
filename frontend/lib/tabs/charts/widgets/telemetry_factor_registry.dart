import 'package:flutter/material.dart';

class TelemetryFactors {
  static const speed = "speed";
  static const drs = "drs";
  static const throttle = "throttle";
  static const brake = "brake";
  static const engineRpm = "engine_rpm";
  static const gear = "gear";
}

class TelemetryFactorDef {
  final String key;
  final String label;
  final IconData icon;
  final bool isPro;

  const TelemetryFactorDef({
    required this.key,
    required this.label,
    required this.icon,
    this.isPro = false,
  });
}

const telemetryFactors = <TelemetryFactorDef>[
  TelemetryFactorDef(key: TelemetryFactors.speed, label: "Speed", icon: Icons.speed),
  TelemetryFactorDef(key: TelemetryFactors.drs, label: "DRS", icon: Icons.flag),
  TelemetryFactorDef(key: TelemetryFactors.throttle, label: "Throttle", icon: Icons.show_chart, isPro: true),
  TelemetryFactorDef(key: TelemetryFactors.brake, label: "Brake", icon: Icons.show_chart, isPro: true),
  TelemetryFactorDef(key: TelemetryFactors.engineRpm, label: "Engine RPM", icon: Icons.precision_manufacturing, isPro: true),
  TelemetryFactorDef(key: TelemetryFactors.gear, label: "Gear", icon: Icons.settings, isPro: true),
];