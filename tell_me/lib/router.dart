import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/privacy/privacy_policy_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/tasks/task_detail_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'services/settings_service.dart';
import 'utils/debug_flags.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(authNotifierProvider);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn =
          user != null || (kDebugMode && DebugFlags.skipAuth);
      final loc = state.matchedLocation;

      if (loc == '/privacy') return null;

      final isAuthRoute = loc == '/login';
      final isOnboardingRoute = loc == '/onboarding';
      final isFirstLaunch = SettingsService.instance.isFirstLaunch;

      if (!isLoggedIn && isFirstLaunch && !isOnboardingRoute) {
        return '/onboarding';
      }
      if (!isLoggedIn && !isFirstLaunch && isOnboardingRoute) return '/login';
      if (!isLoggedIn && !isAuthRoute && !isOnboardingRoute) return '/login';
      if (isLoggedIn && (isAuthRoute || isOnboardingRoute)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/home/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/home/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/home/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/home/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/task/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: TaskDetailScreen(taskId: state.pathParameters['id']!),
          transitionsBuilder: (context, animation, secondary, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    ],
  );
});
