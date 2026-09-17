import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      // Defense in depth: even if somehow pushed, render nothing useful.
      return const Scaffold(body: Center(child: Text('Unavailable')));
    }

    final dashboardState = ref.watch(dashboardControllerProvider);
    final useSim = ref.watch(activeSourceProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Use SimSource (synthetic data)'),
            subtitle: const Text(
              'Emits fake steps/HR through the same stream interface as '
              'Health Connect. Debug builds only.',
            ),
            value: useSim,
            onChanged: (v) {
              ref.read(activeSourceProvider.notifier).state = v;
              controller.setSimSourceActive(v);
            },
          ),
          const Divider(height: 32),
          const Text('Live follow-up controls'),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('HR moving-average smoothing'),
            value: dashboardState.hrSmoothingEnabled,
            onChanged: controller.setSmoothing,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Steps window:'),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('30 min'),
                selected: dashboardState.stepsWindowMinutes == 30,
                onSelected: (_) => controller.setStepsWindowMinutes(30),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('60 min'),
                selected: dashboardState.stepsWindowMinutes == 60,
                onSelected: (_) => controller.setStepsWindowMinutes(60),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            'stepsUpdateCount=${dashboardState.stepsUpdateCount}  '
            'hrUpdateCount=${dashboardState.hrUpdateCount}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
