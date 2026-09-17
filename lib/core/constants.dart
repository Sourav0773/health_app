class AppConstants {
  AppConstants._();

  static const String packageName = 'com.example.health_tracker';
  static const Duration pollInterval = Duration(seconds: 3);
  static const Duration coalesceWindow = Duration(milliseconds: 200);
  static const int defaultStepsWindowMinutes = 60;
  static const int hrRollingWindowSize = 600;
  static const int maxRenderedPoints = 300;
  static const int rawRetentionDays = 7;
  static const int aggregateRetentionDays = 30;
}
