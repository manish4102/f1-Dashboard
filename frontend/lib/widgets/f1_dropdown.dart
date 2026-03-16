import 'package:flutter/material.dart';

class F1DropdownItem<T> {
  final T value;
  final String label;
  final Widget? leading;
  const F1DropdownItem({required this.value, required this.label, this.leading});
}

class F1Dropdown<T> extends StatefulWidget {
  final T? value;
  final List<F1DropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final Widget? prefixIcon;
  final String placeholder;
  final double width;

  /// Optional equality comparator for complex objects.
  /// If not provided, defaults to (a == b).
  final bool Function(T a, T b)? isEqual;

  const F1Dropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.placeholder,
    this.prefixIcon,
    this.width = 280,
    this.isEqual,
  });

  @override
  State<F1Dropdown<T>> createState() => _F1DropdownState<T>();
}

class _F1DropdownState<T> extends State<F1Dropdown<T>> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  bool get _isOpen => _entry != null;

  bool _eq(T a, T b) {
    final cmp = widget.isEqual;
    if (cmp != null) return cmp(a, b);
    return a == b;
  }

  void _toggle() => _isOpen ? _close() : _open();

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  void _open() {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;

    _entry = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            // click outside to close
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox(),
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 8),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: widget.width,
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1218),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A3240), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 28,
                        spreadRadius: 0,
                        offset: Offset(0, 14),
                        color: Color(0x99000000),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: widget.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, i) {
                        final it = widget.items[i];
                        final v = widget.value;
                        final selected = v != null && _eq(it.value, v);

                        return InkWell(
                          onTap: () {
                            widget.onChanged(it.value);
                            _close();
                          },
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF1A2230) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                if (it.leading != null) ...[
                                  SizedBox(width: 22, height: 22, child: it.leading),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Text(
                                    it.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selected ? Colors.white : const Color(0xFFE6E8EE),
                                      fontSize: 14,
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(Icons.check, color: Color(0xFFE6E8EE), size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_entry!);
  }

  @override
  void didUpdateWidget(covariant F1Dropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If parent rebuild changes items/value while menu is open,
    // close to avoid stale overlay state.
    final oldV = oldWidget.value;
    final newV = widget.value;
    final changed =
        (oldV == null && newV != null) ||
        (oldV != null && newV == null) ||
        (oldV != null && newV != null && !_eq(oldV, newV));

    if (_isOpen && changed) {
      _close();
    }
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? label;
    final v = widget.value;

    if (v != null) {
      for (final it in widget.items) {
        if (_eq(it.value, v)) {
          label = it.label;
          break;
        }
      }
    }

    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          width: widget.width,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF121722),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A3240), width: 1),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                widget.prefixIcon!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label ?? widget.placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label == null ? const Color(0xFFB6BCCB) : const Color(0xFFEFF2F8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(0xFFB6BCCB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}