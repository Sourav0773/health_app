import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/health_connect_service.dart';
import '../state/providers.dart';
import '../widgets/denial_banner.dart';
import '../widgets/hr_chart.dart';
import '../widgets/performance_hud.dart';
import '../widgets/steps_chart.dart';
import '../widgets/top_cards.dart';
import 'debug_screen.dart';
import 'permissions_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Permissions',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PermissionsScreen()),
            ),
          ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              tooltip: 'Debug',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DebugScreen()),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.permissionState == PermissionState.denied)
              DenialBanner(
                onRetry: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PermissionsScreen()),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  TopCards(
                    todaySteps: state.todaySteps,
                    latestHrBpm: state.latestHr?.bpm,
                    hrAge: state.hrAge,
                  ),
                  const SizedBox(height: 12),
                  StepsChart(
                    samples: state.stepsBuffer,
                    windowMinutes: state.stepsWindowMinutes,
                  ),
                  const SizedBox(height: 12),
                  HrChart(
                    samples: state.hrBuffer,
                    smoothingEnabled: state.hrSmoothingEnabled,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const PerformanceHud(),
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
