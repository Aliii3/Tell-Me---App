import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

class SettingsNotifier extends StateNotifier<_SettingsState> {
  SettingsNotifier()
      : super(_SettingsState(
          cognitiveMemory: SettingsService.instance.cognitiveMemory,
          voiceFeedback: SettingsService.instance.voiceFeedback,
          language: SettingsService.instance.language,
        ));

  void toggleCognitiveMemory() {
    final next = !state.cognitiveMemory;
    SettingsService.instance.setCognitiveMemory(next);
    state = state.copyWith(cognitiveMemory: next);
  }

  void toggleVoiceFeedback() {
    final next = !state.voiceFeedback;
    SettingsService.instance.setVoiceFeedback(next);
    state = state.copyWith(voiceFeedback: next);
  }

  void setLanguage(String code) {
    SettingsService.instance.setLanguage(code);
    state = state.copyWith(language: code);
  }
}

class _SettingsState {
  final bool cognitiveMemory;
  final bool voiceFeedback;
  final String language;

  const _SettingsState({
    required this.cognitiveMemory,
    required this.voiceFeedback,
    required this.language,
  });

  _SettingsState copyWith({
    bool? cognitiveMemory,
    bool? voiceFeedback,
    String? language,
  }) =>
      _SettingsState(
        cognitiveMemory: cognitiveMemory ?? this.cognitiveMemory,
        voiceFeedback: voiceFeedback ?? this.voiceFeedback,
        language: language ?? this.language,
      );
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, _SettingsState>(
  (ref) => SettingsNotifier(),
);
