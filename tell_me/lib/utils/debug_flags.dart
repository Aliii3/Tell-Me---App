/// Debug-only escape hatches for local testing. These only ever have an
/// effect when `kDebugMode` is true, which release/TestFlight builds never
/// are — so this can never leak into a shipped build.
class DebugFlags {
  DebugFlags._();

  /// When true (and only checked under `kDebugMode`), the router treats the
  /// user as signed in without touching FirebaseAuth at all. Added to work
  /// around a Simulator-only Firebase Auth Keychain bug that blocks real
  /// sign-in on some Simulator runtimes — irrelevant on physical devices.
  static bool skipAuth = false;
}
