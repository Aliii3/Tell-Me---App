import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tell_me/models/project.dart';

/// Writes Project records in the exact binary layout used by builds ≤ 11
/// (8 fields — no dueDate / priorityIndex). Reading these with the current
/// adapter is what white-screened TestFlight builds 11/12 on upgraded
/// installs, so this locks in the fix.
class _LegacyProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 4;

  @override
  Project read(BinaryReader reader) =>
      throw UnimplementedError('legacy adapter is write-only in this test');

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.createdBy)
      ..writeByte(5)
      ..write(obj.progress)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.createdAt);
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_migration_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(ProjectStatusAdapter());
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('projects written by the old 8-field schema load with the new adapter',
      () async {
    // 1. Write with the legacy (build ≤ 11) layout.
    Hive.registerAdapter(_LegacyProjectAdapter());
    var box = await Hive.openBox<Project>('projects_migration');
    await box.put(
      'p1',
      Project(
        id: 'p1',
        title: 'Write a proposal for Inc.',
        emoji: '🏆',
        createdBy: 'You',
        colorValue: 0xFFFFFFFF,
        createdAt: DateTime(2026, 6, 1),
      ),
    );
    await box.close();

    // 2. Reopen with the current generated adapter — this is the exact code
    //    path that runs during app startup on an upgraded install.
    Hive.registerAdapter(ProjectAdapter(), override: true);
    box = await Hive.openBox<Project>('projects_migration');

    final restored = box.get('p1');
    expect(restored, isNotNull);
    expect(restored!.title, 'Write a proposal for Inc.');
    expect(restored.dueDate, isNull); // missing field 8 → null
    expect(restored.priorityIndex, 0); // missing field 9 → defaultValue
  });
}
