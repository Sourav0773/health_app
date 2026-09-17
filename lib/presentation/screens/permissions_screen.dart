import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/health_connect_service.dart';
import '../state/providers.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _requesting = false;

  Future<void> _requestPermissions() async {
    setState(() => _requesting = true);
    final service = ref.read(healthConnectServiceProvider);
    await service.configure();
    final granted = await service.requestPermissions();
    final state = await service.currentPermissionState();
    ref.read(dashboardControllerProvider.notifier).setPermissionState(state);
    if (mounted) setState(() => _requesting = false);
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission request was denied.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final permState = dashboardState.permissionState;

    return Scaffold(
      appBar: AppBar(title: const Text('Health Connect Permissions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PermissionRow(label: 'Steps (StepsRecord)', state: permState),
          const SizedBox(height: 8),
          _PermissionRow(
            label: 'Heart Rate (HeartRateRecord)',
            state: permState,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _requesting ? null : _requestPermissions,
            icon: _requesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_open),
            label: Text(
              permState == PermissionState.granted
                  ? 'Re-check permissions'
                  : 'Grant permissions',
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.label, required this.state});

  final String label;
  final PermissionState state;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (state) {
      PermissionState.granted => (Icons.check_circle, Colors.green),
      PermissionState.denied => (Icons.cancel, Colors.red),
      PermissionState.unknown => (Icons.help_outline, Colors.grey),
    };
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        subtitle: Text(state.name),
      ),
    );
  }
}
