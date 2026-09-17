class HeartBeatModel {
  final int ts;
  final int bpm;

  const HeartBeatModel({required this.ts, required this.bpm});

  String get dedupKey => '$ts:$bpm';

  factory HeartBeatModel.fromJson(Map<String, dynamic> json) => HeartBeatModel(
    ts: json['ts'] as int,
    bpm: json['bpm'] as int,
  );

  Map<String, dynamic> toJson() => {'ts': ts, 'bpm': bpm};
}
