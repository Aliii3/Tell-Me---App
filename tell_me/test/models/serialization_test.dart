import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tell_me/models/calendar_event.dart';
import 'package:tell_me/models/project.dart';
import 'package:tell_me/models/task.dart';

void main() {
  group('CalendarEvent serialization', () {
    test('round-trips through toJson / fromJson', () {
      final event = CalendarEvent(
        id: 'e1',
        dateKey: '2026-06-14',
        title: 'Stand-up',
        time: '10:00',
        duration: '30 min',
        category: 'Team',
        backgroundColor: const Color(0xFFEEEEEE),
        textColor: const Color(0xFF333333),
        avatars: ['A', 'B'],
        hasVideo: true,
      );

      final restored = CalendarEvent.fromJson(event.toJson());

      expect(restored.id, event.id);
      expect(restored.dateKey, event.dateKey);
      expect(restored.title, event.title);
      expect(restored.time, event.time);
      expect(restored.duration, event.duration);
      expect(restored.category, event.category);
      expect(restored.backgroundColor.toARGB32(),
          event.backgroundColor.toARGB32());
      expect(restored.textColor?.toARGB32(), event.textColor?.toARGB32());
      expect(restored.avatars, event.avatars);
      expect(restored.hasVideo, event.hasVideo);
    });

    test('handles null textColor', () {
      final event = CalendarEvent(
        id: 'e2',
        dateKey: '2026-06-15',
        title: 'Lunch',
        time: '13:00',
        duration: '1 hr',
        category: 'Break',
        backgroundColor: const Color(0xFFFCE7F3),
      );

      final restored = CalendarEvent.fromJson(event.toJson());
      expect(restored.textColor, isNull);
    });

    test('defaults avatars to empty and hasVideo to false', () {
      final json = {
        'id': 'e3',
        'dateKey': '2026-06-14',
        'title': 'Meeting',
        'time': '14:00',
        'duration': '1 hr',
        'category': 'Product',
        'backgroundColorValue': 0xFFEDE9FE,
      };
      final event = CalendarEvent.fromJson(json);
      expect(event.avatars, isEmpty);
      expect(event.hasVideo, isFalse);
    });
  });

  group('Task serialization', () {
    test('round-trips through toMap / fromMap', () {
      final now = DateTime(2026, 6, 14, 9, 0);
      final due = DateTime(2026, 6, 15);
      final task = Task(
        id: 't1',
        title: 'Write tests',
        subtitle: 'Today',
        dueTime: '09:00 AM',
        dueDate: due,
        status: TaskStatus.ongoing,
        priority: TaskPriority.high,
        category: 'Work',
        isDone: false,
        createdAt: now,
      );

      final restored = Task.fromMap(task.toMap());

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.subtitle, task.subtitle);
      expect(restored.dueTime, task.dueTime);
      expect(restored.dueDate, task.dueDate);
      expect(restored.status, task.status);
      expect(restored.priority, task.priority);
      expect(restored.category, task.category);
      expect(restored.isDone, task.isDone);
      expect(restored.createdAt, task.createdAt);
    });

    test('handles null optional fields', () {
      final task = Task(
        id: 't2',
        title: 'Minimal task',
        isDone: false,
        createdAt: DateTime(2026, 6, 14),
      );
      final restored = Task.fromMap(task.toMap());
      expect(restored.subtitle, isNull);
      expect(restored.dueDate, isNull);
      expect(restored.dueTime, isNull);
      expect(restored.category, isNull);
    });

    test('copyWith clear flags actually clear nullable fields', () {
      final task = Task(
        id: 't3',
        title: 'Call mom',
        subtitle: 'Weekly check-in',
        dueDate: DateTime(2026, 7, 5),
        dueTime: '5:00 PM',
        isDone: false,
        createdAt: DateTime(2026, 7, 4),
      );
      final cleared = task.copyWith(
        clearSubtitle: true,
        clearDueDate: true,
        clearDueTime: true,
      );
      expect(cleared.subtitle, isNull);
      expect(cleared.dueDate, isNull);
      expect(cleared.dueTime, isNull);
      // Untouched fields survive.
      expect(cleared.title, 'Call mom');
    });

    test('reminderAt combines dueDate with 12h and 24h dueTime formats', () {
      final base = Task(
        id: 't4',
        title: 'Dentist',
        dueDate: DateTime(2026, 7, 10),
        isDone: false,
        createdAt: DateTime(2026, 7, 4),
      );
      expect(base.copyWith(dueTime: '5:30 PM').reminderAt,
          DateTime(2026, 7, 10, 17, 30));
      expect(base.copyWith(dueTime: '17:30').reminderAt,
          DateTime(2026, 7, 10, 17, 30));
      expect(base.copyWith(dueTime: '12:00 AM').reminderAt,
          DateTime(2026, 7, 10, 0, 0));
      // Date but no time → 09:00 default.
      expect(base.reminderAt, DateTime(2026, 7, 10, 9, 0));
      // No date → no reminder.
      expect(base.copyWith(clearDueDate: true).reminderAt, isNull);
    });
  });

  group('Project serialization', () {
    test('round-trips through toMap / fromMap', () {
      final now = DateTime(2026, 6, 14);
      final project = Project(
        id: 'p1',
        title: 'AI App',
        emoji: '🤖',
        status: ProjectStatus.ongoing,
        createdBy: 'Alex',
        progress: 0.6,
        colorValue: 0xFFFFFFFF,
        createdAt: now,
      );

      final restored = Project.fromMap(project.toMap());

      expect(restored.id, project.id);
      expect(restored.title, project.title);
      expect(restored.emoji, project.emoji);
      expect(restored.status, project.status);
      expect(restored.createdBy, project.createdBy);
      expect(restored.progress, closeTo(project.progress, 0.0001));
      expect(restored.colorValue, project.colorValue);
      expect(restored.createdAt, project.createdAt);
    });

    test('preserves future status', () {
      final project = Project(
        id: 'p2',
        title: 'Future project',
        emoji: '🚀',
        status: ProjectStatus.future,
        createdBy: 'Max',
        colorValue: 0xFF000000,
        createdAt: DateTime(2026, 6, 14),
      );
      final restored = Project.fromMap(project.toMap());
      expect(restored.status, ProjectStatus.future);
    });
  });
}
