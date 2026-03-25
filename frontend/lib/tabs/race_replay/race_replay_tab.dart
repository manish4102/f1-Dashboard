import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../shell/session_provider.dart';
import '../../widgets/f1_dropdown.dart';

class RaceReplayTab extends ConsumerStatefulWidget {
  final String? replayUrl;
  final Future<Map<String, dynamic>> Function()? replayLoader;
  final String apiBaseUrl;

  const RaceReplayTab({
    super.key,
    this.replayUrl,
    this.replayLoader,
    this.apiBaseUrl = 'https://manish4102-f1-dashboard.hf.space',
  });

  @override
  ConsumerState<RaceReplayTab> createState() => _RaceReplayTabState();
}

class _RaceReplayTabState extends ConsumerState<RaceReplayTab>
    with SingleTickerProviderStateMixin {
  ReplayData? _data;
  String? _error;

  final ApiClient _api = ApiClient();
  int _defaultSeason = 2026;
  int _defaultRound = 1;

  late final Ticker _ticker;
  Duration? _lastTick;

  bool _playing = false;
  double _speed = 1.0;
  double _t = 0.0;
  double _duration = 0.0;

  String? _selectedDriver;
  final Set<String> _focusedDrivers = {};
  bool _noneMode = false;

  String? _cacheIdUsed;

  Future<void> _loadSelected({
    required int season,
    required int round,
    required String sessionName,
  }) async {
    await ref
        .read(sessionProvider.notifier)
        .load(season: season, round: round, sessionName: sessionName);
  }

  Widget _buildDropdown(dynamic st) {
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
            child: _RaceReplayDropdownWidget(
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

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final st = ref.read(sessionProvider);
      if (st.cacheId != null && st.cacheId!.isNotEmpty) {
        _load(st.cacheId!);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _load(String cacheId) async {
    setState(() {
      _error = null;
      _data = null;
      _playing = false;
      _t = 0.0;
      _duration = 0.0;
      _selectedDriver = null;
      _focusedDrivers.clear();
      _noneMode = false;
      _cacheIdUsed = cacheId;
    });
    _ticker.stop();

    try {
      Map<String, dynamic> replayRoot;

      if (widget.replayLoader != null) {
        replayRoot = await widget.replayLoader!();
      } else if (widget.replayUrl != null) {
        final res = await http.get(Uri.parse(widget.replayUrl!));
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw Exception('Replay HTTP ${res.statusCode}: ${res.body}');
        }
        replayRoot =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      } else {
        final base = widget.apiBaseUrl.trim().replaceAll(RegExp(r'/*$'), '');
        final replayUri = Uri.parse('$base/session/$cacheId/replay/frames');
        final replayRes = await http.get(replayUri);
        if (replayRes.statusCode < 200 || replayRes.statusCode >= 300) {
          throw Exception(
            'Replay HTTP ${replayRes.statusCode}: ${replayRes.body}',
          );
        }

        replayRoot =
            jsonDecode(utf8.decode(replayRes.bodyBytes))
                as Map<String, dynamic>;
      }

      final normalized = _normalizeReplayPayload(replayRoot);
      final parsed = ReplayData.fromJson(normalized);

      setState(() {
        _data = parsed;
        _duration = parsed.durationS;
        _t = 0.0;
        _selectedDriver = parsed.drivers.isNotEmpty
            ? parsed.drivers.first.code
            : null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Map<String, dynamic> _normalizeReplayPayload(Map<String, dynamic> root) {
    final replay = root['replay'];
    if (replay is Map<String, dynamic>) {
      if (replay['drivers'] is Map) return replay;
      final frames = replay['frames'];
      if (frames is List) {
        return _framesToPerDriverMap(
          frames,
          trackMaybe: replay['track'],
          metaMaybe: replay['meta'],
          weatherMaybe: replay['weather'],
        );
      }
      return replay;
    }
    if (replay is List) {
      return _framesToPerDriverMap(replay);
    }
    if (root['drivers'] is Map) return root;
    throw Exception('Unexpected replay payload shape: $root');
  }

  Map<String, dynamic> _framesToPerDriverMap(
    List frames, {
    dynamic trackMaybe,
    dynamic metaMaybe,
    dynamic weatherMaybe,
  }) {
    final Map<String, List<double>> tMap = {};
    final Map<String, List<double>> xMap = {};
    final Map<String, List<double>> yMap = {};

    final Map<String, List<double>> speedMap = {};
    final Map<String, List<int>> gearMap = {};
    final Map<String, List<int>> drsMap = {};

    double maxT = 0.0;

    for (final f in frames) {
      if (f is! Map) continue;
      final tVal = f['t'];
      if (tVal is! num) continue;
      final t = tVal.toDouble();
      if (t > maxT) maxT = t;

      final cars = f['cars'];
      if (cars is! List) continue;

      for (final c in cars) {
        if (c is! Map) continue;
        final code = c['code'];
        final x = c['x'];
        final y = c['y'];
        if (code is! String || x is! num || y is! num) continue;
        final cc = code.toUpperCase();

        tMap.putIfAbsent(cc, () => <double>[]).add(t);
        xMap.putIfAbsent(cc, () => <double>[]).add(x.toDouble());
        yMap.putIfAbsent(cc, () => <double>[]).add(y.toDouble());

        final sp = c['speed'];
        if (sp is num) {
          speedMap.putIfAbsent(cc, () => <double>[]).add(sp.toDouble());
        }

        final gr = c['gear'];
        if (gr is num) {
          gearMap.putIfAbsent(cc, () => <int>[]).add(gr.toInt());
        }

        final dr = c['drs'];
        if (dr is num) {
          drsMap.putIfAbsent(cc, () => <int>[]).add(dr.toInt());
        }
      }
    }

    final drivers = <String, dynamic>{};
    tMap.forEach((code, tt) {
      final xx = xMap[code] ?? const <double>[];
      final yy = yMap[code] ?? const <double>[];
      final n = math.min(tt.length, math.min(xx.length, yy.length));
      if (n < 2) return;

      final entry = <String, dynamic>{
        't': tt.take(n).toList(growable: false),
        'x': xx.take(n).toList(growable: false),
        'y': yy.take(n).toList(growable: false),
      };

      final sp = speedMap[code];
      if (sp != null) {
        final sn = math.min(n, sp.length);
        entry['speed'] = sp.take(sn).toList(growable: false);
      }

      final gr = gearMap[code];
      if (gr != null) {
        final gn = math.min(n, gr.length);
        entry['gear'] = gr.take(gn).toList(growable: false);
      }

      final dr = drsMap[code];
      if (dr != null) {
        final dn = math.min(n, dr.length);
        entry['drs'] = dr.take(dn).toList(growable: false);
      }

      drivers[code] = entry;
    });

    return {
      'meta': metaMaybe is Map ? metaMaybe : {'session_name': 'Race'},
      'track': trackMaybe is Map ? trackMaybe : {'polyline': []},
      'drivers': drivers,
      'duration_s': maxT,
      'weather': weatherMaybe is Map ? weatherMaybe : {},
    };
  }

  void _onTick(Duration now) {
    if (!_playing || _data == null) return;

    final last = _lastTick;
    _lastTick = now;
    if (last == null) return;

    final dt = (now - last).inMicroseconds / 1e6;
    if (dt <= 0) return;

    final next = _t + dt * _speed;
    if (next >= _duration) {
      setState(() {
        _t = _duration;
        _playing = false;
      });
      _ticker.stop();
      return;
    }

    setState(() => _t = next);
  }

  void _togglePlay() {
    if (_data == null) return;
    setState(() => _playing = !_playing);
    if (_playing) {
      _lastTick = null;
      _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  void _seek(double t) {
    if (_data == null) return;
    setState(() => _t = t.clamp(0.0, _duration));
  }

  void _step(double deltaSeconds) => _seek(_t + deltaSeconds);

  bool _passesFocus(String code) {
    if (_noneMode) return false;
    if (_focusedDrivers.isEmpty) return true;
    return _focusedDrivers.contains(code);
  }

  void _toggleFocus(String code) {
    setState(() {
      _noneMode = false;
      if (_focusedDrivers.contains(code)) {
        _focusedDrivers.remove(code);
      } else {
        if (_focusedDrivers.length >= 3) {
          final first = _focusedDrivers.first;
          _focusedDrivers.remove(first);
        }
        _focusedDrivers.add(code);
      }
    });
  }

  void _focusAll() {
    setState(() {
      _noneMode = false;
      _focusedDrivers.clear();
    });
  }

  void _focusNone() {
    setState(() {
      _noneMode = true;
      _focusedDrivers.clear();
    });
  }

  DriverSeries? _findSeriesByCode(List<DriverSeries> drivers, String code) {
    for (final d in drivers) {
      if (d.code == code) return d;
    }
    return null;
  }

  bool _isAllDriversSelected(ReplayData data) {
    if (_noneMode) return false;
    if (_focusedDrivers.isEmpty) return true;
    final all = data.drivers.map((d) => d.code).toSet();
    return _focusedDrivers.length == all.length &&
        _focusedDrivers.containsAll(all);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionProvider, (prev, next) {
      if (next.cacheId != null &&
          next.cacheId!.isNotEmpty &&
          next.cacheId != _cacheIdUsed) {
        _load(next.cacheId!);
      }
    });

    final st = ref.watch(sessionProvider);
    final data = _data;

    if (_error != null) {
      return _CenteredCard(
        title: 'Replay failed to load',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            if (_cacheIdUsed != null) ...[
              const SizedBox(height: 8),
              Text(
                'cache_id: $_cacheIdUsed',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (_cacheIdUsed != null) _load(_cacheIdUsed!);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (data == null) {
      if (st.full == null) {
        return const Center(
          child: Text(
            'Load a session to view Race Replay',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final carsNowAll = data.sampleCarsAt(_t);
    final carsNow = carsNowAll
        .where((c) => _passesFocus(c.code))
        .toList(growable: false);
    final leaderboard = data.computeLeaderboardAt(_t);

    final focusList = (_noneMode)
        ? <String>[]
        : (_focusedDrivers.isEmpty
              ? leaderboard.take(3).map((r) => r.code).toList(growable: false)
              : _focusedDrivers.toList());

    final showTop3 = _isAllDriversSelected(data);
    final top3 = leaderboard.take(3).map((r) => r.code).toList(growable: false);

    final DriverSeries? selectedSeries = (_selectedDriver == null)
        ? null
        : _findSeriesByCode(data.drivers, _selectedDriver!);

    final selSpeed = selectedSeries?.sampleSpeedAt(_t);
    final selGear = selectedSeries?.sampleGearAt(_t);
    final selDrs = selectedSeries?.sampleDrsAt(_t);

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned(top: 120, left: 16, right: 16, child: _buildDropdown(st)),

          Positioned(
            top: 190,
            left: 16,
            right: 16,
            bottom: 76,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 260,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 240,
                                  child: _TopLeftInfo(
                                    t: _t,
                                    speed: _speed,
                                    duration: _duration,
                                    sessionName: data.metaSessionName,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: 240,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF121212,
                                    ).withValues(alpha: 0.78),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Weather',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.thermostat,
                                            color: Colors.redAccent,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Track: ${data.weather['track_temp_c_avg'] ?? '--'}°C',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.thermostat,
                                            color: Colors.blueAccent,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Air: ${data.weather['air_temp_c_avg'] ?? '--'}°C',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.water_drop,
                                            color: Colors.lightBlue,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Humidity: ${data.weather['humidity_avg'] ?? '--'}%',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (showTop3) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: 240,
                                    child: PodiumWidgetReplay(top3: top3),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                if (_selectedDriver != null)
                                  SizedBox(
                                    width: 240,
                                    child: DriverTelemetryCard(
                                      code: _selectedDriver!,
                                      speedKmh: selSpeed,
                                      gear: selGear,
                                      drsOn: selDrs,
                                      aheadText: '--',
                                      behindText: '--',
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                ...focusList.map((code) {
                                  final d = _findSeriesByCode(
                                    data.drivers,
                                    code,
                                  );
                                  if (d == null) return const SizedBox();

                                  String aheadStr = '--';
                                  String behindStr = '--';

                                  final lbIndex = leaderboard.indexWhere(
                                    (r) => r.code == code,
                                  );

                                  if (lbIndex != -1) {
                                    final myProg =
                                        leaderboard[lbIndex].progress;

                                    if (lbIndex > 0) {
                                      final aheadProg =
                                          leaderboard[lbIndex - 1].progress;
                                      final gapMetres = (aheadProg - myProg);
                                      aheadStr =
                                          '${leaderboard[lbIndex - 1].code}: +${(gapMetres / 10).toStringAsFixed(1)}s';
                                    }

                                    if (lbIndex < leaderboard.length - 1) {
                                      final behindProg =
                                          leaderboard[lbIndex + 1].progress;
                                      final gapMetres = (myProg - behindProg);
                                      behindStr =
                                          '${leaderboard[lbIndex + 1].code}: -${(gapMetres / 10).toStringAsFixed(1)}s';
                                    }
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: DriverTelemetryCard(
                                      code: code,
                                      speedKmh: d.sampleSpeedAt(_t),
                                      gear: d.sampleGearAt(_t),
                                      drsOn: d.sampleDrsAt(_t),
                                      aheadText: aheadStr,
                                      behindText: behindStr,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),

                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: CustomPaint(
                              painter: TrackPainter(
                                polyline: data.trackPolyline,
                                cars: carsNow,
                                selected: _selectedDriver,
                              ),
                            ),
                          ),
                        ),

                        Container(
                          width: 240,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _LeaderboardPanelCompact(
                            leaderboard: leaderboard,
                            selected: _selectedDriver,
                            focused: _focusedDrivers,
                            noneMode: _noneMode,
                            onSelectSingle: (code) =>
                                setState(() => _selectedDriver = code),
                            onToggleFocus: _toggleFocus,
                            onFocusAll: _focusAll,
                            onFocusNone: _focusNone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: _BottomControls(
              playing: _playing,
              t: _t,
              duration: _duration,
              speed: _speed,
              onPlayPause: _togglePlay,
              onSeek: _seek,
              onStepBack: () => _step(-1.0),
              onStepFwd: () => _step(1.0),
              onSpeedChanged: (v) => setState(() => _speed = v),
              onRestart: () => _seek(0.0),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Team Colors ----------------------------- */

class TeamColors {
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
  };

  static Color colorForDriver(String code) {
    final team = driverToTeam[code.toUpperCase()] ?? 'default';
    return teamColor[team] ?? teamColor['default']!;
  }
}

/* ----------------------------- Data Models ----------------------------- */

class ReplayData {
  final List<Offset> trackPolyline;
  final List<double> _cumLen;
  final double lapLength;

  final List<DriverSeries> drivers;
  final double durationS;
  final Map<String, dynamic> weather;
  final Map<String, dynamic> meta;
  final int totalLaps;

  ReplayData({
    required this.trackPolyline,
    required List<double> cumLen,
    required this.lapLength,
    required this.drivers,
    required this.durationS,
    required this.weather,
    required this.meta,
    required this.totalLaps,
  }) : _cumLen = cumLen;

  int getCurrentLap(double t) {
    if (drivers.isEmpty) return 1;
    double maxP = 0;
    for (final d in drivers) {
      final p = d.sampleProgressAt(t) ?? 0;
      if (p > maxP) maxP = p;
    }
    if (lapLength <= 0) return 1;
    return (maxP / lapLength).floor() + 1;
  }

  String get metaSessionName {
    final v = meta['session_name'];
    if (v is String && v.trim().isNotEmpty) return v;
    return 'Race';
  }

  factory ReplayData.fromJson(Map<String, dynamic> json) {
    final track = (json['track'] as Map?) ?? {};
    final poly = (track['polyline'] as List?) ?? const [];
    final trackPolyline = poly
        .whereType<List>()
        .where((p) => p.length >= 2)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(growable: false);

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

    final drivers = <DriverSeries>[];
    driversMap.forEach((code, v) {
      if (code is! String || v is! Map) return;
      final tRaw = (v['t'] as List?) ?? const [];
      final xRaw = (v['x'] as List?) ?? const [];
      final yRaw = (v['y'] as List?) ?? const [];
      final n = math.min(tRaw.length, math.min(xRaw.length, yRaw.length));
      if (n < 2) return;

      final sp = v['speed'];
      final gr = v['gear'];
      final dr = v['drs'];

      final t = List<double>.generate(
        n,
        (i) => (tRaw[i] as num).toDouble(),
        growable: false,
      );
      final x = List<double>.generate(
        n,
        (i) => (xRaw[i] as num).toDouble(),
        growable: false,
      );
      final y = List<double>.generate(
        n,
        (i) => (yRaw[i] as num).toDouble(),
        growable: false,
      );

      final progress = _buildUnwrappedProgress(
        trackPolyline: trackPolyline,
        cumLen: cum,
        lapLength: lapLength,
        xs: x,
        ys: y,
        reverseDir: reverseDir,
      );

      drivers.add(
        DriverSeries(
          code: code.toUpperCase(),
          t: t,
          x: x,
          y: y,
          progressUnwrapped: progress,
          speed: (sp is List)
              ? List<double>.generate(
                  math.min(n, sp.length),
                  (i) => (sp[i] as num).toDouble(),
                  growable: false,
                )
              : null,
          gear: (gr is List)
              ? List<int>.generate(
                  math.min(n, gr.length),
                  (i) => (gr[i] as num).toInt(),
                  growable: false,
                )
              : null,
          drs: (dr is List)
              ? List<int>.generate(
                  math.min(n, dr.length),
                  (i) => (dr[i] as num).toInt(),
                  growable: false,
                )
              : null,
        ),
      );
    });

    drivers.sort((a, b) => a.code.compareTo(b.code));
    final duration = (json['duration_s'] as num?)?.toDouble() ?? 0.0;
    final weather =
        (json['weather'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final meta =
        (json['meta'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final totalLaps = (json['meta']?['total_laps'] as num?)?.toInt() ?? 50;

    return ReplayData(
      trackPolyline: trackPolyline,
      cumLen: cum,
      lapLength: lapLength,
      drivers: drivers,
      durationS: duration,
      weather: weather,
      meta: meta,
      totalLaps: totalLaps,
    );
  }

  Offset sampleTrackPos(double s) {
    if (trackPolyline.isEmpty) return Offset.zero;
    if (trackPolyline.length == 1) return trackPolyline.first;
    if (s <= 0) return trackPolyline.first;
    if (s >= lapLength) return trackPolyline.last;

    var lo = 0;
    var hi = _cumLen.length - 1;
    while (lo + 1 < hi) {
      final mid = (lo + hi) >> 1;
      if (_cumLen[mid] <= s) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    final s0 = _cumLen[lo];
    final s1 = _cumLen[lo + 1];
    final denom = (s1 - s0);
    if (denom <= 1e-9) return trackPolyline[lo];

    final a = (s - s0) / denom;
    final p0 = trackPolyline[lo];
    final p1 = trackPolyline[lo + 1];
    return Offset(p0.dx + (p1.dx - p0.dx) * a, p0.dy + (p1.dy - p0.dy) * a);
  }

  List<CarSample> sampleCarsAt(double t) {
    final out = <CarSample>[];
    for (final d in drivers) {
      final prog = d.sampleProgressAt(t);
      if (prog != null && lapLength > 0 && trackPolyline.length > 1) {
        double wrapped = prog % lapLength;
        if (wrapped < 0) wrapped += lapLength;
        final p = sampleTrackPos(wrapped);
        out.add(CarSample(code: d.code, pos: p));
      } else {
        final p = d.sampleAt(t);
        if (p != null) out.add(CarSample(code: d.code, pos: p));
      }
    }
    return out;
  }

  List<LeaderboardRow> computeLeaderboard(List<CarSample> carsNow) {
    throw Exception("Unused with new unwrap setup");
  }

  List<LeaderboardRow> computeLeaderboardAt(double t) {
    final rows = <LeaderboardRow>[];
    for (final d in drivers) {
      final p = d.sampleProgressAt(t);
      if (p == null) continue;
      rows.add(LeaderboardRow(code: d.code, progress: p));
    }
    rows.sort((a, b) => b.progress.compareTo(a.progress));
    return rows;
  }

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

class DriverSeries {
  final String code;
  final List<double> t;
  final List<double> x;
  final List<double> y;
  final List<double> progressUnwrapped;

  final List<double>? speed;
  final List<int>? gear;
  final List<int>? drs;

  DriverSeries({
    required this.code,
    required this.t,
    required this.x,
    required this.y,
    required this.progressUnwrapped,
    this.speed,
    this.gear,
    this.drs,
  });

  Offset? sampleAt(double timeS) {
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

  double? sampleSpeedAt(double timeS) {
    if (speed == null || speed!.isEmpty) return null;
    final idx = _bracketIndex(timeS);
    if (idx == null) return null;
    final lo = math.min(idx.lo, speed!.length - 1);
    final hi = math.min(idx.hi, speed!.length - 1);
    final a = idx.alpha;
    return speed![lo] + (speed![hi] - speed![lo]) * a;
  }

  int? sampleGearAt(double timeS) {
    if (gear == null || gear!.isEmpty) return null;
    final idx = _bracketIndex(timeS);
    if (idx == null) return null;
    final lo = math.min(idx.lo, gear!.length - 1);
    final hi = math.min(idx.hi, gear!.length - 1);
    return idx.alpha < 0.5 ? gear![lo] : gear![hi];
  }

  bool? sampleDrsAt(double timeS) {
    if (drs == null || drs!.isEmpty) return null;
    final idx = _bracketIndex(timeS);
    if (idx == null) return null;
    final lo = math.min(idx.lo, drs!.length - 1);
    final hi = math.min(idx.hi, drs!.length - 1);
    final v = idx.alpha < 0.5 ? drs![lo] : drs![hi];
    return v != 0;
  }

  _Bracket? _bracketIndex(double timeS) {
    if (t.isEmpty) return null;
    if (timeS <= t.first) return _Bracket(0, math.min(1, t.length - 1), 0.0);
    if (timeS >= t.last) {
      final hi = t.length - 1;
      return _Bracket(math.max(0, hi - 1), hi, 1.0);
    }

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
    final a = denom <= 1e-9 ? 0.0 : ((timeS - t0) / denom).clamp(0.0, 1.0);
    return _Bracket(lo, lo + 1, a);
  }
}

class _Bracket {
  final int lo;
  final int hi;
  final double alpha;
  _Bracket(this.lo, this.hi, this.alpha);
}

class CarSample {
  final String code;
  final Offset pos;
  CarSample({required this.code, required this.pos});
}

class LeaderboardRow {
  final String code;
  final double progress;
  LeaderboardRow({required this.code, required this.progress});
}

/* ----------------------------- Painting ----------------------------- */

class TrackPainter extends CustomPainter {
  final List<Offset> polyline;
  final List<CarSample> cars;
  final String? selected;

  TrackPainter({
    required this.polyline,
    required this.cars,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
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
      final color = TeamColors.colorForDriver(c.code);

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
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;

    for (final p in pts) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool shouldRepaint(covariant TrackPainter old) =>
      old.cars != cars || old.polyline != polyline || old.selected != selected;
}

/* ----------------------------- Compact Leaderboard ----------------------------- */

class _LeaderboardPanelCompact extends StatelessWidget {
  final List<LeaderboardRow> leaderboard;
  final String? selected;
  final Set<String> focused;
  final bool noneMode;

  final ValueChanged<String> onSelectSingle;
  final ValueChanged<String> onToggleFocus;
  final VoidCallback onFocusAll;
  final VoidCallback onFocusNone;

  const _LeaderboardPanelCompact({
    required this.leaderboard,
    required this.selected,
    required this.focused,
    required this.noneMode,
    required this.onSelectSingle,
    required this.onToggleFocus,
    required this.onFocusAll,
    required this.onFocusNone,
  });

  bool _isFocused(String code) {
    if (noneMode) return false;
    if (focused.isEmpty) return true;
    return focused.contains(code);
  }

  @override
  Widget build(BuildContext context) {
    const double rowVerticalPadding = 0.0;
    const textStyle = TextStyle(color: Colors.white70, fontSize: 10);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leaderboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  noneMode
                      ? 'Focus: none'
                      : (focused.isEmpty
                            ? 'Focus: all'
                            : 'Focus: ${focused.length}'),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: onFocusAll,
                child: const Text('All', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: onFocusNone,
                child: const Text('None', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 8, color: Color(0xFF2A2A2A)),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: leaderboard.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                final isSel = row.code == selected;
                final isFocused = _isFocused(row.code);
                final color = TeamColors.colorForDriver(row.code);

                return InkWell(
                  onTap: () => onSelectSingle(row.code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: rowVerticalPadding,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSel
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            '${i + 1}.',
                            style: isSel
                                ? const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  )
                                : textStyle,
                          ),
                        ),
                        Transform.scale(
                          scale: 0.7,
                          child: Checkbox(
                            value: isFocused,
                            onChanged: (_) => onToggleFocus(row.code),
                            activeColor: color,
                            checkColor: Colors.black,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(
                              horizontal: -4,
                              vertical: -4,
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            row.code,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              color: isSel ? Colors.white : Colors.white70,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Top Info ----------------------------- */

class _TopLeftInfo extends StatelessWidget {
  final double t;
  final double duration;
  final double speed;
  final String sessionName;

  const _TopLeftInfo({
    required this.t,
    required this.duration,
    required this.speed,
    required this.sessionName,
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
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.white, fontSize: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sessionName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Race Time: ${_fmt(t)}  (x${speed.toStringAsFixed(speed == speed.roundToDouble() ? 0 : 1)})',
          ),
          Text('Duration: ${_fmt(duration)}'),
        ],
      ),
    );
  }
}

/* ----------------------------- Driver Telemetry Card ----------------------------- */

class DriverTelemetryCard extends StatelessWidget {
  final String code;
  final double? speedKmh;
  final int? gear;
  final bool? drsOn;
  final String aheadText;
  final String behindText;

  const DriverTelemetryCard({
    super.key,
    required this.code,
    required this.speedKmh,
    required this.gear,
    required this.drsOn,
    required this.aheadText,
    required this.behindText,
  });

  @override
  Widget build(BuildContext context) {
    final color = TeamColors.colorForDriver(code);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.78),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              'Driver: $code',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
                        const Text(
                          'DRS',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          drsOn == true ? Icons.toggle_on : Icons.toggle_off,
                          color: drsOn == true
                              ? Colors.greenAccent
                              : Colors.white24,
                          size: 28,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _kv('Ahead', aheadText)),
                    const SizedBox(width: 4),
                    Expanded(child: _kv('Behind', behindText)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/* ----------------------------- Podium Widget ----------------------------- */

class PodiumWidgetReplay extends StatelessWidget {
  final List<String> top3;

  const PodiumWidgetReplay({super.key, required this.top3});

  @override
  Widget build(BuildContext context) {
    final first = top3.isNotEmpty ? top3[0] : '--';
    final second = top3.length > 1 ? top3[1] : '--';
    final third = top3.length > 2 ? top3[2] : '--';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.70),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 3',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _podiumItem(2, second)),
              const SizedBox(width: 6),
              Expanded(child: _podiumItem(1, first)),
              const SizedBox(width: 6),
              Expanded(child: _podiumItem(3, third)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumItem(int place, String code) {
    final color = TeamColors.colorForDriver(code);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E).withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '#$place',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                code,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Bottom Controls ----------------------------- */

class _BottomControls extends StatelessWidget {
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

  const _BottomControls({
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
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
          const SizedBox(width: 4),
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
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          'x${s.toStringAsFixed(s == s.roundToDouble() ? 0 : 1)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
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

/* ----------------------------- Error Card ----------------------------- */

class _CenteredCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _CenteredCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A).withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x00000000)),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _RaceReplayDropdownWidget extends StatefulWidget {
  final ApiClient api;
  final int initialSeason;
  final int defaultRound;
  final bool loading;
  final void Function(int season, int round, String sessionName) onLoad;

  const _RaceReplayDropdownWidget({
    required this.api,
    required this.initialSeason,
    required this.defaultRound,
    required this.loading,
    required this.onLoad,
  });

  @override
  State<_RaceReplayDropdownWidget> createState() =>
      _RaceReplayDropdownWidgetState();
}

class _RaceReplayDropdownWidgetState extends State<_RaceReplayDropdownWidget> {
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
        color: Colors.transparent,
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
