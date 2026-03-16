import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'f1_theme.dart';

class SpecialMentionsSection extends StatelessWidget {
  final GlobalKey sectionKey;

  const SpecialMentionsSection({super.key, required this.sectionKey});

  @override
  Widget build(BuildContext context) {
    final mentions = <_SpecialMentionData>[
      const _SpecialMentionData(
        title: "Bernd Mayländer",
        subtitle: "Safety Car Driver",
        image: "assets/images/f1_safety_car.png",
        details: [
          "Born: 29.05.1974",
          "Hometown: Schorndorf, Germany",
          "Safety car driver since: 2000",
          "Current model: Mercedes-AMG GT R",
        ],
      ),
      const _SpecialMentionData(
        title: "Track Marshals",
        subtitle: "The Unsung Heroes",
        image: "assets/images/f1_track_marshalls.png",
        details: [
          "Responsible for trackside safety",
          "Help clear incidents and debris",
          "Support race control operations",
          "Essential to every Grand Prix weekend",
        ],
      ),
      const _SpecialMentionData(
        title: "Pit Crew",
        subtitle: "Precision Under Pressure",
        image: "assets/images/f1_pit_crew.png",
        details: [
          "Execute tyre changes in seconds",
          "Handle front and rear jacks",
          "Coordinate repairs during races",
          "Crucial for strategy and race outcomes",
        ],
      ),
      const _SpecialMentionData(
        title: "Will Buxton",
        subtitle: "F1 Journalist & Broadcaster",
        image: "assets/images/will_buxton.png",
        details: [
          "Known for Formula 1 reporting and broadcasting",
          "Familiar face across F1 media coverage",
          "Popular for gridwalks, analysis, and interviews",
          "One of the most recognizable journalists in modern F1",
        ],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        key: sectionKey,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Special Mentions",
              style: TextStyle(
                color: F1Theme.f1Red,
                fontSize: 72,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 30),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1100;
                final isTablet = constraints.maxWidth >= 700;

                final cardWidth = isDesktop
                    ? 300.0
                    : isTablet
                        ? 280.0
                        : 260.0;

                final cardHeight = isDesktop
                    ? 420.0
                    : isTablet
                        ? 380.0
                        : 340.0;

                const spacing = 28.0;

                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        mentions.length,
                        (i) => Padding(
                          padding: EdgeInsets.only(
                            right: i == mentions.length - 1 ? 0 : spacing,
                          ),
                          child: _FlipMentionCard(
                            data: mentions[i],
                            width: cardWidth,
                            height: cardHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialMentionData {
  final String title;
  final String subtitle;
  final String image;
  final List<String> details;

  const _SpecialMentionData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.details,
  });
}

class _FlipMentionCard extends StatefulWidget {
  final _SpecialMentionData data;
  final double width;
  final double height;

  const _FlipMentionCard({
    required this.data,
    required this.width,
    required this.height,
  });

  @override
  State<_FlipMentionCard> createState() => _FlipMentionCardState();
}

class _FlipMentionCardState extends State<_FlipMentionCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final angle = hovered ? math.pi : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: hovered
            ? (Matrix4.identity()..translate(0.0, -6.0))
            : Matrix4.identity(),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: angle),
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            final isBack = value > math.pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(value),
              child: isBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _buildBackCard(),
                    )
                  : _buildFrontCard(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              widget.data.image,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.18),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.data.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            F1Theme.f1Red,
            const Color(0xFF161616),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.data.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.data.subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            const Divider(
              color: Colors.white24,
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 20),
            ...widget.data.details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  detail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}