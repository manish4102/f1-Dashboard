import 'package:f1/tabs/ai_tab/aichat_tab.dart';
import 'package:f1/tabs/tyre_strategy/tyre_strategy_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'landing_page.dart';
import 'widgets/nav_bar.dart';
import 'widgets/f1_loading_overlay.dart';
import 'providers/loading_provider.dart';

// Tabs
import 'tabs/home/home_page.dart';
import 'tabs/overview/overview_tab.dart';
import 'tabs/charts/charts_tab.dart';
import 'tabs/race_replay/race_replay_tab.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _showHomePage = false;

  void _navigateToHomePage() {
    ref.read(loadingProvider.notifier).show();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showHomePage = true;
        });
        ref.read(loadingProvider.notifier).hide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'F1 Dash',
      theme: theme,
      home: _showHomePage
          ? const HomePageWithNav()
          : LandingScreen(onComplete: _navigateToHomePage),
    );
  }
}

class HomePageWithNav extends ConsumerStatefulWidget {
  const HomePageWithNav({super.key});

  @override
  ConsumerState<HomePageWithNav> createState() => _HomePageWithNavState();
}

class _HomePageWithNavState extends ConsumerState<HomePageWithNav> {
  int _currentIndex = 0;

  Widget _getScreen() {
    switch (_currentIndex) {
      case 0:
        return const HomePage();
      case 1:
        return const OverviewTab();
      case 2:
        return const ChartsTab();
      case 3:
        return const TyreStrategyTab();
      case 4:
        return const RaceReplayTab();
      case 5:
        return const AichatTab();
      default:
        return const HomePage();
    }
  }

  Color _backgroundForIndex(int index) {
    if (index == 0) return const Color.fromARGB(222, 173, 7, 7);
    return const Color(0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider);
    return F1LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: _backgroundForIndex(_currentIndex)),
            ),
            Positioned.fill(child: _getScreen()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: F1NavBar(
                    currentIndex: _currentIndex,
                    onTabChanged: (index) {
                      ref.read(loadingProvider.notifier).show();
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() => _currentIndex = index);
                          ref.read(loadingProvider.notifier).hide();
                        }
                      });
                    },
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
