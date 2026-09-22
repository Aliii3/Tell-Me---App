import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A circular tick-marked instrument dial wrapped around the chat mic orb —
/// minor/major ticks like a radio frequency dial, with an animated progress
/// arc that sweeps continuously while listening and breathes gently at idle.
class DialRing extends StatelessWidget {
  final double size;
  final Animation<double> pulse;
  final bool active;
  final Color accentColor;

  const DialRing({
    super.key,
    required this.size,
    required this.pulse,
    required this.active,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) => CustomPaint(
        size: Size.square(size),
        painter: _DialPainter(
          t: pulse.value,
          active: active,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double t;
  final bool active;
  final Color accentColor;

  _DialPainter({
    required this.t,
    required this.active,
    required this.accentColor,
  });

  static const _tickColor = Color(0xFF1C1E1A);
  static const _minorTickCount = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    for (var i = 0; i < _minorTickCount; i++) {
      final isMajor = i % 5 == 0;
      final angle = (i / _minorTickCount) * 2 * math.pi - math.pi / 2;
      final tickLength = isMajor ? 8.0 : 4.0;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final outer = center + direction * radius;
      final inner = center + direction * (radius - tickLength);

      final tickPaint = Paint()
        ..color = _tickColor.withValues(alpha: isMajor ? 0.30 : 0.14)
        ..strokeWidth = isMajor ? 1.6 : 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(inner, outer, tickPaint);
    }

    final sweepPaint = Paint()
      ..color = accentColor.withValues(alpha: active ? 0.90 : 0.35)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweepAngle =
        active ? t * 2 * math.pi : (math.pi * 0.18 + t * math.pi * 0.10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1),
      -math.pi / 2,
      sweepAngle,
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.active != active ||
      oldDelegate.accentColor != accentColor;
}
