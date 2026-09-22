# Tell Me — What's Left

> Updated: 2026-09-23 · App version `1.0.8+16` · 38/38 tests passing, analyzer
> clean, **`flutter build ios --release` verified working** (Runner.app, 43.6MB).
>
> The September 23 pass fixed a completely broken release build. Before it,
> no device build could be produced at all — see §0. Everything remaining is
> manual/ops work only you can do (accounts, consoles, physical devices).

---

## 0. What changed on 2026-09-23 (context for the items below)

**The project moved to `~/Developer/Tell Me - App`.** It previously sat on the
iCloud-synced Desktop. iCloud stamps `com.apple.FinderInfo` and File Provider
attributes onto build output, and `codesign` refuses to sign anything carrying
them:

```
Failed to code sign binary: .../objective_c.framework:
resource fork, Finder information, or similar detritus not allowed
```

Clearing the attributes did not stick — iCloud re-added them within seconds.
`brctl` was also syncing `.git`. **Do not move this project back into
Desktop/Documents**, or device builds will break again.

Also fixed (see commit `d0153f7`):

- Xcode 27 rejects any target below iOS 15.0, and several pods still declare
  iOS 9–13. `post_install` now pins every pod to the app minimum (16.0).
- The Runner target was on iOS 13.0 while the Podfile declared 16.0. Both are
  now 16.0, so App Store Connect advertises the correct minimum.
- `ITSAppUsesNonExemptEncryption=false` added — no more manual export
  compliance answer on every upload.
- First-launch demo seeding removed from `tasks_provider` / `projects_provider`.
  New users now land on the real empty states instead of nine fake tasks.

## 1. Build & upload the IPA

`version:` is already at `1.0.8+16` (build 15 is what TestFlight has).

1. `flutter build ipa` (or Xcode → Product → Archive).
2. Upload via Transporter / Xcode Organizer to TestFlight.

Signing is already configured: bundle `com.aliyasser.tellme`, team `R2TFFU729Z`,
automatic signing, shared `Runner` scheme with a Release archive action.

## 2. Deploy the Cloud Function (fixes "AI chat always fails") **[blocker]**

The Firebase CLI is not installed on this machine — use `npx firebase-tools`
or `npm i -g firebase-tools` first.

1. Firebase Console → upgrade project `tellme-app-ffbc1` to **Blaze**.
2. `npx firebase-tools functions:secrets:set ANTHROPIC_API_KEY`
3. `npx firebase-tools deploy --only functions` — TypeScript compiles clean
   (`tsc --noEmit` passes).
4. Smoke-test: say "add a task to buy milk tomorrow at 9am" → task appears
   with a due date.

## 3. APNs key (fixes push notifications) **[blocker]**

1. developer.apple.com → Keys → create an **APNs Auth Key** (.p8); note the
   Key ID and Team ID.
2. Firebase Console → Project Settings → Cloud Messaging → upload the .p8.
3. Xcode → Runner → Signing & Capabilities: confirm Push Notifications is
   present (`aps-environment: production` is already in the entitlements).
4. Test on a physical device.

## 4. Publish Firestore rules **[blocker]**

`firestore.rules` (owner-scoped, anonymous blocked) is wired into
`firebase.json`:

1. `npx firebase-tools deploy --only firestore:rules`
2. Verify: sync works signed-in; reads fail signed-out.

## 5. Physical-device verification of the mic-stop fix

Still outstanding — `speech_to_text` is pinned to 7.2.0 for this reason.

1. Install build 16 on a real iPhone.
2. Mic → speak → tap mic to stop. Repeat ~10 times.
3. If it crashes: grab the crash log (Settings → Privacy → Analytics →
   `Runner-*.ips`) — no code changes without it.

## 6. App Store Connect

- Description, keywords, support + privacy-policy URLs (the in-app privacy
  screen exists, but Apple also needs a **hosted** URL).
- Privacy labels: mic usage, chat text sent to an AI provider via Cloud
  Functions, FCM token, Firestore user data.
- Review notes explaining the mic flow.
- **Screenshots must be captured manually** — see §7.

Already satisfied: Sign in with Apple is implemented (required because Google
sign-in is offered), and in-app account deletion exists (Guideline 5.1.1(v)).

## 7. Known environment issues (not code defects)

| Issue | Detail |
|---|---|
| `Simulator.app` missing | `/Applications/Xcode.app/Contents/Developer/Applications/` is empty. Runtimes (iOS 26.4/26.5) and `simctl` work, but there is no GUI simulator. Reinstall Xcode to restore it. Until then, capture App Store screenshots on a physical iPhone 17 Pro Max (6.9", 1320×2868). |
| Simulator debug build fails | `debug_unpack_ios` reports `Flutter.framework does not contain architectures "arm64 x86_64"` while listing exactly those architectures — an ordering/stale-artifact bug. Run `flutter clean` before a simulator build. Does not affect device or release builds. |
| Android unbuildable | `android/app/google-services.json` is gitignored and absent. Re-run `flutterfire configure` before any Play Store work. |

## Post-launch backlog (v1.1+, code work)

- **Calendar ↔ tasks**: dated tasks on the calendar; `create_event` tool in
  the Cloud Function.
- **Recurring tasks**: "gym at 7am every weekday" is a suggested prompt the
  model can't fulfil — add recurrence to `Task` + expansion at scheduling time.
- **Monetization**: RevenueCat paywall, entitlement-gate AI chat,
  restore-purchases in Settings.
- **Arabic/RTL localization**: strings already centralized in `AppStrings`.
- **App privacy manifest**: no app-level `PrivacyInfo.xcprivacy` in the Runner
  target (pods ship their own). Apple currently warns rather than rejects, but
  adding one avoids ITMS-91053 mail.
- **Deeper tests**: widget tests for main screens; integration test for
  voice → task with a mocked function.
- **Sync robustness**: retry queue, conflict resolution, offline indicator.

## Technical debt (unchanged)

| Area | Debt |
|---|---|
| Theming | Screens hardcode the aurora palette; `AppTheme.dark/light` + `theme_provider` are mostly dead — delete or migrate to `ThemeExtension`. |
| Hive schema | Any new `@HiveField` on an existing model MUST have `defaultValue` (or be nullable) — upgraded installs crash at box-open otherwise. |
| `speech_to_text` pin | Pinned 7.2.0. Do not bump to ≥7.3.0 without re-testing tap-to-stop on a physical iPhone (detached-Task threading crash). |
| Web prototype | `app.js` / `styles.css` / `tell-me-prototype.html` at repo root are the old HTML prototype — archive or delete. |
