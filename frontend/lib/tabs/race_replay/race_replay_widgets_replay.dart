import 'dart:math' as math;
import 'package:flutter/material.dart';

/* ============================
   Team Colors
============================ */

class TeamColorsReplay {
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

  static const Map<String, String> driverToTeam = {
    'VER': 'redbull',
    'PER': 'redbull',
    'NOR': 'mclaren',
    'PIA': 'mclaren',
    'LEC': 'ferrari',
    'SAI': 'ferrari',
    'HAM': 'mercedes',
    'RUS': 'mercedes',
    'ALO': 'astonmartin',
    'STR': 'astonmartin',
    'GAS': 'alpine',
    'OCO': 'alpine',
    'ALB': 'williams',
    'SAR': 'williams',
    'HUL': 'haas',
    'MAG': 'haas',
    'BEA': 'haas',
    'BOT': 'stake',
    'ZHO': 'stake',
    'TSU': 'rb',
    'RIC': 'rb',
    'LAW': 'rb',
    'ANT': 'mercedes',
    'BOR': 'stake',
    'HAD': 'rb',
    'COL': 'williams',
  };

  static Color colorForDriver(String code) {
    final team = driverToTeam[code.toUpperCase()] ?? 'default';
    return teamColor[team] ?? teamColor['default']!;
  }
}

/* ============================
   Models
============================ */

class LapInfoReplay {
  final int currentLap;
  final int? totalLaps;
  LapInfoReplay({required this.currentLap, required this.totalLaps});
}

class ReplayDataReplay {
  final List<Offset> trackPolyline;
  final List<double> _cumLen;
  final double lapLength;

  final List<DriverSeriesReplay> drivers;
  final double durationS;
  final Map<String, dynamic> weather;
  final Map<String, dynamic> meta;

  ReplayDataReplay({
    required this.trackPolyline,
    required List<double> cumLen,
    required this.lapLength,
    required this.drivers,
    required this.durationS,
    required this.weather,
    required this.meta,
  }) : _cumLen = cumLen;

  String get metaSessionName {
    final v = meta['session_name'];
    if (v is String && v.trim().isNotEmpty) return v;
    return 'Race';
  }

