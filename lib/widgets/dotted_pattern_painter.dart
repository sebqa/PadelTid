import 'package:flutter/material.dart';

class DottedPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const double spacing = 24;
    const double dotSize = 2;

    // Draw dots in a grid pattern
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Create slight randomness in dot positions
        final offsetX = (x / spacing).floor() % 2 == 0 ? 0.0 : spacing / 2;
        
        canvas.drawCircle(
          Offset(x + offsetX, y),
          dotSize / 2,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 