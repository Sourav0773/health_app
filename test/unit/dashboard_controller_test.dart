import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/data/models/heart_beat_model.dart';
import 'package:health_tracker/data/models/steps_taken_model.dart';
import 'package:health_tracker/data/repositories/data_strem_repo.dart';
import 'package:health_tracker/presentation/state/dashboard_controller.dart';

class _FakeSource implements DataStreamSource {
  final _stepsCtrl = StreamController<StepsTakenModel>.broadcast();
  final _hrCtrl = StreamController<HeartBeatModel>.broadcast();

  @override
  Stream<StepsTakenModel> get stepsStream => _stepsCtrl.stream;
  @override
  Stream<HeartBeatModel> get hrStream => _hrCtrl.stream;

  void emitSteps(StepsTakenModel s) => _stepsCtrl.add(s);
  void emitHr(HeartBeatModel s) => _hrCtrl.add(s);

  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  void dispose() {
    _stepsCtrl.close();
    _hrCtrl.close();
  }
}

void main() {
  late _FakeSource source;
  late DashboardController controller;

  setUp(() {
    source = _FakeSource();
    controller = DashboardController(source);
  });

  tearDown(() {
    controller.dispose();
    source.dispose();
  });

  test('maps a single steps sample into todaySteps and stepsBuffer', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    source.emitSteps(StepsTakenModel(ts: now, count: 42));

    await Future<void>.delayed(const Duration(milliseconds: 10));
    controller.flushForTest();

    expect(controller.state.todaySteps, 42);
    expect(controller.state.stepsBuffer, hasLength(1));
    expect(controller.state.stepsUpdateCount, 1);
  });

  test('coalesces a burst of samples into one state application', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    source.emitSteps(StepsTakenModel(ts: now, count: 10));
    source.emitSteps(StepsTakenModel(ts: now + 1, count: 5));
    source.emitSteps(StepsTakenModel(ts: now + 2, count: 7));

    // All three arrive before the coalesce window elapses.
    controller.flushForTest();

    expect(controller.state.todaySteps, 22);
    expect(controller.state.stepsUpdateCount, 3);
    expect(controller.state.stepsBuffer, hasLength(3));
  });

  test('latestHr and hrBuffer update on new HR sample', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    source.emitHr(HeartBeatModel(ts: now, bpm: 88));
    controller.flushForTest();

    expect(controller.state.latestHr?.bpm, 88);
    expect(controller.state.hrBuffer, hasLength(1));
  });

  test('steps outside the window are filtered out after setStepsWindowMinutes',
      () {
    final old = DateTime.now()
        .subtract(const Duration(minutes: 90))
        .millisecondsSinceEpoch;
    final recent = DateTime.now().millisecondsSinceEpoch;

    source.emitSteps(StepsTakenModel(ts: old, count: 100));
    source.emitSteps(StepsTakenModel(ts: recent, count: 5));
    controller.flushForTest();

    // Default window is 60 min: the 90-min-old sample should be excluded
    // from the rendered buffer even though it still counts toward today's
    // total.
    expect(controller.state.stepsBuffer.every((s) => s.ts == recent), isTrue);
    expect(controller.state.todaySteps, 105);
  });

  test('movingAverage smooths a noisy HR series', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    final series = [
      HeartBeatModel(ts: now, bpm: 60),
      HeartBeatModel(ts: now + 1, bpm: 100),
      HeartBeatModel(ts: now + 2, bpm: 60),
      HeartBeatModel(ts: now + 3, bpm: 100),
      HeartBeatModel(ts: now + 4, bpm: 60),
    ];
    final smoothed = DashboardController.movingAverage(series, window: 3);

    expect(smoothed.length, series.length);
    // The smoothed series should have strictly less variance than raw.
    final rawVariance = _variance(series.map((s) => s.bpm).toList());
    final smoothedVariance = _variance(smoothed.map((s) => s.bpm).toList());
    expect(smoothedVariance, lessThan(rawVariance));
  });
}

double _variance(List<int> values) {
  final mean = values.reduce((a, b) => a + b) / values.length;
  final sq = values.map((v) => (v - mean) * (v - mean));
  return sq.reduce((a, b) => a + b) / values.length;
}
