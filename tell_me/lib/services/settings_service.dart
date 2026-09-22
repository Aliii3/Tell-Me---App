import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsService {
  SettingsService._();
  static final instance = SettingsService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  ThemeMode get themeMode {
    final value = _prefs.getString(AppKeys.themeMode);
    if (value == 'dark') return ThemeMode.dark;
    if (value == 'light') return ThemeMode.light;
    return ThemeMode.dark; // default dark
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = mode == ThemeMode.dark ? 'dark' : 'light';
    await _prefs.setString(AppKeys.themeMode, value);
  }

  // ── Intelligence toggles ──────────────────────────────────────────────────

  bool get cognitiveMemory => _prefs.getBool(AppKeys.cognitiveMemory) ?? true;

  Future<void> setCognitiveMemory(bool value) async {
    await _prefs.setBool(AppKeys.cognitiveMemory, value);
  }

  bool get voiceFeedback => _prefs.getBool(AppKeys.voiceFeedback) ?? true;

  Future<void> setVoiceFeedback(bool value) async {
    await _prefs.setBool(AppKeys.voiceFeedback, value);
  }

  // ── Language ──────────────────────────────────────────────────────────────

  String get language => _prefs.getString(AppKeys.language) ?? 'en';

  Future<void> setLanguage(String code) async {
    await _prefs.setString(AppKeys.language, code);
  }

  // ── First launch ──────────────────────────────────────────────────────────

  bool get isFirstLaunch => _prefs.getBool(AppKeys.firstLaunch) ?? true;

  Future<void> markLaunched() async {
    await _prefs.setBool(AppKeys.firstLaunch, false);
  }
}
