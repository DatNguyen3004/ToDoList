import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

class DrawingPreview extends StatefulWidget {
  const DrawingPreview({required this.drawingJson, super.key});

  final String? drawingJson;

  @override
  State<DrawingPreview> createState() => _DrawingPreviewState();
}

class _DrawingPreviewState extends State<DrawingPreview> {
  static const _cacheLimit = 24;
  static final LinkedHashMap<String, List<_PreviewStroke>> _cache =
      LinkedHashMap();

  late List<_PreviewStroke> _strokes;

  @override
  void initState() {
    super.initState();
    _strokes = _loadStrokes();
  }

  @override
  void didUpdateWidget(covariant DrawingPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drawingJson != widget.drawingJson) {
      _strokes = _loadStrokes();
    }
  }

  List<_PreviewStroke> _loadStrokes() {
    final source = widget.drawingJson;
    if (source == null || source.isEmpty) return const [];
    final cached = _cache.remove(source);
    if (cached != null) {
      _cache[source] = cached;
      return cached;
    }
    try {
      final decoded = jsonDecode(source);
      final strokeData = decoded is Map<String, dynamic>
          ? decoded['strokes'] as List<dynamic>? ?? const <dynamic>[]
          : decoded as List<dynamic>;
      final strokes = strokeData
          .map((item) => _PreviewStroke.fromJson(item as Map<String, dynamic>))
          .toList();
      _cache[source] = strokes;
      if (_cache.length > _cacheLimit) _cache.remove(_cache.keys.first);
      return strokes;
    } on Object {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox.expand(
        child: _strokes.isEmpty
            ? const Center(
                child: Icon(
                  Icons.draw_outlined,
                  color: Color(0xFF90CAF9),
                  size: 28,
                ),
              )
            : CustomPaint(
                painter: _DrawingPreviewPainter(_strokes),
                child: const SizedBox.expand(),
              ),
      ),
    );
  }
}

enum _PreviewTool { pen, highlighter, eraser }

class _PreviewStroke {
  const _PreviewStroke({
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
  });

  factory _PreviewStroke.fromJson(Map<String, dynamic> json) {
    return _PreviewStroke(
      tool: _PreviewTool.values.byName(json['tool'] as String),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
      points: (json['points'] as List<dynamic>)
          .map(
            (point) => Offset(
              ((point as List<dynamic>)[0] as num).toDouble(),
              (point[1] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }

  final _PreviewTool tool;
  final Color color;
  final double width;
  final List<Offset> points;

  double get paintedWidth => switch (tool) {
    _PreviewTool.pen => width,
    _PreviewTool.highlighter => width * 2.2,
    _PreviewTool.eraser => width * 2.5,
  };
}

class _DrawingPreviewPainter extends CustomPainter {
  const _DrawingPreviewPainter(this.strokes);

  final List<_PreviewStroke> strokes;

  Rect _drawingBounds() {
    Rect? bounds;
    for (final stroke in strokes) {
      final radius = stroke.paintedWidth / 2;
      for (final point in stroke.points) {
        final pointBounds = Rect.fromCircle(center: point, radius: radius);
        bounds = bounds == null
            ? pointBounds
            : bounds.expandToInclude(pointBounds);
      }
    }
    return bounds ?? const Rect.fromLTWH(0, 0, 1, 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 5.0;
    final bounds = _drawingBounds();
    final drawingWidth = math.max(bounds.width, 1.0);
    final drawingHeight = math.max(bounds.height, 1.0);
    final availableWidth = math.max(size.width - padding * 2, 1.0);
    final availableHeight = math.max(size.height - padding * 2, 1.0);
    final scale = math.min(
      availableWidth / drawingWidth,
      availableHeight / drawingHeight,
    );
    final drawnWidth = drawingWidth * scale;
    final drawnHeight = drawingHeight * scale;
    final left = (size.width - drawnWidth) / 2;
    final top = (size.height - drawnHeight) / 2;

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.translate(left, top);
    canvas.scale(scale);
    canvas.translate(-bounds.left, -bounds.top);
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    canvas.restore();
  }

  void _paintStroke(Canvas canvas, _PreviewStroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    switch (stroke.tool) {
      case _PreviewTool.pen:
        paint
          ..color = stroke.color
          ..strokeWidth = stroke.width;
        break;
      case _PreviewTool.highlighter:
        paint
          ..color = stroke.color.withValues(alpha: 0.32)
          ..strokeWidth = stroke.width * 2.2;
        break;
      case _PreviewTool.eraser:
        paint
          ..color = Colors.transparent
          ..strokeWidth = stroke.width * 2.5
          ..blendMode = BlendMode.clear;
        break;
    }

    if (stroke.points.length == 1) {
      canvas.drawPoints(PointMode.points, stroke.points, paint);
      return;
    }
    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (final point in stroke.points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPreviewPainter oldDelegate) =>
      oldDelegate.strokes != strokes;
}
