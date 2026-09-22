import 'package:speech_to_text/speech_to_text.dart';

/// Why a listening session ended.
enum VoiceEndReason {
  /// A final transcript was delivered via `onFinal`.
  result,

  /// Listening ended (timeout / silence) without any recognized speech.
  noSpeech,

  /// The recognizer reported an error (audio session lost, interruption…).
  error,
}

class VoiceService {
  VoiceService._();
  static final instance = VoiceService._();

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _isListening = false;
  bool get isListening => _isListening;

  bool _gotFinalResult = false;
  bool _hadError = false;
  void Function(VoiceEndReason reason)? _onEnded;

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (e) {
        _hadError = true;
        _finish(VoiceEndReason.error);
      },
      onStatus: (status) {
        // The recognizer reports 'done' / 'notListening' when it stops on
        // its own (silence timeout, listenFor elapsed, interruption). This
        // is what prevents the UI from being stuck on "Listening…".
        if (status == 'done' || status == 'notListening') {
          if (!_gotFinalResult && !_hadError) {
            _finish(VoiceEndReason.noSpeech);
          }
        }
      },
    );
    return _initialized;
  }

  void _finish(VoiceEndReason reason) {
    if (!_isListening) return;
    _isListening = false;
    final cb = _onEnded;
    _onEnded = null;
    cb?.call(reason);
  }

  /// Starts listening. [onPartial] streams the live transcript while the
  /// user speaks; [onFinal] delivers the final transcript; [onEnded] fires
  /// exactly once when the session stops for any reason (including after
  /// [onFinal]).
  Future<bool> startListening({
    required void Function(String transcript) onPartial,
    required void Function(String transcript) onFinal,
    required void Function(VoiceEndReason reason) onEnded,
  }) async {
    final ready = await _ensureInitialized();
    if (!ready) return false;

    _gotFinalResult = false;
    _hadError = false;
    _onEnded = onEnded;
    _isListening = true;

    // No localeId → speech_to_text uses the device's system locale.
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _gotFinalResult = true;
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            onFinal(words);
            _finish(VoiceEndReason.result);
          } else {
            _finish(VoiceEndReason.noSpeech);
          }
        } else {
          onPartial(result.recognizedWords);
        }
      },
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(partialResults: true),
    );

    return true;
  }

  Future<void> stopListening() async {
    // stop() lets the recognizer deliver a final result for what was said
    // so far; onResult/onStatus above then settle the session state.
    await _speech.stop();
  }

  void dispose() {
    _speech.cancel();
    _isListening = false;
    _onEnded = null;
  }
}
