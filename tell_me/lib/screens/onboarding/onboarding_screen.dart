import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/settings_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/aurora.dart';
import '../../utils/constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _features = [
    (icon: Icons.mic_rounded, label: AppStrings.featureVoice),
    (icon: Icons.notifications_active_rounded, label: AppStrings.featureReminders),
    (icon: Icons.auto_awesome_rounded, label: AppStrings.featureChat),
    (icon: Icons.check_circle_outline_rounded, label: AppStrings.featureTasks),
    (icon: Icons.event_note_rounded, label: AppStrings.featurePlanning),
    (icon: Icons.calendar_month_rounded, label: AppStrings.featureCalendar),
  ];

  Future<void> _continue(BuildContext context) async {
    await SettingsService.instance.markLaunched();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.60),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              AppStrings.smartLearning.toUpperCase(),
                              style: AppTypography.dotMatrix(
                                fontSize: 10,
                                color: Aurora.highlightInk,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Heading
                          Text(
                            'Speak it.',
                            style: AppTypography.sora(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Aurora.ink,
                              height: 1.15,
                            ).copyWith(letterSpacing: -0.5),
                          ),
                          Text(
                            "It's scheduled.",
                            style: AppTypography.sora(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: Aurora.inkSoft,
                              height: 1.15,
                            ).copyWith(letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 12),
                          HighlightText(
                            'Say what you need — Tell Me turns it into tasks, '
                            'reminders, and calendar events.',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Feature grid — frosted glass tiles
                          GridView.count(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: _features
                                .map((f) => _GlassFeatureTile(
                                    icon: f.icon, label: f.label))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  // CTAs pinned below the scroll area.
                  _PillButton(
                    label: AppStrings.getStarted,
                    onTap: () => _continue(context),
                  ),
                  const SizedBox(height: 12),
                  _PillButton(
                    label: AppStrings.signIn,
                    onTap: () => _continue(context),
                    glass: true,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Frosted feature tile ──────────────────────────────────────────────────────

class _GlassFeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GlassFeatureTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Aurora.highlightInk),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm(
                color: Aurora.ink,
                weight: FontWeight.w600,
              ).copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pill CTA ──────────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool glass;

  const _PillButton({
    required this.label,
    required this.onTap,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: glass
              ? Colors.white.withValues(alpha: 0.40)
              : const Color(0xFF1C1E1A),
          borderRadius: BorderRadius.circular(100),
          border: glass
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.60), width: 1)
              : null,
          boxShadow: glass
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF1C1E1A).withValues(alpha: 0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.bodyLg(
            color: glass ? Aurora.ink : Colors.white,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
