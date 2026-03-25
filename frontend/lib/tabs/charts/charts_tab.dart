// lib/tabs/charts/charts_tab.dart
import 'dart:convert';
import 'dart:ui';

import 'package:f1/tabs/charts/widgets/brake_chart_widget.dart';
import 'package:f1/tabs/charts/widgets/throttle_chart_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/shell/session_provider.dart';
import '/theme/glow.dart';
import '/api/api_client.dart';
import '/widgets/f1_dropdown.dart';
import '/widgets/f1_snackbar.dart';

// Lap charts renderer (must accept payload/visible/zoom)
import '/tabs/lap_charts/lap_charts_tab.dart';

// Telemetry UI (edit sheet + factor list)
import 'widgets/telemetry_factor_registry.dart';
import 'widgets/telemetry_factor_sheet.dart';

// ✅ Dashboard-style telemetry widgets (updated)
import 'widgets/speed_chart_widget.dart';
import 'widgets/drs_chart_widget.dart';
import 'widgets/pedals_dashboard_widget.dart';
import 'widgets/engine_rpm_chart_widget.dart';
import 'widgets/gear_chart_widget.dart';

class ChartsTab extends ConsumerStatefulWidget {
  const ChartsTab({super.key});

  @override
  ConsumerState<ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends ConsumerState<ChartsTab> {
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

  String _getDriverFullName(String code) {
    return driverFullNames[code.toUpperCase()] ?? code;
  }

  // ✅ driver visibility (single source of truth)
  final Map<String, bool> visibleDrivers = {};

  // ✅ zoom for lap charts (single source of truth)
  double lapZoom = 1.0;

  // API client for dropdown
  final ApiClient _api = ApiClient();

  int _defaultSeason = 2026;
  int _defaultRound = 1;
  String _defaultSessionName = "Race";

  // ✅ telemetry factor selection (defaults)
  final Set<String> selectedFactors = {
    TelemetryFactors.speed,
    TelemetryFactors.drs,
  };

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(sessionProvider);
    final payload = st.full;
    if (payload == null) {
      return const Center(child: Text("Load a session to view Charts."));
    }

    if (st.justLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          F1Snackbar.success(context, 'Charts loaded successfully!');
        }
      });
    }

    // Initialize driver visibility once
    final drivers = _asList(payload.drivers);
    if (visibleDrivers.isEmpty) {
      for (final d in drivers) {
        final m = _asMap(d);
        final code = (m["code"] ?? "").toString().trim();
        if (code.isNotEmpty) visibleDrivers[code] = true;
      }
    }

    // ✅ telemetry (backend sends telemetry_charts; your FullPayload getter should map it to telemetryCharts)
    final tc = _asMap(payload.telemetryCharts);
    final series = _asMap(tc["series"]);
    final x = _asList(tc["x"]);
    final xType = (tc["x_type"] ?? "distance_m").toString();

    final hasTelemetry = series.isNotEmpty && x.isNotEmpty;

    return Container(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Content that scrolls behind
          ListView(
            padding: const EdgeInsets.only(
              top: 220,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildDriverChips(payload, visibleDrivers),
              const SizedBox(height: 24),
              _buildLapChartsSection(payload, visibleDrivers),
              const SizedBox(height: 24),
              _buildTelemetrySection(payload, x, xType, series),
              const SizedBox(height: 24),
            ],
          ),
          // Fixed dropdown at top with glass effect
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: _buildLapChartsDropdown(st),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTelemetryDashboards({
    required dynamic payload,
    required List<dynamic> x,
    required String xType,
    required Map<String, dynamic> series,
  }) {
    // Filter visible drivers only
    final shownCodes = visibleDrivers.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    if (shownCodes.isEmpty) {
      return const [
        Text(
          "Select at least one driver to view telemetry.",
          style: TextStyle(color: Colors.white70),
        ),
      ];
    }

    // Use last sample by default (later you can wire a cursor indexOverride)
    final idx = x.isEmpty ? 0 : x.length - 1;

    final widgets = <Widget>[];

    bool addedPedals = false;

    for (final key in selectedFactors) {
      switch (key) {
        case TelemetryFactors.speed:
          widgets.add(
            SpeedChartWidget(
              payload: payload,
              x: x,
              xType: xType,
              series: series,
              enabledCodes: shownCodes,
            ),
          );
          break;

        case TelemetryFactors.drs:
          widgets.add(
            DRSChartWidget(
              payload: payload,
              x: x,
              xType: xType,
              series: series,
              enabledCodes: shownCodes,
            ),
          );
          break;

        // ✅ Combine throttle + brake into ONE rendering pass
        case TelemetryFactors.throttle:
        case TelemetryFactors.brake:
          if (!addedPedals) {
            widgets.add(
              ThrottleChartWidget(
                payload: payload,
                x: x,
                xType: xType,
                series: series,
                enabledCodes: shownCodes,
              ),
            );

            widgets.add(
              BrakeChartWidget(
                payload: payload,
                x: x,
                xType: xType,
                series: series,
                enabledCodes: shownCodes,
              ),
            );

            addedPedals = true;
          }
          break;

        case TelemetryFactors.engineRpm:
          widgets.add(
            EngineRPMChartWidget(
              payload: payload,
              x: x,
              xType: xType,
              series: series,
              enabledCodes: shownCodes,
            ),
          );
          break;

        case TelemetryFactors.gear:
          widgets.add(
            GearChartWidget(
              payload: payload,
              x: x,
              xType: xType,
              series: series,
              enabledCodes: shownCodes,
            ),
          );
          break;
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        const Text(
          "Tap Edit to select telemetry charts.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return widgets
        .map(
          (w) => Padding(padding: const EdgeInsets.only(bottom: 14), child: w),
        )
        .toList();
  }

  // ---------- helpers ----------
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
    final drivers = _asList(payload.drivers);
    for (final d in drivers) {
      final m = _asMap(d);
      if ((m["code"] ?? "").toString() == code) {
        final hex = (m["color"] ?? "#90A4AE").toString();
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade900.withOpacity(0.6),
            Colors.red.shade700.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Telemetry Dashboard",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Real-time driver performance analysis",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              _editButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final next = await showTelemetryFactorSheet(
          context: context,
          selected: selectedFactors,
        );
        if (next != null) {
          setState(() {
            selectedFactors
              ..clear()
              ..addAll(next);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              "Configure",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverChips(dynamic payload, Map<String, bool> visibleDrivers) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.group,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Select Drivers",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                "${visibleDrivers.values.where((v) => v).length} selected",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleDrivers.keys.map((code) {
              final isOn = visibleDrivers[code] ?? true;
              final color = _driverColor(payload, code);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: FilterChip(
                  selected: isOn,
                  label: Text(
                    _getDriverFullName(code),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOn ? Colors.white : Colors.white60,
                    ),
                  ),
                  avatar: isOn
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  selectedColor: color.withOpacity(0.3),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  side: BorderSide(
                    color: isOn
                        ? color.withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                  onSelected: (v) => setState(() => visibleDrivers[code] = v),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLapChartsSection(
    dynamic payload,
    Map<String, bool> visibleDrivers,
  ) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                "LAP CHARTS",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              _zoomControls(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 420,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.none,
            child: LapChartsTab(
              payload: payload,
              visible: visibleDrivers,
              zoom: lapZoom,
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 18),
            onPressed: () =>
                setState(() => lapZoom = (lapZoom * 0.85).clamp(0.6, 2.0)),
            color: Colors.white70,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "${lapZoom.toStringAsFixed(1)}x",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: () => setState(() => lapZoom = 1.0),
            color: Colors.white70,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetrySection(
    dynamic payload,
    List<dynamic> x,
    String xType,
    Map<String, dynamic> series,
  ) {
    final hasTelemetry = series.isNotEmpty && x.isNotEmpty;

    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                "TELEMETRY",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (selectedFactors.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${selectedFactors.length} charts",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasTelemetry)
            _buildEmptyState()
          else
            ..._buildTelemetryDashboards(
              payload: payload,
              x: x,
              xType: xType,
              series: series,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Column(
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: Colors.white30),
          SizedBox(height: 12),
          Text(
            "No telemetry data available",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Load a session with telemetry data to view charts",
            style: TextStyle(fontSize: 13, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required VoidCallback onTap,
    bool isIconOnly = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isIconOnly ? 14 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildLapChartsDropdown(dynamic st) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: _LapChartsDropdownWidget(
              api: _api,
              initialSeason: _defaultSeason,
              defaultRound: _defaultRound,
              loading: st.loading,
              onLoad: (season, round, sessionName) => _loadSelected(
                season: season,
                round: round,
                sessionName: sessionName,
              ),
            ),
          ),
        ),
      ),
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
}

class _LapChartsDropdownWidget extends StatefulWidget {
  final ApiClient api;
  final int initialSeason;
  final int defaultRound;
  final bool loading;
  final void Function(int season, int round, String sessionName) onLoad;

  const _LapChartsDropdownWidget({
    required this.api,
    required this.initialSeason,
    required this.defaultRound,
    required this.loading,
    required this.onLoad,
  });

  @override
  State<_LapChartsDropdownWidget> createState() =>
      _LapChartsDropdownWidgetState();
}

class _LapChartsDropdownWidgetState extends State<_LapChartsDropdownWidget> {
  late int _season;
  List<GpEventLite> _events = [];
  GpEventLite? _event;
  GpSessionLite? _session;
  bool _loadingSchedule = false;

  @override
  void initState() {
    super.initState();
    _season = widget.initialSeason;
    _loadSchedule(pickDefaultEvent: true);
  }

  Future<void> _loadSchedule({required bool pickDefaultEvent}) async {
    setState(() {
      _loadingSchedule = true;
      _events = [];
      _event = null;
      _session = null;
    });

    try {
      final events = await widget.api.getSchedule(season: _season);
      setState(() {
        _events = events;
        if (pickDefaultEvent && events.isNotEmpty) {
          _event = events.firstWhere(
            (e) => e.round == widget.defaultRound,
            orElse: () => events.first,
          );
          _session = null;
        }
      });
    } finally {
      if (mounted) setState(() => _loadingSchedule = false);
    }
  }

  void _loadNow() {
    final ev = _event;
    final ses = _session;
    if (ev == null || ses == null) return;
    widget.onLoad(_season, ev.round, ses.name);
  }

  @override
  Widget build(BuildContext context) {
    final seasons = List.generate(10, (i) => widget.initialSeason - i);
    final sessions = _event?.sessions ?? const <GpSessionLite>[];
    final canLoad =
        !widget.loading &&
        !_loadingSchedule &&
        _event != null &&
        _session != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Material(
        color: const Color.fromARGB(0, 255, 255, 255),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            F1Dropdown<int>(
              width: 160,
              value: _season,
              placeholder: 'Season',
              prefixIcon: const Icon(
                Icons.calendar_today,
                size: 18,
                color: Color(0xFFB6BCCB),
              ),
              items: seasons
                  .map((y) => F1DropdownItem<int>(value: y, label: '$y'))
                  .toList(),
              onChanged: (y) {
                setState(() {
                  _season = y;
                  _event = null;
                  _session = null;
                });
                _loadSchedule(pickDefaultEvent: false);
              },
            ),
            const SizedBox(width: 12),
            F1Dropdown<GpEventLite>(
              width: 280,
              value: _event,
              placeholder: _loadingSchedule ? 'Loading…' : 'Grand Prix',
              prefixIcon: const Icon(
                Icons.flag,
                size: 18,
                color: Color(0xFFB6BCCB),
              ),
              isEqual: (a, b) => a.round == b.round,
              items: _events
                  .map(
                    (e) => F1DropdownItem<GpEventLite>(value: e, label: e.name),
                  )
                  .toList(),
              onChanged: (e) {
                setState(() {
                  _event = e;
                  _session = null;
                });
              },
            ),
            const SizedBox(width: 12),
            F1Dropdown<GpSessionLite>(
              width: 180,
              value: _session,
              placeholder: 'Session',
              prefixIcon: const Icon(
                Icons.sports_motorsports,
                size: 18,
                color: Color(0xFFB6BCCB),
              ),
              isEqual: (a, b) => a.name == b.name,
              items: sessions
                  .map(
                    (s) =>
                        F1DropdownItem<GpSessionLite>(value: s, label: s.name),
                  )
                  .toList(),
              onChanged: (s) => setState(() => _session = s),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: canLoad ? _loadNow : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE10600),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: Row(
                  children: [
                    if (widget.loading)
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(
                        Icons.play_arrow,
                        size: 18,
                        color: Colors.white,
                      ),
                    const SizedBox(width: 8),
                    const Text(
                      "Load",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
