import 'package:hive_flutter/hive_flutter.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum TaskStatus {
  @HiveField(0)
  ongoing,
  @HiveField(1)
  upcoming,
  @HiveField(2)
  completed,
}

@HiveType(typeId: 1)
enum TaskPriority {
  @HiveField(0)
  none,
  @HiveField(1)
  low,
  @HiveField(2)
  medium,
  @HiveField(3)
  high,
}

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? subtitle;

  @HiveField(3)
  String? dueTime;

  @HiveField(4)
  DateTime? dueDate;

  @HiveField(5)
  TaskStatus status;

  @HiveField(6)
  TaskPriority priority;

  @HiveField(7)
  String? category;

  @HiveField(8)
  bool isDone;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.subtitle,
    this.dueTime,
    this.dueDate,
    this.status = TaskStatus.upcoming,
    this.priority = TaskPriority.none,
    this.category,
    this.isDone = false,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'dueTime': dueTime,
        'dueDate': dueDate?.toIso8601String(),
        'status': status.index,
        'priority': priority.index,
        'category': category,
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Task.fromMap(Map<String, dynamic> m) => Task(
        id: m['id'] as String,
        title: m['title'] as String,
        subtitle: m['subtitle'] as String?,
        dueTime: m['dueTime'] as String?,
        dueDate: m['dueDate'] != null
            ? DateTime.parse(m['dueDate'] as String)
            : null,
        status: TaskStatus.values[m['status'] as int? ?? 0],
        priority: TaskPriority.values[m['priority'] as int? ?? 0],
        category: m['category'] as String?,
        isDone: m['isDone'] as bool? ?? false,
        createdAt: DateTime.parse(m['createdAt'] as String),
        completedAt: m['completedAt'] != null
            ? DateTime.parse(m['completedAt'] as String)
            : null,
      );

  Task copyWith({
    String? title,
    String? subtitle,
    String? dueTime,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    String? category,
    bool? isDone,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool clearSubtitle = false,
    bool clearDueDate = false,
    bool clearDueTime = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      subtitle: clearSubtitle ? null : (subtitle ?? this.subtitle),
      dueTime: clearDueTime ? null : (dueTime ?? this.dueTime),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  /// The concrete moment a reminder should fire, or null when the task has
  /// no due date. Combines [dueDate] with [dueTime] ("HH:MM" or "h:mm AM/PM");
  /// tasks with a date but no time default to 09:00.
  DateTime? get reminderAt {
    final date = dueDate;
    if (date == null) return null;
    var hour = 9;
    var minute = 0;
    final raw = dueTime?.trim();
    if (raw != null && raw.isNotEmpty) {
      final match =
          RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$').firstMatch(raw);
      if (match != null) {
        hour = int.parse(match.group(1)!);
        minute = int.parse(match.group(2)!);
        final meridiem = match.group(3)?.toUpperCase();
        if (meridiem == 'PM' && hour < 12) hour += 12;
        if (meridiem == 'AM' && hour == 12) hour = 0;
      }
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
