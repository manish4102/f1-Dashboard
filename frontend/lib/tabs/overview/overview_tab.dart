// lib/tabs/overview/overview_tab.dart
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shell/session_provider.dart';
import '../../widgets/podium_widget.dart';
import '../../widgets/leaderboard_widget.dart';
import '../../api/api_client.dart';
import '../../widgets/f1_dropdown.dart';
import '../../widgets/f1_snackbar.dart';

class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  bool _loadedDefault = false;

  int _defaultSeason = 2026;
  int _defaultRound = 1;
  String _defaultSessionName = "Race";

  final ApiClient _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _fetchCurrentSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadDefaultOnce();
      _listenForLoad();
    });
  }

  void _listenForLoad() {
    ref.listen<SessionState>(sessionProvider, (previous, next) {
      if (next.justLoaded && previous?.justLoaded != true) {
        F1Snackbar.success(context, 'Overview loaded successfully!');
      }
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

    // Adjust this to match your floating navbar height + margin
    const double floatingNavOffset = 120;

    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: floatingNavOffset),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: _F1FiltersProviderBar(
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
                      if (st.error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          st.error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Expanded(child: _OverviewHome()),
        ],
      ),
    );
  }
}

class _OverviewHome extends ConsumerWidget {
  const _OverviewHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(sessionProvider);
    final payload = st.full;

    if (payload == null) {
      if (st.loading) return const Center(child: CircularProgressIndicator());
      return const Center(
        child: Text(
          "Load a session to view Overview.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final overview = Map<String, dynamic>.from(payload.overview ?? {});
    final leaderboard = List<dynamic>.from(overview["leaderboard"] ?? []);
    final podium = List<dynamic>.from(overview["podium"] ?? []);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/racing_flags.png',
                    width: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'PODIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/images/racing_flags.png',
                    width: 40,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PodiumWidget(podium: podium, payload: payload),
            ],
          ),
        ),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/racing_flags.png',
                  width: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                const Text(
                  'LEADERBOARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'assets/images/racing_flags.png',
                  width: 40,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            const SizedBox(height: 14),
            LeaderboardWidget(leaderboard: leaderboard, payload: payload),
          ],
        ),
      ],
    );
  }
}

class _F1FiltersProviderBar extends StatefulWidget {
  final ApiClient api;
  final int initialSeason;
  final int defaultRound;
  final bool loading;
  final void Function(int season, int round, String sessionName) onLoad;

  const _F1FiltersProviderBar({
    required this.api,
    required this.initialSeason,
    required this.defaultRound,
    required this.loading,
    required this.onLoad,
  });

  @override
  State<_F1FiltersProviderBar> createState() => _F1FiltersProviderBarState();
}

class _F1FiltersProviderBarState extends State<_F1FiltersProviderBar> {
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
              width: 200,
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
            const SizedBox(width: 14),
            F1Dropdown<GpEventLite>(
              width: 340,
              value: _event,
              placeholder: _loadingSchedule ? 'Loading…' : 'Grand Prix',
              prefixIcon: const Icon(
                Icons.flag,
                size: 18,
                color: Color(0xFFB6BCCB),
              ),
              isEqual: (a, b) => a.round == b.round,
              items: _events.map((e) {
                return F1DropdownItem<GpEventLite>(
                  value: e,
                  label: e.name,
                  leading: _flagCircle(e.countryCode),
                );
              }).toList(),
              onChanged: (e) {
                setState(() {
                  _event = e;
                  _session = null;
                });
              },
            ),
            const SizedBox(width: 14),
            F1Dropdown<GpSessionLite>(
              width: 260,
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

  static Widget _flagCircle(String iso2) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2A3240)),
      ),
      child: CircleAvatar(
        radius: 10,
        backgroundColor: const Color(0xFF1A2230),
        child: Text(
          iso2.isEmpty ? '' : iso2.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFFE6E8EE),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
