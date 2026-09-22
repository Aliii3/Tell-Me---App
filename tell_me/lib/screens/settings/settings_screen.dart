import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/aurora.dart';
import '../../utils/constants.dart';
import '../../widgets/neumorphic_card.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _bgTop    = Color(0xFFC5CCBF);
const _bgBottom = Color(0xFFBBB5AC);
const _darkCard = Color(0xFF1A1D18);
const _darkCard2 = Color(0xFF252920);
const _lavBadge = Color(0xFFB8A8E8);
const _lavText  = Color(0xFF3D2F6A);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings  = ref.watch(settingsProvider);
    final user      = ref.watch(authStateProvider).valueOrNull;

    final displayName = _displayName(user);
    final email       = user?.email ?? '';
    final initial     = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: _bgTop,
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────────────
          const Positioned.fill(child: AuroraBackground()),

          // ── Content ──────────────────────────────────────────────────────
          Positioned.fill(
            child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Star burst
                        CustomPaint(
                          size: const Size(36, 36),
                          painter: _StarBurstPainter(),
                        ),
                        const Spacer(),
                        // Dot grid
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.28),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: List.generate(
                                9,
                                (_) => Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _darkCard.withValues(alpha: 0.70),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Page title ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      children: [
                        Text(
                          AppStrings.settings,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: _darkCard,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),

                // ── Profile bento card ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _darkCard,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: _lavBadge,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _lavText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Name + email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Section 1: Preferences ────────────────────────────────
                _SectionLabel(label: 'Preferences'),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.mic_rounded,
                          title: 'Voice Feedback',
                          subtitle: 'Read replies aloud',
                          trailing: Switch(
                            value: settings.voiceFeedback,
                            onChanged: (_) => ref
                                .read(settingsProvider.notifier)
                                .toggleVoiceFeedback(),
                            activeThumbColor: _lavBadge,
                            activeTrackColor: _darkCard2,
                          ),
                        ),
                        const _Divider(),
                        _SettingsRow(
                          icon: Icons.psychology_rounded,
                          title: AppStrings.cognitiveMemory,
                          subtitle: 'Let Tell Me see your tasks in chat',
                          trailing: Switch(
                            value: settings.cognitiveMemory,
                            onChanged: (_) => ref
                                .read(settingsProvider.notifier)
                                .toggleCognitiveMemory(),
                            activeThumbColor: _lavBadge,
                            activeTrackColor: _darkCard2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Section 2: Account ────────────────────────────────────
                _SectionLabel(label: 'Account'),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.red,
                          title: AppStrings.signOut,
                          titleColor: AppColors.red,
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF1A1D18),
                          ),
                          onTap: () async {
                            await AuthService.instance.signOut();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                        ),
                        const _Divider(),
                        _SettingsRow(
                          icon: Icons.delete_forever_rounded,
                          iconColor: AppColors.red,
                          title: AppStrings.deleteAccount,
                          titleColor: AppColors.red,
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF1A1D18),
                          ),
                          onTap: () => _confirmDeleteAccount(context),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Section 3: About ──────────────────────────────────────
                _SectionLabel(label: 'About'),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.info_outline_rounded,
                          title: 'App Version',
                          trailing: FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snap) => Text(
                              snap.hasData
                                  ? '${snap.data!.version} (${snap.data!.buildNumber})'
                                  : '—',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                        const _Divider(),
                        _SettingsRow(
                          icon: Icons.lock_outline_rounded,
                          title: AppStrings.privacyData,
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF1A1D18),
                          ),
                          onTap: () => context.go('/privacy'),
                        ),
                        const _Divider(),
                        _SettingsRow(
                          icon: Icons.cleaning_services_rounded,
                          iconColor: AppColors.red,
                          title: 'Clear On-Device Data',
                          titleColor: AppColors.red,
                          subtitle: 'Delete all local tasks, plans & events',
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF1A1D18),
                          ),
                          onTap: () => _confirmClearData(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 150)),
              ],
            ),
          ),
          ), // Positioned.fill
        ],
      ),
    );
  }

  String _displayName(User? user) {
    if (user == null) return 'You';
    if (user.isAnonymous) return 'Guest';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'You';
  }
}

// ── Shared dark dialog ───────────────────────────────────────────────────────

Future<bool> _confirmDark(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1C1E1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      content: Text(
        message,
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.60), fontSize: 13.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel,
              style: const TextStyle(
                  color: Color(0xFFE07070), fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return result == true;
}

// ── Clear on-device data ─────────────────────────────────────────────────────

Future<void> _confirmClearData(BuildContext context, WidgetRef ref) async {
  final confirmed = await _confirmDark(
    context,
    title: 'Clear on-device data?',
    message: 'This removes all tasks, plans, and events stored on this device, '
        'and cancels their reminders. Data synced to your account is not '
        'affected. This can\'t be undone.',
    confirmLabel: 'Clear',
  );
  if (!confirmed || !context.mounted) return;

  await StorageService.instance.clearAll();
  await NotificationService.instance.cancelAll();
  // Recreate the notifiers so they reload from the now-empty local store.
  ref.invalidate(tasksProvider);
  ref.invalidate(projectsProvider);
  ref.invalidate(calendarNotifierProvider);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('On-device data cleared.')),
    );
  }
}

// ── Account deletion ─────────────────────────────────────────────────────────

Future<void> _confirmDeleteAccount(BuildContext context) async {
  final confirmed = await _confirmDark(
    context,
    title: 'Delete account?',
    message: "This permanently deletes your account and all your data. "
        "This can't be undone.",
  );
  if (!confirmed || !context.mounted) return;

  final user = AuthService.instance.currentUser;
  final providerId =
      (user?.providerData.isNotEmpty ?? false) ? user!.providerData.first.providerId : '';

  String? password;
  if (providerId == 'password') {
    final controller = TextEditingController();
    password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm your password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (password == null || password.isEmpty) return;
  }
  if (!context.mounted) return;

  try {
    await AuthService.instance.deleteAccount(password: password);
    if (context.mounted) context.go('/login');
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't delete account: $error")),
      );
    }
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 20, 8),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7665),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: NeumorphicCard(
        padding: EdgeInsets.zero,
        baseColor: _bgBottom,
        borderRadius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

// ── Single settings row ───────────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _darkCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor ?? Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              // Title (+ optional subtitle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? const Color(0xFF1A1D18),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF5A6152),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFAFB8AB),
      indent: 60,
      endIndent: 16,
    );
  }
}

// ── 8-pointed star burst painter ─────────────────────────────────────────────
class _StarBurstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _darkCard.withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.42;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi) / 4;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
