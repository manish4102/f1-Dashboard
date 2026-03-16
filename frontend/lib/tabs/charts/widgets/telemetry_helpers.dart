import 'dart:convert';
import 'package:flutter/material.dart';

Map<String, dynamic> asMap(dynamic v) {
  if (v == null) return <String, dynamic>{};
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  if (v is String) {
    final decoded = jsonDecode(v);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  }
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic v) {
  if (v == null) return <dynamic>[];
  if (v is List) return v;
  return <dynamic>[];
}

double clampDouble(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

/// Finds the index in x (distance axis) closest to the given target.
/// If you don’t have a cursor/hover yet, you can just use the last index.
int nearestIndex(List<dynamic> x, double target) {
  if (x.isEmpty) return 0;
  int best = 0;
  double bestDiff = double.infinity;

  for (int i = 0; i < x.length; i++) {
    final xi = x[i];
    if (xi is! num) continue;
    final d = (xi.toDouble() - target).abs();
    if (d < bestDiff) {
      bestDiff = d;
      best = i;
    }
  }
  return best;
}

/// Safely reads a numeric telemetry value at index.
double? valueAt(List<dynamic> arr, int i) {
  if (i < 0 || i >= arr.length) return null;
  final v = arr[i];
  if (v is num) return v.toDouble();
  return null;
}

/// Simple driver color resolver like you already do.
Color driverColor(dynamic payload, String code) {
  try {
    final drivers = asList(payload.drivers);
    for (final d in drivers) {
      final m = asMap(d);
      if ((m["code"] ?? "").toString() == code) {
        final hex = (m["color"] ?? "#90A4AE").toString().replaceAll("#", "");
        final val = int.tryParse("FF$hex", radix: 16) ?? 0xFF90A4AE;
        return Color(val);
      }
    }
  } catch (_) {}
  return const Color(0xFF90A4AE);
}