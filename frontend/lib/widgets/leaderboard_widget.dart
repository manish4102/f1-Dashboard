/// lib/widgets/leaderboard_widget.dart
import 'package:flutter/material.dart';

class _TeamAssets {
  final String carFront;
  final String logo;

  const _TeamAssets({required this.carFront, required this.logo});
}

class LeaderboardWidget extends StatelessWidget {
  final List<dynamic> leaderboard;
  final dynamic payload;

  const LeaderboardWidget({
    super.key,
    required this.leaderboard,
    required this.payload,
  });

  // Use a single primary color per team (solid fill), not a gradient.
  static const Map<String, Color> teamColor = {
    'mclaren': Color(0xFFFF7A00),
    'redbull': Color(0xFF1C3D7A),
    'ferrari': Color(0xFFD00019),
    'mercedes': Color(0xFF00D2BE),
    'astonmartin': Color(0xFF0A6B5B),
    'alpine': Color.fromARGB(255, 195, 42, 255),
    'williams': Color(0xFF005AFF),
    'haas': Color(0xFFB0B0B0),
    'stake': Color(0xFF00C853),
    'rb': Color(0xFF6C5CE7),
    'default': Color(0xFF2B2B2B),
  };

  static const Map<String, _TeamAssets> teamAssets = {
    'mclaren': _TeamAssets(
      carFront: 'assets/images/cars/mclaren.png',
      logo: 'assets/images/logos/mclaren.png',
    ),
    'ferrari': _TeamAssets(
      carFront: 'assets/images/cars/ferrari.png',
      logo: 'assets/images/logos/ferrari.png',
    ),
    'mercedes': _TeamAssets(
      carFront: 'assets/images/cars/mercedes.png',
      logo: 'assets/images/logos/mercedes.png',
    ),
    'redbull': _TeamAssets(
      carFront: 'assets/images/cars/redbull.png',
      logo: 'assets/images/logos/redbull.png',
    ),
    'astonmartin': _TeamAssets(
      carFront: 'assets/images/cars/aston_martin.png',
      logo: 'assets/images/logos/aston_martin.png',
    ),
    'alpine': _TeamAssets(
      carFront: 'assets/images/cars/alpine.png',
      logo: 'assets/images/logos/alpine.png',
    ),
    'williams': _TeamAssets(
      carFront: 'assets/images/cars/williams.png',
      logo: 'assets/images/logos/williams.png',
    ),
    'haas': _TeamAssets(
      carFront: 'assets/images/cars/haas.png',
      logo: 'assets/images/logos/haas_nobg.png',
    ),
    'stake': _TeamAssets(
      carFront: 'assets/images/cars/stake.png',
      logo: 'assets/images/logos/stake.png',
    ),
    'rb': _TeamAssets(
      carFront: 'assets/images/cars/rb.png',
      logo: 'assets/images/logos/rb.png',
    ),
    'default': _TeamAssets(
      carFront: 'assets/images/f1_car.png',
      logo: 'assets/images/f1_logo.png',
    ),
  };

  static const Map<String, String> teamAliases = {
    'mclaren': 'mclaren',
    'mc laren': 'mclaren',
    'ferrari': 'ferrari',
    'mercedes': 'mercedes',
    'mercedes-amg': 'mercedes',
    'mercedes amg': 'mercedes',
    'red bull': 'redbull',
    'red bull racing': 'redbull',
    'oracle red bull racing': 'redbull',
    'aston martin': 'astonmartin',
    'astonmartin': 'astonmartin',
    'alpine': 'alpine',
    'williams': 'williams',
    'haas': 'haas',
    'stake': 'stake',
    'stake f1 team': 'stake',
    'sauber': 'stake',
    'kick sauber': 'stake',
    'kick': 'stake',
    'rb': 'rb',
    'vcarb': 'rb',
    'visa cash app rb': 'rb',
    'visa cash app': 'rb',
    'alphatauri': 'rb',
    'toro rosso': 'rb',
    'racingbulls': 'rb',
  };

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

