import 'package:flutter/material.dart';

class F1NavBar extends StatelessWidget {
  final Function(int)? onTabChanged;
  final int currentIndex;

  const F1NavBar({
    super.key,
    this.onTabChanged,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE10600),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            _buildTab("Home", Icons.home_rounded, 0),
            _buildTab("Overview", Icons.dashboard_rounded, 1),
            _buildTab("Charts", Icons.show_chart_rounded, 2),
            _buildLogo(),
            _buildTab("Tyre", Icons.tire_repair_rounded, 3),
            _buildTab("Replay", Icons.replay_circle_filled_rounded, 4),
            _buildTab("AI Chat", Icons.smart_toy_rounded, 5),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, int index) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onTabChanged?.call(index),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 14 : 10,
              vertical: isSelected ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: Colors.white.withOpacity(0.08),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 62,
      child: Center(
        child: Image.asset(
          "assets/images/f1_logo.png",
          width: 40,
          height: 18,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}