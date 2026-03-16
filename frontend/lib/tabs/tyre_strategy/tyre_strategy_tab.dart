import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../shell/session_provider.dart';
import '../../theme/glow.dart';
import '../../widgets/f1_dropdown.dart';

class TyreStrategyTab extends ConsumerStatefulWidget {
  const TyreStrategyTab({super.key});

  @override
  ConsumerState<TyreStrategyTab> createState() => _TyreStrategyTabState();
}

class _TyreStrategyTabState extends ConsumerState<TyreStrategyTab> {
  final ApiClient _api = ApiClient(baseUrl: "http://localhost:8001");

  int _defaultSeason = 2025;
  int _defaultRound = 24;
  String _defaultSessionName = "Race";

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(sessionProvider);
    final payload = st.full;

    if (payload == null) {
      return _buildEmptyState("Load a session to view Tyre Strategy.");
    }

    final ts = _asMap(payload.tyreStrategy);
    final drivers = _asList(ts["drivers"]);

    final lapCharts = _asMap(payload.lapCharts);
    final totalLaps = _asInt(lapCharts["laps_count"]) ?? 60;

    if (drivers.isEmpty) {
      return _buildEmptyState("No tyre stint data available for this session.");
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
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
              _buildLegend(),
              const SizedBox(height: 20),
              ...drivers.asMap().entries.map((entry) {
                final idx = entry.key;
                final d = entry.value;
                final dm = _asMap(d);
                final code =
                    (dm["driver_code"] ?? dm["code"] ?? dm["driver"] ?? "—")
                        .toString();

                final stintsRaw = _asList(dm["stints"]);
                final stints = stintsRaw.map((s) => _asMap(s)).toList();

                if (stints.isEmpty) {
                  return _driverCardNoData(context, payload, code, idx);
                }
                return _driverCard(context, payload, code, stints, totalLaps, idx);
              }),
              const SizedBox(height: 24),
            ],
          ),
          Positioned(
            top: 120,
            left: 16,
            right: 16,
            child: _buildTyreStrategyDropdown(st),
          ),
        ],
      ),
    );
  }

  Widget _buildTyreStrategyDropdown(dynamic st) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
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
            child: _TyreStrategyDropdownWidget(
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

  Widget _buildEmptyState(String message) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.layers_outlined,
                size: 56,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade900.withValues(alpha: 0.7),
            Colors.red.shade700.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.layers, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tyre Strategy",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Race tyre compound & stint analysis",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return GlowCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.palette,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "TYRE COMPOUNDS",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 18,
            runSpacing: 14,
            children: [
              _compoundBadge("SOFT"),
              _compoundBadge("MEDIUM"),
              _compoundBadge("HARD"),
              _compoundBadge("INTER"),
              _compoundBadge("WET"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compoundBadge(String label) {
    final color = _compoundColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: _getTyreImage(label, 28),
          ),
          const SizedBox(width: 10),
          Text(
            label == "INTER" ? "INTERMEDIATE" : label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverCardNoData(
    BuildContext context,
    dynamic payload,
    String code,
    int index,
  ) {
    final color = _driverColor(payload, code);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _buildDriverAvatar(code, color, 44),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.remove_circle_outline,
                    color: Colors.white38,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "No Data",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _driverCard(
    BuildContext context,
    dynamic payload,
    String code,
    List<Map<String, dynamic>> stints,
    int totalLaps,
    int index,
  ) {
    final color = _driverColor(payload, code);

    final normalized =
        stints.map((s) {
          final compound =
              (s["compound"] ?? s[" tyre"] ?? s["Compound"] ?? "—").toString();
          final lapStart = _asInt(s["lap_start"]) ?? _asInt(s["start"]) ?? 1;
          final lapEnd = _asInt(s["lap_end"]) ?? _asInt(s["end"]) ?? lapStart;
          return {
            "compound": compound,
            "lap_start": lapStart,
            "lap_end": lapEnd,
          };
        }).toList()
          ..sort(
            (a, b) =>
                (a["lap_start"] as int).compareTo(b["lap_start"] as int),
          );

    final computedMaxEnd = normalized.fold<int>(
      0,
      (m, s) => (s["lap_end"] as int) > m ? (s["lap_end"] as int) : m,
    );
    final laps = totalLaps > computedMaxEnd ? totalLaps : computedMaxEnd;

    final totalStintLaps = normalized.fold<int>(0, (sum, s) {
      final start = s["lap_start"] as int;
      final end = s["lap_end"] as int;
      return sum + (end - start + 1);
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildDriverAvatar(code, color, 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _infoChip(
                            "${normalized.length} stint${normalized.length > 1 ? 's' : ''}",
                          ),
                          const SizedBox(width: 8),
                          _infoChip("$laps lap race"),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withValues(alpha: 0.2),
                        Colors.red.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "$totalStintLaps",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.redAccent,
                        ),
                      ),
                      const Text(
                        "LAPS",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white54,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTyreBar(normalized),
            const SizedBox(height: 20),
            _buildStintDetails(normalized),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverAvatar(String code, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        code.length >= 3 ? code.substring(0, 3) : code,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: size * 0.38,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTyreBar(List<Map<String, dynamic>> normalized) {
    const barHeight = 42.0;
    const radius = 12.0;

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Row(
          children: normalized.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;

            final start = s["lap_start"] as int;
            final end = s["lap_end"] as int;
            final len = (end - start + 1).clamp(1, 9999);

            final compound = (s["compound"] as String).toUpperCase();
            final fill = _compoundColor(compound);
            final isFirst = i == 0;

            return Expanded(
              flex: len,
              child: Container(
                decoration: BoxDecoration(
                  color: fill,
                  border: Border(
                    left: isFirst
                        ? BorderSide.none
                        : BorderSide(
                            color: Colors.black.withValues(alpha: 0.65),
                            width: 2,
                          ),
                    top: BorderSide(
                      color: Colors.black.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: Colors.black.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  "$len",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: len < 4 ? 12 : 16,
                    color: compound == "HARD"
                        ? Colors.black.withValues(alpha: 0.78)
                        : Colors.black.withValues(alpha: 0.72),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStintDetails(List<Map<String, dynamic>> normalized) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: normalized.asMap().entries.map((entry) {
        final s = entry.value;
        final compound = (s["compound"] as String).toUpperCase();
        final start = s["lap_start"] as int;
        final end = s["lap_end"] as int;
        final lapCount = end - start + 1;
        final compoundColor = _compoundColor(compound);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: compoundColor.withValues(alpha: 0.25),
            border: Border.all(
              color: compoundColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: compoundColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: compoundColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: compoundColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: _getTyreImage(compound, 30),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    compound,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: compoundColor.withValues(alpha: 0.8),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Lap $start → $end",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$lapCount laps",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) {
    if (v is List) return v;
    return const <dynamic>[];
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Color _compoundColor(String compound) {
    switch (compound.toUpperCase()) {
      case "SOFT":
        return const Color(0xFFFF4D6D);
      case "MEDIUM":
        return const Color(0xFFFFD166);
      case "HARD":
        return const Color(0xFFE5E5E5);
      case "INTERMEDIATE":
      case "INTER":
        return const Color(0xFF43AA8B);
      case "WET":
        return const Color(0xFF277DA1);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  Widget _getTyreImage(String compound, double size) {
    String imagePath;
    switch (compound.toUpperCase()) {
      case "SOFT":
        imagePath = "assets/images/soft_tyre.png";
        break;
      case "MEDIUM":
        imagePath = "assets/images/medium_tyre.png";
        break;
      case "HARD":
        imagePath = "assets/images/hard_tyre.png";
        break;
      case "INTERMEDIATE":
      case "INTER":
        imagePath = "assets/images/inter_tyre.png";
        break;
      case "WET":
        imagePath = "assets/images/wet_tyre.png";
        break;
      default:
        imagePath = "assets/images/soft_tyre.png";
    }

    return Image.asset(
      imagePath,
      height: size,
      width: size,
      fit: BoxFit.contain,
    );
  }

  Color _driverColor(dynamic payload, String code) {
    final drivers = payload.drivers;
    for (final d in drivers) {
      final m = _asMap(d);
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

class _TyreStrategyDropdownWidget extends StatefulWidget {
  final ApiClient api;
  final int initialSeason;
  final int defaultRound;
  final bool loading;
  final void Function(int season, int round, String sessionName) onLoad;

  const _TyreStrategyDropdownWidget({
    required this.api,
    required this.initialSeason,
    required this.defaultRound,
    required this.loading,
    required this.onLoad,
  });

  @override
  State<_TyreStrategyDropdownWidget> createState() =>
      _TyreStrategyDropdownWidgetState();
}

class _TyreStrategyDropdownWidgetState
    extends State<_TyreStrategyDropdownWidget> {
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