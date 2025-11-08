import 'dart:math' as math;

import 'package:flutter/material.dart';

class CircleGamePainter extends CustomPainter {
  final int currentPosition;
  final int? previousPosition;
  final int? nextPosition;
  final int? skippedPosition;
  final double jumpProgress;
  final double fillProgress;
  final double rotationAngle;
  final double targetScale;
  final bool showError;

  CircleGamePainter({
    required this.currentPosition,
    this.previousPosition,
    this.nextPosition,
    this.skippedPosition,
    required this.jumpProgress,
    required this.fillProgress,
    required this.rotationAngle,
    required this.targetScale,
    required this.showError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;
    const circleCount = 12;

    // Save canvas state for rotation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    // Draw connections between circles
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < circleCount; i++) {
      final angle1 = (i * 2 * math.pi / circleCount) - math.pi / 2;
      final angle2 = ((i + 1) * 2 * math.pi / circleCount) - math.pi / 2;

      final p1 = Offset(
        center.dx + radius * math.cos(angle1),
        center.dy + radius * math.sin(angle1),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle2),
        center.dy + radius * math.sin(angle2),
      );

      canvas.drawLine(p1, p2, linePaint);
    }

    // Draw dashed line to skipped position (error indicator)
    if (showError && skippedPosition != null) {
      final skippedAngle =
          (skippedPosition! * 2 * math.pi / circleCount) - math.pi / 2;
      final skippedPos = Offset(
        center.dx + radius * math.cos(skippedAngle),
        center.dy + radius * math.sin(skippedAngle),
      );

      final dashedPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      _drawDashedLine(canvas, center, skippedPos, dashedPaint);
    }

    // Draw circles
    final circlePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < circleCount; i++) {
      final angle = (i * 2 * math.pi / circleCount) - math.pi / 2;
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      // Draw gray halo first
      final haloPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 20, haloPaint);

      if (i == currentPosition) {
        // Current position - red circle with scale animation
        circlePaint.color = const Color(0xFFFF5555);
        canvas.drawCircle(pos, 15 * targetScale, circlePaint);
      } else {
        // Regular red circles
        circlePaint.color = const Color(0xFFFF5555);
        canvas.drawCircle(pos, 12, circlePaint);
      }
    }

    // Restore canvas for arrow (arrow should not rotate)
    canvas.restore();

    // Draw arrow pointer (like clock hand) from center to current position
    if (previousPosition != null && jumpProgress < 1.0) {
      // During jump animation - interpolate between previous and current
      final prevAngle =
          (previousPosition! * 2 * math.pi / circleCount) -
              math.pi / 2 +
              rotationAngle;
      final currAngle =
          (currentPosition * 2 * math.pi / circleCount) -
              math.pi / 2 +
              rotationAngle;
      final interpolatedAngle =
          prevAngle + (currAngle - prevAngle) * jumpProgress;

      _drawArrowPointer(
        canvas,
        center,
        radius * 0.85,
        interpolatedAngle,
        Colors.white,
      );
    } else {
      // Static position
      final angle =
          (currentPosition * 2 * math.pi / circleCount) -
              math.pi / 2 +
              rotationAngle;
      _drawArrowPointer(
        canvas,
        center,
        radius * 0.85,
        angle,
        Colors.white.withValues(alpha: .5),
      );
    }

    // Draw filling effect on the arrow (changes from white to blue)
    if (fillProgress > 0) {
      final angle =
          (currentPosition * 2 * math.pi / circleCount) -
              math.pi / 2 +
              rotationAngle;
      // Stop before arrow head (85% of total length)
      final filledLength = radius * 0.85 * fillProgress * 0.85;

      final fillPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final endX = center.dx + filledLength * math.cos(angle);
      final endY = center.dy + filledLength * math.sin(angle);

      canvas.drawLine(center, Offset(endX, endY), fillPaint);
    }
  }

  void _drawArrowPointer(
      Canvas canvas,
      Offset center,
      double length,
      double angle,
      Color color,
      ) {
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final endX = center.dx + length * math.cos(angle);
    final endY = center.dy + length * math.sin(angle);
    final endPoint = Offset(endX, endY);

    // Draw main line
    canvas.drawLine(center, endPoint, arrowPaint);

    // Draw arrow head
    final arrowHeadPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const arrowHeadSize = 12.0;
    final arrowAngle1 = angle + math.pi - math.pi / 6;
    final arrowAngle2 = angle + math.pi + math.pi / 6;

    final arrowPath = Path();
    arrowPath.moveTo(endX, endY);
    arrowPath.lineTo(
      endX + arrowHeadSize * math.cos(arrowAngle1),
      endY + arrowHeadSize * math.sin(arrowAngle1),
    );
    arrowPath.lineTo(
      endX + arrowHeadSize * math.cos(arrowAngle2),
      endY + arrowHeadSize * math.sin(arrowAngle2),
    );
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowHeadPaint);

    // Draw small circle at center
    final centerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 20, centerCirclePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitDx = dx / distance;
    final unitDy = dy / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final dashEnd = math.min(currentDistance + dashWidth, distance);
      canvas.drawLine(
        Offset(
          start.dx + unitDx * currentDistance,
          start.dy + unitDy * currentDistance,
        ),
        Offset(start.dx + unitDx * dashEnd, start.dy + unitDy * dashEnd),
        paint,
      );
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CircleGamePainter oldDelegate) => true;
}