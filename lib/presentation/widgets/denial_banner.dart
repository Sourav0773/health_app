import 'package:flutter/material.dart';

/// Requirement 1: "Handle denial gracefully (non-blocking banner + retry)".
/// Sits above content, never blocks interaction with the rest of the app.
class DenialBanner extends StatelessWidget {
  const DenialBanner({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      content: const Text(
        'Health Connect permissions were denied. Live steps/heart-rate '
        'updates are paused until access is granted.',
      ),
      leading: const Icon(Icons.warning_amber_rounded),
      actions: [
        TextButton(onPressed: onRetry, child: const Text('RETRY')),
      ],
    );
  }
}
