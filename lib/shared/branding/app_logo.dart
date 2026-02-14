import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _AppLogoPainter(),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final basePaint = Paint()..color = const Color(0xFF2F7F6D);
    canvas.drawCircle(center, radius, basePaint);

    final tileSize = size.width * 0.58;
    final tileRect = Rect.fromCenter(
      center: center,
      width: tileSize,
      height: tileSize,
    );
    final tilePaint = Paint()..color = const Color(0xFFF3E8D4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tileRect, Radius.circular(size.width * 0.12)),
      tilePaint,
    );

    final dotPaint = Paint()..color = const Color(0xFFE07A5F);
    final dotRadius = size.width * 0.045;
    canvas.drawCircle(center.translate(-dotRadius * 1.6, -dotRadius * 1.2), dotRadius, dotPaint);
    canvas.drawCircle(center.translate(dotRadius * 1.6, -dotRadius * 1.2), dotRadius, dotPaint);
    canvas.drawCircle(center.translate(0, dotRadius * 1.4), dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
