import 'package:flutter/material.dart';

import 'telemetry_factor_registry.dart';

Future<Set<String>?> showTelemetryFactorSheet({
  required BuildContext context,
  required Set<String> selected,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TelemetryFactorSheet(selected: selected),
  );
}

class _TelemetryFactorSheet extends StatefulWidget {
  final Set<String> selected;

  const _TelemetryFactorSheet({required this.selected});

  @override
  State<_TelemetryFactorSheet> createState() => _TelemetryFactorSheetState();
}

class _TelemetryFactorSheetState extends State<_TelemetryFactorSheet> {
  late final Set<String> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = {...widget.selected}; // local copy
  }

  @override
  Widget build(BuildContext context) {
    final items = telemetryFactors; // List<TelemetryFactorItem>

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: const Color(0xFF111114),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  _pillButton(
                    label: "Edit",
                    onTap: () {},
                  ),
                  const Spacer(),
                  const Text(
                    "Telemetry Charts",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  _pillButton(
                    label: "✕",
                    isIconOnly: true,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 10),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.white.withOpacity(0.06),
                ),
                itemBuilder: (context, i) {
                  final it = items[i];
                  final selected = _localSelected.contains(it.key);

                  return InkWell(
                    onTap: () => setState(() {
                      if (selected) {
                        _localSelected.remove(it.key);
                      } else {
                        _localSelected.add(it.key);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // icon pill
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Icon(it.icon, color: Colors.white.withOpacity(0.85)),
                          ),
                          const SizedBox(width: 14),

                          Expanded(
                            child: Text(
                              it.label,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                          ),

                          // checkbox
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFFF3B30) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFFF3B30)
                                    : Colors.white.withOpacity(0.20),
                                width: 2,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer helper text
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
              child: Text(
                "Customize the telemetry data displayed to align with your individual preferences.",
                style: TextStyle(color: Colors.white.withOpacity(0.35)),
                textAlign: TextAlign.center,
              ),
            ),

            // ✅ LOAD BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Return chosen selection to ChartsTab
                    Navigator.pop(context, _localSelected);
                  },
                  child: const Text(
                    "Load charts",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required VoidCallback onTap,
    bool isIconOnly = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isIconOnly ? 14 : 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}