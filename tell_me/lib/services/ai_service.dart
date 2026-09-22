import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/chat_message.dart';

class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);

  @override
  String toString() => message;
}

/// A task action the model asked the app to perform (create_tasks,
/// update_task, complete_task, delete_task). Executed client-side against
/// the local task store.
class TaskAction {
  final String name;
  final Map<String, dynamic> input;
  const TaskAction({required this.name, required this.input});
}

/// The model's reply: confirmation text plus zero or more task actions.
class AiReply {
  final String text;
  final List<TaskAction> actions;
  const AiReply({required this.text, this.actions = const []});
}

/// Extra context the model needs to resolve relative dates and reference
/// existing tasks ("cancel the milk one").
class AiContext {
  final DateTime now;
  final String timezone;
  final List<Map<String, dynamic>> tasks;
  const AiContext({
    required this.now,
    required this.timezone,
    required this.tasks,
  });

  Map<String, dynamic> toMap() => {
        'now': now.toIso8601String(),
        'timezone': timezone,
        'tasks': tasks,
      };
}

/// Talks to the `chatWithAI` Firebase Cloud Function, which proxies to the
/// Anthropic Messages API with task tools. The API key lives server-side
/// only — this service never holds it.
class AiService {
  AiService._();
  static final instance = AiService._();

  final _functions = FirebaseFunctions.instance;

  Future<AiReply> sendMessage(
    List<ChatMessage> history, {
    AiContext? context,
  }) async {
    // The Anthropic API requires the conversation to start with a user turn;
    // also keep error banners out of the model's context.
    final sendable = history
        .where((m) => !m.isError)
        .skipWhile((m) => m.role == MessageRole.assistant)
        .toList();
    if (sendable.isEmpty) {
      throw const AiServiceException('Nothing to send yet.');
    }

    try {
      final callable = _functions.httpsCallable(
        'chatWithAI',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'messages': sendable
            .map((m) => {
                  'role': m.isUser ? 'user' : 'assistant',
                  'content': m.content,
                })
            .toList(),
        if (context != null) 'context': context.toMap(),
      });

      final data = result.data;
      final reply = (data['reply'] as String?)?.trim() ?? '';
      final actions = <TaskAction>[];
      final rawActions = data['actions'];
      if (rawActions is List) {
        for (final a in rawActions) {
          if (a is Map && a['name'] is String) {
            actions.add(TaskAction(
              name: a['name'] as String,
              input: Map<String, dynamic>.from(a['input'] as Map? ?? {}),
            ));
          }
        }
      }
      if (reply.isEmpty && actions.isEmpty) {
        throw const AiServiceException('Tell Me had nothing to say back.');
      }
      return AiReply(text: reply, actions: actions);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[TellMe] chatWithAI failed: ${e.code} ${e.message}');
      throw AiServiceException(switch (e.code) {
        'unauthenticated' => 'You need to be signed in to chat with Tell Me.',
        'unavailable' ||
        'deadline-exceeded' =>
          "Couldn't reach Tell Me — check your connection and try again.",
        'resource-exhausted' =>
          'Tell Me is a bit overloaded right now — try again in a minute.',
        _ => 'Tell Me hit a server problem — please try again in a moment.',
      });
    }
  }
}
