import 'dart:async';
import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/sync_service.dart';

const _uuid = Uuid();

class TasksNotifier extends StateNotifier<List<Task>> {
  TasksNotifier() : super([]) {
    _load();
  }

  StreamSubscription<List<Task>>? _cloudSub;

  /// Ids of tasks whose cloud write hasn't been confirmed yet. A Firestore
  /// snapshot must not clobber these (e.g. a task created while offline).
  final Set<String> _pendingSync = {};

  /// Stable notification id derived from the task's uuid.
  static int _notifId(String taskId) => taskId.hashCode & 0x7fffffff;

  Future<void> _scheduleReminder(Task task) async {
    final when = task.reminderAt;
    if (when == null || task.isDone) {
      await NotificationService.instance.cancelReminder(_notifId(task.id));
      return;
    }
    await NotificationService.instance.scheduleLocalReminder(
      id: _notifId(task.id),
      title: task.title,
      body: task.subtitle ?? 'This task is due now.',
      when: when,
    );
  }

  void _pushToCloud(Task task) {
    _pendingSync.add(task.id);
    // Keep the id in _pendingSync on failure so a cloud snapshot can't wipe
    // the local copy before the write eventually succeeds.
    SyncService.instance.saveTask(task).then(
          (_) => _pendingSync.remove(task.id),
          onError: (Object e) {},
        );
  }

  Future<void> _load() async {
    final local = StorageService.instance.getAllTasks();

    if (local.isEmpty && SettingsService.instance.isFirstLaunch) {
      // On first launch, check the cloud so returning users on a new device
      // get their real data immediately. A genuinely new user starts with an
      // empty list and sees the empty state, not sample content.
      final cloud = await SyncService.instance.fetchTasks();
      if (cloud.isNotEmpty) {
        await StorageService.instance.replaceAllTasks(cloud);
        state = cloud;
      }
      await SettingsService.instance.markLaunched();
    } else {
      state = local;
    }

    // Subscribe to real-time Firestore changes for cross-device sync.
    _cloudSub = SyncService.instance.watchTasks().listen(_onCloudUpdate);
  }

  // Called each time Firestore emits a snapshot for this user's tasks.
  void _onCloudUpdate(List<Task> cloud) {
    if (cloud.isEmpty) return; // Don't wipe local data if the cloud has none yet.
    // Cloud wins — except for tasks whose own cloud write hasn't been
    // confirmed yet (created/edited offline); keep the local copy of those.
    final merged = [...cloud];
    final cloudIds = cloud.map((t) => t.id).toSet();
    for (final t in state) {
      if (_pendingSync.contains(t.id)) {
        if (cloudIds.contains(t.id)) {
          merged[merged.indexWhere((c) => c.id == t.id)] = t;
        } else {
          merged.add(t);
        }
      }
    }
    StorageService.instance.replaceAllTasks(merged); // keep Hive in sync
    state = merged;
    // Tasks that arrived from another device need reminders on this one.
    for (final t in merged) {
      _scheduleReminder(t);
    }
  }

  @override
  void dispose() {
    _cloudSub?.cancel();
    super.dispose();
  }

  Future<Task> addTask(String title,
      {String? subtitle,
      DateTime? dueDate,
      String? dueTime,
      String? category,
      TaskStatus status = TaskStatus.upcoming,
      TaskPriority priority = TaskPriority.none}) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      subtitle: subtitle,
      dueDate: dueDate,
      dueTime: dueTime,
      category: category,
      status: status,
      priority: priority,
      isDone: false,
      createdAt: DateTime.now(),
    );
    await StorageService.instance.saveTask(task);
    _pushToCloud(task);
    state = [...state, task];
    await _scheduleReminder(task);
    return task;
  }

  Future<void> toggleDone(String id) async {
    final updated = state.map((t) {
      if (t.id != id) return t;
      final newDone = !t.isDone;
      final copy = newDone
          ? t.copyWith(
              isDone: true,
              status: TaskStatus.completed,
              completedAt: DateTime.now())
          : t.copyWith(
              isDone: false,
              status: TaskStatus.ongoing,
              clearCompletedAt: true);
      StorageService.instance.saveTask(copy);
      _pushToCloud(copy);
      _scheduleReminder(copy); // cancels when done, reschedules when undone
      return copy;
    }).toList();
    state = updated;
  }

  Future<void> deleteTask(String id) async {
    await StorageService.instance.deleteTask(id);
    SyncService.instance.deleteTask(id).then((_) {}, onError: (Object e) {});
    _pendingSync.remove(id);
    await NotificationService.instance.cancelReminder(_notifId(id));
    state = state.where((t) => t.id != id).toList();
  }

  Future<void> updateTask(Task task) async {
    await StorageService.instance.saveTask(task);
    _pushToCloud(task);
    state = state.map((t) => t.id == task.id ? task : t).toList();
    await _scheduleReminder(task);
  }

  /// Re-inserts a previously deleted task verbatim (used for undo).
  Future<void> restoreTask(Task task) async {
    await StorageService.instance.saveTask(task);
    _pushToCloud(task);
    if (state.any((t) => t.id == task.id)) return;
    state = [...state, task];
    await _scheduleReminder(task);
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, List<Task>>((ref) => TasksNotifier());

final ongoingTasksProvider = Provider<List<Task>>(
  (ref) => ref
      .watch(tasksProvider)
      .where((t) => t.status == TaskStatus.ongoing && !t.isDone)
      .toList(),
);

final upcomingTasksProvider = Provider<List<Task>>(
  (ref) =>
      ref.watch(tasksProvider).where((t) => t.status == TaskStatus.upcoming).toList(),
);

final completedTasksProvider = Provider<List<Task>>(
  (ref) => ref.watch(tasksProvider).where((t) => t.isDone).toList(),
);

/// Number of consecutive days ending today where at least one task was completed.
final streakProvider = Provider<int>((ref) {
  final tasks = ref.watch(tasksProvider);
  final completedDays = tasks
      .where((t) => t.isDone && t.completedAt != null)
      .map((t) => DateUtils.dateOnly(t.completedAt!))
      .toSet();

  var streak = 0;
  var day = DateUtils.dateOnly(DateTime.now());
  while (completedDays.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
});
