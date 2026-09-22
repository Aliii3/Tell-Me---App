# Tell Me — Production Checklist

> Generated: 2026-05-03
> Current state: Flutter MVP complete, `flutter analyze` passing, local storage + mock data + real voice input wired.

---

## Priority 1 — Minimum to Ship

| # | Task | File / Location | Notes |
|---|------|-----------------|-------|
| 1 | Real bundle ID | `ios/Runner.xcodeproj` + `android/app/build.gradle` | Replace `com.example.tell_me` |
| 2 | iOS signing cert + provisioning profile | Xcode → Signing & Capabilities | Distribution cert required for App Store |
| 3 | Android keystore | `android/key.properties` + `build.gradle` signingConfigs | Keep keystore file out of git |
| 4 | App icon | `flutter_launcher_icons` package + `assets/icon/icon.png` | 1024×1024 PNG, no alpha on iOS |
| 5 | Native splash screen | `flutter_native_splash` package | Removes default white flash before Flutter renders |
| 6 | Firebase Auth | `lib/services/auth_service.dart` stub | Email/password + Google + Apple (Apple required for App Store) |
| 7 | Privacy policy page | In-app screen or URL | Required by both stores when requesting mic/speech permissions |
| 8 | Real AI responses | `lib/services/ai_service.dart` lines 1–20 | Stub comment marks exact insertion point for OpenAI / Claude API |

---

## Priority 2 — Core Product Quality

| # | Task | File / Location | Notes |
|---|------|-----------------|-------|
| 9 | Cloud storage | New `lib/services/sync_service.dart` | Firestore or Supabase; mirror `Task` + `Project` Hive models |
| 10 | Push notifications | `firebase_messaging` package | Task due-date reminders |
| 11 | Local notifications | `flutter_local_notifications` package | On-device alerts without FCM |
| 12 | Empty states | All list screens (`tasks_screen`, `dashboard_screen`) | Show illustrated empty state when no data |
| 13 | Error states | `chat_screen`, AI calls, future cloud calls | Graceful degradation + retry UI |
| 14 | Offline handling | `ai_service.dart`, `sync_service.dart` | Detect connectivity, queue writes |

---

## Priority 3 — Monetization

| # | Task | File / Location | Notes |
|---|------|-----------------|-------|
| 15 | Subscription / paywall screen | New `lib/screens/paywall/paywall_screen.dart` | RevenueCat SDK is the standard choice |
| 16 | Feature gating | Gate AI + voice behind subscription tier | Check entitlement before calling `ai_service` / `voice_service` |
| 17 | Restore purchases button | `lib/screens/settings/settings_screen.dart` | Required by App Store guidelines |

---

## Priority 4 — Accessibility & Localization

| # | Task | File / Location | Notes |
|---|------|-----------------|-------|
| 18 | Semantic labels | All custom widgets | Add `Semantics()` wrappers; test with VoiceOver / TalkBack |
| 19 | Dynamic type | Typography system | Verify layouts at largest iOS text size |
| 20 | Arabic localization (RTL) | `lib/l10n/app_ar.arb` | All strings already extracted to `AppStrings` in `constants.dart` |
| 21 | English ARB file | `lib/l10n/app_en.arb` | Add `flutter_localizations` + `intl` gen to `pubspec.yaml` |

---

## Priority 5 — Testing

| # | Task | File / Location | Notes |
|---|------|-----------------|-------|
| 22 | Widget tests | `test/` directory | Task CRUD, chat send/receive, theme toggle |
| 23 | Integration tests | `integration_test/` directory | Full user flows: onboarding → dashboard → add task → complete task |
| 24 | Golden tests | `test/goldens/` | Screenshot-diff key screens across light/dark |

---

## Priority 6 — Voice (Nice to Have)

| # | Task | File / Location | Notes |
|---|------|-----------------|-------|
| 25 | Text-to-speech (AI reads responses) | `lib/services/voice_service.dart` | `flutter_tts` or ElevenLabs TTS |
| 26 | ElevenLabs STT (streaming, higher quality) | `lib/services/voice_service.dart` lines 4–7 | Replace `speech_to_text` block; stub comment marks the spot |
| 27 | Android offline voice | `speech_to_text` uses Google STT (needs internet on Android) | On-device model via ML Kit Speech if offline support needed |

---

## App Store / Play Store Submission Notes

### iOS (App Store Connect)
- Minimum iOS version: set to **16.0** in Xcode (covers 97 %+ of active devices)
- Require **Sign in with Apple** if offering any other social login
- Mic + speech recognition usage strings already added to `Info.plist`
- Export compliance: answer **No** if not using custom encryption (standard HTTPS is exempt)
- App review notes: explain voice permission — reviewers will tap the mic button

### Android (Google Play Console)
- `RECORD_AUDIO` permission already in `AndroidManifest.xml`
- Target API: **34** (Android 14) — required for new apps from August 2024
- `compileSdk` and `targetSdk` in `android/app/build.gradle` must both be 34
- Data safety form in Play Console: declare microphone usage + any data sent to AI APIs

---

## Shortest Path to Store Submission (Ordered)

```
1. Bundle ID + signing
2. App icon + native splash
3. Firebase Auth (email + Google + Apple)
4. Privacy policy screen
5. OpenAI / Claude API wired into ai_service.dart
6. Basic error / empty states
7. Submit for review
```

Everything in Priority 3–6 can ship post-launch in v1.1+.
