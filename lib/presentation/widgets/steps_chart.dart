import 'package:flutter/material.dart';
import 'package:health_tracker/data/models/steps_taken_model.dart';
import '../../core/theme.dart';
import 'line_chart.dart';

class StepsChart extends StatelessWidget {
  const StepsChart({super.key, required this.samples, required this.windowMinutes});

  final List<StepsTakenModel> samples;
  final int windowMinutes;

  @override
  Widget build(BuildContext context) {
    final points = samples
        .map((s) => ChartPoint(s.ts, s.count.toDouble()))
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Steps (last $windowMinutes min)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (points.length < 2)
              const SizedBox(
                height: 180,
                child: Center(child: Text('Waiting for data…')),
              )
            else
              LineChartWidget(points: points, lineColor: AppTheme.stepsLine),
          ],
        ),
      ),
    );
  }
}
