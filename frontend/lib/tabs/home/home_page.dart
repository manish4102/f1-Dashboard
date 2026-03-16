// lib/home_page.dart
import 'package:flutter/material.dart';
import 'widgets/f1_theme.dart';
import 'widgets/hero_section.dart';
import 'widgets/what_is_f1_section.dart';
import 'widgets/drivers_teams_section.dart';
import 'widgets/special_mentions_section.dart';
import 'widgets/teams_section.dart';
import 'widgets/favorites_section.dart';
import 'widgets/f1_footer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();

  final _kHero = GlobalKey();
  final _kAbout = GlobalKey();
  final _kEducation = GlobalKey();
  final _kDriversTeams = GlobalKey();
  final _kSpecial = GlobalKey();
  final _kCars = GlobalKey();
  final _kCalendar = GlobalKey();
  final _kFavorites = GlobalKey();

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
      alignment: 0.02,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: F1Theme.f1Red,
      colorScheme: const ColorScheme.dark(
        primary: F1Theme.f1Red,
        surface: F1Theme.surface1,
        onSurface: F1Theme.textPrimary,
      ),
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: F1Theme.textPrimary,
        displayColor: F1Theme.textPrimary,
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: F1Theme.f1Red, // ✅ full-page red background
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
  padding: const EdgeInsets.only(top: 50),
  decoration: const BoxDecoration(
    color: Colors.black,
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(100),
      bottomRight: Radius.circular(100),
    ),
  ),
  child: HeroSection(sectionKey: _kHero),
),
                    
                      // ✅ everything else stays centered and constrained
                      Padding(
  padding: const EdgeInsets.symmetric(horizontal: 40), // 👈 adjust here
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1500),
      child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              WhatIsF1Section(sectionKey: _kAbout),
                              DriversTeamsSection(sectionKey: _kDriversTeams),
                              CarsTeamsSection(sectionKey: _kCars),
                              SpecialMentionsSection(sectionKey: _kSpecial),
                              FavoritesSection(sectionKey: _kFavorites),
                              const SizedBox(height: 60),
                              const F1Footer(),
                            ],
                          ),
                        ),
                      ),
              ),],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