  int? get metaTotalLaps {
    final v = meta['laps_total'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  factory ReplayDataReplay.fromJson(Map<String, dynamic> json) {
    final track = (json['track'] as Map?) ?? {};
    final poly = (track['polyline'] as List?) ?? const [];
    final trackPolyline = poly
        .whereType<List>()
        .where((p) => p.length >= 2)
        .map((p) =>
            Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(growable: false);

    // cumulative length
    final cum = <double>[];
    double sum = 0.0;
    if (trackPolyline.isNotEmpty) {
      cum.add(0.0);
      for (var i = 1; i < trackPolyline.length; i++) {
        final a = trackPolyline[i - 1];
        final b = trackPolyline[i];
        final dx = b.dx - a.dx;
        final dy = b.dy - a.dy;
        sum += math.sqrt(dx * dx + dy * dy);
        cum.add(sum);
      }
    }
    final lapLength = sum;

    final driversMap = (json['drivers'] as Map?) ?? {};

    final reverseDir = _shouldReverseDirection(
      trackPolyline: trackPolyline,
      cumLen: cum,
      lapLength: lapLength,
      driversMap: driversMap,
    );

    final drivers = <DriverSeriesReplay>[];
    driversMap.forEach((code, v) {
      if (code is! String || v is! Map) return;

      final tRaw = (v['t'] as List?) ?? const [];
      final xRaw = (v['x'] as List?) ?? const [];
      final yRaw = (v['y'] as List?) ?? const [];
      final n = math.min(tRaw.length, math.min(xRaw.length, yRaw.length));
      if (n < 2) return;

      final t = List<double>.generate(
          n, (i) => (tRaw[i] as num).toDouble(),
          growable: false);
      final x = List<double>.generate(
          n, (i) => (xRaw[i] as num).toDouble(),
          growable: false);
      final y = List<double>.generate(
          n, (i) => (yRaw[i] as num).toDouble(),
          growable: false);

      final progress = _buildUnwrappedProgress(
        trackPolyline: trackPolyline,
        cumLen: cum,
        lapLength: lapLength,
        xs: x,
        ys: y,
        reverseDir: reverseDir,
      );

      drivers.add(DriverSeriesReplay(
        code: code.toUpperCase(),
        t: t,
        x: x,
        y: y,
        progressUnwrapped: progress,
      ));
    });

    drivers.sort((a, b) => a.code.compareTo(b.code));

    final duration = (json['duration_s'] as num?)?.toDouble() ?? 0.0;
    final weather = (json['weather'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final meta =
        (json['meta'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    return ReplayDataReplay(
      trackPolyline: trackPolyline,
      cumLen: cum,
      lapLength: lapLength,
      drivers: drivers,
      durationS: duration,
      weather: weather,
      meta: meta,
    );
  }

  List<CarSampleReplay> sampleCarsAt(double t) {
    final out = <CarSampleReplay>[];
    for (final d in drivers) {
      final p = d.samplePosAt(t);
      if (p != null) out.add(CarSampleReplay(code: d.code, pos: p));
    }
    return out;
  }

  // ✅ Leaderboard: fixed positions 1..N, names move based on unwrapped progress
  List<LeaderboardRowReplay> computeLeaderboardAt(double t) {
    final rows = <LeaderboardRowReplay>[];
    for (final d in drivers) {
      final p = d.sampleProgressAt(t);
      if (p == null) continue;
      rows.add(LeaderboardRowReplay(code: d.code, progressUnwrapped: p));
    }
    rows.sort((a, b) => b.progressUnwrapped.compareTo(a.progressUnwrapped));
    return rows;
  }

  LapInfoReplay computeLapInfoAt(double t) {
    if (lapLength <= 1e-6) {
      return LapInfoReplay(currentLap: 1, totalLaps: metaTotalLaps);
    }
    final lb = computeLeaderboardAt(t);
    if (lb.isEmpty) {
      return LapInfoReplay(currentLap: 1, totalLaps: metaTotalLaps);
    }
    final leaderCode = lb.first.code;
    final leader = drivers.where((d) => d.code == leaderCode).toList();
    if (leader.isEmpty) {
      return LapInfoReplay(currentLap: 1, totalLaps: metaTotalLaps);
    }
    final prog = leader.first.sampleProgressAt(t) ?? 0.0;
    final lapNow = math.max(1, (prog / lapLength).floor() + 1);
    return LapInfoReplay(currentLap: lapNow, totalLaps: metaTotalLaps);
  }

  /* ========= Direction + unwrap ========= */

  static bool _shouldReverseDirection({
    required List<Offset> trackPolyline,
    required List<double> cumLen,
    required double lapLength,
    required Map driversMap,
  }) {
    if (trackPolyline.length < 2 || lapLength <= 1e-9) return false;

    Map? anyDriver;
    for (final v in driversMap.values) {
      if (v is Map) {
        final x = v['x'];
        final y = v['y'];
        if (x is List && y is List && x.length >= 50 && y.length >= 50) {
          anyDriver = v;
          break;
        }
      }
    }
    if (anyDriver == null) return false;

    final xs = anyDriver['x'] as List;
    final ys = anyDriver['y'] as List;
    final n = math.min(200, math.min(xs.length, ys.length));
    if (n < 20) return false;

    double sRaw(Offset p) {
      var bestD2 = double.infinity;
      var bestS = 0.0;

      for (var i = 0; i < trackPolyline.length - 1; i++) {
        final a = trackPolyline[i];
        final b = trackPolyline[i + 1];
        final ab = b - a;
        final ap = p - a;

        final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
        if (ab2 <= 1e-12) continue;

        var u = (ap.dx * ab.dx + ap.dy * ab.dy) / ab2;
        if (u < 0.0) u = 0.0;
        if (u > 1.0) u = 1.0;

        final proj = Offset(a.dx + ab.dx * u, a.dy + ab.dy * u);
        final dx = p.dx - proj.dx;
        final dy = p.dy - proj.dy;
        final d2 = dx * dx + dy * dy;

        if (d2 < bestD2) {
          bestD2 = d2;
          final segLen = math.sqrt(ab2);
          bestS = cumLen[i] + segLen * u;
        }
      }

      if (bestS < 0) bestS = 0;
      if (bestS > lapLength) bestS = lapLength;
      return bestS;
    }

    final deltas = <double>[];
    var prev = sRaw(
      Offset((xs[0] as num).toDouble(), (ys[0] as num).toDouble()),
    );

    for (var i = 1; i < n; i++) {
      final cur = sRaw(
        Offset((xs[i] as num).toDouble(), (ys[i] as num).toDouble()),
      );
      final d = cur - prev;
      if (d.abs() < lapLength * 0.4) deltas.add(d);
      prev = cur;
    }

    if (deltas.length < 10) return false;
    deltas.sort();
    final median = deltas[deltas.length ~/ 2];
    return median < 0;
  }

  static List<double> _buildUnwrappedProgress({
    required List<Offset> trackPolyline,
    required List<double> cumLen,
    required double lapLength,
    required List<double> xs,
    required List<double> ys,
    required bool reverseDir,
  }) {
    if (trackPolyline.length < 2 || lapLength <= 1e-9) {
      return List<double>.filled(xs.length, 0.0, growable: false);
    }

    double sAlongLap(Offset p) {
      var bestD2 = double.infinity;
      var bestS = 0.0;

      for (var i = 0; i < trackPolyline.length - 1; i++) {
        final a = trackPolyline[i];
        final b = trackPolyline[i + 1];
        final ab = b - a;
        final ap = p - a;

        final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
        if (ab2 <= 1e-12) continue;

        var u = (ap.dx * ab.dx + ap.dy * ab.dy) / ab2;
        if (u < 0.0) u = 0.0;
        if (u > 1.0) u = 1.0;

        final proj = Offset(a.dx + ab.dx * u, a.dy + ab.dy * u);
        final dx = p.dx - proj.dx;
        final dy = p.dy - proj.dy;
        final d2 = dx * dx + dy * dy;

        if (d2 < bestD2) {
          bestD2 = d2;
          final segLen = math.sqrt(ab2);
          bestS = cumLen[i] + segLen * u;
        }
      }

      if (bestS < 0) bestS = 0;
      if (bestS > lapLength) bestS = lapLength;

      if (reverseDir) {
        bestS = lapLength - bestS;
        if (bestS < 0) bestS = 0;
        if (bestS > lapLength) bestS = lapLength;
      }

      return bestS;
    }

    final raw = List<double>.generate(
      xs.length,
      (i) => sAlongLap(Offset(xs[i], ys[i])),
      growable: false,
    );

    final out = List<double>.filled(raw.length, 0.0, growable: false);
    out[0] = raw[0];

    var lapOffset = 0.0;
    for (var i = 1; i < raw.length; i++) {
      final prev = raw[i - 1];
      final cur = raw[i];
      final d = cur - prev;

      if (d < -lapLength * 0.6) {
        lapOffset += lapLength;
      } else if (d > lapLength * 0.6) {
        lapOffset -= lapLength;
      }
      out[i] = cur + lapOffset;
    }

    return out;
  }
}

class DriverSeriesReplay {
  final String code;
  final List<double> t;
  final List<double> x;
  final List<double> y;
  final List<double> progressUnwrapped;

  DriverSeriesReplay({
    required this.code,
    required this.t,
    required this.x,
    required this.y,
    required this.progressUnwrapped,
  });

  Offset? samplePosAt(double timeS) {
    if (t.isEmpty) return null;
    if (timeS <= t.first) return Offset(x.first, y.first);
    if (timeS >= t.last) return Offset(x.last, y.last);

    var lo = 0;
    var hi = t.length - 1;
    while (lo + 1 < hi) {
      final mid = (lo + hi) >> 1;
      if (t[mid] <= timeS) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    final t0 = t[lo];
    final t1 = t[lo + 1];
    final denom = (t1 - t0);
    if (denom <= 1e-9) return Offset(x[lo], y[lo]);

    final a = (timeS - t0) / denom;
    return Offset(
      x[lo] + (x[lo + 1] - x[lo]) * a,
      y[lo] + (y[lo + 1] - y[lo]) * a,
    );
  }

  double? sampleProgressAt(double timeS) {
    if (t.isEmpty) return null;
    if (timeS <= t.first) return progressUnwrapped.first;
    if (timeS >= t.last) return progressUnwrapped.last;

    var lo = 0;
    var hi = t.length - 1;
    while (lo + 1 < hi) {
      final mid = (lo + hi) >> 1;
      if (t[mid] <= timeS) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    final t0 = t[lo];
    final t1 = t[lo + 1];
    final denom = (t1 - t0);
    if (denom <= 1e-9) return progressUnwrapped[lo];

    final a = (timeS - t0) / denom;
    return progressUnwrapped[lo] +
        (progressUnwrapped[lo + 1] - progressUnwrapped[lo]) * a;
  }
}

class CarSampleReplay {
  final String code;
  final Offset pos;
  CarSampleReplay({required this.code, required this.pos});
}

class LeaderboardRowReplay {
  final String code;
  final double progressUnwrapped;
  LeaderboardRowReplay({required this.code, required this.progressUnwrapped});
}

/* ============================
   Painter
============================ */

class TrackPainterReplay extends CustomPainter {
  final List<Offset> polyline;
  final List<CarSampleReplay> cars;
  final String? selected;

  TrackPainterReplay({
    required this.polyline,
    required this.cars,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    if (polyline.length < 2) return;

    final bounds = _bounds(polyline);
    final pad = 18.0;

    final availW = math.max(1.0, size.width - pad * 2);
    final availH = math.max(1.0, size.height - pad * 2);

    final sx = availW / math.max(1e-9, bounds.width);
    final sy = availH / math.max(1e-9, bounds.height);
    final s = math.min(sx, sy);

    final scaledW = bounds.width * s;
    final scaledH = bounds.height * s;

    final dx = (size.width - scaledW) / 2 - bounds.left * s;
    final dy = (size.height - scaledH) / 2 - bounds.top * s;

    Offset toScreen(Offset p) => Offset(p.dx * s + dx, p.dy * s + dy);

    final path = Path();
    final first = toScreen(polyline.first);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < polyline.length; i++) {
      final p = toScreen(polyline[i]);
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = const Color(0xFF4D4D4D),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFBFBFBF),
    );

    for (final c in cars) {
      final p = toScreen(c.pos);
      final isSel = selected != null && c.code == selected;
      final color = TeamColorsReplay.colorForDriver(c.code);

      canvas.drawCircle(p, isSel ? 7 : 5, Paint()..color = color);

      if (isSel) {
        canvas.drawCircle(
          p,
          11,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white,
        );
      }

      _drawLabel(canvas, p, c.code, bg: color);
    }
  }

  void _drawLabel(Canvas canvas, Offset p, String code, {required Color bg}) {
    final tp = TextPainter(
      text: TextSpan(
        text: code.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(blurRadius: 6, color: Colors.black)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final off = Offset(p.dx + 8, p.dy - tp.height / 2);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(off.dx - 3, off.dy - 2, tp.width + 6, tp.height + 4),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, Paint()..color = bg.withOpacity(0.85));
    tp.paint(canvas, off);
  }

  Rect _bounds(List<Offset> pts) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in pts) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool shouldRepaint(covariant TrackPainterReplay old) =>
      old.cars != cars || old.polyline != polyline || old.selected != selected;
}

/* ============================
   UI Widgets (Replay suffix)
============================ */

class TopLeftInfoReplay extends StatelessWidget {
  final double t;
  final double duration;
  final double speed;
  final String sessionName;

  final int lapNow;
  final int? lapTotal;

  // debug: show current session params to confirm GP changes
  final int season;
  final int roundNo;
  final String sessionShort;

  const TopLeftInfoReplay({
    super.key,
    required this.t,
    required this.duration,
    required this.speed,
    required this.sessionName,
    required this.lapNow,
    required this.lapTotal,
    required this.season,
    required this.roundNo,
    required this.sessionShort,
  });

  String _fmt(double s) {
    final total = s.round();
    final hh = total ~/ 3600;
    final mm = (total % 3600) ~/ 60;
    final ss = total % 60;
    if (hh > 0) {
      return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
    }
    return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sp = speed.toStringAsFixed(speed == speed.roundToDouble() ? 0 : 1);
    final lapTotalStr = lapTotal == null ? '--' : lapTotal.toString();

    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 10),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sessionName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Race Time: ${_fmt(t)}  (x$sp)'),
            Text('Duration: ${_fmt(duration)}'),
            const SizedBox(height: 2),
            Text('Lap: $lapNow / $lapTotalStr',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 2),
            Text('S$season R$roundNo [$sessionShort]',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class LeftPanelReplay extends StatelessWidget {
  final ReplayDataReplay data;
  final double t;
  final Map<String, dynamic> weather;
  final List<String> focusCodes;
  final List<LeaderboardRowReplay> leaderboard;

  const LeftPanelReplay({
    super.key,
    required this.data,
    required this.t,
    required this.weather,
    required this.focusCodes,
    required this.leaderboard,
  });

  String _fmtNum(dynamic v, {String suffix = ''}) {
    if (v == null) return '--';
    if (v is num) return '${v.toStringAsFixed(1)}$suffix';
    return '$v$suffix';
  }

  int _posOf(String code) {
    for (var i = 0; i < leaderboard.length; i++) {
      if (leaderboard[i].code == code) return i + 1;
    }
    return -1;
  }

  String _aheadText(String code) {
    final p = _posOf(code);
    if (p <= 1) return 'Leader';
    final ahead = leaderboard[p - 2].code;
    return 'P${p - 1} $ahead';
  }

  String _behindText(String code) {
    final p = _posOf(code);
    if (p < 1 || p >= leaderboard.length) return '--';
    final behind = leaderboard[p].code;
    return 'P${p + 1} $behind';
  }

  double? _speedKmh(String code) => null;
  int? _gear(String code) => null;
  bool? _drsOn(String code) => null;

  @override
  Widget build(BuildContext context) {
    final focus = focusCodes.take(3).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          _panel(
            title: 'Weather',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Track', _fmtNum(weather['track_temp_c_avg'], suffix: '°C')),
                _kv('Air', _fmtNum(weather['air_temp_c_avg'], suffix: '°C')),
                _kv('Humidity', _fmtNum(weather['humidity_avg'], suffix: '%')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _panel(
            title: 'Focus (top 3)',
            child: focus.isEmpty
                ? const Text(
                    'No focus selected.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  )
                : Column(
                    children: focus
                        .map((code) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DriverTelemetryCardReplay(
                                code: code,
                                speedKmh: _speedKmh(code),
                                gear: _gear(code),
                                drsOn: _drsOn(code),
                                aheadText: _aheadText(code),
                                behindText: _behindText(code),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(k,
                  style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class LeaderboardPanelReplay extends StatelessWidget {
  final List<LeaderboardRowReplay> leaderboard;
  final String? selected;
  final Set<String> focused;
  final bool noneMode;

  final ValueChanged<String> onSelectSingle;
  final ValueChanged<String> onToggleFocus;
  final VoidCallback onFocusAll;
  final VoidCallback onFocusNone;

  const LeaderboardPanelReplay({
    super.key,
    required this.leaderboard,
    required this.selected,
    required this.focused,
    required this.noneMode,
    required this.onSelectSingle,
    required this.onToggleFocus,
    required this.onFocusAll,
    required this.onFocusNone,
  });

  bool _isChecked(String code) {
    if (noneMode) return false;
    if (focused.isEmpty) return true; // All
    return focused.contains(code);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final headerH = 70.0;
      final available = math.max(120.0, c.maxHeight - headerH);
      final rowH = (available / math.max(1, leaderboard.length)).clamp(18.0, 34.0);

      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leaderboard',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    noneMode
                        ? 'Focus: none'
                        : (focused.isEmpty ? 'Focus: all' : 'Focus: ${focused.length}'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                TextButton(onPressed: onFocusAll, child: const Text('All')),
                TextButton(onPressed: onFocusNone, child: const Text('None')),
              ],
            ),
            const Divider(height: 1, color: Color(0xFF2A2A2A)),
            const SizedBox(height: 6),

            Expanded(
              child: Column(
                children: List.generate(leaderboard.length, (i) {
                  final row = leaderboard[i];
                  final isSel = row.code == selected;
                  final checked = _isChecked(row.code);
                  final color = TeamColorsReplay.colorForDriver(row.code);

                  final isTop3 = i < 3;

                  return SizedBox(
                    height: rowH,
                    child: InkWell(
                      onTap: () => onSelectSingle(row.code),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF1B1B1B)
                              : (isTop3 ? const Color(0xFF161616) : Colors.transparent),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text(
                                '${i + 1}.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSel ? Colors.white : Colors.white70,
                                  fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                            ),
                            Checkbox(
                              value: checked,
                              onChanged: (_) => onToggleFocus(row.code),
                              activeColor: color,
                              checkColor: Colors.black,
                              side: const BorderSide(color: Color(0xFF444444)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity:
                                  const VisualDensity(horizontal: -4, vertical: -4),
                            ),
                            Container(
                              width: 6,
                              height: 14,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                row.code,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSel ? Colors.white : Colors.white70,
                                  fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            )
          ],
        ),
      );
    });
  }
}

class BottomControlsReplay extends StatelessWidget {
  final bool playing;
  final double t;
  final double duration;
  final double speed;

  final VoidCallback onPlayPause;
  final VoidCallback onStepBack;
  final VoidCallback onStepFwd;
  final VoidCallback onRestart;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSpeedChanged;

  const BottomControlsReplay({
    super.key,
    required this.playing,
    required this.t,
    required this.duration,
    required this.speed,
    required this.onPlayPause,
    required this.onStepBack,
    required this.onStepFwd,
    required this.onRestart,
    required this.onSeek,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final speeds = const [0.5, 1.0, 2.0, 4.0, 8.0];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Restart',
            onPressed: onRestart,
            icon: const Icon(Icons.replay, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Step back',
            onPressed: onStepBack,
            icon: const Icon(Icons.skip_previous, color: Colors.white),
          ),
          IconButton(
            tooltip: playing ? 'Pause' : 'Play',
            onPressed: onPlayPause,
            icon: Icon(
              playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: Colors.white,
              size: 34,
            ),
          ),
          IconButton(
            tooltip: 'Step forward',
            onPressed: onStepFwd,
            icon: const Icon(Icons.skip_next, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: const Color(0xFF2A2A2A),
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
              ),
              child: Slider(
                value: duration <= 0 ? 0 : t.clamp(0.0, duration),
                min: 0,
                max: math.max(0.0001, duration),
                onChanged: onSeek,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                dropdownColor: const Color(0xFF151515),
                value: speed,
                items: speeds
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            'x${s.toStringAsFixed(s == s.roundToDouble() ? 0 : 1)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onSpeedChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CenteredCardReplay extends StatelessWidget {
  final String title;
  final Widget child;

  const CenteredCardReplay({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x00000000)),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================
   DriverTelemetryCardReplay
   (matches your widget style)
============================ */

class DriverTelemetryCardReplay extends StatelessWidget {
  final String code;
  final double? speedKmh;
  final int? gear;
  final bool? drsOn;
  final String aheadText;
  final String behindText;

  const DriverTelemetryCardReplay({
    super.key,
    required this.code,
    required this.speedKmh,
    required this.gear,
    required this.drsOn,
    required this.aheadText,
    required this.behindText,
  });

  Widget _kv(String k, String v, {bool valueBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          v,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = TeamColorsReplay.colorForDriver(code);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              'Driver: $code',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _kv(
                        'Speed',
                        speedKmh != null ? '${speedKmh!.round()} km/h' : '--',
                        valueBold: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _kv('Gear', gear != null ? '$gear' : '--', valueBold: true),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DRS',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Icon(
                          drsOn == true ? Icons.toggle_on : Icons.toggle_off,
                          color: drsOn == true ? Colors.greenAccent : Colors.white24,
                          size: 28,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _kv('Ahead', aheadText, valueBold: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _kv('Behind', behindText, valueBold: true)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}