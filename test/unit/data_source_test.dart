import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/data/data_source.dart';

void main() {
  group('SimSource Unit Tests', () {
    late DataSource simSource;

    setUp(() {
      simSource = DataSource();
    });

    tearDown(() {
      simSource.dispose();
    });

    test('seedSteps generates expected count and valid timestamps', () {
      final seeded = simSource.seedSteps(count: 10, startTs: 1000);

      expect(seeded.length, equals(10));
      expect(seeded.first.ts, equals(1000));
      expect(seeded.first.count, equals(10));
    });

    test('seedHr generates expected heart rate samples', () {
      final seeded = simSource.seedHr(count: 5, startTs: 5000);

      expect(seeded.length, equals(5));
      expect(seeded.first.ts, equals(5000));
      expect(seeded.first.bpm, equals(70));
    });

    test('start() emits periodic step and heart rate events', () async {
      await simSource.start();

      // Expect at least one event from both step and HR streams
      final stepSampleFuture = simSource.stepsStream.first;
      final hrSampleFuture = simSource.hrStream.first;

      final stepSample = await stepSampleFuture;
      final hrSample = await hrSampleFuture;

      expect(stepSample.count, greaterThan(0)); // Fixed: lowercase 'greaterThan'
      expect(hrSample.bpm, greaterThanOrEqualTo(55));

      await simSource.stop();
    });
  });
}