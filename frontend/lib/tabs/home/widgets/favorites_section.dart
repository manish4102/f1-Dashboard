import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'f1_theme.dart';

class FavoritesSection extends StatelessWidget {
  final GlobalKey sectionKey;

  const FavoritesSection({super.key, required this.sectionKey});

  @override
  Widget build(BuildContext context) {
    final favorites = <_FavoriteData>[
      const _FavoriteData(
        title: "Favorite Driver",
        name: "Charles Leclerc",
        image: "assets/images/fav_driver.png",
        details: [
          "Ferrari driver from Monaco",
          "One of the fastest qualifiers in F1",
          "Multiple Grand Prix victories",
          "A modern Ferrari icon",
        ],
      ),
      const _FavoriteData(
        title: "Favorite Team",
        name: "Scuderia Ferrari",
        image: "assets/images/fav_team.png",
        details: [
          "The most historic team in Formula 1",
          "Founded by Enzo Ferrari",
          "Home to legendary drivers",
          "One of the most passionate fanbases in motorsport",
        ],
      ),
      const _FavoriteData(
        title: "Favorite Circuit",
        name: "Circuit de Monaco",
        image: "assets/images/fav_circuit.png",
        details: [
          "One of the most iconic circuits in Formula 1",
          "Narrow streets of Monte Carlo",
          "First held in 1929",
          "Considered the ultimate driver challenge",
        ],
      ),
      const _FavoriteData(
        title: "Favorite F1 Legend",
        name: "Michael Schumacher",
        image: "assets/images/michael_schumacher.png",
        details: [
          "7× Formula One World Champion",
          "Dominated F1 with Ferrari in the 2000s",
          "One of the greatest drivers in history",
          "Set numerous records in Formula 1",
        ],
      ),
      const _FavoriteData(
        title: "Favorite Driver Parade",
        name: "Miami GP 2025 Drivers’ Parade",
        image: "assets/images/fav_driver_parade.png",
        details: [
          "Unique boat-style parade in Miami",
          "Drivers presented on floating platforms",
          "One of the most creative F1 driver parades",
          "A memorable moment from the 2025 season",
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
              "Favorites",
              style: TextStyle(
                color: F1Theme.f1Red,
                fontSize: 72,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 30),

            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;

                final cardWidth = isDesktop ? 320.0 : 280.0;
                final cardHeight = isDesktop ? 420.0 : 360.0;

                const spacing = 28.0;

                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        favorites.length,
                        (i) => Padding(
                          padding: EdgeInsets.only(
                              right: i == favorites.length - 1 ? 0 : spacing),
                          child: _FavoriteFlipCard(
                            data: favorites[i],
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

class _FavoriteData {
  final String title;
  final String name;
  final String image;
  final List<String> details;

  const _FavoriteData({
    required this.title,
    required this.name,
    required this.image,
    required this.details,
  });
}

class _FavoriteFlipCard extends StatefulWidget {
  final _FavoriteData data;
  final double width;
  final double height;

  const _FavoriteFlipCard({
    required this.data,
    required this.width,
    required this.height,
  });

  @override
  State<_FavoriteFlipCard> createState() => _FavoriteFlipCardState();
}

class _FavoriteFlipCardState extends State<_FavoriteFlipCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final angle = hovered ? math.pi : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
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
            Image.asset(widget.data.image, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data.title,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(widget.data.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
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
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.data.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            ...widget.data.details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(detail,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}