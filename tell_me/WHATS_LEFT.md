# Tell Me — What's Left

> Updated: 2026-07-11 (evening) · App version `1.0.8+15` (source now ahead of the
> uploaded IPA — see note in §1) · 38/38 tests passing, analyzer clean.
>
> The July 11 execution pass completed everything the code side could do:
> aurora redesign visually QA'd on all 9 screens (contact sheet:
> `screenshots_all_screens.png`), app icon + native splash generated and wired,
> Firestore rules wired into `firebase.json`, Cloud Function `tsc`-clean,
> Android debug APK building, `speech_to_text` re-pinned to 7.2.0 (fixes the
> Android build AND keeps the iOS tap-to-stop crash fix), design-system golden
> tests added (`test/goldens/`).

Everything remaining is **manual/ops work only you can do** (accounts,
consoles, physical devices), in priority order.

---

## 1. Build & upload a new IPA (source has moved past build 15)

The pubspec now pins `speech_to_text: 7.2.0` (was 6.6.2 in the uploaded build
15) plus the new icon/splash. Device testing must use a build cut from current
source:

1. Bump `version:` in `pubspec.yaml` to `1.0.8+16`.
2. `flutter build ipa` (or Xcode → Product → Archive).
3. Upload via Transporter / Xcode Organizer to TestFlight.

## 2. Deploy the Cloud Function (fixes "AI chat always fails") **[blocker]**

1. Firebase Console → upgrade project to **Blaze** plan.
2. `firebase functions:secrets:set ANTHROPIC_API_KEY` (paste your Anthropic key).
3. `firebase deploy --only functions` — the TypeScript already compiles clean.
4. Smoke-test in the app: say "add a task to buy milk tomorrow at 9am" →
   task appears in the Tasks screen with a due date.

## 3. APNs key (fixes push notifications) **[blocker]**

1. developer.apple.com → Keys → create an **APNs Auth Key** (.p8);
   note the Key ID and Team ID.
2. Firebase Console → Project Settings → Cloud Messaging → Apple app config →
   upload the .p8 with Key ID + Team ID.
3. Xcode → Runner → Signing & Capabilities: confirm the Push Notifications
   capability is present.
4. Test on a physical device: schedule a task a few minutes out → local
   reminder fires; then send a test push from Firebase Console.

## 4. Publish Firestore rules **[blocker]**

`firestore.rules` (owner-scoped, anonymous blocked) is already wired into
`firebase.json`:

1. `firebase deploy --only firestore:rules`
   (or paste the file into Firebase Console → Firestore → Rules → Publish).
2. Verify: sync works signed-in; reads fail signed-out.

## 5. Physical-device verification of the mic-stop fix

The tap-to-stop crash fix is now `speech_to_text 7.2.0` (verified: its iOS
code has none of the 7.3.0 detached-Task threading; simulator launch is
clean). Confirm on hardware with the build from §1:

1. Install build 16 on a real iPhone.
2. Mic → speak → tap mic to stop. Repeat ~10 times.
3. If it crashes: grab the crash log (Settings → Privacy → Analytics →
   `Runner-*.ips`) and bring it back — no code changes without it.

## 6. Store accounts & signing

- **Android**: create a release keystore, fill `android/key.properties`
  (keep the keystore out of any VCS). Add SHA-1/SHA-256 to Firebase for
  Google sign-in.
- **App Store Connect**: description, keywords, support + privacy-policy URLs;
  privacy labels (mic usage, chat text sent to AI provider via Cloud
  Functions, FCM token, Firestore user data); review notes explaining the mic
  flow; screenshots — fresh aurora ones are in `screenshots_all_screens.png`
  (individual PNGs can be re-shot on demand).
- **Optional**: replace the generated placeholder icon
  (`assets/icon/icon.png`) with a designed one, then re-run
  `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.

---

## Post-launch backlog (v1.1+, code work — ask Claude)

- **Calendar ↔ tasks**: dated tasks on the calendar; `create_event` tool in
  the Cloud Function.
- **Recurring tasks**: "gym at 7am every weekday" is a suggested prompt the
  model can't fulfil — add recurrence to `Task` + expansion at scheduling time.
- **Monetization**: RevenueCat paywall, entitlement-gate AI chat,
  restore-purchases in Settings.
- **Arabic/RTL localization**: strings already centralized in `AppStrings`.
- **Deeper tests**: widget tests for main screens; integration test for
  voice → task with a mocked function. (Design-system goldens now exist in
  `test/goldens/` — `flutter test test/goldens --update-goldens` after any
  intentional palette change.)
- **Sync robustness**: retry queue, conflict resolution, offline indicator.

## Technical debt (unchanged)

| Area | Debt |
|---|---|
| Theming | Screens hardcode the aurora palette; `AppTheme.dark/light` + `theme_provider` are mostly dead — delete or migrate to `ThemeExtension`. |
| Hive schema | Any new `@HiveField` on an existing model MUST have `defaultValue` (or be nullable) — upgraded installs crash at box-open otherwise. |
| `speech_to_text` pin | Pinned 7.2.0. Do not bump to ≥7.3.0 without re-testing tap-to-stop on a physical iPhone (detached-Task threading crash). |
| Web prototype | `app.js` / `styles.css` / `tell-me-prototype.html` at repo root are the old HTML prototype — archive or delete. |
