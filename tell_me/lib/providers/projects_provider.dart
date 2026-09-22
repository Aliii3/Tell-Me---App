import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier() : super([]) {
    _load();
  }

  StreamSubscription<List<Project>>? _cloudSub;

  Future<void> _load() async {
    final local = StorageService.instance.getAllProjects();

    if (local.isEmpty) {
      // Pull anything already in the cloud (returning user on a new device);
      // a new user starts empty and sees the empty state.
      final cloud = await SyncService.instance.fetchProjects();
      if (cloud.isNotEmpty) {
        await StorageService.instance.replaceAllProjects(cloud);
        state = cloud;
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
