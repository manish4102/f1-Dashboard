import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/glow.dart';
import 'session_provider.dart';

class SessionHeader extends ConsumerStatefulWidget {
  const SessionHeader({super.key});

  @override
  ConsumerState<SessionHeader> createState() => _SessionHeaderState();
}

class _SessionHeaderState extends ConsumerState<SessionHeader> {
  int season = DateTime.now().year;
  int round = 1;
  String sessionName = "Race";

  List<int> get seasons => List.generate(8, (i) => DateTime.now().year - i);
  List<int> get rounds => List.generate(24, (i) => i + 1);
  List<String> get sessions => const [
    "Race",
    "Qualifying",
    "Sprint",
    "Sprint Qualifying",
    "Practice 1",
    "Practice 2",
    "Practice 3",
  ];

  @override
  Widget build(BuildContext context) {
    final SessionState st = ref.watch(sessionProvider);

    final c = Theme.of(context).colorScheme;

    return GlowCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("SESSION SELECT", icon: Icons.tune),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _dropdown<int>(
                label: "Season",
                value: season,
                items: seasons,
                onChanged: (v) => setState(() => season = v),
              ),
              _dropdown<int>(
                label: "Event",
                value: round,
                items: rounds,
                itemLabel: (r) => "Round $r",
                onChanged: (v) => setState(() => round = v),
              ),
              _dropdown<String>(
                label: "Session",
                value: sessionName,
                items: sessions,
                onChanged: (v) => setState(() => sessionName = v),
              ),
              FilledButton.icon(
                onPressed: st.loading
                    ? null
                    : () => ref
                          .read(sessionProvider.notifier)
                          .load(
                            season: season,
                            round: round,
                            sessionName: sessionName,
                          ),
                icon: st.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: const Text("Load"),
              ),

              // ✅ This is safe now because st is SessionState
              if (st.cacheId != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: c.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.primary.withOpacity(0.22)),
                  ),
                  child: Text(
                    "Cache: ${st.cacheId}",
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (st.error != null)
            Text(st.error!, style: const TextStyle(color: Colors.redAccent)),
          if (st.full != null) ...[
            const SizedBox(height: 6),
            Text(
              "${st.full!.meta["event_name"] ?? ""} • ${st.full!.meta["country"] ?? ""}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T> onChanged,
    String Function(T v)? itemLabel,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map(
              (e) => DropdownMenuItem<T>(
                value: e,
                child: Text(itemLabel != null ? itemLabel(e) : e.toString()),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          onChanged(v);
        },
      ),
    );
  }
}
