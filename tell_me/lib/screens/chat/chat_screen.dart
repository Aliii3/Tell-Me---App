import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/tts_service.dart';
import '../../services/voice_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/aurora.dart';
import '../../widgets/dial_ring.dart';

const _bgTop    = Color(0xFFC5CCBF);
const _accent   = Color(0xFF7C6FD4);

// ── Suggestion prompts ────────────────────────────────────────────────────────
const _suggestions = [
  ('Plan my morning for tomorrow', 'Plan my morning for tomorrow'),
  ('Add gym at 7am every weekday', 'Add gym at 7am every weekday'),
];

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  bool _isListening  = false;
  bool _isSpeaking   = false;
  bool _micError     = false;
  bool _noSpeech     = false;
  String _lastResponse = '';
  String _liveTranscript = '';
  String _lastTranscript = '';

  late final AnimationController _ring1;
  Timer? _clockTimer;
  DateTime? _listenStart;

  @override
  void initState() {
    super.initState();
    _ring1 = _makeRing(0);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    TtsService.instance.speaking.addListener(_onSpeakingChanged);
  }

  /// Speaks [text] via the system voice when voice feedback is enabled.
  void _maybeSpeak(String text) {
    if (!ref.read(settingsProvider).voiceFeedback) return;
    TtsService.instance.speak(text);
  }

  void _onSpeakingChanged() {
    if (mounted) setState(() => _isSpeaking = TtsService.instance.speaking.value);
  }

  AnimationController _makeRing(int delayMs) {
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) ctrl.repeat();
    });
    return ctrl;
  }

  @override
  void dispose() {
    TtsService.instance.speaking.removeListener(_onSpeakingChanged);
    _ring1.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _clearTransientFlagsLater() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _micError = false;
          _noSpeech = false;
        });
      }
    });
  }

  Future<void> _toggleMic() async {
    // Stop TTS before listening
    if (_isSpeaking) await TtsService.instance.stop();

    if (_isListening) {
      // onEnded (below) resets the UI once the recognizer settles.
      await VoiceService.instance.stopListening();
      return;
    }

    setState(() {
      _isListening = true;
      _micError = false;
      _noSpeech = false;
      _liveTranscript = '';
      _listenStart = DateTime.now();
    });

    final started = await VoiceService.instance.startListening(
      onPartial: (transcript) {
        if (mounted) setState(() => _liveTranscript = transcript);
      },
      onFinal: (transcript) {
        if (!mounted) return;
        setState(() {
          _lastTranscript = transcript;
          _liveTranscript = '';
        });
        ref.read(chatProvider.notifier).sendMessage(transcript);
      },
      onEnded: (reason) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _liveTranscript = '';
          _noSpeech = reason == VoiceEndReason.noSpeech;
          _micError = reason == VoiceEndReason.error;
        });
        if (reason != VoiceEndReason.result) _clearTransientFlagsLater();
      },
    );

    if (!started && mounted) {
      setState(() {
        _isListening = false;
        _micError = true;
      });
      _clearTransientFlagsLater();
    }
  }

  String _twoDigit(int n) => n.toString().padLeft(2, '0');

  /// Idle → current time. Listening → seconds elapsed since it started.
  /// Both rendered in the dot-matrix style, like the reference's clock/dial.
  String _dotMatrixReadout() {
    if (_isListening && _listenStart != null) {
      final elapsed = DateTime.now().difference(_listenStart!);
      final minutes = elapsed.inMinutes.remainder(60);
      final seconds = elapsed.inSeconds.remainder(60);
      return '${_twoDigit(minutes)}:${_twoDigit(seconds)}';
    }
    final now = DateTime.now();
    return '${_twoDigit(now.hour)}:${_twoDigit(now.minute)}';
  }

  void _sendSuggestion(String text) {
    if (_isListening || ref.read(chatIsWaitingProvider)) return;
    if (_isSpeaking) TtsService.instance.stop();
    setState(() => _lastTranscript = text);
    ref.read(chatProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final isWaiting = ref.watch(chatIsWaitingProvider);

    // Speak new AI messages when voice feedback is enabled (skip errors)
    ref.listen<List<ChatMessage>>(chatProvider, (prev, next) {
      if (next.length > (prev?.length ?? 0)) {
        final latest = next.last;
        if (latest.role == MessageRole.assistant) {
          setState(() => _lastResponse = latest.content);
          if (!latest.isError) _maybeSpeak(latest.content);
        }
      }
    });

    // Derive label strings from current state
    final String headline;
    final String subtitle;
    final IconData orbIcon;
    final Color orbColor;

    if (_isListening) {
      headline  = 'Listening...';
      subtitle  = "Speak clearly. Tap to finish.";
      orbIcon   = Icons.stop_rounded;
      orbColor  = _accent;
    } else if (_noSpeech) {
      headline  = "Didn't catch that";
      subtitle  = 'Tap the mic and try again';
      orbIcon   = Icons.hearing_disabled_rounded;
      orbColor  = _accent.withValues(alpha: 0.55);
    } else if (isWaiting) {
      headline  = 'Thinking...';
      subtitle  = 'Processing your request';
      orbIcon   = Icons.auto_awesome_rounded;
      orbColor  = _accent.withValues(alpha: 0.65);
    } else if (_isSpeaking) {
      headline  = 'Speaking...';
      subtitle  = 'Tap to stop';
      orbIcon   = Icons.volume_up_rounded;
      orbColor  = const Color(0xFF5DCAA5);
    } else if (_micError) {
      headline  = 'Mic unavailable';
      subtitle  = 'Check microphone permissions in Settings';
      orbIcon   = Icons.mic_off_rounded;
      orbColor  = const Color(0xFFE07070);
    } else {
      headline  = 'Tap to speak';
      subtitle  = 'Tell me what you want to plan today';
      orbIcon   = Icons.mic_rounded;
      orbColor  = _accent.withValues(alpha: 0.82);
    }

    // Show response card whenever there is a response and user isn't actively speaking
    final bool showSuggestions = !_isListening && !isWaiting && !_isSpeaking && _lastResponse.isEmpty;
    final bool showResponse    = !_isListening && _lastResponse.isNotEmpty;

    return Scaffold(
      backgroundColor: _bgTop,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const _BrutalistBadge(label: 'TELL'),
                      const Spacer(),
                      const _BrutalistBadge(label: 'ME'),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          TtsService.instance.stop();
                          context.go('/home');
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 16,
                              color: Aurora.ink.withValues(alpha: 0.70)),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── Orb + rings ──────────────────────────────────────────
                Semantics(
                  button: true,
                  label: _isListening
                      ? 'Stop listening'
                      : _isSpeaking
                          ? 'Stop speaking'
                          : 'Start voice input',
                  child: GestureDetector(
                  onTap: _isSpeaking
                      ? () => TtsService.instance.stop()
                      : isWaiting
                          ? null
                          : _toggleMic,
                  child: SizedBox(
                    width: 176,
                    height: 176,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        DialRing(
                          size: 176,
                          pulse: _ring1,
                          active: _isListening,
                          accentColor: _accent,
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: orbColor,
                            border: Border.all(
                              color: const Color(0xFFB4A8FF)
                                  .withValues(alpha: 0.55),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: orbColor.withValues(alpha: 0.50),
                                blurRadius: _isListening ? 40 : 28,
                                spreadRadius: _isListening ? 4 : 1,
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              orbIcon,
                              key: ValueKey(orbIcon),
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),

                const SizedBox(height: 20),

                // ── Status text ──────────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    headline,
                    key: ValueKey(headline),
                    style: AppTypography.displayLg(color: Aurora.ink)
                        .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    subtitle,
                    key: ValueKey(subtitle),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Aurora.inkSoft.withValues(alpha: 0.90),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Dot-matrix readout ────────────────────────────────────
                Text(
                  _dotMatrixReadout(),
                  style: AppTypography.dotMatrix(
                    fontSize: 22,
                    color: Aurora.ink.withValues(alpha: 0.45),
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 22),

                // ── Waveform + live transcript (listening only) ──────────
                if (_isListening) ...[
                  const _WaveformBars(),
                  if (_liveTranscript.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
                      child: Text(
                        '“$_liveTranscript”',
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                ],

                // ── Response card (speaking / thinking) ─────────────────
                if (showResponse)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedOpacity(
                      opacity: showResponse ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1E1A).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // What the app heard — so a misrecognition is
                            // visible and correctable, not silent.
                            if (_lastTranscript.isNotEmpty) ...[
                              Text(
                                'YOU SAID',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Colors.white.withValues(alpha: 0.40),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '“$_lastTranscript”',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white.withValues(alpha: 0.60),
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              const SizedBox(height: 10),
                            ],
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 170),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: HighlightText(
                                  _lastResponse,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const Spacer(flex: 2),

                // ── AI assistant panel (idle only) ───────────────────────
                if (showSuggestions)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _AiAssistantPanel(
                      onSuggestion: _sendSuggestion,
                      onAsk: _toggleMic,
                    ),
                  ),

                // Clear the floating nav dock + mic FAB from the home shell.
                const SizedBox(height: 148),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Waveform bars ─────────────────────────────────────────────────────────────

class _WaveformBars extends StatefulWidget {
  const _WaveformBars();

  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rnd = math.Random(42);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const barCount   = 12;
    final baseHeights = List.generate(barCount, (i) => 4.0 + _rnd.nextDouble() * 28);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (i) {
            final phase = (i / barCount) * math.pi * 2;
            final wave  = math.sin(t * math.pi * 2 + phase);
            final h     = baseHeights[i] * (0.6 + 0.4 * wave);
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.65 + 0.35 * ((wave + 1) / 2)),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Suggestion card ───────────────────────────────────────────────────────────

// ── Brutalist badge ────────────────────────────────────────────────────────────

class _BrutalistBadge extends StatelessWidget {
  final String label;
  const _BrutalistBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── AI assistant panel (holo gradient, reference style) ───────────────────────

class _AiAssistantPanel extends StatelessWidget {
  final ValueChanged<String> onSuggestion;
  final VoidCallback onAsk;
  const _AiAssistantPanel({required this.onSuggestion, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: Aurora.holo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF504078).withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'AI ASSISTANT',
                style: AppTypography.dotMatrix(
                  fontSize: 15,
                  color: const Color(0xFF3C2850).withValues(alpha: 0.80),
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
              Icon(Icons.open_in_full_rounded,
                  size: 13,
                  color: const Color(0xFF3C2850).withValues(alpha: 0.45)),
            ],
          ),
          const SizedBox(height: 12),
          ..._suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SuggestionChip(
                text: s.$1,
                onTap: () => onSuggestion(s.$2),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Dark "ask anything" pill → starts voice input
          GestureDetector(
            onTap: onAsk,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1E1A),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Ask anything to plan...',
                      style: AppTypography.bodySm(
                        color: Colors.white.withValues(alpha: 0.65),
                      ).copyWith(fontSize: 12),
                    ),
                  ),
                  Icon(Icons.mic_rounded,
                      size: 15, color: Colors.white.withValues(alpha: 0.75)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.65),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySm(color: const Color(0xFF2A2E24))
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 7),
            Icon(Icons.add_rounded,
                size: 13,
                color: const Color(0xFF2A2E24).withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }
}
