// lib/tabs/lap_charts/lap_charts_tab.dart
import 'dart:convert';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/session_provider.dart';
import '../../widgets/f1_dropdown.dart';
import '../../api/api_client.dart';

class LapChartsTab extends ConsumerStatefulWidget {
  final dynamic payload;
  final Map<String, bool> visible;
  final double zoom;

  static const Map<String, String> driverFullNames = {
    'VER': 'Max Verstappen',
    'NOR': 'Lando Norris',
    'PIA': 'Oscar Piastri',
    'RUS': 'George Russell',
    'HAM': 'Lewis Hamilton',
    'LEC': 'Charles Leclerc',
    'SAI': 'Carlos Sainz',
    'ANT': 'Andrea Kimi Antonelli',
    'ALO': 'Fernando Alonso',
    'STR': 'Lance Stroll',
    'GAS': 'Pierre Gasly',
    'OCO': 'Esteban Ocon',
    'ALB': 'Alex Albon',
    'HUL': 'Nico Hülkenberg',
    'MAG': 'Kevin Magnussen',
    'BOT': 'Valtteri Bottas',
    'ZHO': 'Zhou Guanyu',
    'TSU': 'Yuki Tsunoda',
    'RIC': 'Daniel Ricciardo',
    'LAW': 'Liam Lawson',
    'PER': 'Sergio Pérez',
  };

  String _getDriverLabel(String code) {
    final name = driverFullNames[code.toUpperCase()] ?? code;
    return '$code - $name';
  }

  const LapChartsTab({
    super.key,
    required this.payload,
    required this.visible,
    required this.zoom,
  });

  @override
  ConsumerState<LapChartsTab> createState() => _LapChartsTabState();
}

class _LapChartsTabState extends ConsumerState<LapChartsTab> {
  final ApiClient _api = ApiClient();

  int _defaultSeason = 2026;
  int _defaultRound = 1;
  String _defaultSessionName = "Race";
  bool _loadedDefault = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadDefaultOnce();
    });
  }

  Future<void> _fetchCurrentSession() async {
    try {
      final resp = await _api.client.get(
        Uri.parse('${_api.baseUrl}/api/current'),
      );
      if (resp.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(resp.body));
        setState(() {
          _defaultSeason =
              int.tryParse(data['season']?.toString() ?? '2026') ?? 2026;
          _defaultRound = int.tryParse(data['round']?.toString() ?? '1') ?? 1;
          _defaultSessionName = data['session']?.toString() ?? 'Race';
        });
      }
    } catch (_) {}
  }

  void _loadDefaultOnce() {
    if (_loadedDefault) return;
    _loadedDefault = true;
    final st = ref.read(sessionProvider);
    if (st.full != null || st.loading) return;
    ref
        .read(sessionProvider.notifier)
        .load(
          season: _defaultSeason,
          round: _defaultRound,
          sessionName: _defaultSessionName,
        );
  }

  Future<void> _loadSelected({
    required int season,
    required int round,
    required String sessionName,
  }) async {
    await ref
        .read(sessionProvider.notifier)
        .load(season: season, round: round, sessionName: sessionName);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(sessionProvider);
    const double floatingNavOffset = 120;

    final lc = _asMap(widget.payload.lapCharts);
    final laps = _asList(lc["laps"]);
    final series = _asMap(lc["series"]);

    if (series.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            _buildDropdown(st),
            Expanded(
              child: const SafeArea(
                child: Center(
                  child: Text(
                    "No lap chart series data found in payload.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildDropdown(st),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
                child: _chart(context, widget.payload, laps, series),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(dynamic st) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chart(
    BuildContext context,
    dynamic payload,
    List<dynamic> laps,
    Map<String, dynamic> series,
  ) {
    final bars = <LineChartBarData>[];

    double? globalMin;
    double? globalMax;

    for (final entry in series.entries) {
      final code = entry.key;
      if (!(widget.visible[code] ?? true)) continue;

      final driverObj = _asMap(entry.value);
      final lts = _asList(driverObj["lap_times_s"]);

      final spots = <FlSpot>[];
      for (int i = 0; i < lts.length && i < laps.length; i++) {
        final v = lts[i];
        if (v == null || v is! num) continue;

        final xVal = laps[i];
        if (xVal is! num) continue;

        final y = v.toDouble();
        final x = xVal.toDouble();

        spots.add(FlSpot(x, y));
        globalMin = globalMin == null ? y : (y < globalMin! ? y : globalMin);
        globalMax = globalMax == null ? y : (y > globalMax! ? y : globalMax);
      }

      if (spots.isEmpty) continue;

      final color = _driverColor(payload, code);
      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          color: color,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    if (bars.isEmpty || globalMin == null || globalMax == null) {
      return const Center(
        child: Text(
          "No lap time data available for this session.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final mid = (globalMin! + globalMax!) / 2.0;
    final half = (globalMax - globalMin) / 2.0;
    final z = widget.zoom;
    final minY = mid - half * z;
    final maxY = mid + half * z;

    final intervalX = (laps.length / 6).clamp(1, 10).toDouble();
    final intervalY = (((maxY - minY) / 5).clamp(1, 20)).toDouble();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.08),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: intervalX,
              getTitlesWidget: (v, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "L${v.toInt()}",
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: intervalY,
              getTitlesWidget: (v, meta) => Text(
                "${v.toStringAsFixed(0)}s",
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: bars,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.9),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                String driverCode = '';
                for (final entry in series.entries) {
                  if (!(widget.visible[entry.key] ?? true)) continue;
                  final driverObj = _asMap(entry.value);
                  final lts = _asList(driverObj["lap_times_s"]);
                  if (lts.isNotEmpty && spot.x >= 0 && spot.x < lts.length) {
                    final yVal = lts[spot.x.toInt()];
                    if (yVal == spot.y) {
                      driverCode = entry.key;
                      break;
                    }
                  }
                }
                return LineTooltipItem(
                  '$driverCode\n${spot.y.toStringAsFixed(3)}s',
                  TextStyle(
                    color: spot.bar.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v == null) return <String, dynamic>{};
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String) {
      final decoded = jsonDecode(v);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic v) {
    if (v == null) return <dynamic>[];
    if (v is List) return v;
    return <dynamic>[];
  }

  Color _driverColor(dynamic payload, String code) {
    final drivers = payload.drivers;
    for (final d in drivers) {
      final m = d is Map<String, dynamic>
          ? d
          : Map<String, dynamic>.from(d as Map);
      if ((m["code"] ?? "") == code) {
        final hex = (m["color"] ?? "#90A4AE") as String;
        return _hexToColor(hex);
      }
    }
    return const Color(0xFF90A4AE);
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll("#", "");
    final v = int.tryParse("FF$h", radix: 16) ?? 0xFF90A4AE;
    return Color(v);
  }
}
