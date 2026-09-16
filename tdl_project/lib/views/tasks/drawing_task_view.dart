import 'dart:convert';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import '../../models/task_item.dart';

enum DrawingTool { pen, highlighter, eraser }

const _primaryBlue = Color(0xFF1976D2);

class DrawingTaskDraft {
  const DrawingTaskDraft({
    required this.title,
    required this.drawingJson,
    required this.strokeCount,
  });

  final String title;
  final String drawingJson;
  final int strokeCount;
}

class DrawingTaskView extends StatefulWidget {
  const DrawingTaskView({
    required this.onSave,
    this.initialTask,
    this.onDeleteEmpty,
    super.key,
  });

  final TaskItem? initialTask;
  final ValueChanged<DrawingTaskDraft> onSave;
  final VoidCallback? onDeleteEmpty;

  @override
  State<DrawingTaskView> createState() => _DrawingTaskViewState();
}

class _DrawingTaskViewState extends State<DrawingTaskView> {
  static const _drawingPalette = <Color>[
    Color(0xFF17212B),
    Color(0xFF4B5563),
    Color(0xFFF8FAFC),
    Color(0xFF795548),
    Color(0xFF7F1D1D),
    Color(0xFF991B1B),
    Color(0xFFEF4444),
    Color(0xFFFB7185),
    Color(0xFFEC4899),
    Color(0xFFBE185D),
    Color(0xFFA855F7),
    Color(0xFF7C3AED),
    Color(0xFF4F46E5),
    Color(0xFF1E3A8A),
    Color(0xFF2563EB),
    Color(0xFF2196F3),
    Color(0xFF38BDF8),
    Color(0xFF06B6D4),
    Color(0xFF0F766E),
    Color(0xFF14B8A6),
    Color(0xFF166534),
    Color(0xFF22C55E),
    Color(0xFF84CC16),
    Color(0xFFA3E635),
    Color(0xFFEAB308),
    Color(0xFFFACC15),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFEA580C),
    Color(0xFFB45309),
  ];

  late final TextEditingController _titleController;
  final List<_DrawingStroke> _strokes = [];
  final List<_DrawingStroke> _redoStrokes = [];
  int _undoBoundary = 0;
  final Map<int, Offset> _activePointers = {};
  _DrawingStroke? _currentStroke;
  int? _drawingPointer;
  Offset _canvasOffset = Offset.zero;
  DrawingTool _selectedTool = DrawingTool.pen;
  Color _selectedColor = _drawingPalette.first;
  double _strokeWidth = 5;
  bool _canPop = false;
  bool _isClosing = false;
  bool _didSetInitialThemeColor = false;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTask?.title);
    _loadDrawing(widget.initialTask?.drawingJson);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSetInitialThemeColor) return;
    _didSetInitialThemeColor = true;
    if (Theme.of(context).brightness == Brightness.dark) {
      _selectedColor = const Color(0xFFF8FAFC);
    }
  }

  void _loadDrawing(String? drawingJson) {
    if (drawingJson == null || drawingJson.isEmpty) return;
    try {
      final decoded = jsonDecode(drawingJson);
      final strokeData = decoded is Map<String, dynamic>
          ? decoded['strokes'] as List<dynamic>? ?? const <dynamic>[]
          : decoded as List<dynamic>;
      _strokes.addAll(
        strokeData.map(
          (item) => _DrawingStroke.fromJson(item as Map<String, dynamic>),
        ),
      );
      if (decoded is Map<String, dynamic>) {
        final redoData =
            decoded['redoStrokes'] as List<dynamic>? ?? const <dynamic>[];
        _redoStrokes.addAll(
          redoData.map(
            (item) => _DrawingStroke.fromJson(item as Map<String, dynamic>),
          ),
        );
        _undoBoundary = (decoded['undoBoundary'] as num?)?.toInt() ?? 0;
        _undoBoundary = _undoBoundary.clamp(0, _strokes.length);
      }
    } on Object {
      // Ignore invalid drawings saved by an unfinished older version.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Offset _toCanvasPoint(Offset localPoint) => localPoint - _canvasOffset;

  Offset _pointerCenter() {
    var total = Offset.zero;
    for (final point in _activePointers.values) {
      total += point;
    }
    return total / _activePointers.length.toDouble();
  }

  void _handlePointerDown(PointerDownEvent event) {
    setState(() {
      _activePointers[event.pointer] = event.localPosition;
      if (_activePointers.length == 1) {
        _redoStrokes.clear();
        _drawingPointer = event.pointer;
        _currentStroke = _DrawingStroke(
          tool: _selectedTool,
          color: _selectedColor,
          width: _strokeWidth,
          points: [_toCanvasPoint(event.localPosition)],
        );
      } else {
        _drawingPointer = null;
        _currentStroke = null;
      }
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) return;
    final previousCenter = _pointerCenter();
    setState(() {
      _activePointers[event.pointer] = event.localPosition;
      if (_activePointers.length >= 2) {
        _canvasOffset += _pointerCenter() - previousCenter;
      } else if (_drawingPointer == event.pointer) {
        _currentStroke?.points.add(_toCanvasPoint(event.localPosition));
      }
    });
  }

  void _handlePointerUp(PointerEvent event) {
    setState(() {
      if (_activePointers.length == 1 &&
          _drawingPointer == event.pointer &&
          _currentStroke != null) {
        _strokes.add(_currentStroke!);
      }
      _activePointers.remove(event.pointer);
      _currentStroke = null;
      _drawingPointer = null;
    });
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    setState(() {
      _activePointers.remove(event.pointer);
      _currentStroke = null;
      _drawingPointer = null;
    });
  }

  void _undo() {
    if (_strokes.length <= _undoBoundary) return;
    setState(() => _redoStrokes.add(_strokes.removeLast()));
  }

  void _redo() {
    if (_redoStrokes.isEmpty) return;
    setState(() => _strokes.add(_redoStrokes.removeLast()));
  }

  Future<void> _selectTool(DrawingTool tool) async {
    if (_selectedTool != tool) {
      setState(() => _selectedTool = tool);
      return;
    }
    if (tool == DrawingTool.eraser) return;

    final colorValue = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => _DrawingColorPalette(
        colors: _drawingPalette,
        selectedColor: _selectedColor,
      ),
    );
    if (colorValue != null && mounted) {
      setState(() => _selectedColor = Color(colorValue));
    }
  }

  void _save({bool clearHistory = true}) {
    final rawTitle = _titleController.text.trim();
    if (rawTitle.isEmpty && _strokes.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Hãy nhập nội dung để lưu.')),
        );
      return;
    }

    if (clearHistory) {
      _redoStrokes.clear();
      _undoBoundary = _strokes.length;
    }
    widget.onSave(
      DrawingTaskDraft(
        title: rawTitle,
        drawingJson: jsonEncode({
          'version': 2,
          'strokes': _strokes
              .map((stroke) => stroke.toJson(canvasOffset: _canvasOffset))
              .toList(),
          'redoStrokes': _redoStrokes
              .map((stroke) => stroke.toJson(canvasOffset: _canvasOffset))
              .toList(),
          'undoBoundary': _undoBoundary,
        }),
        strokeCount: _strokes.length,
      ),
    );
    _closePage();
  }

  void _handleBack() {
    if (_isClosing) return;
    if (_titleController.text.trim().isNotEmpty || _strokes.isNotEmpty) {
      _save(clearHistory: false);
    } else {
      if (_isEditing) widget.onDeleteEmpty?.call();
      _closePage();
    }
  }

  void _closePage() {
    if (_isClosing) return;
    _isClosing = true;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            _isEditing ? 'Chỉnh sửa bản vẽ' : 'Bản vẽ mới',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            FilledButton(
              key: const Key('save_drawing_task_button'),
              onPressed: _save,
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                TextField(
                  key: const Key('drawing_task_title_field'),
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tiêu đề bản vẽ',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Listener(
                      key: const Key('drawing_canvas'),
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _handlePointerDown,
                      onPointerMove: _handlePointerMove,
                      onPointerUp: _handlePointerUp,
                      onPointerCancel: _handlePointerCancel,
                      child: ColoredBox(
                        color: isDark ? const Color(0xFF101820) : Colors.white,
                        child: CustomPaint(
                          painter: _DrawingPainter(
                            strokes: _strokes,
                            currentStroke: _currentStroke,
                            canvasOffset: _canvasOffset,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: isDark
                      ? const Color(0xFF172A3A)
                      : const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _ToolSlot(
                              child: IconButton(
                                key: const Key('drawing_undo_button'),
                                tooltip: 'Hoàn tác',
                                onPressed: _strokes.length <= _undoBoundary
                                    ? null
                                    : _undo,
                                color: isDark
                                    ? const Color(0xFFEAF5FF)
                                    : const Color(0xFF202124),
                                icon: const Icon(Icons.undo_rounded),
                              ),
                            ),
                            _ToolSlot(
                              child: IconButton(
                                key: const Key('drawing_redo_button'),
                                tooltip: 'Làm lại',
                                onPressed: _redoStrokes.isEmpty ? null : _redo,
                                color: isDark
                                    ? const Color(0xFFEAF5FF)
                                    : const Color(0xFF202124),
                                icon: const Icon(Icons.redo_rounded),
                              ),
                            ),
                            _DrawingToolButton(
                              key: const Key('drawing_pen_button'),
                              icon: Icons.edit_rounded,
                              tooltip: 'Bút thường',
                              selected: _selectedTool == DrawingTool.pen,
                              onPressed: () => _selectTool(DrawingTool.pen),
                            ),
                            _DrawingToolButton(
                              key: const Key('drawing_highlighter_button'),
                              icon: Icons.border_color_rounded,
                              tooltip: 'Bút ghi nhớ',
                              selected:
                                  _selectedTool == DrawingTool.highlighter,
                              onPressed: () =>
                                  _selectTool(DrawingTool.highlighter),
                            ),
                            _DrawingToolButton(
                              key: const Key('drawing_eraser_button'),
                              icon: Icons.auto_fix_normal_rounded,
                              tooltip: 'Bút xóa',
                              selected: _selectedTool == DrawingTool.eraser,
                              onPressed: () => setState(
                                () => _selectedTool = DrawingTool.eraser,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.line_weight_rounded,
                              size: 20,
                              color: isDark
                                  ? const Color(0xFFEAF5FF)
                                  : const Color(0xFF202124),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Slider(
                                key: const Key('drawing_width_slider'),
                                min: 1,
                                max: 30,
                                divisions: 29,
                                value: _strokeWidth,
                                activeColor: _primaryBlue,
                                inactiveColor: const Color(0xFFBBDEFB),
                                onChanged: (value) {
                                  setState(() => _strokeWidth = value);
                                },
                              ),
                            ),
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: Center(
                                child: Container(
                                  key: const Key('drawing_width_preview'),
                                  width: _strokeWidth.clamp(3, 26),
                                  height: _strokeWidth.clamp(3, 26),
                                  decoration: BoxDecoration(
                                    color: _selectedTool == DrawingTool.eraser
                                        ? Theme.of(context).colorScheme.outline
                                        : _selectedColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolSlot extends StatelessWidget {
  const _ToolSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    );
  }
}

class _DrawingToolButton extends StatelessWidget {
  const _DrawingToolButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            foregroundColor: selected
                ? Colors.white
                : Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFEAF5FF)
                : const Color(0xFF202124),
            backgroundColor: selected ? _primaryBlue : Colors.transparent,
            side: BorderSide.none,
            shape: const CircleBorder(),
          ),
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _DrawingColorButton extends StatelessWidget {
  const _DrawingColorButton({
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 29,
        height: 29,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: selected ? Border.all(color: color, width: 2) : null,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _DrawingColorPalette extends StatelessWidget {
  const _DrawingColorPalette({
    required this.colors,
    required this.selectedColor,
  });

  final List<Color> colors;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        child: Column(
          key: const Key('drawing_color_palette'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn màu bút',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in colors)
                  _DrawingColorButton(
                    key: ValueKey('drawing_palette_color_${color.toARGB32()}'),
                    color: color,
                    selected: selectedColor == color,
                    onTap: () => Navigator.pop(context, color.toARGB32()),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawingStroke {
  _DrawingStroke({
    required this.tool,
    required this.color,
    required this.width,
    required this.points,
  });

  factory _DrawingStroke.fromJson(Map<String, dynamic> json) {
    return _DrawingStroke(
      tool: DrawingTool.values.byName(json['tool'] as String),
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

  final DrawingTool tool;
  final Color color;
  final double width;
  final List<Offset> points;

  Map<String, dynamic> toJson({Offset canvasOffset = Offset.zero}) => {
    'tool': tool.name,
    'color': color.toARGB32(),
    'width': width,
    'points': points
        .map(
          (point) => [point.dx + canvasOffset.dx, point.dy + canvasOffset.dy],
        )
        .toList(),
  };
}

class _DrawingPainter extends CustomPainter {
  const _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.canvasOffset,
  });

  final List<_DrawingStroke> strokes;
  final _DrawingStroke? currentStroke;
  final Offset canvasOffset;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.save();
    canvas.translate(canvasOffset.dx, canvasOffset.dy);
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }
    final current = currentStroke;
    if (current != null) _paintStroke(canvas, current);
    canvas.restore();
    canvas.restore();
  }

  void _paintStroke(Canvas canvas, _DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    switch (stroke.tool) {
      case DrawingTool.pen:
        paint
          ..color = stroke.color
          ..strokeWidth = stroke.width;
        break;
      case DrawingTool.highlighter:
        paint
          ..color = stroke.color.withValues(alpha: 0.32)
          ..strokeWidth = stroke.width * 2.2;
        break;
      case DrawingTool.eraser:
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
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
