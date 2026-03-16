import 'dart:async';
import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const LandingScreen({super.key, this.onComplete});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _stage = 0;
  bool _animating = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSequence();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSequence() {
    if (_animating) return;

    setState(() {
      _animating = true;
      _stage = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      setState(() => _stage++);

      if (_stage >= 6) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 320), () {
          if (!mounted) return;
          widget.onComplete?.call();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        height: vh,
        child: LandingStartSection(
          stage: _stage,
          animating: _animating,
          onExplore: _startSequence,
        ),
      ),
    );
  }
}

/// ================= HERO =================
class LandingHeroSection extends StatelessWidget {
  final String imageAsset;

  const LandingHeroSection({super.key, required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    final vh = MediaQuery.of(context).size.height;

    return Container(
      height: vh,
      width: double.infinity,

      // 🔴 Racing red gradient background
      child: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 2000,
                maxHeight: 1000,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),

                    // 🔥 Image frame shadow
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 60,
                        spreadRadius: 10,
                        color: Colors.black.withOpacity(0.65),
                        offset: const Offset(0, 30),
                      ),
                    ],

                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1.5,
                    ),
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 26,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          color: Colors.black.withOpacity(0.55),
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.85),
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Scroll down",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= START SECTION =================
class LandingStartSection extends StatelessWidget {
  final int stage;
  final bool animating;
  final VoidCallback onExplore;

  const LandingStartSection({
    super.key,
    required this.stage,
    required this.animating,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, c) {
        final scale = (c.maxWidth / 1100).clamp(0.85, 1.15);

        return Container(
          width: double.infinity,
          color: const Color.fromARGB(255, 18, 21, 28),
          padding: const EdgeInsets.fromLTRB(18, 40, 18, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: StartLightsWidget(stage: stage),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "IT'S LIGHTS OUT\nAND AWAY WE GO!!!",
                    textAlign: TextAlign.center,
                    style: t.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 56,
                      height: 1.2,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 25,
                          color: Colors.black.withOpacity(0.75),
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ================= LIGHTS =================
class StartLightsWidget extends StatelessWidget {
  final int stage;

  const StartLightsWidget({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 80,
          child: Container(
            width: 500,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _LightColumn(index: i, stage: stage),
            );
          }),
        ),
      ],
    );
  }
}

class _LightColumn extends StatelessWidget {
  final int index;
  final int stage;

  const _LightColumn({required this.index, required this.stage});

  bool get _redOn => stage >= (index + 1) && stage <= 5;
  bool get _greenOn => stage >= 6;

  @override
  Widget build(BuildContext context) {
    final offColor = const Color.fromARGB(255, 22, 24, 30);
    final Color lit = _greenOn
        ? const Color(0xFF29D65A)
        : (_redOn ? const Color(0xFFFF2D2D) : offColor);

    return Container(
      width: 120,
      height: 350,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          colors: [Color(0xFF14161A), Color(0xFF07080B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 45,
            color: Colors.black.withOpacity(0.65),
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const _Bulb.off(),
          const SizedBox(height: 8),
          const _Bulb.off(),
          const SizedBox(height: 15),
          _Bulb.lit(color: lit, glow: _redOn || _greenOn),
          const SizedBox(height: 8),
          _Bulb.lit(color: lit, glow: _redOn || _greenOn),
        ],
      ),
    );
  }
}

class _Bulb extends StatelessWidget {
  final bool isOff;
  final Color color;
  final bool glow;

  const _Bulb._({required this.isOff, required this.color, required this.glow});

  const _Bulb.off()
    : this._(isOff: true, color: const Color(0xFF0B0C0F), glow: false);

  const _Bulb.lit({required Color color, required bool glow})
    : this._(isOff: false, color: color, glow: glow);

  @override
  Widget build(BuildContext context) {
    if (isOff) {
      return Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFF1C1E22), Color(0xFF07080B)],
            radius: 0.9,
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.98), color.withOpacity(0.75)],
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  blurRadius: 20,
                  spreadRadius: 3,
                  color: color.withOpacity(0.5),
                ),
              ]
            : [],
      ),
    );
  }
}

/// ================= BUTTON =================
class ExploreDashboardButton extends StatelessWidget {
  final bool animating;
  final VoidCallback onPressed;

  const ExploreDashboardButton({
    super.key,
    required this.animating,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 90,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 6),
          boxShadow: [
            BoxShadow(
              blurRadius: 50,
              color: Colors.black.withOpacity(0.65),
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: animating ? null : onPressed,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFB90000),
          ),
          child: const Text(
            "EXPLORE DASHBOARD",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
