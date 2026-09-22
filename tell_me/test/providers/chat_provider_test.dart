import 'package:flutter_test/flutter_test.dart';
import 'package:tell_me/models/chat_message.dart';
import 'package:tell_me/providers/chat_provider.dart';

void main() {
  group('ChatMessage', () {
    test('isUser returns true for user role', () {
      final msg = ChatMessage(
        id: '1',
        content: 'Hello',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      expect(msg.isUser, isTrue);
      expect(msg.isAssistant, isFalse);
    });

    test('isAssistant returns true for assistant role', () {
      final msg = ChatMessage(
        id: '2',
        content: 'Hi',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      expect(msg.isAssistant, isTrue);
      expect(msg.isUser, isFalse);
    });
  });

  group('ChatNotifier', () {
    late ChatNotifier notifier;

    setUp(() => notifier = ChatNotifier());
    tearDown(() => notifier.dispose());

    test('starts with a single assistant greeting', () {
      expect(notifier.state.length, 1);
      expect(notifier.state.first.role, MessageRole.assistant);
      expect(notifier.state.first.content, isNotEmpty);
    });

    test('isWaiting is false initially', () {
      expect(notifier.isWaiting, isFalse);
    });

    test('sendMessage adds user message then assistant response', () async {
      await notifier.sendMessage('Hello');
      // greeting + user message + assistant response
      expect(notifier.state.length, 3);
      expect(notifier.state[1].role, MessageRole.user);
      expect(notifier.state[1].content, 'Hello');
      expect(notifier.state[2].role, MessageRole.assistant);
    });

    test('sendMessage ignores blank input', () async {
      await notifier.sendMessage('   ');
      expect(notifier.state.length, 1);
    });

    test('sendMessage ignores empty string', () async {
      await notifier.sendMessage('');
      expect(notifier.state.length, 1);
    });

    test('isWaiting returns to false after sendMessage completes', () async {
      await notifier.sendMessage('Test');
      expect(notifier.isWaiting, isFalse);
    });

    test('clear() empties the message list', () async {
      await notifier.sendMessage('Hello');
      notifier.clear();
      expect(notifier.state, isEmpty);
      expect(notifier.isWaiting, isFalse);
    });

    test('consecutive messages accumulate correctly', () async {
      await notifier.sendMessage('First');
      await notifier.sendMessage('Second');
      // greeting + (user + assistant) * 2
      expect(notifier.state.length, 5);
      expect(notifier.state[1].content, 'First');
      expect(notifier.state[3].content, 'Second');
    });
  });
}
