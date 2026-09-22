import 'package:hive_flutter/hive_flutter.dart';

part 'project.g.dart';

@HiveType(typeId: 3)
enum ProjectStatus {
  @HiveField(0)
  ongoing,
  @HiveField(1)
  future,
}

@HiveType(typeId: 4)
class Project extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String emoji;

  @HiveField(3)
  ProjectStatus status;

  @HiveField(4)
  String createdBy;

  @HiveField(5)
  double progress;

  @HiveField(6)
  int colorValue;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? dueDate;

  /// 0 = none, 1 = low, 2 = medium, 3 = high (mirrors TaskPriority indices).
  /// defaultValue keeps records written by builds ≤11 (which lack this field)
  /// readable — without it, opening the box crashes on `null as int`.
  @HiveField(9, defaultValue: 0)
  int priorityIndex;

  Project({
    required this.id,
    required this.title,
    required this.emoji,
    this.status = ProjectStatus.ongoing,
    required this.createdBy,
    this.progress = 0.0,
    required this.colorValue,
    required this.createdAt,
    this.dueDate,
    this.priorityIndex = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'status': status.index,
        'createdBy': createdBy,
        'progress': progress,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'priorityIndex': priorityIndex,
      };

  factory Project.fromMap(Map<String, dynamic> m) => Project(
        id: m['id'] as String,
        title: m['title'] as String,
        emoji: m['emoji'] as String,
        status: ProjectStatus.values[m['status'] as int? ?? 0],
        createdBy: m['createdBy'] as String,
        progress: (m['progress'] as num).toDouble(),
        colorValue: m['colorValue'] as int,
        createdAt: DateTime.parse(m['createdAt'] as String),
        dueDate: m['dueDate'] != null
            ? DateTime.parse(m['dueDate'] as String)
            : null,
        priorityIndex: m['priorityIndex'] as int? ?? 0,
      );

  Project copyWith({
    String? title,
    String? emoji,
    ProjectStatus? status,
    String? createdBy,
    double? progress,
    int? colorValue,
    DateTime? dueDate,
    int? priorityIndex,
    bool clearDueDate = false,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      progress: progress ?? this.progress,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priorityIndex: priorityIndex ?? this.priorityIndex,
    );
  }
}
