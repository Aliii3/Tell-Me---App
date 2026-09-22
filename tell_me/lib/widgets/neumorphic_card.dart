import 'package:flutter/material.dart';

/// Frosted-glass list card — translucent white fill with a bright hairline
/// border, matching the soft-focus pastel background. `baseColor` is kept for
/// API compatibility but the glass treatment ignores it.
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const NeumorphicCard({
    super.key,
    required this.child,
    required this.baseColor,
    this.borderRadius = 18,
    this.padding = const EdgeInsets.all(14),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF504078).withValues(alpha: 0.08),
            offset: const Offset(0, 5),
            blurRadius: 18,
          ),
        ],
      ),
      child: child,
    );
  }
}
