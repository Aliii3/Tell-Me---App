import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

const _uuid = Uuid();

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier() : super([]) {
    _load();
  }

  StreamSubscription<List<Project>>? _cloudSub;

  Future<void> _load() async {
    final local = StorageService.instance.getAllProjects();

    if (local.isEmpty) {
      final cloud = await SyncService.instance.fetchProjects();
      if (cloud.isNotEmpty) {
        await StorageService.instance.replaceAllProjects(cloud);
        state = cloud;
      } else {
        await _seedMockData();
      }
    } else {
      state = local;
    }

    _cloudSub = SyncService.instance.watchProjects().listen(_onCloudUpdate);
  }

  void _onCloudUpdate(List<Project> cloud) {
    if (cloud.isEmpty) return;
    StorageService.instance.replaceAllProjects(cloud);
    state = cloud;
  }

  @override
  void dispose() {
    _cloudSub?.cancel();
    super.dispose();
  }

  Future<void> _seedMockData() async {
    final now = DateTime.now();
    final projects = [
      Project(id: _uuid.v4(), title: 'Write a proposal for Inc.', emoji: '🏆', status: ProjectStatus.ongoing, createdBy: 'You', progress: 0.35, colorValue: Colors.white.toARGB32(), createdAt: now),
      Project(id: _uuid.v4(), title: 'Ed-tech market analysis...', emoji: '📊', status: ProjectStatus.future, createdBy: 'You', progress: 0.20, colorValue: const Color(0xFF060A16).toARGB32(), createdAt: now),
      Project(id: _uuid.v4(), title: 'E-commerce landing page.', emoji: '🛍️', status: ProjectStatus.ongoing, createdBy: 'You', progress: 0.55, colorValue: Colors.white.toARGB32(), createdAt: now),
    ];
    for (final p in projects) {
      await StorageService.instance.saveProject(p);
    }
    state = projects;
  }

  Future<void> addProject(Project project) async {
    await StorageService.instance.saveProject(project);
    SyncService.instance.saveProject(project);
    state = [...state, project];
  }

  Future<void> updateProject(Project project) async {
    await StorageService.instance.saveProject(project);
    SyncService.instance.saveProject(project);
    state = state.map((p) => p.id == project.id ? project : p).toList();
  }

  Future<void> deleteProject(String id) async {
    await StorageService.instance.deleteProject(id);
    SyncService.instance.deleteProject(id);
    state = state.where((p) => p.id != id).toList();
  }
}

final projectsProvider = StateNotifierProvider<ProjectsNotifier, List<Project>>(
  (ref) => ProjectsNotifier(),
);
