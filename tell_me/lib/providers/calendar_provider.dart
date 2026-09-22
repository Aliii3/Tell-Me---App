import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/calendar_event.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../theme/app_colors.dart';

const _uuid = Uuid();
final _dateFmt = DateFormat('yyyy-MM-dd');

String dateKey(DateTime d) => _dateFmt.format(d);

class CalendarNotifier
    extends StateNotifier<Map<String, List<CalendarEvent>>> {
  CalendarNotifier() : super({}) {
    _load();
  }

  StreamSubscription<List<CalendarEvent>>? _cloudSub;

  Future<void> _load() async {
    final local = StorageService.instance.getAllEvents();

    if (local.isEmpty) {
      final cloud = await SyncService.instance.fetchEvents();
      if (cloud.isNotEmpty) {
        await StorageService.instance.replaceAllEvents(cloud);
        state = _toMap(cloud);
      } else {
        await _seed();
      }
    } else {
      state = _toMap(local);
    }

    _cloudSub = SyncService.instance.watchEvents().listen(_onCloudUpdate);
  }

  void _onCloudUpdate(List<CalendarEvent> cloud) {
    if (cloud.isEmpty) return;
    StorageService.instance.replaceAllEvents(cloud);
    state = _toMap(cloud);
  }

  @override
  void dispose() {
    _cloudSub?.cancel();
    super.dispose();
  }

  Map<String, List<CalendarEvent>> _toMap(List<CalendarEvent> events) {
    final map = <String, List<CalendarEvent>>{};
    for (final e in events) {
      map.putIfAbsent(e.dateKey, () => []).add(e);
    }
    return map;
  }

  Future<void> _seed() async {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final todayKey = dateKey(today);
    final tomorrowKey = dateKey(tomorrow);

    final events = [
      CalendarEvent(id: _uuid.v4(), dateKey: todayKey, title: 'Daily Stand up', time: '10:00', duration: '30 min', category: 'Team', backgroundColor: AppColors.calendarGray, textColor: const Color(0xFF333333)),
      CalendarEvent(id: _uuid.v4(), dateKey: todayKey, title: 'Design Meeting', time: '12:00', duration: '2 hrs', category: 'Product', backgroundColor: AppColors.calendarSage, textColor: const Color(0xFF3D4F3F), avatars: ['A', 'B'], hasVideo: true),
      CalendarEvent(id: _uuid.v4(), dateKey: todayKey, title: 'Lunch Time', time: '15:00', duration: '1 hr', category: 'Break', backgroundColor: AppColors.calendarNeutral, textColor: const Color(0xFF4F5D52)),
      CalendarEvent(id: _uuid.v4(), dateKey: tomorrowKey, title: 'Product Review', time: '11:00', duration: '1 hr', category: 'Product', backgroundColor: AppColors.calendarSage, textColor: const Color(0xFF3D4F3F)),
    ];

    for (final e in events) {
      await StorageService.instance.saveEvent(e);
    }
    state = _toMap(events);
  }

  Future<void> addEvent(CalendarEvent event) async {
    await StorageService.instance.saveEvent(event);
    SyncService.instance.saveEvent(event);
    final key = event.dateKey;
    state = {
      ...state,
      key: [...(state[key] ?? []), event],
    };
  }

  Future<void> updateEvent(CalendarEvent event, {String? previousKey}) async {
    // The date may have changed, moving the event to a different day bucket.
    final oldKey = previousKey ?? event.dateKey;
    await StorageService.instance.saveEvent(event);
    SyncService.instance.saveEvent(event);
    final next = {...state};
    if (oldKey != event.dateKey) {
      next[oldKey] = (next[oldKey] ?? []).where((e) => e.id != event.id).toList();
    }
    final bucket = (next[event.dateKey] ?? []).where((e) => e.id != event.id).toList()
      ..add(event);
    next[event.dateKey] = bucket;
    state = next;
  }

  Future<void> deleteEvent(String id, String key) async {
    await StorageService.instance.deleteEvent(id);
    SyncService.instance.deleteEvent(id);
    state = {
      ...state,
      key: (state[key] ?? []).where((e) => e.id != id).toList(),
    };
  }
}

/// Parses a "HH:mm" (24h) time string to minutes-since-midnight for sorting.
int _minutesOf(String time) {
  final parts = time.split(':');
  if (parts.length < 2) return 0;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h * 60 + m;
}

final calendarNotifierProvider = StateNotifierProvider<CalendarNotifier,
    Map<String, List<CalendarEvent>>>(
  (ref) => CalendarNotifier(),
);

final selectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final calendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final selected = ref.watch(selectedDateProvider);
  final all = ref.watch(calendarNotifierProvider);
  final list = <CalendarEvent>[...?all[dateKey(selected)]]
    ..sort((a, b) => _minutesOf(a.time).compareTo(_minutesOf(b.time)));
  return list;
});
