import 'package:flutter/material.dart';
import 'package:f1/api/api_client.dart';
import 'f1_dropdown.dart';

class F1FiltersBar extends StatefulWidget {
  final ApiClient api;
  final int initialSeason;

  /// Full payload callback (so you can update the dashboard)
  final void Function(Map<String, dynamic> fullPayload)? onFullPayload;

  const F1FiltersBar({
    super.key,
    required this.api,
    this.initialSeason = 2025,
    this.onFullPayload,
  });

  @override
  State<F1FiltersBar> createState() => _F1FiltersBarState();
}

class _F1FiltersBarState extends State<F1FiltersBar> {
  late int _season;

  List<GpEventLite> _events = [];
  GpEventLite? _event;
  GpSessionLite? _session;

  bool _loadingSchedule = false;
  bool _loadingSession = false;

  @override
  void initState() {
    super.initState();
    _season = widget.initialSeason;
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
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

        // Default selections
        _event = events.isNotEmpty ? events.first : null;

        // Choose Race if present, else last session, else null
        final ses = _event?.sessions ?? const <GpSessionLite>[];
        _session = _pickDefaultSession(ses);
      });
    } finally {
      if (mounted) setState(() => _loadingSchedule = false);
    }
  }

  static GpSessionLite? _pickDefaultSession(List<GpSessionLite> sessions) {
    if (sessions.isEmpty) return null;

    // Prefer "Race"
    for (final s in sessions) {
      if (s.name.toLowerCase() == 'race') return s;
    }
    // Otherwise last one
    return sessions.last;
  }

  Future<void> _loadSelectedSession() async {
    final ev = _event;
    final ses = _session;
    if (ev == null || ses == null) return;

    setState(() => _loadingSession = true);

    try {
      // 1) POST /load-session -> cache_id
      final load = await widget.api.loadSession(
        season: _season,
        round: ev.round,
        sessionName: ses.name,
      );

      final cacheId = (load['cache_id'] ?? '').toString();
      if (cacheId.isEmpty) {
        throw Exception('load-session did not return cache_id');
      }

      // 2) GET /session/{cacheId}/full
      final full = await widget.api.getFull(cacheId: cacheId);

      widget.onFullPayload?.call(Map<String, dynamic>.from(full));
    } finally {
      if (mounted) setState(() => _loadingSession = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = widget.initialSeason;
    final seasons = [
      currentYear + 1,
      currentYear,
      currentYear - 1,
      currentYear - 2,
      currentYear - 3,
      currentYear - 4,
      currentYear - 5,
      currentYear - 6,
      currentYear - 7,
      currentYear - 8,
    ];
    final sessions = _event?.sessions ?? const <GpSessionLite>[];

    return Row(
      children: [
        // Season
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
            setState(() => _season = y);
            _loadSchedule();
          },
        ),
        const SizedBox(width: 14),

        // Grand Prix
        F1Dropdown<GpEventLite>(
          width: 340,
          value: _event,
          placeholder: _loadingSchedule ? 'Loading…' : 'Grand Prix',
          prefixIcon: const Icon(
            Icons.flag,
            size: 18,
            color: Color(0xFFB6BCCB),
          ),
          items: _events
              .map(
                (e) => F1DropdownItem<GpEventLite>(
                  value: e,
                  label: e.name,
                  leading: _flagCircle(e.countryCode),
                ),
              )
              .toList(),
          onChanged: (e) {
            setState(() {
              _event = e;
              _session = _pickDefaultSession(e.sessions);
            });
          },
        ),
        const SizedBox(width: 14),

        // Session
        F1Dropdown<GpSessionLite>(
          width: 260,
          value: _session,
          placeholder: 'Session',
          prefixIcon: const Icon(
            Icons.sports_motorsports,
            size: 18,
            color: Color(0xFFB6BCCB),
          ),
          items: sessions
              .map(
                (s) => F1DropdownItem<GpSessionLite>(value: s, label: s.name),
              )
              .toList(),
          onChanged: (s) async {
            setState(() => _session = s);
            await _loadSelectedSession();
          },
        ),
        const SizedBox(width: 12),

        if (_loadingSession)
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  static Widget _flagCircle(String iso2) {
    // Replace with real flag assets later if you want
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
