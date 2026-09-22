import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/calendar_event.dart';
import '../models/project.dart';
import '../models/task.dart';
import 'storage_service.dart';

class SyncService {
  SyncService._();
  static final instance = SyncService._();

  final _db = FirebaseFirestore.instance;

  // Only sync for verified (non-anonymous) accounts so data is truly portable.
  bool get _canSync {
    final u = FirebaseAuth.instance.currentUser;
    return u != null && !u.isAnonymous;
  }

  CollectionReference<Map<String, dynamic>> _col(String uid, String name) =>
      _db.collection('users').doc(uid).collection(name);

  // ── Real-time streams ──────────────────────────────────────────────────────
  //
  // Each stream uses asyncExpand on authStateChanges so it automatically
  // reconnects under the correct UID when the user signs in or switches
  // accounts, without any extra wiring in the notifiers.

  Stream<List<Task>> watchTasks() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null || user.isAnonymous) return const Stream.empty();
      return _col(user.uid, 'tasks')
          .snapshots()
          .map((s) => s.docs.map((d) => Task.fromMap(d.data())).toList());
    });
  }

  Stream<List<Project>> watchProjects() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null || user.isAnonymous) return const Stream.empty();
      return _col(user.uid, 'projects')
          .snapshots()
          .map((s) => s.docs.map((d) => Project.fromMap(d.data())).toList());
    });
  }

  Stream<List<CalendarEvent>> watchEvents() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null || user.isAnonymous) return const Stream.empty();
      return _col(user.uid, 'events')
          .snapshots()
          .map((s) =>
              s.docs.map((d) => CalendarEvent.fromJson(d.data())).toList());
    });
  }

  // ── One-shot reads (used only at first launch) ─────────────────────────────

  Future<List<Task>> fetchTasks() async {
    if (!_canSync) return [];
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await _col(uid, 'tasks').get();
    return snap.docs.map((d) => Task.fromMap(d.data())).toList();
  }

  Future<List<Project>> fetchProjects() async {
    if (!_canSync) return [];
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await _col(uid, 'projects').get();
    return snap.docs.map((d) => Project.fromMap(d.data())).toList();
  }

  Future<List<CalendarEvent>> fetchEvents() async {
    if (!_canSync) return [];
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await _col(uid, 'events').get();
    return snap.docs.map((d) => CalendarEvent.fromJson(d.data())).toList();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<void> saveTask(Task task) async {
    if (!_canSync) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _col(uid, 'tasks').doc(task.id).set(task.toMap());
  }

  Future<void> deleteTask(String id) async {
    if (!_canSync) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _col(uid, 'tasks').doc(id).delete();
  }

  Future<void> saveProject(Project project) async {
    if (!_canSync) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _col(uid, 'projects').doc(project.id).set(project.toMap());
  }

  Future<void> deleteProject(String id) async {
    if (!_canSync) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _col(uid, 'projects').doc(id).delete();
  }

  Future<void> saveEvent(CalendarEvent event) async {
    if (!_canSync) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _col(uid, 'events').doc(event.id).set(event.toJson());
  }

  Future<void> deleteEvent(String id) async {
    if (!_canSync) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _col(uid, 'events').doc(id).delete();
  }

  // ── Migration: anonymous → signed-in account ───────────────────────────────
  //
  // Called when the user completes sign-in for the first time. Pushes all
  // locally stored data to their new Firestore account so nothing is lost.

  Future<void> pushAllLocalData() async {
    if (!_canSync) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final tasks = StorageService.instance.getAllTasks();
    for (final t in tasks) {
      await _col(uid, 'tasks').doc(t.id).set(t.toMap());
    }

    final projects = StorageService.instance.getAllProjects();
    for (final p in projects) {
      await _col(uid, 'projects').doc(p.id).set(p.toMap());
    }

    final events = StorageService.instance.getAllEvents();
    for (final e in events) {
      await _col(uid, 'events').doc(e.id).set(e.toJson());
    }
  }

  // ── Account deletion ────────────────────────────────────────────────────

  Future<void> deleteAllUserData(String uid) async {
    final batch = _db.batch();
    for (final name in ['tasks', 'projects', 'events']) {
      final docs = await _col(uid, name).get();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }
}
