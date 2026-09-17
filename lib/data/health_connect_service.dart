import 'dart:async';
import 'package:health/health.dart';
import 'package:health_tracker/data/models/heart_beat_model.dart';
import 'package:health_tracker/data/models/steps_taken_model.dart';
import 'package:health_tracker/data/repositories/data_strem_repo.dart';
import '../core/constants.dart';

enum PermissionState { unknown, granted, denied }

class HealthConnectService implements DataStreamSource {
  HealthConnectService({Health? health}) : _health = health ?? Health();

  final Health _health;
  Timer? _pollTimer;
  DateTime _lastPollTime = DateTime.now().subtract(const Duration(minutes: 5));

  final Set<String> _seenStepKeys = {};
  final Set<String> _seenHrKeys = {};

  final _stepsController = StreamController<StepsTakenModel>.broadcast();
  final _hrController = StreamController<HeartBeatModel>.broadcast();

  static final _types = [HealthDataType.STEPS, HealthDataType.HEART_RATE];
  static final _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  @override
  Stream<StepsTakenModel> get stepsStream => _stepsController.stream;

  @override
  Stream<HeartBeatModel> get hrStream => _hrController.stream;

  Future<void> configure() async {
    await _health.configure();
  }

  Future<bool> requestPermissions() async {
    final hasPermissions = await _health.hasPermissions(
      _types,
      permissions: _permissions,
    );
    if (hasPermissions == true) return true;

    try {
      return await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
    } catch (_) {
      return false;
    }
  }

  Future<PermissionState> currentPermissionState() async {
    final granted = await _health.hasPermissions(
      _types,
      permissions: _permissions,
    );
    if (granted == null) return PermissionState.unknown;
    return granted ? PermissionState.granted : PermissionState.denied;
  }

  @override
  Future<void> start() async {
    _pollTimer?.cancel();
    unawaited(_poll());
    _pollTimer = Timer.periodic(AppConstants.pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    final windowStart = _lastPollTime;
    final windowEnd = DateTime.now();

    List<HealthDataPoint> points;
    try {
      points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: windowStart,
        endTime: windowEnd,
      );
    } catch (_) {
      return;
    }

    for (final p in points) {
      final ts = p.dateFrom.millisecondsSinceEpoch;
      final value = p.value;

      if (p.type == HealthDataType.STEPS) {
        final count = (value as NumericHealthValue).numericValue.round();
        final sample = StepsTakenModel(ts: ts, count: count);
        if (_seenStepKeys.add(sample.dedupKey)) {
          _stepsController.add(sample);
        }
      } else if (p.type == HealthDataType.HEART_RATE) {
        final bpm = (value as NumericHealthValue).numericValue.round();
        final sample = HeartBeatModel(ts: ts, bpm: bpm);
        if (_seenHrKeys.add(sample.dedupKey)) {
          _hrController.add(sample);
        }
      }
    }

    _lastPollTime = windowEnd;
    if (_seenStepKeys.length > 5000) _seenStepKeys.clear();
    if (_seenHrKeys.length > 5000) _seenHrKeys.clear();
  }

  @override
  Future<void> stop() async {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _stepsController.close();
    _hrController.close();
  }
}
