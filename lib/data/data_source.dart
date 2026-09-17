import 'dart:async';
import 'dart:math';
import 'package:health_tracker/data/models/heart_beat_model.dart';
import 'package:health_tracker/data/models/steps_taken_model.dart';
import 'package:health_tracker/data/repositories/data_strem_repo.dart';
import '../core/constants.dart';


class DataSource implements DataStreamSource {
  DataSource({Random? random}) : _random = random ?? Random();

  final Random _random;
  Timer? _timer;
  int _hrBaseline = 72;

  final _stepsController = StreamController<StepsTakenModel>.broadcast();
  final _hrController = StreamController<HeartBeatModel>.broadcast();

  @override
  Stream<StepsTakenModel> get stepsStream => _stepsController.stream;

  @override
  Stream<HeartBeatModel> get hrStream => _hrController.stream;

  @override
  Future<void> start() async {
    _timer?.cancel();
    _timer = Timer.periodic(AppConstants.pollInterval, (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now().millisecondsSinceEpoch;

    final burst = 1 + _random.nextInt(3);
    for (var i = 0; i < burst; i++) {
      final delta = 5 + _random.nextInt(25);
      _stepsController.add(StepsTakenModel(ts: now + i, count: delta));
    }

    _hrBaseline += _random.nextInt(3) - 1;
    _hrBaseline = _hrBaseline.clamp(55, 150);
    final spike = _random.nextDouble() < 0.05 ? _random.nextInt(20) : 0;
    _hrController.add(HeartBeatModel(ts: now, bpm: _hrBaseline + spike));
  }

  List<StepsTakenModel> seedSteps({int count = 20, int startTs = 0}) {
    return List.generate(
      count,
          (i) => StepsTakenModel(ts: startTs + i * 60000, count: 10 + (i % 5) * 3),
    );
  }

  List<HeartBeatModel> seedHr({int count = 20, int startTs = 0}) {
    return List.generate(
      count,
          (i) => HeartBeatModel(ts: startTs + i * 5000, bpm: 70 + (i % 7)),
    );
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stepsController.close();
    _hrController.close();
  }
}