  @override
  Widget build(BuildContext context) {
    final rows =
        leaderboard
            .map((e) => Map<String, dynamic>.from(e ?? {}))
            .where((m) => (m['position'] != null))
            .toList()
          ..sort((a, b) {
            final pa = int.tryParse('${a['position']}') ?? 999;
            final pb = int.tryParse('${b['position']}') ?? 999;
            return pa.compareTo(pb);
          });

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'No leaderboard data available.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // ✅ Race leader baseline: smallest absolute "Time" among rows that have a parsable time.
    final parsedTimes = rows
        .map(_extractAbsRaceTimeSeconds)
        .where((t) => t != null)
        .cast<double>()
        .toList();

    final leaderAbsSeconds = parsedTimes.isEmpty
        ? null
        : parsedTimes.reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const _Header(),
        // const SizedBox(height: 12),
        ...rows.take(20).map((r) => _row(context, r, leaderAbsSeconds)),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    Map<String, dynamic> r,
    double? leaderAbsSeconds,
  ) {
    final pos = int.tryParse('${r['position']}') ?? 0;
    final code = (r['driver_code'] ?? '—').toString().trim().toUpperCase();
    final teamKey = _resolveTeamKey(r);

    final c = teamColor[teamKey] ?? teamColor['default']!;
    final assets = teamAssets[teamKey] ?? teamAssets['default']!;

    final driverName =
        driverFullNames[code] ?? (r['driver_name'] ?? code).toString();
    final teamName = (r['team_name'] ?? '').toString().trim();
    final teamLabel = teamName.isNotEmpty ? teamName : _prettyTeam(teamKey);

    final absSeconds = _extractAbsRaceTimeSeconds(r);
    final fallback = _fallbackStatus(r);

    final timeLabel = _raceTvTimeLabel(
      pos: pos,
      absSeconds: absSeconds,
      leaderAbsSeconds: leaderAbsSeconds,
      fallback: fallback,
    );

    // Sizing tuned for your screenshot
    const double rowH = 86;
    const double leftRankW = 92; // big number column
    const double timeW = 120;
    const double logoW = 118;
    const double radius = 18;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: rowH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Row(
          children: [
            // [1] LEFT RANK BLOCK (ONLY ONE NUMBER — BIG)
            Container(
              width: leftRankW,
              height: double.infinity,
              color: Colors.black,
              alignment: Alignment.center,
              child: Text(
                '$pos',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 62,
                  height: 1.0,
                ),
              ),
            ),

            // [2] MAIN COLOR BAR (SOLID COLOR LEFT->RIGHT) + car + text
            Expanded(
              child: Container(
                height: double.infinity,
                color: c, // ✅ solid color
                child: Stack(
                  children: [
                    // car bottom-left
                    Positioned(
                      left: 12,
                      bottom: 6,
                      child: SizedBox(
                        width: 132,
                        height: 58,
                        child: Image.asset(
                          assets.carFront,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),

                    // text
                    Padding(
                      padding: const EdgeInsets.only(left: 156, right: 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            teamLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // [3] TIME COLUMN
            Container(
              width: timeW,
              height: double.infinity,
              alignment: Alignment.center,
              color: Colors.black.withOpacity(0.12),
              child: pos == 1
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LEADER',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : Text(
                      timeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
            ),

            // [4] LOGO PANEL (✅ SAME TEAM COLOR BEHIND LOGO)
            Container(
              width: logoW,
              height: double.infinity,
              color: c, // ✅ team color continues behind logo
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Image.asset(
                    assets.logo,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- Time Logic (Race TV style) -----------------

  String _fallbackStatus(Map<String, dynamic> row) {
    // You can adjust these to your backend keys.
    final candidates = [
      row['status'],
      row['result'],
      row['dnf'],
      row['laps_down'],
      row['gap'],
    ];

    for (final c in candidates) {
      final s = (c ?? '').toString().trim();
      if (s.isEmpty) continue;
      if (s == '.' || s == '—' || s.toLowerCase() == 'null') continue;
      return s;
    }
    return '';
  }

  /// TV label rules (Race):
  /// - P1: show total time (H:MM:SS.mmm or M:SS.mmm)
  /// - others: show gap to leader
  ///     < 60s  => +S.mmm   (e.g. +5.123)
  ///     >= 60s => +M:SS.mmm (e.g. +1:12.400)
  String _raceTvTimeLabel({
    required int pos,
    required double? absSeconds,
    required double? leaderAbsSeconds,
    required String fallback,
  }) {
    if (pos == 1) {
      if (absSeconds != null) return _fmtRaceClock(absSeconds);
      return 'Leader';
    }

    if (absSeconds == null || leaderAbsSeconds == null) {
      return fallback.isNotEmpty ? fallback : '—';
    }

    final gap = absSeconds - leaderAbsSeconds;

    // Round to nearest thousandth
    final rounded = (gap * 1000).round() / 1000.0;
    final safe = (rounded.abs() < 0.0005) ? 0.0 : rounded;

    return _fmtGapTv(safe);
  }

  /// Extract absolute race/session time from backend row.
  /// Supports common keys + pandas Timedelta-like strings.
  double? _extractAbsRaceTimeSeconds(Map<String, dynamic> row) {
    // If your backend ever gives seconds directly:
    final v = row['total_time_s'] ?? row['time_s'];
    final asNum = _asDouble(v);
    if (asNum != null) return asNum;

    // Try multiple likely keys (FastF1 often uses "Time" with uppercase in dataframes)
    final raw = _firstNonEmptyString(row, const [
      'time',
      'Time',
      'race_time',
      'session_time',
    ]);
    if (raw == null) return null;

    return _parseAnyTimeToSeconds(raw);
  }

  String? _firstNonEmptyString(Map<String, dynamic> row, List<String> keys) {
    for (final k in keys) {
      final v = row[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isEmpty) continue;
      if (s == '.' || s == '—' || s.toLowerCase() == 'null') continue;
      return s;
    }
    return null;
  }

  /// Parses:
  /// - FastF1/pandas Timedelta: "0 days 01:24:10.452000"
  /// - With days: "2 days 00:00:01.000000"
  /// - "HH:MM:SS.mmm" / "HH:MM:SS.ffffff"
  /// - Backend colon-ms: "HH:MM:SS:MS"
  /// - Quali style: "M:SS.mmm"
  double? _parseAnyTimeToSeconds(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;

    // 1) pandas Timedelta: "0 days 01:24:10.452000"
    final td = RegExp(
      r'^(?:(\d+)\s+days?\s+)?(\d{1,2}):(\d{2}):(\d{2})(?:\.(\d{1,9}))?$',
      caseSensitive: false,
    ).firstMatch(s);
    if (td != null) {
      final days = int.tryParse(td.group(1) ?? '0') ?? 0;
      final hh = int.tryParse(td.group(2) ?? '0') ?? 0;
      final mm = int.tryParse(td.group(3) ?? '0') ?? 0;
      final ss = int.tryParse(td.group(4) ?? '0') ?? 0;

      final fracRaw = td.group(5); // up to nanoseconds
      final fracSec = _fractionToSeconds(fracRaw);

      return (days * 86400) + (hh * 3600) + (mm * 60) + ss + fracSec;
    }

    // 2) Backend "HH:MM:SS:MS" (ms separated by colon)
    final colonMs = RegExp(
      r'^(?:(\d+)\s+days?\s+)?(\d{1,2}):(\d{2}):(\d{2}):(\d{1,6})$',
      caseSensitive: false,
    ).firstMatch(s);
    if (colonMs != null) {
      final days = int.tryParse(colonMs.group(1) ?? '0') ?? 0;
      final hh = int.tryParse(colonMs.group(2) ?? '0') ?? 0;
      final mm = int.tryParse(colonMs.group(3) ?? '0') ?? 0;
      final ss = int.tryParse(colonMs.group(4) ?? '0') ?? 0;
      final msRaw = colonMs.group(5) ?? '0';

      // Normalize:
      // - if "12" assume centiseconds => 0.120s
      // - if "452" milliseconds => 0.452s
      // - if "452000" microseconds => 0.452000s
      final frac = _msLikeToSeconds(msRaw);

      return (days * 86400) + (hh * 3600) + (mm * 60) + ss + frac;
    }

    // 3) Quali style "M:SS.mmm"
    final quali = RegExp(r'^(\d+):(\d{2})(?:\.(\d{1,9}))?$').firstMatch(s);
    if (quali != null) {
      final m = int.tryParse(quali.group(1) ?? '0') ?? 0;
      final sec = int.tryParse(quali.group(2) ?? '0') ?? 0;
      final frac = _fractionToSeconds(quali.group(3));
      return (m * 60) + sec + frac;
    }

    // 4) Raw numeric seconds "123.456"
    final numeric = double.tryParse(s.replaceAll('s', '').trim());
    if (numeric != null) return numeric;

    return null;
  }

  double _fractionToSeconds(String? fracRaw) {
    if (fracRaw == null || fracRaw.isEmpty) return 0.0;
    // fracRaw could be 1..9 digits representing fractions of a second.
    // "452000" => 0.452000
    final digits = fracRaw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0.0;
    final padded = digits.length >= 9
        ? digits.substring(0, 9)
        : digits.padRight(9, '0');
    final nanos = int.tryParse(padded) ?? 0;
    return nanos / 1e9;
  }

  double _msLikeToSeconds(String msLike) {
    final digits = msLike.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0.0;

    // Heuristic:
    // 1-2 digits => centiseconds (cc)  (e.g. "12" => 0.120)
    // 3 digits => milliseconds (mmm)   (e.g. "452" => 0.452)
    // 4-6 digits => microseconds-ish   (e.g. "452000" => 0.452000)
    if (digits.length <= 2) {
      final cs = int.tryParse(digits) ?? 0;
      return (cs * 10) / 1000.0;
    }
    if (digits.length == 3) {
      final ms = int.tryParse(digits) ?? 0;
      return ms / 1000.0;
    }
    // microseconds (pad to 6)
    final padded = digits.length >= 6
        ? digits.substring(0, 6)
        : digits.padRight(6, '0');
    final micros = int.tryParse(padded) ?? 0;
    return micros / 1e6;
  }

  /// Leader total time format like TV: "1:32:10.452" or "24:10.452"
  String _fmtRaceClock(double totalSeconds) {
    final msTotal = (totalSeconds * 1000).round();
    final ms = msTotal % 1000;
    int s = (msTotal ~/ 1000);

    final hh = s ~/ 3600;
    s %= 3600;
    final mm = s ~/ 60;
    final ss = s % 60;

    if (hh > 0) {
      return '$hh:${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
    }
    // no hours
    return '${mm.toString()}:${ss.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
  }

  /// Gap format like TV:
  /// <60s: "+5.123"
  /// >=60s: "+1:12.400"
  String _fmtGapTv(double gapSeconds) {
    final sign = gapSeconds >= 0 ? '+' : '-';
    final abs = gapSeconds.abs();

    final msTotal = (abs * 1000).round();
    final ms = msTotal % 1000;
    int s = (msTotal ~/ 1000);

    if (s < 60) {
      final sec = s.toString();
      return '$sign$sec.${ms.toString().padLeft(3, '0')}';
    }

    final mm = s ~/ 60;
    final ss = s % 60;
    return '$sign$mm:${ss.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim());
  }

  // ----------------- Existing Helpers -----------------

  String _resolveTeamKey(Map<String, dynamic> row) {
    final explicit = (row['team_key'] ?? '').toString().trim().toLowerCase();
    if (explicit.isNotEmpty) {
      final aliased = teamAliases[explicit] ?? explicit;
      return teamAssets.containsKey(aliased) ? aliased : 'default';
    }

    final name = (row['team_name'] ?? '').toString().trim().toLowerCase();
    if (name.isEmpty) return 'default';

    if (teamAliases.containsKey(name)) return teamAliases[name]!;

    for (final entry in teamAliases.entries) {
      if (name.contains(entry.key)) return entry.value;
    }

    return 'default';
  }

  String _prettyTeam(String k) {
    switch (k) {
      case 'redbull':
        return 'Red Bull Racing';
      case 'astonmartin':
        return 'Aston Martin';
      default:
        if (k.isEmpty) return '—';
        return '${k[0].toUpperCase()}${k.substring(1)}';
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.leaderboard, color: Colors.white70, size: 18),
        SizedBox(width: 8),
        Text(
          'LEADERBOARD',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
