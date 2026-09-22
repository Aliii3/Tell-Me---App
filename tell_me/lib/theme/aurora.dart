import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'grain_painter.dart';

/// ── Shared design tokens for the pastel "blurred photo" look ────────────────
class Aurora {
  Aurora._();

  // Accent (kept from existing language)
  static const accent = Color(0xFF7C6FD4);

  // Lavender highlight — the reference marks key phrases with this
  static const highlight = Color(0xFFD9C6F2);
  static const highlightInk = Color(0xFF3C2850);

  // Ink on the pastel background
  static const ink = Color(0xFF23261E);
  static const inkSoft = Color(0xFF565C4C);

  // Dark cards
  static const darkCard = Color(0xFF1A1D18);
  static const darkCard2 = Color(0xFF252920);

  // Holographic / iridescent card gradient (peach → lavender → mint)
  static const holo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF6CDB2), // peach
      Color(0xFFE3C8EE), // lavender
      Color(0xFFB9D4E8), // periwinkle
      Color(0xFFB6DCC4), // mint
    ],
    stops: [0.0, 0.38, 0.68, 1.0],
  );

  // Softer holo for large surfaces (note cards)
  static const holoSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF3D9C6),
      Color(0xFFDFC9EC),
      Color(0xFFBFD8CB),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}

/// Full-screen background that mimics the reference's out-of-focus photo:
/// bright cream light in the upper half, warm peach and lavender wisps in the
/// middle, deep sage green sweeping across the lower portion. Blurred blobs
/// are painted once (RepaintBoundary) with film grain on top.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) => const RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _AuroraPainter()),
            GrainOverlay(),
          ],
        ),
      );
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base — soft warm ivory falling into muted sage
    final base = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.3, 0),
        Offset(w * 0.6, h),
        const [
          Color(0xFFF2EEE4), // warm ivory
          Color(0xFFE2E0D2), // pale stone
          Color(0xFFAFB89F), // muted sage
          Color(0xFF95A186), // deeper sage
        ],
        const [0.0, 0.35, 0.75, 1.0],
      );
    canvas.drawRect(Offset.zero & size, base);

    void blob(double cx, double cy, double r, Color color, double blur) {
      final paint = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawCircle(Offset(cx * w, cy * h), r * w, paint);
    }

    // Bright cream glow — upper right (the "sky" of the photo)
    blob(0.85, 0.08, 0.55, const Color(0xFFFDF9EC).withValues(alpha: 0.85), 90);
    // Soft white light — top center
    blob(0.45, 0.02, 0.40, const Color(0xFFFFFFFF).withValues(alpha: 0.55), 80);
    // Warm peach wisp — mid left
    blob(0.10, 0.30, 0.34, const Color(0xFFEACBAE).withValues(alpha: 0.50), 70);
    // Lavender wisp — center right
    blob(0.88, 0.42, 0.30, const Color(0xFFCFC2E4).withValues(alpha: 0.45), 70);
    // Blush hint — center
    blob(0.40, 0.48, 0.26, const Color(0xFFE7C7C2).withValues(alpha: 0.30), 80);
    // Deep sage mass — lower left (the "sweater")
    blob(0.12, 0.88, 0.48, const Color(0xFF7D8E6E).withValues(alpha: 0.70), 80);
    // Olive green — lower right
    blob(0.85, 0.97, 0.42, const Color(0xFF8A9878).withValues(alpha: 0.60), 85);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Text with the lavender marker highlight from the reference design.
/// Wraps each line's painted background in a rounded lavender box.
class HighlightText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int? maxLines;

  const HighlightText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: style.copyWith(
          color: Aurora.highlightInk,
          backgroundColor: Aurora.highlight,
          height: (style.height ?? 1.35) + 0.25,
        ),
      ),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
