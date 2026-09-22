import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Subtle film-grain texture overlay. Place inside a Stack, above the gradient
/// background but below content. Fixed seed = stable pattern, never repaints.
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: const _GrainPainter(),
            child: const SizedBox.expand(),
          ),
        ),
      );
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(31415);
    final total =
        ((size.width * size.height) * 0.040).clamp(4000, 16000).toInt();

    final lightPts = <Offset>[];
    final darkPts  = <Offset>[];

    for (var i = 0; i < total; i++) {
      final p = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
      (i % 3 == 0 ? darkPts : lightPts).add(p);
    }

    canvas.drawPoints(
      ui.PointMode.points,
      lightPts,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.11)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPoints(
      ui.PointMode.points,
      darkPts,
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.07)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Simulated frosted-glass decoration — no BackdropFilter needed.
/// Use as BoxDecoration on any Container that sits over a gradient + grain background.
BoxDecoration glassDecoration({
  double whiteAlpha = 0.08,
  double borderAlpha = 0.55,
  double radius = 24,
}) =>
    BoxDecoration(
      color: Color.fromRGBO(255, 255, 255, whiteAlpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Color.fromRGBO(255, 255, 255, borderAlpha),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Color.fromRGBO(255, 255, 255, 0.10),
          blurRadius: 8,
          spreadRadius: -2,
          offset: const Offset(0, -1),
        ),
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
