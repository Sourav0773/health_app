import 'dart:collection';

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';

/// Requirement 4: "tiny Performance HUD (build time avg, last paint time,
/// FPS estimate) to assert in tests." Uses the engine's own frame timing
/// callback rather than guessing, so numbers line up with what DevTools
/// reports.
class PerformanceHud extends StatefulWidget {
  const PerformanceHud({super.key});

  @override
  State<PerformanceHud> createState() => PerformanceHudState();
}

class PerformanceHudState extends State<PerformanceHud> {
  static const _windowSize = 120; // ~2s of frames at 60fps
  final Queue<FrameTiming> _frames = Queue();

  double avgBuildMs = 0;
  double lastPaintMs = 0;
  double fpsEstimate = 0;
  int jankFrames = 0;

  void Function(List<FrameTiming>)? _callback;

  @override
  void initState() {
    super.initState();
    _callback = _onTimings;
    SchedulerBinding.instance.addTimingsCallback(_callback!);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _frames.add(t);
      if (_frames.length > _windowSize) _frames.removeFirst();
      final totalMs = t.totalSpan.inMicroseconds / 1000.0;
      if (totalMs > 16.67) jankFrames++;
    }
    if (_frames.isEmpty) return;

    final buildTotal = _frames.fold<int>(
      0,
      (sum, t) => sum + t.buildDuration.inMicroseconds,
    );
    final raster = _frames.last.rasterDuration.inMicroseconds / 1000.0;
    final avgFrameSpan = _frames.fold<int>(
          0,
          (sum, t) => sum + t.totalSpan.inMicroseconds,
        ) /
        _frames.length;

    if (!mounted) return;
    setState(() {
      avgBuildMs = (buildTotal / _frames.length) / 1000.0;
      lastPaintMs = raster;
      fpsEstimate = avgFrameSpan <= 0 ? 0 : 1000000 / avgFrameSpan;
    });
  }

  @override
  void dispose() {
    if (_callback != null) {
      SchedulerBinding.instance.removeTimingsCallback(_callback!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('performance_hud'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stat('build', '${avgBuildMs.toStringAsFixed(1)}ms'),
          const SizedBox(width: 10),
          _stat('paint', '${lastPaintMs.toStringAsFixed(1)}ms'),
          const SizedBox(width: 10),
          _stat('fps', fpsEstimate.toStringAsFixed(0)),
          const SizedBox(width: 10),
          _stat('jank', '$jankFrames'),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Text(
      '$label $value',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
