class StepsTakenModel {
  final int ts;
  final int count;

  const StepsTakenModel({required this.ts, required this.count});

  String get dedupKey => '$ts:$count';

  factory StepsTakenModel.fromJson(Map<String, dynamic> json) => StepsTakenModel(
    ts: json['ts'] as int,
    count: json['count'] as int,
  );

  Map<String, dynamic> toJson() => {'ts': ts, 'count': count};
}
