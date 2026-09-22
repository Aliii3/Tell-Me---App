import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/calendar_event.dart';
import '../models/task.dart';
import '../models/project.dart';
import '../utils/constants.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();

  late Box<Task> _tasksBox;
  late Box<Project> _projectsBox;
  late Box<String> _eventsBox;

  Future<void> init() async {
    if (kIsWeb) return;

    await Hive.initFlutter();

    Hive.registerAdapter(TaskStatusAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(ProjectStatusAdapter());
    Hive.registerAdapter(ProjectAdapter());

    _tasksBox = await _openBoxSafe<Task>(AppKeys.tasksBox);
    _projectsBox = await _openBoxSafe<Project>(AppKeys.projectsBox);
    _eventsBox = await _openBoxSafe<String>(AppKeys.eventsBox);
  }

  /// Opens a box; if it can't be read (corruption, or a record written by an
  /// incompatible older schema), deletes it and reopens empty. Losing one
  /// local box beats an app that can never start — and signed-in users get
  /// their data back from Firestore on the next sync.
  Future<Box<T>> _openBoxSafe<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e, stack) {
      debugPrint('[TellMe] box "$name" unreadable, resetting: $e\n$stack');
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox<T>(name);
    }
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  List<Task> getAllTasks() => kIsWeb ? [] : _tasksBox.values.toList();

  Future<void> saveTask(Task task) async {
    if (kIsWeb) return;
    await _tasksBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    if (kIsWeb) return;
    await _tasksBox.delete(id);
  }

  Future<void> clearTasks() async {
    if (kIsWeb) return;
    await _tasksBox.clear();
  }

  Future<void> replaceAllTasks(List<Task> tasks) async {
    if (kIsWeb) return;
    await _tasksBox.clear();
    for (final t in tasks) {
      await _tasksBox.put(t.id, t);
    }
  }

  // ── Projects ──────────────────────────────────────────────────────────────

  List<Project> getAllProjects() => kIsWeb ? [] : _projectsBox.values.toList();

  Future<void> saveProject(Project project) async {
    if (kIsWeb) return;
    await _projectsBox.put(project.id, project);
  }

  Future<void> deleteProject(String id) async {
    if (kIsWeb) return;
    await _projectsBox.delete(id);
  }

  Future<void> clearProjects() async {
    if (kIsWeb) return;
    await _projectsBox.clear();
  }

  Future<void> replaceAllProjects(List<Project> projects) async {
    if (kIsWeb) return;
    await _projectsBox.clear();
    for (final p in projects) {
      await _projectsBox.put(p.id, p);
    }
  }

  // ── Calendar Events ────────────────────────────────────────────────────────

  List<CalendarEvent> getAllEvents() => kIsWeb
      ? []
      : _eventsBox.values
          .map((json) => CalendarEvent.fromJson(jsonDecode(json)))
          .toList();

  Future<void> saveEvent(CalendarEvent event) async {
    if (kIsWeb) return;
    await _eventsBox.put(event.id, jsonEncode(event.toJson()));
  }

  Future<void> deleteEvent(String id) async {
    if (kIsWeb) return;
    await _eventsBox.delete(id);
  }

  Future<void> clearEvents() async {
    if (kIsWeb) return;
    await _eventsBox.clear();
  }

  // ── Account deletion ─────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await clearTasks();
    await clearProjects();
    await clearEvents();
  }

  Future<void> replaceAllEvents(List<CalendarEvent> events) async {
    if (kIsWeb) return;
    await _eventsBox.clear();
    for (final e in events) {
      await _eventsBox.put(e.id, jsonEncode(e.toJson()));
    }
  }
}
