import 'package:flutter/material.dart';
import 'package:health_tracker/data/models/heart_beat_model.dart';
import '../../core/theme.dart';
import '../state/dashboard_controller.dart';
import 'line_chart.dart';

class HrChart extends StatelessWidget {
  const HrChart({
    super.key,
    required this.samples,
    required this.smoothingEnabled,
  });

  final List<HeartBeatModel> samples;
  final bool smoothingEnabled;

  @override
  Widget build(BuildContext context) {
    final points = samples
        .map((s) => ChartPoint(s.ts, s.bpm.toDouble()))
        .toList(growable: false);

    List<ChartPoint>? smoothedPoints;
    if (smoothingEnabled && samples.length > 1) {
      final smoothed = DashboardController.movingAverage(samples);
      smoothedPoints = smoothed
          .map((s) => ChartPoint(s.ts, s.bpm.toDouble()))
          .toList(growable: false);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Heart rate', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (points.length < 2)
              const SizedBox(
                height: 180,
                child: Center(child: Text('Waiting for data…')),
              )
            else
              LineChartWidget(
                points: points,
                lineColor: AppTheme.hrLine,
                secondaryPoints: smoothedPoints,
                secondaryColor: AppTheme.hrSmoothedLine,
              ),
          ],
        ),
      ),
    );
  }
}
