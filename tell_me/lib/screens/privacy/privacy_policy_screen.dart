import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/aurora.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    _Section(
      title: 'Microphone & Voice',
      body:
          'Tell Me requests microphone access solely to capture your spoken input. '
          'Voice audio is processed on-device by the system speech recogniser and is '
          'never stored or transmitted to our servers.',
    ),
    _Section(
      title: 'Data We Store',
      body:
          'Tasks, projects, and calendar events you create are stored locally on your '
          'device. If you sign in with an account, they are also synced to your private '
          'Firebase (Firestore) space so they are available across your devices; if you '
          'use the app without an account, they stay on your device only.',
    ),
    _Section(
      title: 'Notifications',
      body:
          'To deliver reminders and push notifications, the app registers a device '
          'notification token with Firebase Cloud Messaging. Reminders you schedule are '
          'kept on your device.',
    ),
    _Section(
      title: 'AI Conversations',
      body:
          'When you send a message in the chat, the text — along with your current date '
          'and (if enabled) your task list — is sent through our secure Firebase Cloud '
          'Function to an AI provider to generate a response. We do not retain chat '
          'history on our servers. Please do not share sensitive personal information in '
          'the chat.',
    ),
    _Section(
      title: 'Third-Party Services',
      body:
          'Tell Me may integrate with AI APIs (e.g. Anthropic Claude). These services '
          'have their own privacy policies. We select providers that do not use your '
          'data to train their models.',
    ),
    _Section(
      title: 'Data Retention & Deletion',
      body:
          'Local data is removed when you uninstall the app, and you can clear it any '
          'time from Settings → "Clear On-Device Data". To permanently delete your '
          'account and all synced data, use Settings → Delete Account.',
    ),
    _Section(
      title: 'Contact',
      body:
          'Questions or requests regarding your privacy can be sent to '
          'privacy@tellme.app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Aurora.ink.withValues(alpha: 0.75)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PRIVACY POLICY',
          style: AppTypography.dotMatrix(
              fontSize: 15, color: Aurora.ink, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                // Last updated badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.60),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Last updated: June 2026',
                      style: AppTypography.caption(color: Aurora.highlightInk),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your privacy matters to us.',
                  style: AppTypography.headingMd(color: Aurora.ink),
                ),
                const SizedBox(height: 8),
                HighlightText(
                  'Tell Me is built to keep your data on your device. '
                  'Here is exactly what we access and why.',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                ..._sections.map((s) => _SectionTile(section: s)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final _Section section;

  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: AppTypography.bodyMd(
              color: Aurora.ink,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            section.body,
            style: AppTypography.bodyMd(color: Aurora.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});
}
