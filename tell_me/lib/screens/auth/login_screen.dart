import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/aurora.dart';
import '../../utils/debug_flags.dart';

const _bgTop    = Color(0xFFC5CCBF);
const _accent   = Color(0xFF7C6FD4);
// Dark ink for the branding block on the light sage background.
const _ink      = Color(0xFF23261E);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isSignUp          = false;
  bool _isLoading         = false;
  bool _obscurePassword   = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _submitEmailPassword() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (!_emailRe.hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (_isSignUp && password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      if (_isSignUp) {
        await AuthService.instance.createAccount(email, password);
      } else {
        await AuthService.instance.signInWithEmail(email, password);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = authErrorMessage(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await AuthService.instance.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = authErrorMessage(e.code));
    } catch (_) {
      // e.g. user cancelled the Google/Apple sheet, or a plugin/network error.
      if (mounted) setState(() => _error = "Couldn't sign in. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _appleSignIn() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await AuthService.instance.signInWithApple();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = authErrorMessage(e.code));
    } catch (_) {
      // e.g. user cancelled the Google/Apple sheet, or a plugin/network error.
      if (mounted) setState(() => _error = "Couldn't sign in. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !_emailRe.hasMatch(email)) {
      setState(() => _error = 'Enter your email above, then tap "Forgot password?".');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to $email.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = authErrorMessage(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAnonymously() async {
    setState(() { _isLoading = true; _error = null; });
    debugPrint('[TellMe] continue-without-account: tapped');
    try {
      final cred = await AuthService.instance.signInAnonymously();
      debugPrint('[TellMe] continue-without-account: signed in as ${cred.user?.uid}');
    } on FirebaseAuthException catch (e) {
      debugPrint('[TellMe] continue-without-account: FirebaseAuthException ${e.code}');
      setState(() => _error = 'Firebase error: ${e.code} — ${e.message}');
    } catch (e, stack) {
      debugPrint('[TellMe] continue-without-account: unexpected error $e\n$stack');
      setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background ────────────────────────────────────────────────────
          const Positioned.fill(child: AuroraBackground()),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Branding ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    children: [
                      const _StarBurst(),
                      const SizedBox(height: 14),
                      Text(
                        'TELL ME',
                        style: AppTypography.dotMatrix(
                          fontSize: 32,
                          color: _ink,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your AI productivity planner',
                        style: TextStyle(
                          fontSize: 12,
                          color: _ink.withValues(alpha: 0.60),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Form panel ────────────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1C1E1A),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text(
                            _isSignUp ? 'CREATE ACCOUNT' : 'WELCOME BACK',
                            style: AppTypography.dotMatrix(
                              fontSize: 20,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSignUp
                                ? 'Start managing your tasks with AI.'
                                : 'Sign in to continue.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.40),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Email
                          _AuthField(
                            controller: _emailCtrl,
                            hint: 'Email address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),

                          // Password
                          _AuthField(
                            controller: _passwordCtrl,
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitEmailPassword(),
                            suffix: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.40),
                              ),
                            ),
                          ),

                          // Forgot password (sign-in mode only)
                          if (!_isSignUp) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _isLoading ? null : _forgotPassword,
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _accent.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // Error
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Row(children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 14,
                                  color: const Color(0xFFE07070)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFE07070),
                                  ),
                                ),
                              ),
                            ]),
                          ],

                          const SizedBox(height: 24),

                          // Primary CTA
                          GestureDetector(
                            onTap: _isLoading ? null : _submitEmailPassword,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                color: _isLoading
                                    ? _accent.withValues(alpha: 0.55)
                                    : _accent,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accent.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isSignUp ? 'Create account →' : 'Sign in →',
                                        style: AppTypography.bodyLg(
                                          color: Colors.white,
                                          weight: FontWeight.w700,
                                        ).copyWith(fontSize: 15),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Divider
                          Row(children: [
                            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text('or',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.30),
                                  )),
                            ),
                            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10))),
                          ]),

                          const SizedBox(height: 22),

                          // Google
                          _SocialBtn(
                            label: 'Continue with Google',
                            badge: 'G',
                            badgeColor: const Color(0xFF4285F4),
                            onTap: _isLoading ? null : _googleSignIn,
                          ),
                          const SizedBox(height: 10),

                          // Apple
                          _SocialBtn(
                            label: 'Continue with Apple',
                            badge: '',
                            badgeColor: Colors.white,
                            onTap: _isLoading ? null : _appleSignIn,
                          ),

                          const SizedBox(height: 28),

                          // Toggle sign-in / sign-up
                          Center(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _isSignUp = !_isSignUp;
                                _error = null;
                              }),
                              child: Text(
                                _isSignUp
                                    ? 'Already have an account?  Sign in'
                                    : "Don't have an account?  Create one",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Skip
                          Center(
                            child: GestureDetector(
                              onTap: _isLoading ? null : _continueAnonymously,
                              child: Text(
                                'Continue without account →',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _accent.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          // Debug-only bypass — works around a Simulator
                          // Keychain bug that blocks real Firebase sign-in.
                          // Never appears in a release/TestFlight build.
                          if (kDebugMode) ...[
                            const SizedBox(height: 10),
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  DebugFlags.skipAuth = true;
                                  context.go('/home');
                                },
                                child: Text(
                                  '🐛 Debug: skip sign-in (Simulator only)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.30),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auth text field ───────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.28),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.35)),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _accent.withValues(alpha: 0.28),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }
}

// ── Social button ─────────────────────────────────────────────────────────────

class _SocialBtn extends StatelessWidget {
  final String label;
  final String badge;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _SocialBtn({
    required this.label,
    required this.badge,
    required this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Star burst ────────────────────────────────────────────────────────────────

class _StarBurst extends StatelessWidget {
  const _StarBurst();

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 28, height: 28, child: CustomPaint(painter: _StarPainter()));
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _ink.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2, cy = size.height / 2, r = size.width * 0.42;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
          Offset(cx, cy), Offset(cx + r * math.cos(a), cy + r * math.sin(a)), p);
    }
  }

  @override
  bool shouldRepaint(_StarPainter _) => false;
}
