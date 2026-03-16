import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'f1_theme.dart';

class CarsTeamsSection extends StatelessWidget {
  final GlobalKey sectionKey;

  const CarsTeamsSection({super.key, required this.sectionKey});

  static const Map<String, Color> teamColor = {
    'mclaren': Color(0xFFFF7A00),
    'redbull': Color(0xFF1C3D7A),
    'ferrari': Color(0xFFD00019),
    'mercedes': Color(0xFF00D2BE),
    'astonmartin': Color(0xFF0A6B5B),
    'alpine': Color.fromARGB(255, 195, 42, 255),
    'williams': Color(0xFF005AFF),
    'haas': Color(0xFFB0B0B0),
    'stake': Color(0xFF00C853),
    'rb': Color(0xFF6C5CE7),
    'audi': Color(0xFFB30000),
    'cadillac': Color(0xFF003A8F),
    'default': Color(0xFF2B2B2B),
  };

  @override
  Widget build(BuildContext context) {
    final teams = <_TeamCardData>[
      const _TeamCardData(
        "Mercedes",
        "George Russell • Kimi Antonelli",
        "mercedes",
        "assets/images/cars/mercedes_front.png",
        "assets/images/logos/mercedes.png",
      ),
      const _TeamCardData(
        "Ferrari",
        "Charles Leclerc • Lewis Hamilton",
        "ferrari",
        "assets/images/cars/ferrari_front.png",
        "assets/images/logos/ferrari.png",
      ),
      const _TeamCardData(
        "McLaren",
        "Lando Norris • Oscar Piastri",
        "mclaren",
        "assets/images/cars/mclaren_front.png",
        "assets/images/logos/mclaren_nobg.png",
      ),
      const _TeamCardData(
        "Red Bull Racing",
        "Max Verstappen • Isack Hadjar",
        "redbull",
        "assets/images/cars/redbull_front.png",
        "assets/images/logos/redbull.png",
      ),
      const _TeamCardData(
        "Aston Martin",
        "Fernando Alonso • Lance Stroll",
        "astonmartin",
        "assets/images/cars/aston_martin_front.png",
        "assets/images/logos/aston_martin.png",
      ),
      const _TeamCardData(
        "Alpine",
        "Pierre Gasly • Franco Colapinto • Jack Doohan",
        "alpine",
        "assets/images/cars/alpine_front.png",
        "assets/images/logos/alpine.png",
      ),
      const _TeamCardData(
        "Williams",
        "Alexander Albon • Carlos Sainz",
        "williams",
        "assets/images/cars/williams_front.png",
        "assets/images/logos/williams.png",
      ),
      const _TeamCardData(
        "Haas",
        "Ollie Bearman • Esteban Ocon",
        "haas",
        "assets/images/cars/haas_front.png",
        "assets/images/logos/haas_nobg.png",
      ),
      const _TeamCardData(
        "Racing Bulls",
        "Arvid Lindblad • Liam Lawson",
        "rb",
        "assets/images/cars/rb_front.png",
        "assets/images/logos/rb.png",
      ),
      const _TeamCardData(
        "Audi",
        "Gabriel Bortoleto • Nico Hulkenberg",
        "audi",
        "assets/images/cars/audi_front.png",
        "assets/images/logos/audi.png",
      ),
      const _TeamCardData(
        "Cadillac",
        "Sergio Perez • Valtteri Bottas",
        "cadillac",
        "assets/images/cars/cadillac_front.png",
        "assets/images/logos/cadillac.png",
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        key: sectionKey,
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Teams",
              style: TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 24),
            _TeamsInfiniteCoverFlowCarousel(teams: teams),
          ],
        ),
      ),
    );
  }
}

class _TeamCardData {
  final String name;
  final String drivers;
  final String teamKey;
  final String image;
  final String logo;

  const _TeamCardData(
    this.name,
    this.drivers,
    this.teamKey,
    this.image,
    this.logo,
  );
}

