import 'dart:ui';
import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../widgets/f1_dropdown.dart';
import '../../shell/session_provider.dart';

class SessionSelectorDropdown extends StatefulWidget {
  final ApiClient api;
  final int initialSeason;
  final int defaultRound;
  final String defaultSessionName;
  final Function(int season, int round, String sessionName) onLoad;
  final bool showLoading;
  final String? error;

  const SessionSelectorDropdown({
    super.key,
    required this.api,
    required this.initialSeason,
    required this.defaultRound,
    required this.defaultSessionName,
    required this.onLoad,
    this.showLoading = false,
    this.error,
  });

  @override
  State<SessionSelectorDropdown> createState() =>
      _SessionSelectorDropdownState();
}

class _SessionSelectorDropdownState extends State<SessionSelectorDropdown> {
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
      if (mounted) {
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
      }
    } finally {
      if (mounted) {
        setState(() => _loadingSchedule = false);
      }
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
        !widget.showLoading &&
        !_loadingSchedule &&
        _event != null &&
        _session != null;

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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Material(
              color: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                    items: _events.map((e) {
                      return F1DropdownItem<GpEventLite>(
                        value: e,
                        label: e.name,
                      );
                    }).toList(),
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
                          (s) => F1DropdownItem<GpSessionLite>(
                            value: s,
                            label: s.name,
                          ),
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
                          if (widget.showLoading)
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
          ),
        ),
      ),
    );
  }
}
