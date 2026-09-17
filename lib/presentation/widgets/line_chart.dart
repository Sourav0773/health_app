import 'package:flutter/material.dart';

import '../../core/theme.dart';

class ChartPoint {
  final int ts;
  final double value;
  const ChartPoint(this.ts, this.value);
}

/// Reusable interactive line chart shared by the Steps and HR charts
/// (Requirement 3). Pan + pinch-zoom via [GestureDetector.onScaleUpdate]
/// (a single scale gesture covers both 1-finger pan and 2-finger pinch),
/// tap shows a tooltip for the nearest sample.
///
/// Perf note (Requirement 3/4 "no per-frame allocations in paint()"):
/// the Paint/TextPainter objects used by [_LineChartPainter] are created
/// once in its constructor and reused across every paint() call. Only
/// the Path is rebuilt per paint (unavoidable — it encodes the current
/// point set) and its point loop does no additional allocation.
class LineChartWidget extends StatefulWidget {
  const LineChartWidget({
    super.key,
    required this.points,
    required this.lineColor,
    this.secondaryPoints,
    this.secondaryColor,
    this.yLabel = '',
    this.height = 180,
  });

  final List<ChartPoint> points;
  final Color lineColor;
  final List<ChartPoint>? secondaryPoints; // e.g. HR smoothed overlay
  final Color? secondaryColor;
  final String yLabel;
  final double height;

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  double _scale = 1.0;
  double _baseScale = 1.0;
  double _panX = 0.0;
  double _baseFocalX = 0.0;
  Offset? _tapLocal;

  late final _LineChartPainter _painter = _LineChartPainter(
    lineColor: widget.lineColor,
    secondaryColor: widget.secondaryColor,
  );

  @override
  Widget build(BuildContext context) {
    _painter
      ..points = widget.points
      ..secondaryPoints = widget.secondaryPoints
      ..scale = _scale
      ..panX = _panX
      ..tapLocal = _tapLocal;

    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        onScaleStart: (d) {
          _baseScale = _scale;
          _baseFocalX = d.focalPoint.dx - _panX;
        },
        onScaleUpdate: (d) {
          setState(() {
            _scale = (_baseScale * d.scale).clamp(1.0, 8.0);
            _panX = d.focalPoint.dx - _baseFocalX;
          });
        },
        onTapUp: (d) => setState(() => _tapLocal = d.localPosition),
        child: CustomPaint(
          painter: _painter,
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.lineColor, this.secondaryColor})
      : _linePaint = Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
        _secondaryPaint = Paint()
          ..color = secondaryColor ?? lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
        _gridPaint = Paint()
          ..color = AppTheme.gridLine
          ..strokeWidth = 1,
        _dotPaint = Paint()..color = lineColor,
        _tooltipBgPaint = Paint()..color = AppTheme.tooltipBg,
        _textPainter = TextPainter(textDirection: TextDirection.ltr);

  final Color lineColor;
  final Color? secondaryColor;

  // Preallocated, reused every frame — see class doc.
  final Paint _linePaint;
  final Paint _secondaryPaint;
  final Paint _gridPaint;
  final Paint _dotPaint;
  final Paint _tooltipBgPaint;
  final TextPainter _textPainter;

  List<ChartPoint> points = const [];
  List<ChartPoint>? secondaryPoints;
  double scale = 1.0;
  double panX = 0.0;
  Offset? tapLocal;

  @override
  void paint(Canvas canvas, Size size) {
    // Grid (4 horizontal lines) — reuses _gridPaint, no per-line alloc.
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }

    if (points.length < 2) return;

    final minV = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxV = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    Offset toOffset(ChartPoint p, int index, int total) {
      final x = (index / (total - 1)) * size.width * scale + panX;
      final y = size.height - ((p.value - minV) / range) * size.height;
      return Offset(x, y);
    }

    void drawSeries(List<ChartPoint> series, Paint paint) {
      final path = Path();
      for (var i = 0; i < series.length; i++) {
        final o = toOffset(series[i], i, series.length);
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawSeries(points, _linePaint);
    if (secondaryPoints != null && secondaryPoints!.length > 1) {
      drawSeries(secondaryPoints!, _secondaryPaint);
    }

    if (tapLocal != null) {
      // Find nearest point by x-distance in transformed space.
      var nearestIdx = 0;
      var nearestDist = double.infinity;
      for (var i = 0; i < points.length; i++) {
        final o = toOffset(points[i], i, points.length);
        final d = (o.dx - tapLocal!.dx).abs();
        if (d < nearestDist) {
          nearestDist = d;
          nearestIdx = i;
        }
      }
      final nearest = points[nearestIdx];
      final o = toOffset(nearest, nearestIdx, points.length);
      canvas.drawCircle(o, 4, _dotPaint);

      final t = DateTime.fromMillisecondsSinceEpoch(nearest.ts);
      final label =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}  ${nearest.value.toStringAsFixed(0)}';
      _textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      );
      _textPainter.layout();
      final boxOrigin = Offset(
        (o.dx - _textPainter.width / 2).clamp(0, size.width - _textPainter.width),
        (o.dy - _textPainter.height - 14).clamp(0, size.height),
      );
      final rect = Rect.fromLTWH(
        boxOrigin.dx - 4,
        boxOrigin.dy - 2,
        _textPainter.width + 8,
        _textPainter.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        _tooltipBgPaint,
      );
      _textPainter.paint(canvas, boxOrigin);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) {
    return old.points != points ||
        old.secondaryPoints != secondaryPoints ||
        old.scale != scale ||
        old.panX != panX ||
        old.tapLocal != tapLocal;
  }
}
