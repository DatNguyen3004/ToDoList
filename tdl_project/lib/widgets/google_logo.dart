import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({this.size = 27, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(size * 0.11),
      child: const CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.22;
    final radius = (size.width - strokeWidth) / 2;
    final arcBounds = Rect.fromCircle(center: center, radius: radius);

    Paint segment(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      arcBounds,
      -135 * math.pi / 180,
      90 * math.pi / 180,
      false,
      segment(const Color(0xFFEA4335)),
    );
    canvas.drawArc(
      arcBounds,
      135 * math.pi / 180,
      90 * math.pi / 180,
      false,
      segment(const Color(0xFFFBBC05)),
    );
    canvas.drawArc(
      arcBounds,
      45 * math.pi / 180,
      90 * math.pi / 180,
      false,
      segment(const Color(0xFF34A853)),
    );
    canvas.drawArc(
      arcBounds,
      -45 * math.pi / 180,
      90 * math.pi / 180,
      false,
      segment(const Color(0xFF4285F4)),
    );

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * 0.51, size.height * 0.5),
      Offset(size.width * 0.91, size.height * 0.5),
      bluePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.5),
      Offset(size.width * 0.78, size.height * 0.68),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
