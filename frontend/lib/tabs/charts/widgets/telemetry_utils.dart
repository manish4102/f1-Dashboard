import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

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

double sampleNum(List<dynamic> arr, int i, {double fallback = 0}) {
  if (arr.isEmpty) return fallback;
  final idx = i.clamp(0, arr.length - 1);
  final v = arr[idx];
  if (v is num) return v.toDouble();
  return fallback;
}

/// Convert discrete series into step-like spots (x stays continuous).
List<FlSpot> makeSteppedSpots(List<double> xs, List<double> ys) {
  final spots = <FlSpot>[];
  if (xs.isEmpty || ys.isEmpty) return spots;
  final n = xs.length < ys.length ? xs.length : ys.length;
  for (int i = 0; i < n; i++) {
    final x = xs[i];
    final y = ys[i];
    if (i == 0) {
      spots.add(FlSpot(x, y));
    } else {
      // duplicate x with prev y to create horizontal step
      spots.add(FlSpot(x, ys[i - 1]));
      spots.add(FlSpot(x, y));
    }
  }
  return spots;
}