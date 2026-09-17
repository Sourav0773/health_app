import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_tracker/data/models/heart_beat_model.dart';
import 'package:health_tracker/data/models/steps_taken_model.dart';
import '../../core/constants.dart';
import '../../data/health_connect_service.dart';
import '../../data/repositories/data_strem_repo.dart';
import 'dashboard_state.dart';

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this._source) : super(const DashboardState()) {
    _stepsSub = _source.stepsStream.listen(_bufferSteps);
    _hrSub = _source.hrStream.listen(_bufferHr);
  }

  final DataStreamSource _source;
  StreamSubscription<StepsTakenModel>? _stepsSub;
  StreamSubscription<HeartBeatModel>? _hrSub;

  final List<StepsTakenModel> _pendingSteps = [];
  final List<HeartBeatModel> _pendingHr = [];
  Timer? _coalesceTimer;

  void _bufferSteps(StepsTakenModel s) {
    _pendingSteps.add(s);
    _scheduleFlush();
  }

  void _bufferHr(HeartBeatModel s) {
    _pendingHr.add(s);
    _scheduleFlush();
  }

  void _scheduleFlush() {
    _coalesceTimer ??= Timer(AppConstants.coalesceWindow, _flush);
  }

  void _flush() {
    _coalesceTimer = null;
    if (_pendingSteps.isEmpty && _pendingHr.isEmpty) return;

    var next = state;

    if (_pendingSteps.isNotEmpty) {
      next = _applySteps(next, List.of(_pendingSteps));
      _pendingSteps.clear();
    }
    if (_pendingHr.isNotEmpty) {
      next = _applyHr(next, List.of(_pendingHr));
      _pendingHr.clear();
    }

    state = next;
  }

  @visibleForTesting
  void flushForTest() => _flush();

  DashboardState _applySteps(DashboardState s, List<StepsTakenModel> batch) {
    final merged = [...s.stepsBuffer, ...batch]
      ..sort((a, b) => a.ts.compareTo(b.ts));

    final cutoff = DateTime.now()
        .subtract(Duration(minutes: s.stepsWindowMinutes))
        .millisecondsSinceEpoch;
    final windowed = merged.where((e) => e.ts >= cutoff).toList();

    final startOfDay = DateTime.now();
    final startOfDayMs = DateTime(
      startOfDay.year,
      startOfDay.month,
      startOfDay.day,
    ).millisecondsSinceEpoch;
    // todaySteps is cumulative across the *whole* session buffer we've
    // seen today, not just the visible window — merged already has
    // everything received this session.
    final todayTotal = merged
        .where((e) => e.ts >= startOfDayMs)
        .fold<int>(0, (sum, e) => sum + e.count);

    return s.copyWith(
      stepsBuffer: _decimate(windowed),
      todaySteps: todayTotal,
      stepsUpdateCount: s.stepsUpdateCount + batch.length,
    );
  }

  DashboardState _applyHr(DashboardState s, List<HeartBeatModel> batch) {
    final merged = [...s.hrBuffer, ...batch]
      ..sort((a, b) => a.ts.compareTo(b.ts));

    final trimmed = merged.length > AppConstants.hrRollingWindowSize
        ? merged.sublist(merged.length - AppConstants.hrRollingWindowSize)
        : merged;

    final latest = batch.last;

    return s.copyWith(
      hrBuffer: _decimate(trimmed),
      latestHr: latest,
      hrUpdateCount: s.hrUpdateCount + batch.length,
    );
  }

  List<T> _decimate<T>(List<T> series) {
    if (series.length <= AppConstants.maxRenderedPoints) return series;
    final bucketSize = (series.length / AppConstants.maxRenderedPoints).ceil();
    final out = <T>[];
    for (var i = 0; i < series.length; i += bucketSize) {
      final end = (i + bucketSize).clamp(0, series.length);
      out.add(series[end - 1]);
    }
    return out;
  }

  void setSmoothing(bool enabled) {
    state = state.copyWith(hrSmoothingEnabled: enabled);
  }

  void setStepsWindowMinutes(int minutes) {
    state = state.copyWith(stepsWindowMinutes: minutes);
    _flush();
  }

  void setPermissionState(PermissionState p) {
    state = state.copyWith(permissionState: p);
  }

  void setSimSourceActive(bool active) {
    state = state.copyWith(simSourceActive: active);
  }

  static List<HeartBeatModel> movingAverage(List<HeartBeatModel> input, {int window = 5}) {
    if (input.length < 2) return input;
    final out = <HeartBeatModel>[];
    for (var i = 0; i < input.length; i++) {
      final start = (i - window + 1).clamp(0, input.length);
      final slice = input.sublist(start, i + 1);
      final avg = slice.fold<int>(0, (a, b) => a + b.bpm) / slice.length;
      out.add(HeartBeatModel(ts: input[i].ts, bpm: avg.round()));
    }
    return out;
  }

  @override
  void dispose() {
    _coalesceTimer?.cancel();
    _stepsSub?.cancel();
    _hrSub?.cancel();
    super.dispose();
  }
}
