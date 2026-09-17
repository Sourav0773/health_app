import 'package:health_tracker/core/constants.dart';
import 'package:health_tracker/data/models/heart_beat_model.dart';
import 'package:health_tracker/data/models/steps_taken_model.dart';
import '../../data/health_connect_service.dart';

class DashboardState {
  final List<StepsTakenModel> stepsBuffer;
  final List<HeartBeatModel> hrBuffer;
  final int todaySteps;
  final HeartBeatModel? latestHr;
  final PermissionState permissionState;
  final bool simSourceActive;
  final bool hrSmoothingEnabled;
  final int stepsWindowMinutes;
  final int stepsUpdateCount;
  final int hrUpdateCount;

  const DashboardState({
    this.stepsBuffer = const [],
    this.hrBuffer = const [],
    this.todaySteps = 0,
    this.latestHr,
    this.permissionState = PermissionState.unknown,
    this.simSourceActive = false,
    this.hrSmoothingEnabled = false,
    this.stepsWindowMinutes = AppConstants.defaultStepsWindowMinutes,
    this.stepsUpdateCount = 0,
    this.hrUpdateCount = 0,
  });

  Duration get hrAge => latestHr == null
      ? Duration.zero
      : DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(latestHr!.ts),
  );

  DashboardState copyWith({
    List<StepsTakenModel>? stepsBuffer,
    List<HeartBeatModel>? hrBuffer,
    int? todaySteps,
    HeartBeatModel? latestHr,
    PermissionState? permissionState,
    bool? simSourceActive,
    bool? hrSmoothingEnabled,
    int? stepsWindowMinutes,
    int? stepsUpdateCount,
    int? hrUpdateCount,
  }) {
    return DashboardState(
      stepsBuffer: stepsBuffer ?? this.stepsBuffer,
      hrBuffer: hrBuffer ?? this.hrBuffer,
      todaySteps: todaySteps ?? this.todaySteps,
      latestHr: latestHr ?? this.latestHr,
      permissionState: permissionState ?? this.permissionState,
      simSourceActive: simSourceActive ?? this.simSourceActive,
      hrSmoothingEnabled: hrSmoothingEnabled ?? this.hrSmoothingEnabled,
      stepsWindowMinutes: stepsWindowMinutes ?? this.stepsWindowMinutes,
      stepsUpdateCount: stepsUpdateCount ?? this.stepsUpdateCount,
      hrUpdateCount: hrUpdateCount ?? this.hrUpdateCount,
    );
  }
}