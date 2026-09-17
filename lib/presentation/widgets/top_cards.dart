import 'package:flutter/material.dart';

class TopCards extends StatelessWidget {
  const TopCards({
    super.key,
    required this.todaySteps,
    required this.latestHrBpm,
    required this.hrAge,
  });

  final int todaySteps;
  final int? latestHrBpm;
  final Duration hrAge;

  String get _hrAgeLabel {
    if (latestHrBpm == null) return 'no data yet';
    if (hrAge.inSeconds < 60) return '${hrAge.inSeconds}s ago';
    return '${hrAge.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.directions_walk,
            label: 'Steps today',
            value: '$todaySteps',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.favorite,
            label: 'Heart rate',
            value: latestHrBpm == null ? '--' : '$latestHrBpm bpm',
            caption: _hrAgeLabel,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ]),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            if (caption != null)
              Text(caption!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
