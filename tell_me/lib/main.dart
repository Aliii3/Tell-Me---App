import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';

void main() {
  runZonedGuarded(_bootstrap, (error, stack) {
    debugPrint('[TellMe] fatal: $error\n$stack');
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // If anything in pre-frame init throws, show a diagnostic screen rather
  // than dying before runApp — an eternal white screen with no information
  // is the worst possible failure mode (and exactly what TestFlight builds
  // 11/12 shipped with when a Hive schema change broke box loading).
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    // Storage + settings must be ready before the first frame — the router
    // and providers read them synchronously.
    await StorageService.instance.init();
    await SettingsService.instance.init();
    // TTS model download (~100MB) is deferred to first Chat screen open via
    // TtsService.ensureReady(), which gates it behind a Wi-Fi check.
  } catch (error, stack) {
    debugPrint('[TellMe] bootstrap failed: $error\n$stack');
    runApp(_BootstrapErrorApp(error: error));
    return;
  }

  // Render the UI immediately. Notification setup is intentionally NOT
  // awaited here: on a real device the APNs token fetch can hang (e.g. when
  // the APNs key isn't configured in Firebase yet), and awaiting it before
  // runApp would leave the app stuck on a white screen.
  runApp(const ProviderScope(child: TellMeApp()));

  if (!kIsWeb) {
    unawaited(NotificationService.instance.init().catchError((
      Object error,
      StackTrace stack,
    ) {
      debugPrint('[TellMe] notification init failed: $error\n$stack');
    }));
  }
}

/// Minimal fallback UI when pre-frame initialization fails. Deliberately has
/// no dependency on any service that might itself be the thing that broke.
class _BootstrapErrorApp extends StatelessWidget {
  final Object error;
  const _BootstrapErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1C1E1A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 40, color: Color(0xFFE07070)),
                const SizedBox(height: 16),
                const Text(
                  "Tell Me couldn't start",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please force-quit and reopen the app. If this keeps '
                  'happening, reinstall it or contact support with the '
                  'details below.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$error',
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontFamily: 'Menlo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
