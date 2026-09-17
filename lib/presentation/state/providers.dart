import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_tracker/data/data_source.dart';
import '../../data/health_connect_service.dart';
import '../../data/repositories/data_strem_repo.dart';
import 'dashboard_controller.dart';
import 'dashboard_state.dart';

final healthConnectServiceProvider = Provider<HealthConnectService>((ref) {
  final service = HealthConnectService();
  ref.onDispose(service.dispose);
  return service;
});

final simSourceProvider = Provider<DataSource?>((ref) {
  if (!kDebugMode) return null;
  final sim = DataSource();
  ref.onDispose(sim.dispose);
  return sim;
});

final activeSourceProvider = StateProvider<bool>((ref) => false);

final currentDataSourceProvider = Provider<DataStreamSource>((ref) {
  final useSim = ref.watch(activeSourceProvider);
  if (useSim && kDebugMode) {
    return ref.watch(simSourceProvider)!;
  }
  return ref.watch(healthConnectServiceProvider);
});

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final source = ref.watch(currentDataSourceProvider);
  final controller = DashboardController(source);
  source.start();
  ref.onDispose(() {
    source.stop();
    controller.dispose();
  });
  return controller;
});
