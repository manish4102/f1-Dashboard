// lib/widgets/hero_section.dart
import 'package:flutter/material.dart';
import 'f1_theme.dart';

class HeroSection extends StatelessWidget {
  final GlobalKey sectionKey;

  const HeroSection({super.key, required this.sectionKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: sectionKey,
      // ✅ no left/right padding so the hero can go edge-to-edge
      padding: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        // ✅ ONLY bottom corners rounded
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(100),
          bottomRight: Radius.circular(100),
        ),
        child: Container(
          // ✅ black panel on top of red page
          decoration: BoxDecoration(
            color: const Color(0xFF07070B),
            border: Border.all(color: const Color(0xFF1C1C22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ image on top
              AspectRatio(
                // tweak this if you want more/less height
                aspectRatio: 16 / 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/pitstop_red.png',
                      fit: BoxFit.contain,
                    ),
                    // subtle fade so image blends into black panel
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ text below
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  children: const [
                    Text(
                      "WELCOME TO FORMULA 1",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.0,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Building race-ready insights",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: F1Theme.f1Red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}