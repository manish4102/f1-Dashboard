// lib/widgets/session_select_bar.dart
import 'package:flutter/material.dart';

/// ----------------------------
/// GP EVENT MODEL + HELPERS
/// ----------------------------
class GpEvent {
  final int round;
  final String name;
  final String countryCode; // ISO 2-letter (IT, US, JP...)

  const GpEvent({
    required this.round,
    required this.name,
    required this.countryCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GpEvent && runtimeType == other.runtimeType && round == other.round;

  @override
  int get hashCode => round.hashCode;
}

String flagEmoji(String countryCode) {
  final cc = countryCode.toUpperCase();
  if (cc.length != 2) return "";
  const base = 0x1F1E6;
  final a = cc.codeUnitAt(0) - 0x41 + base;
  final b = cc.codeUnitAt(1) - 0x41 + base;
  return String.fromCharCode(a) + String.fromCharCode(b);
}

/// ✅ 2025 calendar (edit as you like)
const List<GpEvent> events2025 = [
  GpEvent(round: 1, name: "Bahrain Grand Prix", countryCode: "BH"),
  GpEvent(round: 2, name: "Saudi Arabian Grand Prix", countryCode: "SA"),
  GpEvent(round: 3, name: "Australian Grand Prix", countryCode: "AU"),
  GpEvent(round: 4, name: "Japanese Grand Prix", countryCode: "JP"),
  GpEvent(round: 5, name: "Chinese Grand Prix", countryCode: "CN"),
  GpEvent(round: 6, name: "Miami Grand Prix", countryCode: "US"),
  GpEvent(round: 7, name: "Emilia Romagna Grand Prix", countryCode: "IT"),
  GpEvent(round: 8, name: "Monaco Grand Prix", countryCode: "MC"),
  GpEvent(round: 9, name: "Canadian Grand Prix", countryCode: "CA"),
  GpEvent(round: 10, name: "Spanish Grand Prix", countryCode: "ES"),
  GpEvent(round: 11, name: "Austrian Grand Prix", countryCode: "AT"),
  GpEvent(round: 12, name: "British Grand Prix", countryCode: "GB"),
  GpEvent(round: 13, name: "Hungarian Grand Prix", countryCode: "HU"),
  GpEvent(round: 14, name: "Belgian Grand Prix", countryCode: "BE"),
  GpEvent(round: 15, name: "Dutch Grand Prix", countryCode: "NL"),
  GpEvent(round: 16, name: "Italian Grand Prix", countryCode: "IT"),
  GpEvent(round: 17, name: "Azerbaijan Grand Prix", countryCode: "AZ"),
  GpEvent(round: 18, name: "Singapore Grand Prix", countryCode: "SG"),
  GpEvent(round: 19, name: "United States Grand Prix", countryCode: "US"),
  GpEvent(round: 20, name: "Mexico City Grand Prix", countryCode: "MX"),
  GpEvent(round: 21, name: "São Paulo Grand Prix", countryCode: "BR"),
  GpEvent(round: 22, name: "Las Vegas Grand Prix", countryCode: "US"),
  GpEvent(round: 23, name: "Qatar Grand Prix", countryCode: "QA"),
  GpEvent(round: 24, name: "Abu Dhabi Grand Prix", countryCode: "AE"),
];

/// ----------------------------
/// SESSION SELECT BAR
/// ----------------------------
/// Dropdowns + Load button, centered.
/// No "SESSION SELECT" title (as you requested).
class SessionSelectBar extends StatelessWidget {
  const SessionSelectBar({
    super.key,
    required this.season,
    required this.onSeasonChanged,
    required this.event,
    required this.onEventChanged,
    required this.sessionName,
    required this.onSessionChanged,
    required this.onLoadPressed,
    required this.loading,
    required this.cacheId,
    this.seasons = const [2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019],
    this.events = events2025,
    this.sessions = const [
      "Race",
      "Qualifying",
      "Sprint",
      "Practice 1",
      "Practice 2",
      "Practice 3",
    ],
    this.maxWidth = 1280,
  });

  final int season;
  final ValueChanged<int> onSeasonChanged;

  final GpEvent event;
  final ValueChanged<GpEvent> onEventChanged;

  final String sessionName;
  final ValueChanged<String> onSessionChanged;

  final Future<void> Function() onLoadPressed;

  final bool loading;
  final String? cacheId;

  final List<int> seasons;
  final List<GpEvent> events;
  final List<String> sessions;

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: [
                SizedBox(
                  width: 220,
                  child: _SelectField<int>(
                    label: "Season",
                    value: season,
                    items: seasons,
                    itemBuilder: (v) => Text(
                      v.toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onChanged: onSeasonChanged,
                    leading: const Icon(Icons.calendar_month, size: 18, color: Colors.white70),
                    selectedLabel: (v) => v.toString(),
                  ),
                ),
                const SizedBox(width: 14),

                SizedBox(
                  width: 360,
                  child: _SelectField<GpEvent>(
                    label: "Event",
                    value: event,
                    items: events,
                    itemBuilder: (e) => Row(
                      children: [
                        Text(flagEmoji(e.countryCode), style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    selectedLabel: (e) => "${flagEmoji(e.countryCode)}  ${e.name}",
                    onChanged: onEventChanged,
                    leading: const Icon(Icons.flag_outlined, size: 18, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 14),

                SizedBox(
                  width: 240,
                  child: _SelectField<String>(
                    label: "Session",
                    value: sessionName,
                    items: sessions,
                    itemBuilder: (s) => Text(s, overflow: TextOverflow.ellipsis),
                    selectedLabel: (s) => s,
                    onChanged: onSessionChanged,
                    leading: const Icon(Icons.sports_motorsports, size: 18, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 14),

                _LoadButton(
                  loading: loading,
                  onPressed: () => onLoadPressed(),
                ),

                const SizedBox(width: 14),

                if (cacheId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Text(
                      "Cache: $cacheId",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------------------
/// LOAD BUTTON (red pill like your screenshot)
/// ----------------------------
class _LoadButton extends StatelessWidget {
  const _LoadButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.92), width: 3),
          boxShadow: [
            BoxShadow(
              blurRadius: 28,
              offset: const Offset(0, 12),
              color: Colors.black.withOpacity(0.55),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB90000),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.download, size: 18),
          label: Text(
            loading ? "LOADING…" : "LOAD",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// ----------------------------
/// SELECT FIELD (white closed value + red focus border)
/// ----------------------------
class _SelectField<T> extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    this.leading,
    this.selectedLabel,
  });

  final String label;
  final T value;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final ValueChanged<T> onChanged;
  final Widget? leading;

  /// custom label for the CLOSED (selected) state
  final String Function(T)? selectedLabel;

  String _fallbackText(T v) => v.toString();

  @override
  Widget build(BuildContext context) {
    final closedText = selectedLabel?.call(value);

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
      menuMaxHeight: 360,

      // ✅ Menu is white like your screenshots
      dropdownColor: Colors.white,

      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),

        prefixIcon: leading == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 12, right: 6),
                child: leading,
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),

        filled: true,
        fillColor: Colors.black.withOpacity(0.25),

        // ✅ default border (subtle)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),

        // ✅ red border when selected/open (focus)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB90000), width: 2),
        ),
      ),

      // ✅ CLOSED value always white (fixes “black selected text”)
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),

      selectedItemBuilder: (ctx) {
        return items.map((it) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              closedText ?? _fallbackText(value),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }).toList();
      },

      // ✅ Menu items are black text on white background
      items: items.map((v) {
        return DropdownMenuItem<T>(
          value: v,
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
            child: itemBuilder(v),
          ),
        );
      }).toList(),

      onChanged: (v) {
        if (v == null) return;
        onChanged(v);
      },
    );
  }
}