import 'package:flutter/material.dart';

class GlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [
            c.surface.withOpacity(0.85),
            c.surface.withOpacity(0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: c.primary.withOpacity(0.22),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: c.primary.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  const SectionTitle(this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: c.primary.withOpacity(0.9)),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: t.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}