import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/task.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import 'tasks_provider.dart';

const _uuid = Uuid();

const _initialGreeting = "Hi, I'm Tell Me — what can I help you plan today?";

/// Whether a request to the AI is currently in flight. Lives outside the
/// message list so the UI reacts to it (the notifier itself never notifies
/// listeners about non-state fields).
final chatIsWaitingProvider = StateProvider<bool>((ref) => false);

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  /// [ref] is optional so unit tests can construct the notifier without a
  /// ProviderContainer; without it, task actions and the waiting provider
  /// are skipped.
  ChatNotifier([this._ref])
      : super([
          ChatMessage(
            id: _uuid.v4(),
            content: _initialGreeting,
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          ),
        ]);

  final Ref? _ref;

  bool _isWaiting = false;
  bool get isWaiting => _isWaiting;

  void _setWaiting(bool value) {
    _isWaiting = value;
    _ref?.read(chatIsWaitingProvider.notifier).state = value;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isWaiting) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: text.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = [...state, userMsg];
    _setWaiting(true);

    ChatMessage reply;
    try {
      final aiReply = await AiService.instance
          .sendMessage(state, context: _buildContext());
      final actionSummary = await _applyActions(aiReply.actions);
      final content = aiReply.text.isNotEmpty
          ? aiReply.text
          : (actionSummary ?? 'Done.');
      reply = ChatMessage(
        id: _uuid.v4(),
        content: content,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      reply = ChatMessage(
        id: _uuid.v4(),
        content: e is AiServiceException
            ? e.message
            : "Couldn't reach Tell Me — check your connection and try again.",
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        isError: true,
      );
    }

    _setWaiting(false);
    if (mounted) state = [...state, reply];
  }

  void clear() {
    state = [];
    _setWaiting(false);
  }

  // ── Context sent to the model ─────────────────────────────────────────────

  AiContext? _buildContext() {
    final ref = _ref;
    if (ref == null) return null;
    final now = DateTime.now();
    // Cognitive Memory off → don't hand the model the task list; it can still
    // create new tasks, it just won't "remember" existing ones.
    final tasks = SettingsService.instance.cognitiveMemory
        ? ref.read(tasksProvider)
        : const <Task>[];
    return AiContext(
      now: now,
      timezone: now.timeZoneName,
      tasks: [
        for (final t in tasks)
          {
            'id': t.id,
            'title': t.title,
            'dueDate': t.dueDate?.toIso8601String(),
            'dueTime': t.dueTime,
            'priority': t.priority.name,
            'isDone': t.isDone,
          },
      ],
    );
  }

  // ── Executing task actions returned by the model ──────────────────────────

  Future<String?> _applyActions(List<TaskAction> actions) async {
    final ref = _ref;
    if (ref == null || actions.isEmpty) return null;
    final notifier = ref.read(tasksProvider.notifier);
    final applied = <String>[];

    Task? findTask(Map<String, dynamic> input) {
      final id = input['id'] as String?;
      if (id == null) return null;
      for (final t in ref.read(tasksProvider)) {
        if (t.id == id) return t;
      }
      return null;
    }

    for (final action in actions) {
      switch (action.name) {
        case 'create_tasks':
          final rawList = action.input['tasks'];
          if (rawList is! List) break;
          for (final raw in rawList) {
            if (raw is! Map) continue;
            final m = Map<String, dynamic>.from(raw);
            final title = (m['title'] as String?)?.trim();
            if (title == null || title.isEmpty) continue;
            final dueDate = _parseDate(m['due_date']);
            final dueTime = _displayTime(m['due_time']);
            await notifier.addTask(
              title,
              subtitle: _subtitleFor(dueDate, dueTime),
              dueDate: dueDate,
              dueTime: dueTime,
              category: (m['category'] as String?)?.trim(),
              priority: _parsePriority(m['priority']),
            );
            applied.add('Added "$title"');
          }

        case 'update_task':
          final task = findTask(action.input);
          if (task == null) break;
          final newDate = _parseDate(action.input['due_date']);
          final newTime = _displayTime(action.input['due_time']);
          final updated = task.copyWith(
            title: (action.input['title'] as String?)?.trim(),
            dueDate: newDate,
            dueTime: newTime,
            priority: action.input['priority'] != null
                ? _parsePriority(action.input['priority'])
                : null,
          );
          await notifier.updateTask(updated.copyWith(
            subtitle: _subtitleFor(updated.dueDate, updated.dueTime) ??
                updated.subtitle,
          ));
          applied.add('Updated "${updated.title}"');

        case 'complete_task':
          final task = findTask(action.input);
          if (task == null || task.isDone) break;
          await notifier.toggleDone(task.id);
          applied.add('Completed "${task.title}"');

        case 'delete_task':
          final task = findTask(action.input);
          if (task == null) break;
          await notifier.deleteTask(task.id);
          applied.add('Deleted "${task.title}"');
      }
    }
    return applied.isEmpty ? null : '${applied.join('. ')}.';
  }

  static DateTime? _parseDate(dynamic v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

  static TaskPriority _parsePriority(dynamic v) => switch (v) {
        'high' => TaskPriority.high,
        'medium' => TaskPriority.medium,
        'low' => TaskPriority.low,
        _ => TaskPriority.none,
      };

  /// "17:30" → "5:30 PM" (the display format the rest of the app uses).
  static String? _displayTime(dynamic v) {
    if (v is! String) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(v.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  }

  static String? _subtitleFor(DateTime? date, String? time) {
    if (date == null) return null;
    final label = DateFormat('EEE, MMM d').format(date);
    return time != null ? '$label · $time' : label;
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
    (ref) => ChatNotifier(ref));
