import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reads assistant replies aloud using the operating system's built-in
/// speech synthesizer.
///
/// This replaces the previous on-device Kokoro neural TTS: that required a
/// ~100MB model download and native ONNX inference from a v0.0.1 plugin,
/// which hard-crashed release builds the moment it initialized. The system
/// synthesizer is instant, needs no download, and is maintained by the OS.
class TtsService {
  TtsService._() {
    _configure();
  }
  static final instance = TtsService._();

  final _tts = FlutterTts();

  /// True while the engine is actively speaking. Chat screen watches this.
  final speaking = ValueNotifier<bool>(false);

  Future<void> _configure() async {
    try {
      _tts.setStartHandler(() => speaking.value = true);
      _tts.setCompletionHandler(() => speaking.value = false);
      _tts.setCancelHandler(() => speaking.value = false);
      _tts.setErrorHandler((_) => speaking.value = false);
      await _tts.awaitSpeakCompletion(false);
      await _tts.setSpeechRate(0.5); // natural pace on iOS/Android
    } catch (e) {
      // Configuration failure should never affect the rest of the app —
      // voice replies just stay silent.
      debugPrint('[TtsService] configure failed: $e');
    }
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(trimmed);
    } catch (e) {
      debugPrint('[TtsService] speak error: $e');
      speaking.value = false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    speaking.value = false;
  }
}
