import 'package:flutter/material.dart';
import 'dart:math' as math;

class TennisBallPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  TennisBallPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the curved line pattern
    final path = Path();
    
    // Main curve
    path.moveTo(center.dx - radius, center.dy);
    path.cubicTo(
      center.dx - radius * 0.5, center.dy - radius * 0.8, // First control point
      center.dx + radius * 0.5, center.dy + radius * 0.8, // Second control point
      center.dx + radius, center.dy, // End point
    );

    // Draw the main curve
    canvas.drawPath(path, paint);

    // Draw the same curve rotated 180 degrees
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 