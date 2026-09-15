import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 102, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _BrandLogoPainter()),
    );
  }
}

class _BrandLogoPainter extends CustomPainter {
  const _BrandLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 102;
    Offset point(double x, double y) => Offset(x * unit, y * unit);

    final shadowPaint = Paint()
      ..color = const Color(0xFF1976D2).withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * unit);
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10 * unit, 14 * unit, 82 * unit, 82 * unit),
      Radius.circular(25 * unit),
    );
    canvas.drawRRect(shadowRect.shift(point(0, 7)), shadowPaint);

    final backSheet = RRect.fromRectAndRadius(
      Rect.fromLTWH(25 * unit, 4 * unit, 71 * unit, 78 * unit),
      Radius.circular(22 * unit),
    );
    canvas.drawRRect(backSheet, Paint()..color = const Color(0xFFA9D8FF));

    final frontSheet = RRect.fromRectAndRadius(
      Rect.fromLTWH(7 * unit, 14 * unit, 80 * unit, 84 * unit),
      Radius.circular(25 * unit),
    );
    canvas.drawRRect(
      frontSheet,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DA3FF), Color(0xFF2489E8)],
        ).createShader(frontSheet.outerRect),
    );

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5 * unit
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final checkPath = Path()
      ..moveTo(24 * unit, 50 * unit)
      ..lineTo(34 * unit, 60 * unit)
      ..lineTo(51 * unit, 40 * unit);
    canvas.drawPath(checkPath, linePaint);
    canvas.drawLine(point(60, 43), point(76, 43), linePaint);
    canvas.drawLine(point(60, 58), point(72, 58), linePaint);
    canvas.drawLine(point(25, 76), point(72, 76), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
