import 'package:flutter/material.dart';
import 'f1_theme.dart';

class WhatIsF1Section extends StatelessWidget {
  final GlobalKey sectionKey;

  const WhatIsF1Section({super.key, required this.sectionKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      color: F1Theme.f1Red,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 60),
      child: Column(
        children: const [
          // 1) Text left + stats + image right
          _ZigZagBlock(
            title: "What is Formula 1?",
            body: [
              "Formula 1 is the highest class of international auto racing. It features the fastest racing cars in the world, driven by elite professional racers competing for the World Championship across legendary circuits worldwide.",
              "Each race is a complex strategy battle involving tire management, pit stops, weather conditions, and real-time decision making. Teams design and build their own cars within strict regulations to maximize performance.",
              "F1 combines cutting-edge engineering with exceptional driver skill, making it the pinnacle of motorsport.",
            ],
            showStats: true,
            imageOnRight: true,
            imageAsset: "assets/images/about_f12.png",
            imageFit: BoxFit.cover,
            imageHeight: 300,
            imageWidthFactor: 1.3,
          ),

          SizedBox(height: 70),

          // 2) Image left + text right (car)
          _ZigZagBlock(
            title: "The F1 Car",
            body: [
              "An F1 car is a carbon-fiber monocoque built for extreme stiffness and minimal weight. Almost every surface is shaped for aerodynamics—generating downforce to keep the car glued to the track.",
              "The car uses advanced composite materials, high-performance alloys, and precision manufacturing. Teams tune suspension geometry, brakes, cooling, and aero packages to match each circuit.",
              "Under the skin, packaging is everything: tight layouts for the power unit, battery systems, radiators, and airflow paths—because millimeters can decide lap time.",
            ],
            showStats: false,
            imageOnRight: false,
            imageAsset: "assets/images/f1_car.png",
            imageFit: BoxFit.contain,
            imageHeight: 340,
            imageWidthFactor: 1.35,
          ),

          SizedBox(height: 70),

          // 3) Text left + image right (steering wheel)
          _ZigZagBlock(
            title: "Steering Wheel & Controls",
            body: [
              "The steering wheel is a full command center. Drivers adjust power deployment, brake balance, differential settings, engine modes, radio, and more—often while cornering at high speed.",
              "It’s built from lightweight materials with a high-grip finish and a screen for live telemetry. Buttons and rotary switches are positioned for muscle memory and quick changes.",
              "This is why F1 is as much mental workload as it is driving skill—drivers constantly manage the car while racing wheel-to-wheel.",
            ],
            showStats: false,
            imageOnRight: true,
            imageAsset: "assets/images/f1_steering_wheel.png",
            imageFit: BoxFit.contain,
            imageHeight: 320,
            imageWidthFactor: 1.2,
          ),

          SizedBox(height: 80),

          // 4) Calendar centered (big)
          _CenteredImageBlock(
            title: "Season Calendar - 2026",
            imageAsset:
                "assets/images/f1_calendar.png", // <- change extension/path if needed
            // tweak these two to taste
            maxWidth: 950,
            borderRadius: 28,
          ),
        ],
      ),
    );
  }
}

class _ZigZagBlock extends StatelessWidget {
  final String title;
  final List<String> body;
  final bool showStats;
  final bool imageOnRight;
  final String imageAsset;
  final BoxFit imageFit;
  final double imageHeight;
  final double imageWidthFactor;

  const _ZigZagBlock({
    required this.title,
    required this.body,
    required this.showStats,
    required this.imageOnRight,
    required this.imageAsset,
    required this.imageFit,
    required this.imageHeight,
    required this.imageWidthFactor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        final textWidget = _TextColumn(
          title: title,
          body: body,
          showStats: showStats,
        );

        final imageWidget = _ImageCard(
          imageAsset: imageAsset,
          fit: imageFit,
          height: imageHeight,
          widthFactor: imageWidthFactor,
        );

        if (!isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textWidget,
              const SizedBox(height: 30),
              imageWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: imageOnRight
              ? [
                  Expanded(flex: 3, child: textWidget),
                  const SizedBox(width: 50),
                  Expanded(flex: 2, child: imageWidget),
                ]
              : [
                  Expanded(flex: 2, child: imageWidget),
                  const SizedBox(width: 50),
                  Expanded(flex: 3, child: textWidget),
                ],
        );
      },
    );
  }
}

class _TextColumn extends StatelessWidget {
  final String title;
  final List<String> body;
  final bool showStats;

  const _TextColumn({
    required this.title,
    required this.body,
    required this.showStats,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w600,
              height: 1.05,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          for (int i = 0; i < body.length; i++) ...[
            Text(
              body[i],
              style: const TextStyle(
                fontSize: 20,
                height: 1.7,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
            if (i != body.length - 1) const SizedBox(height: 24),
          ],
          if (showStats) ...[
            const SizedBox(height: 50),
            const _StatsRow(),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _StatColumn(value: "11", label: "TEAMS"),
        SizedBox(width: 40),
        _StatColumn(value: "22", label: "DRIVERS"),
        SizedBox(width: 40),
        _StatColumn(value: "~300", label: "KM RACE"),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: 120,
          height: 85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 6),
              )
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              color: F1Theme.f1Red,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String imageAsset;
  final BoxFit fit;
  final double height;
  final double widthFactor;

  const _ImageCard({
    required this.imageAsset,
    required this.fit,
    required this.height,
    required this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * widthFactor;

        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: imageWidth,
              height: height,
              child: Image.asset(
                imageAsset,
                fit: fit,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CenteredImageBlock extends StatelessWidget {
  final String title;
  final String imageAsset;
  final double maxWidth;
  final double borderRadius;

  const _CenteredImageBlock({
    required this.title,
    required this.imageAsset,
    required this.maxWidth,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth.clamp(0, maxWidth);
          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: SizedBox(
                width: w.toDouble(),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}