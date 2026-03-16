// lib/widgets/podium_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class PodiumWidget extends StatelessWidget {
  final List<dynamic> podium;
  final dynamic payload;

  const PodiumWidget({super.key, required this.podium, required this.payload});

  // ---------------------------------------------------------------------------
  // TEAM ASSET PATHS
  // Front-view cars exist as: <team>_front.png in same cars directory.
  // Example: assets/images/cars/redbull_front.png
  // ---------------------------------------------------------------------------

  static const Map<String, List<Color>> teamBg = {
    'mclaren': [Color(0xFFFF7A00), Color(0xFF2A1B0E)],
    'redbull': [Color(0xFF1C3D7A), Color(0xFF0A1324)],
    'ferrari': [Color(0xFFD00019), Color(0xFF2A0A0E)],
    'mercedes': [Color(0xFF00D2BE), Color(0xFF061B1A)],
    'astonmartin': [Color(0xFF0A6B5B), Color(0xFF051A16)],
    'alpine': [Color.fromARGB(255, 195, 42, 255), Color(0xFF08132A)],
    'williams': [Color(0xFF005AFF), Color(0xFF071428)],
    'haas': [Color(0xFFB0B0B0), Color(0xFF121212)],
    'stake': [Color(0xFF00C853), Color(0xFF071A0F)],
    'rb': [Color(0xFF6C5CE7), Color(0xFF120E2A)],
    'default': [Color(0xFF2B2B2B), Color(0xFF0B0B0B)],
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

  String _getDriverFullName(String code) {
    return driverFullNames[code.toUpperCase()] ?? code;
  }

  String _resolveTeamKey(Map<String, dynamic> row, dynamic payload) {
    // 1) Best: explicit key from API row
    final explicit = _norm(row['team_key']);
    if (explicit.isNotEmpty && teamAssets.containsKey(explicit))
      return explicit;

    // 2) Try common fields on the row itself
    final rowTeam = _firstNonEmpty(row, const [
      'team',
      'team_name',
      'constructor',
      'constructor_name',
      'teamName',
      'constructorName',
    ]);
    final k1 = _aliasToKey(rowTeam);
    if (k1 != null) return k1;

    // 3) Look up driver in payload.drivers by code and read their team fields
    final code = _norm(row['driver_code']).toUpperCase();
    try {
      final drivers = payload?.drivers ?? [];
      for (final d in drivers) {
        final m = Map<String, dynamic>.from(d ?? {});
        if (_norm(m['code']).toUpperCase() == code) {
          final drvTeam = _firstNonEmpty(m, const [
            'team_key',
            'team',
            'team_name',
            'constructor',
            'constructor_name',
            'teamName',
            'constructorName',
          ]);
          final k2 = _aliasToKey(drvTeam);
          if (k2 != null) return k2;

          // Sometimes nested team object
          final t = m['team'];
          if (t is Map) {
            final nm = _norm(t['name']);
            final k3 = _aliasToKey(nm);
            if (k3 != null) return k3;
          }
        }
      }
    } catch (_) {}

    return 'default';
  }

  String _norm(dynamic v) => (v ?? '').toString().trim().toLowerCase();

  String? _firstNonEmpty(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = (m[k] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  String? _aliasToKey(String? input) {
    if (input == null) return null;
    final s = input.trim().toLowerCase();

    // exact match
    final exact = teamAliases[s];
    if (exact != null) return exact;

    // contains match (for "Oracle Red Bull Racing", etc.)
    for (final e in teamAliases.entries) {
      if (s.contains(e.key)) return e.value;
    }

    // direct key fallback
    if (teamAssets.containsKey(s)) return s;

    return null;
  }

  static const Map<String, _TeamAssets> teamAssets = {
    'mclaren': _TeamAssets(
      carFront: 'assets/images/cars/mclaren_front.png',
      logo: 'assets/images/logos/mclaren.png',
    ),
    'ferrari': _TeamAssets(
      carFront: 'assets/images/cars/ferrari_front.png',
      logo: 'assets/images/logos/ferrari.png',
    ),
    'mercedes': _TeamAssets(
      carFront: 'assets/images/cars/mercedes_front.png',
      logo: 'assets/images/logos/mercedes.png',
    ),
    'redbull': _TeamAssets(
      carFront: 'assets/images/cars/redbull_front.png',
      logo: 'assets/images/logos/redbull.png',
    ),
    'astonmartin': _TeamAssets(
      carFront: 'assets/images/cars/aston_martin_front.png',
      logo: 'assets/images/logos/aston_martin.png',
    ),
    'alpine': _TeamAssets(
      carFront: 'assets/images/cars/alpine_front.png',
      logo: 'assets/images/logos/alpine.png',
    ),
    'williams': _TeamAssets(
      carFront: 'assets/images/cars/williams_front.png',
      logo: 'assets/images/logos/williams.png',
    ),
    'haas': _TeamAssets(
      carFront: 'assets/images/cars/haas_front.png',
      logo: 'assets/images/logos/haas.png',
    ),
    'stake': _TeamAssets(
      carFront: 'assets/images/cars/stake_front.png',
      logo: 'assets/images/logos/stake.png',
    ),
    'rb': _TeamAssets(
      carFront: 'assets/images/cars/rb_front.png',
      logo: 'assets/images/logos/rb.png',
    ),
    'default': _TeamAssets(
      carFront: 'assets/images/f1_car.png',
      logo: 'assets/images/f1_logo.png',
    ),
  };

  static const Map<String, String> teamAliases = {
    // McLaren
    'mclaren': 'mclaren',
    'mc laren': 'mclaren',

    // Ferrari
    'ferrari': 'ferrari',

    // Mercedes
    'mercedes': 'mercedes',
    'mercedes-amg': 'mercedes',
    'mercedes amg': 'mercedes',

    // Red Bull
    'red bull': 'redbull',
    'red bull racing': 'redbull',
    'oracle red bull racing': 'redbull',

    // Aston Martin
    'aston martin': 'astonmartin',
    'astonmartin': 'astonmartin',

    // Alpine
    'alpine': 'alpine',

    // Williams
    'williams': 'williams',

    // Haas
    'haas': 'haas',

    // Sauber / Stake / Kick
    'stake': 'stake',
    'stake f1 team': 'stake',
    'sauber': 'stake',
    'kick sauber': 'stake',
    'kick': 'stake',

    // RB / VCARB / AlphaTauri variants
    'rb': 'rb',
    'vcarb': 'rb',
    'visa cash app rb': 'rb',
    'visa cash app': 'rb',
    'alphatauri': 'rb',
    'toro rosso': 'rb',
  };

  // Tuned podium colors to mimic the screenshot.
  // Sides are warm orange, center is deep blue by default.
  // If you want TEAM-based, swap these with per-team gradients.
  static const List<Color> orangePodium = [
    Color(0xFFFF7A00),
    Color(0xFF2A1B0E),
  ];
  static const List<Color> bluePodium = [Color(0xFF2B5EAA), Color(0xFF0A1324)];

  @override
  Widget build(BuildContext context) {
    final Map<int, Map<String, dynamic>> byPos = {};
    for (final p in podium) {
      final m = Map<String, dynamic>.from(p ?? {});
      final pos = int.tryParse((m['position'] ?? '').toString()) ?? -1;
      if (pos >= 1 && pos <= 3) byPos[pos] = m;
    }

    final p1 = byPos[1] ?? <String, dynamic>{'position': 1, 'driver_code': '—'};
    final p2 = byPos[2] ?? <String, dynamic>{'position': 2, 'driver_code': '—'};
    final p3 = byPos[3] ?? <String, dynamic>{'position': 3, 'driver_code': '—'};

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _podiumCard(p2, _PodiumSlot.sideLeft),
          const SizedBox(width: 18),
          _podiumCard(p1, _PodiumSlot.center),
          const SizedBox(width: 18),
          _podiumCard(p3, _PodiumSlot.sideRight),
        ],
      ),
    );
  }

  // Convert strings like "0 days 00:00:12.594000" -> "12.59s"
  String _secondsOnlyLabel(String raw) {
    final secs = _durationLikeToSeconds(raw);
    if (secs == null) return raw;
    return _fmtSeconds(secs);
  }

  String _subLabel(Map<String, dynamic> row) {
    final pos = int.tryParse((row['position'] ?? '').toString()) ?? 0;
    if (pos == 1) return 'Race Leader';

    final raw = (row['gap'] ?? row['time'] ?? row['duration'] ?? '')
        .toString()
        .trim();
    if (raw.isEmpty) return '—';

    // if gap already includes '+', normalize to seconds if duration-like
    if (raw.startsWith('+')) {
      final cleaned = raw.substring(1).trim();
      final secs = _durationLikeToSeconds(cleaned);
      return secs != null ? '+${_fmtSeconds(secs)}' : raw;
    }

    // duration-like -> +seconds
    final secs = _durationLikeToSeconds(raw);
    if (secs != null) return '+${_fmtSeconds(secs)}';

    // numeric -> +seconds
    final n = double.tryParse(raw.replaceAll('s', '').trim());
    if (n != null) return '+${_fmtSeconds(n)}';

    return raw;
  }

  double? _durationLikeToSeconds(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;

    final daysRegex = RegExp(r'^(\d+)\s+days?\s+', caseSensitive: false);
    int days = 0;
    String rest = s;
    final m = daysRegex.firstMatch(s);
    if (m != null) {
      days = int.tryParse(m.group(1) ?? '0') ?? 0;
      rest = s.substring(m.end).trim();
    }

    final parts = rest.split(':');
    if (parts.length != 3) return null;

    final hh = int.tryParse(parts[0]) ?? 0;
    final mm = int.tryParse(parts[1]) ?? 0;

    final secPart = parts[2];
    final sec =
        double.tryParse(secPart) ??
        double.tryParse(secPart.replaceAll(RegExp(r'[^0-9.]'), ''));

    if (sec == null) return null;

    return (days * 86400) + (hh * 3600) + (mm * 60) + sec;
  }

  String _fmtSeconds(double s) {
    if (s < 10) return '${s.toStringAsFixed(2)}s';
    if (s < 100) return '${s.toStringAsFixed(1)}s';
    return '${s.toStringAsFixed(0)}s';
  }

  Widget _podiumCard(Map<String, dynamic> row, _PodiumSlot slot) {
    debugPrint('PODIUM row: $row');

    final code = (row['driver_code'] ?? '').toString();

    debugPrint('driver_code=$code');

    debugPrint('team_key=${row['team_key']}');
    debugPrint('team=${row['team']}');
    debugPrint('team_name=${row['team_name']}');
    debugPrint('constructor=${row['constructor']}');
    debugPrint('constructor_name=${row['constructor_name']}');

    final posInt = int.tryParse((row['position'] ?? '').toString()) ?? 0;
    final pos = posInt == 0 ? '—' : posInt.toString();

    //final code = (row['driver_code'] ?? '—').toString().trim().toUpperCase();
    final teamKey = _resolveTeamKey(row, payload);
    final assets = teamAssets[teamKey] ?? teamAssets['default']!;

    // Dimensions tuned to match the screenshot proportions
    final bool isCenter = slot == _PodiumSlot.center;
    final double w = isCenter ? 420 : 380;
    final double h = isCenter ? 420 : 380;
    final List<Color> bg =
        teamBg[teamKey] ?? [Colors.grey.shade800, Colors.black];

    final Color teamGlow = bg[0];

    // Car should "pop out"
    final double carHeight = isCenter ? 260 : 235;
    final double carBottom = isCenter ? 102 : 96;

    final String sub = _subLabel(row);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer glow / shadow behind card (big soft)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(46),
                boxShadow: [
                  BoxShadow(
                    color: teamGlow.withOpacity(0.45),
                    blurRadius: 60,
                    spreadRadius: 6,
                    offset: const Offset(0, 18),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 40,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
            ),
          ),

          // Main card
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(46),
              child: Stack(
                children: [
                  // Base gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            bg[0].withOpacity(0.97),
                            bg[1].withOpacity(0.97),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),

                  // Inner glow border
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(46),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Strong glossy highlight top-left (the “glass” look)
                  Positioned(
                    top: 16,
                    left: 18,
                    child: Opacity(
                      opacity: 0.42,
                      child: Container(
                        width: w * 0.62,
                        height: h * 0.34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Subtle inner vignette
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.06),
                            Colors.black.withOpacity(0.28),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Big number overlay (bevel-ish via shadows)
                  Positioned(
                    top: -28,
                    left: 26,
                    child: Text(
                      pos,
                      style: TextStyle(
                        fontSize: isCenter ? 310 : 290,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.34),
                        height: 1,
                        shadows: [
                          Shadow(
                            blurRadius: 28,
                            color: Colors.white.withOpacity(0.16),
                            offset: const Offset(-2, -2),
                          ),
                          Shadow(
                            blurRadius: 20,
                            color: Colors.black.withOpacity(0.22),
                            offset: const Offset(2, 6),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Team logo top-right (NOT behind car)
                  Positioned(
                    top: 22,
                    right: 22,
                    child: _GlassLogoTile(
                      size: 66,
                      child: Image.asset(
                        assets.logo,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              teamAssets['default']!.logo,
                              fit: BoxFit.contain,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Car drop shadow on the "floor"
          Positioned(
            left: 40,
            right: 40,
            bottom: carBottom - 16,
            child: Opacity(
              opacity: 0.55,
              child: Container(
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.65),
                      blurRadius: 26,
                      spreadRadius: 8,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Car (popping out of the card)
          Positioned(
            left: -34,
            right: -34,
            bottom: carBottom - 50,
            child: Image.asset(
              assets.carFront,
              height: carHeight,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                teamAssets['default']!.carFront,
                height: carHeight,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Bottom text (like screenshot)
          Positioned(
            left: 34,
            right: 34,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isCenter ? 58 : 54,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        blurRadius: 18,
                        color: Colors.black.withOpacity(0.30),
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDriverFullName(code),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontWeight: FontWeight.w600,
                    fontSize: isCenter ? 18 : 17,
                    shadows: [
                      Shadow(
                        blurRadius: 14,
                        color: Colors.black.withOpacity(0.22),
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  // P1 = Race Leader, P2/P3 = +seconds converted
                  isCenter ? sub : sub,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontWeight: FontWeight.w600,
                    fontSize: isCenter ? 18 : 17,
                    shadows: [
                      Shadow(
                        blurRadius: 14,
                        color: Colors.black.withOpacity(0.22),
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Top-right logo tile (glassy)
class _GlassLogoTile extends StatelessWidget {
  final double size;
  final Widget child;

  const _GlassLogoTile({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TeamAssets {
  final String carFront;
  final String logo;
  const _TeamAssets({required this.carFront, required this.logo});
}

enum _PodiumSlot { sideLeft, center, sideRight }