class _TeamsInfiniteCoverFlowCarousel extends StatefulWidget {
  final List<_TeamCardData> teams;

  const _TeamsInfiniteCoverFlowCarousel({
    required this.teams,
  });

  @override
  State<_TeamsInfiniteCoverFlowCarousel> createState() =>
      _TeamsInfiniteCoverFlowCarouselState();
}

class _TeamsInfiniteCoverFlowCarouselState
    extends State<_TeamsInfiniteCoverFlowCarousel> {
  static const int _sideCount = 5;
  static const int _virtualItemCount = 200000;

  late final int _initialPage;
  late final PageController _controller;

  double _page = 0.0;

  @override
  void initState() {
    super.initState();

    final middle = _virtualItemCount ~/ 2;
    final normalizedMiddle = middle - (middle % widget.teams.length);

    _initialPage = normalizedMiddle;
    _controller = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.18,
    );

    _page = _initialPage.toDouble();

    _controller.addListener(() {
      final current = _controller.page ?? _page;
      if (mounted) {
        setState(() => _page = current);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _teamIndexFromVirtual(int virtualIndex) {
    final len = widget.teams.length;
    return ((virtualIndex % len) + len) % len;
  }

  void _handleWheel(PointerScrollEvent event) {
    if (!_controller.hasClients) return;

    final dominant =
        event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
            ? event.scrollDelta.dx
            : event.scrollDelta.dy;

    final target = (_controller.offset + dominant).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );

    _controller.jumpTo(target);
  }

  void _animateToRelative(int offsetFromCenter) {
    final target = (_page.round() + offsetFromCenter)
        .clamp(0, _virtualItemCount - 1);
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _animateToRealTeamIndex(int realIndex) {
    final currentVirtual = _page.round();
    final currentReal = _teamIndexFromVirtual(currentVirtual);
    final len = widget.teams.length;

    int forward = (realIndex - currentReal + len) % len;
    int backward = forward - len;

    final bestOffset = forward.abs() <= backward.abs() ? forward : backward;
    _animateToRelative(bestOffset);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final cardWidth = isDesktop ? 500.0 : 360.0;
        final cardHeight = isDesktop ? 590.0 : 450.0;
        final carouselHeight = isDesktop ? 760.0 : 560.0;

        final centerX = constraints.maxWidth / 2;
        final centerY = carouselHeight / 2 - 6;

        final centerVirtual = _page.round();
        final activeRealIndex = _teamIndexFromVirtual(centerVirtual);
        final activeTeam = widget.teams[activeRealIndex];
        final glowColor =
            CarsTeamsSection.teamColor[activeTeam.teamKey] ??
            CarsTeamsSection.teamColor['default']!;

        final visibleCards = <_VirtualCardLayoutData>[];

        for (int offset = -_sideCount; offset <= _sideCount; offset++) {
          final virtualIndex = centerVirtual + offset;
          final delta = virtualIndex - _page;
          final teamIndex = _teamIndexFromVirtual(virtualIndex);

          visibleCards.add(
            _VirtualCardLayoutData(
              virtualIndex: virtualIndex,
              teamIndex: teamIndex,
              delta: delta,
              absDelta: delta.abs(),
            ),
          );
        }

        visibleCards.sort((a, b) => b.absDelta.compareTo(a.absDelta));

        return Listener(
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent) {
              _handleWheel(signal);
            }
          },
          child: SizedBox(
            height: carouselHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -10),
                        child: Container(
                          width: cardWidth * 1.45,
                          height: cardHeight * 1.05,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withOpacity(0.20),
                                blurRadius: 180,
                                spreadRadius: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _virtualItemCount,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, __) => const SizedBox.expand(),
                  ),
                ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ...visibleCards.map((item) {
                          final team = widget.teams[item.teamIndex];
                          final d = item.delta;
                          final a = item.absDelta;
                          final t = (a / _sideCount).clamp(0.0, 1.0);

                          final scale = _lerp(1.0, 0.60, t);
                          final rotation = _lerp(0.0, 0.24, t) * d.sign;
                          final translateY = _lerp(0.0, 76.0, t);

                          final baseSpacing = isDesktop ? 132.0 : 94.0;
                          final curveSpacing = isDesktop ? 22.0 : 14.0;
                          final translateX =
                              (d * baseSpacing) +
                              (math.pow(d.abs(), 1.22) *
                                  curveSpacing *
                                  d.sign);

                          final dimOpacity = _lerp(0.0, 0.45, t);
                          final cardOpacity = _lerp(1.0, 0.44, t);
                          final shadowBlur = _lerp(36.0, 12.0, t);
                          final shadowOffsetY = _lerp(28.0, 10.0, t);

                          final showFullText = a < 1.35;
                          final isCenter = a < 0.5;

                          return Positioned(
                            left: centerX - (cardWidth / 2) + translateX,
                            top: centerY - (cardHeight / 2) + translateY,
                            child: Opacity(
                              opacity: cardOpacity,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0011)
                                  ..rotateZ(rotation)
                                  ..scale(scale, scale),
                                child: _SmoothTeamCard(
                                  data: team,
                                  width: cardWidth,
                                  height: cardHeight,
                                  dimOpacity: dimOpacity,
                                  shadowBlur: shadowBlur,
                                  shadowOffsetY: shadowOffsetY,
                                  showFullText: showFullText,
                                  isCenter: isCenter,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 2,
                  child: _CarouselIndicators(
                    count: widget.teams.length,
                    activeIndex: activeRealIndex,
                    activeColor: glowColor,
                    onTap: _animateToRealTeamIndex,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _lerp(double a, double b, double t) => a + ((b - a) * t);
}

class _VirtualCardLayoutData {
  final int virtualIndex;
  final int teamIndex;
  final double delta;
  final double absDelta;

  const _VirtualCardLayoutData({
    required this.virtualIndex,
    required this.teamIndex,
    required this.delta,
    required this.absDelta,
  });
}

class _SmoothTeamCard extends StatelessWidget {
  final _TeamCardData data;
  final double width;
  final double height;
  final double dimOpacity;
  final double shadowBlur;
  final double shadowOffsetY;
  final bool showFullText;
  final bool isCenter;

  const _SmoothTeamCard({
    required this.data,
    required this.width,
    required this.height,
    required this.dimOpacity,
    required this.shadowBlur,
    required this.shadowOffsetY,
    required this.showFullText,
    required this.isCenter,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        CarsTeamsSection.teamColor[data.teamKey] ??
        CarsTeamsSection.teamColor['default']!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: shadowBlur,
            offset: Offset(0, shadowOffsetY),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bgColor.withOpacity(0.98),
                    bgColor,
                    Color.lerp(bgColor, Colors.black, 0.34)!,
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.08, -0.14),
                    radius: 1.08,
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 28,
              right: 28,
              child: _GlassLogoBadge(
                logoPath: data.logo,
                size: 84,
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: isCenter ? 120 : 132,
              child: Transform.scale(
                scale: isCenter ? 1.03 : 0.97,
                child: Image.asset(
                  data.image,
                  fit: BoxFit.contain,
                  height: height * 0.42,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.90),
                      Colors.black.withOpacity(0.28),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.28, 0.72],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(dimOpacity),
                ),
              ),
            ),
            if (showFullText)
              Positioned(
                left: 28,
                right: 28,
                bottom: 26,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCenter ? 30 : 24,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.drivers,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
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
}

class _GlassLogoBadge extends StatelessWidget {
  final String logoPath;
  final double size;

  const _GlassLogoBadge({
    required this.logoPath,
    this.size = 62,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(
              color: Colors.white.withOpacity(0.24),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset(
            logoPath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _CarouselIndicators extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color activeColor;
  final ValueChanged<int> onTap;

  const _CarouselIndicators({
    required this.count,
    required this.activeIndex,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return GestureDetector(
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: isActive ? 38 : 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor
                  : Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}