import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tell_me/theme/aurora.dart';
import 'package:tell_me/widgets/neumorphic_card.dart';

/// Goldens for the aurora design system. Text uses the test-default font
/// (deterministic across machines); these exist to catch palette, gradient,
/// and contrast regressions — not typography.
void main() {
  Widget host(Widget child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: AuroraBackground()),
              Center(child: child),
            ],
          ),
        ),
      );

  testWidgets('aurora background', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(host(const SizedBox.shrink()));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/aurora_background.png'),
    );
  });

  testWidgets('frosted glass card + lavender highlight', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 400));
    await tester.pumpWidget(host(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: NeumorphicCard(
          baseColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Design Sprint Lecture',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Aurora.ink,
                ),
              ),
              SizedBox(height: 8),
              HighlightText(
                'A way to quickly ideate, prototype, and validate a product '
                'idea in a week.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    ));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/glass_card_highlight.png'),
    );
  });

  testWidgets('holographic panel + dark pill', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 400));
    await tester.pumpWidget(host(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: Aurora.holo,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI ASSISTANT',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 3,
                  color: Aurora.highlightInk,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Aurora.darkCard,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Ask anything to plan...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/holo_panel.png'),
    );
  });

  testWidgets('dark bento card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 400));
    await tester.pumpWidget(host(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Aurora.darkCard,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TODAY'S TASKS",
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 2,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Aurora.darkCard2,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Aurora.accent,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Buy food',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/dark_bento_card.png'),
    );
  });
}
