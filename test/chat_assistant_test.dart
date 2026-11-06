import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:publicwebsite/chat/chat_service.dart';
import 'package:publicwebsite/chat/chat_widget.dart';
import 'package:publicwebsite/main.dart';

import 'support/fake_backend.dart';

void main() {
  setUp(setUpFakeBackend);

  test('assistant links are parsed and limited to known routes', () {
    final reply = parseAssistantReply(
      'Try our hub.\n[[Learning Hub|/hub]]\n[[Hack|/secret]]\n[[Store|/store]]',
    );
    expect(reply.text, 'Try our hub.');
    expect(reply.actions.map((a) => a.route), ['/hub', '/store']);
  });

  test('offline assistant answers common questions with shortcuts', () async {
    final assistant = ChatAssistant(); // no API key in tests
    expect(assistant.usingLlm, isFalse);
    final reply = await assistant.reply([
      ChatMessage(fromUser: true, text: 'How do I get a certificate?'),
    ]);
    expect(reply.text, contains('60%'));
    expect(reply.actions.single.route, '/dashboard');
  });

  test(
    'gemini request carries grounding and history; reply is parsed',
    () async {
      late Map<String, dynamic> sent;
      final client = MockClient((request) async {
        expect(request.headers['x-goog-api-key'], 'test-key');
        expect(request.url.path, contains('gemini-3.5-flash:generateContent'));
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text':
                          'Start with EI Fundamentals.\n[[Learning Hub|/hub]]',
                    },
                  ],
                },
              },
            ],
          }),
          200,
        );
      });
      final gemini = GeminiAssistant(apiKey: 'test-key', client: client);
      final reply = await gemini.reply([
        ChatMessage(fromUser: true, text: 'Which course first?'),
      ]);
      final system =
          ((sent['systemInstruction'] as Map)['parts'] as List).first['text']
              as String;
      expect(system, contains('Emotional Intelligence Fundamentals'));
      expect(system, contains('Mindful Reflection Journal'));
      expect((sent['contents'] as List).single['role'], 'user');
      expect(reply.text, 'Start with EI Fundamentals.');
      expect(reply.actions.single.route, '/hub');
    },
  );

  test('rate limits fall back to offline answers', () async {
    final assistant = ChatAssistant(
      primary: GeminiAssistant(
        apiKey: 'k',
        client: MockClient((_) async => http.Response('{}', 429)),
      ),
    );
    final reply = await assistant.reply([
      ChatMessage(fromUser: true, text: 'show me the store'),
    ]);
    expect(reply.text, contains('busy'));
    expect(reply.actions.single.route, '/store');
  });

  testWidgets('chat panel opens, answers and navigates', (tester) async {
    ChatOverlay.enabled = true;
    addTearDown(() => ChatOverlay.enabled = false);
    tester.view.physicalSize = const Size(1700, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MtAlchemyApp());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ask Alchemy'));
    await tester.pumpAndSettle();
    expect(find.text('Alchemy Assistant'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).last,
      'What is in the store?',
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Our store currently offers'), findsOneWidget);
    await tester.tap(find.text('Open store'));
    await tester.pumpAndSettle();
    expect(find.text('Tools for everyday practice.'), findsOneWidget);
  });

  test('assistant markdown is rendered as styled text', () {
    final span = formatAssistantText('Try **EI Fundamentals**\n* Mindfulness');
    final plain = span.toPlainText();
    expect(plain, 'Try EI Fundamentals\n•  Mindfulness');
    expect((span.children![1] as TextSpan).style!.fontWeight, FontWeight.w700);
  });
}
