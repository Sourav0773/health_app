import 'package:health_tracker/data/models/heart_beat_model.dart';
import 'package:health_tracker/data/models/steps_taken_model.dart';

abstract class DataStreamSource {
  Stream<StepsTakenModel> get stepsStream;
  Stream<HeartBeatModel> get hrStream;

  Future<void> start();
  Future<void> stop();

  void dispose();
}
