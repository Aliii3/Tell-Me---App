import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'router.dart' show routerProvider;
import 'services/sync_service.dart';
import 'theme/app_theme.dart';

class TellMeApp extends ConsumerWidget {
  const TellMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // When an anonymous user completes sign-in, push their local data to
    // Firestore so nothing is lost during the anonymous → account migration.
    ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      final wasAnonymous = prev?.valueOrNull?.isAnonymous ?? false;
      final isAuthenticated = next.valueOrNull != null &&
          !(next.valueOrNull!.isAnonymous);
      if (wasAnonymous && isAuthenticated) {
        SyncService.instance.pushAllLocalData();
      }
    });

    return MaterialApp.router(
      title: 'Tell Me',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeProvider),
      routerConfig: router,
    );
  }
}
