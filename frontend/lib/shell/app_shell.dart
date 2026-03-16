import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../tabs/charts/charts_tab.dart';
import '../theme/app_theme.dart';
import '../theme/glow.dart';
import 'session_header.dart';

import '../tabs/overview/overview_tab.dart';
import '../tabs/lap_charts/lap_charts_tab.dart';
import '../tabs/tyre_strategy/tyre_strategy_tab.dart';
import '../tabs/race_replay/race_replay_tab.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Text(
                      "F1 DASH",
                      style: t.titleLarge?.copyWith(letterSpacing: 1.0),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Telemetry UI",
                      style: t.bodySmall?.copyWith(color: Colors.white60),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: "Logout",
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SessionHeader(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlowCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: TabBar(
                    controller: tabs,
                    isScrollable: true,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                    tabs: const [
                      Tab(text: "Overview"),
                      Tab(text: "Charts"),
                      Tab(text: "Tyre Strategy"),
                      Tab(text: "Race Replay"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TabBarView(
                    controller: tabs,
                    children: const [
                      OverviewTab(),
                      ChartsTab(),
                      TyreStrategyTab(),
                      RaceReplayTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
