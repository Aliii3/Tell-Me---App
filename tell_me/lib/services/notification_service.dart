import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// Top-level so the Flutter engine can invoke it in a background isolate.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // FCM displays the notification automatically when the app is terminated
  // or in the background. No additional work needed here.
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'tell_me_default';
  static const _channelName = 'Tell Me';
  static const _channelDesc = 'Task and project reminders';

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _tzReady = false;

  Future<void> _ensureTimezone() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      // Fall back to UTC rather than failing init; reminders would fire at
      // the wrong wall-clock time but still fire.
      debugPrint('[TellMe] timezone lookup failed, using UTC: $e');
    }
    _tzReady = true;
  }

  Future<void> init() async {
    // Register the background handler before any other Firebase call.
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    await _ensureTimezone();

    // Request permission (required on iOS, optional prompt on Android 13+).
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Initialise flutter_local_notifications for foreground display.
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // Create the Android notification channel (no-op on iOS).
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Fetch and cache the FCM registration token. Bounded by a timeout so a
    // device without a configured APNs key can't block this indefinitely.
    // getToken throws on the iOS simulator (no APNS token) — treat any
    // failure as "no token" rather than aborting init.
    try {
      _fcmToken = await _messaging
          .getToken()
          .timeout(const Duration(seconds: 15), onTimeout: () => null);
      _messaging.onTokenRefresh.listen((t) => _fcmToken = t);
    } catch (_) {
      _fcmToken = null;
    }

    // Show a local notification for messages that arrive while the app is
    // in the foreground (FCM suppresses the system banner in that case).
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    _local.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Show a notification right now (foreground FCM banners, etc.).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await _local.show(id, title, body, _details);
  }

  /// Schedule a reminder to fire at [when] (device-local wall-clock time).
  /// Silently does nothing if [when] is in the past. Exact scheduling is
  /// attempted first; on Android 12+ without the exact-alarm permission it
  /// falls back to inexact (may fire up to a few minutes late).
  Future<void> scheduleLocalReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await _ensureTimezone();
    final fireAt = tz.TZDateTime.from(when, tz.local);
    if (!fireAt.isAfter(tz.TZDateTime.now(tz.local))) return;

    try {
      await _local.zonedSchedule(
        id,
        title,
        body,
        fireAt,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('[TellMe] exact alarm unavailable, falling back: $e');
      await _local.zonedSchedule(
        id,
        title,
        body,
        fireAt,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Cancel a previously scheduled reminder. Safe to call for ids that were
  /// never scheduled.
  Future<void> cancelReminder(int id) => _local.cancel(id);

  /// Cancel every scheduled reminder (used when clearing on-device data).
  Future<void> cancelAll() => _local.cancelAll();
}
