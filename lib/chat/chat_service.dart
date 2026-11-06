import 'dart:convert';

import 'package:http/http.dart' as http;

import '../backend/app_config.dart';
import '../commerce/commerce_prototype_store.dart';
import '../data/mock_data.dart';
import '../shared/auth_prototype_store.dart';

/// A shortcut the assistant offers under its reply, e.g. "Open store".
class ChatAction {
  const ChatAction(this.label, this.route);
  final String label;
  final String route;
}

class ChatMessage {
  ChatMessage({
    required this.fromUser,
    required this.text,
    this.actions = const [],
    this.error = false,
  });
  final bool fromUser;
  final String text;
  final List<ChatAction> actions;
  final bool error;
}

/// Routes the assistant may link to. Anything else is dropped.
const assistantRoutes = <String, String>{
  '/': 'Home',
  '/about': 'About',
  '/services': 'Services',
  '/coaching': 'Individual coaching',
  '/organizations': 'Organizations',
  '/programmes': 'Corporate programmes',
  '/impact': 'Impact stories',
  '/insights': 'Insights',
  '/contact': 'Contact us',
  '/hub': 'Learning Hub',
  '/store': 'Store',
  '/cart': 'Cart',
  '/login': 'Sign in',
  '/register': 'Create account',
  '/dashboard': 'Learner dashboard',
  '/trainer-dashboard': 'Trainer dashboard',
  '/employer': 'Employer portal',
  '/employees': 'Manage employees',
  '/assign-course': 'Assign courses',
  '/reports': 'Learning reports',
  '/quote-request': 'Request a quote',
  '/orders': 'My orders',
  '/digital-library': 'Digital library',
  '/admin': 'Admin dashboard',
  '/admin/products': 'Manage products',
  '/admin/orders': 'Manage orders',
  '/admin/courses': 'Manage courses',
  '/admin/quotes': 'Quote requests',
  '/admin/enquiries': 'Contact enquiries',
  '/profile': 'My profile',
};

/// Builds the grounding prompt from live catalogue data and the user's role.
String buildSystemPrompt() {
  final auth = AuthPrototypeStore.instance;
  final role = auth.role ?? 'Visitor (not signed in)';
  final store = CommercePrototypeStore.instance;
  final courses = publishedCourses
      .map(
        (c) =>
            '- ${c.title} (${c.level}, ${c.duration}, RM ${c.price.toStringAsFixed(0)}): ${c.shortDescription}'
            '${c.prerequisites.isEmpty ? '' : ' Prerequisites: ${c.prerequisites.join(', ')}.'}',
      )
      .join('\n');
  final products = store.publishedProducts
      .map(
        (p) =>
            '- ${p.name} (${p.digital ? 'digital download' : 'physical, ${p.stock} in stock'}, RM ${p.price.toStringAsFixed(2)}): ${p.description}',
      )
      .join('\n');
  final routes = assistantRoutes.entries
      .map((e) => '${e.key} = ${e.value}')
      .join('; ');
  return '''
You are "Alchemy Assistant", the friendly help assistant on the MT Alchemy website and learning platform.

About MT Alchemy: a Malaysian people-development consultancy. Tagline "Made to Thrive" (also "People first. Possibility always.") It helps individuals, teams and organizations grow through emotional intelligence (EQ), mindfulness, leadership, communication, team effectiveness and workplace well-being. Founder Mabel Tan KH is an EQ coach and HRDC-certified trainer; Esther Ng is Consultant & Operations Advisor. 1,100+ participants reached through corporate teams, education, youth leadership and community programmes. Services: Emotional Intelligence & Mindfulness; Leadership & Communication; Organization Well-being Assessment; Team Building & Effectiveness; Community engagement (CSR); Customised programmes; one-to-one Individual Coaching.

Platform roles:
- Learner: browse the Learning Hub, enrol, complete lessons, take the course quiz (pass mark 60%), download a certificate after passing, see trainer feedback on the dashboard.
- Employer: register an organisation, add employees, assign courses with due dates, view learning reports (CSV/PDF), request quotes for programmes or bulk materials.
- Trainer: review learner quiz submissions and give feedback, follow learner progress, preview courses.
- Admin: manage courses (with PDFs and quizzes), products and stock, orders and payment status, quote requests and contact enquiries.
Only Learner and Employer accounts can self-register; Trainer and Admin accounts are created by MT Alchemy.
Store: add items to cart, checkout requires sign-in, payment is simulated (an admin marks orders Paid). Physical items cost RM 10 shipping. Digital items unlock in the Digital Library after payment.
For consulting, coaching or corporate programmes, suggest the Contact page or (for employers) Request a quote.

Courses:
$courses

Store products:
$products

Current user role: $role${auth.displayName == null ? '' : ', name: ${auth.displayName}'}.

Rules:
- Answer in 1-4 short paragraphs or a short list. Be warm, clear and practical. Use RM for prices.
- Only state facts given above. If unsure (e.g. dates, availability, personal advice), say so and suggest contacting MT Alchemy.
- You are not a therapist; for mental-health crises, encourage contacting a professional or local emergency services.
- Never ask for passwords or payment details.
- When a page would help, end with up to 3 links on their own lines in the exact form [[Label|/route]] using only these routes: $routes
''';
}

final _actionPattern = RegExp(r'\[\[([^|\]]{1,40})\|(/[a-z\-/]*)\]\]');

/// Splits model text into the visible reply and validated route actions.
ChatMessage parseAssistantReply(String raw) {
  final actions = <ChatAction>[];
  for (final m in _actionPattern.allMatches(raw)) {
    final route = m.group(2)!;
    if (assistantRoutes.containsKey(route) &&
        actions.every((a) => a.route != route) &&
        actions.length < 3) {
      actions.add(ChatAction(m.group(1)!.trim(), route));
    }
  }
  final text = raw
      .replaceAll(_actionPattern, '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  return ChatMessage(fromUser: false, text: text, actions: actions);
}

abstract class AssistantBackend {
  String get name;
  Future<ChatMessage> reply(List<ChatMessage> history);
}

/// Google Gemini via the Generative Language REST API (free tier key from
/// Google AI Studio).
class GeminiAssistant implements AssistantBackend {
  GeminiAssistant({
    required this.apiKey,
    this.model = 'gemini-3.5-flash',
    this.fallbackModels = const ['gemini-3.1-flash-lite'],
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;

  /// Tried in order when the primary model is overloaded or retired.
  final List<String> fallbackModels;
  final http.Client _client;

  @override
  String get name => 'Gemini ($model)';

  @override
  Future<ChatMessage> reply(List<ChatMessage> history) async {
    final turns = history
        .where((m) => !m.error)
        .toList()
        .reversed
        .take(12)
        .toList()
        .reversed;
    final body = {
      'systemInstruction': {
        'parts': [
          {'text': buildSystemPrompt()},
        ],
      },
      'contents': [
        for (final m in turns)
          {
            'role': m.fromUser ? 'user' : 'model',
            'parts': [
              {
                'text': m.fromUser
                    ? m.text
                    : [
                        m.text,
                        for (final a in m.actions) '[[${a.label}|${a.route}]]',
                      ].join('\n'),
              },
            ],
          },
      ],
      'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 1500},
    };
    late http.Response response;
    for (final candidate in [model, ...fallbackModels]) {
      try {
        response = await _client
            .post(
              Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/$candidate:generateContent',
              ),
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 25));
      } on Exception {
        response = http.Response('{}', 504);
      }
      // 503 overloaded, 404 retired model, 504 timeout: try the next model.
      if (!const {404, 503, 504}.contains(response.statusCode)) break;
    }
    if (response.statusCode == 429) {
      throw const AssistantException(
        'The assistant is busy right now (free-tier limit reached). Please try again in a minute.',
      );
    }
    if (response.statusCode != 200) {
      throw AssistantException(
        'The assistant could not answer (error ${response.statusCode}).',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List? ?? const [];
    final parts =
        ((candidates.firstOrNull as Map?)?['content'] as Map?)?['parts']
            as List? ??
        const [];
    final text = parts
        .map((p) => (p as Map)['text'] as String? ?? '')
        .join()
        .trim();
    if (text.isEmpty) {
      throw const AssistantException(
        'I could not find a good answer to that. Try rephrasing your question.',
      );
    }
    return parseAssistantReply(text);
  }
}

class AssistantException implements Exception {
  const AssistantException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Rule-based answers used when no Gemini key is configured or the network
/// call fails. Covers the most common questions about the platform.
class OfflineAssistant implements AssistantBackend {
  @override
  String get name => 'Built-in help';

  static bool _has(String q, List<String> words) => words.any(q.contains);

  @override
  Future<ChatMessage> reply(List<ChatMessage> history) async {
    final q = history.lastWhere((m) => m.fromUser).text.toLowerCase();
    final role = AuthPrototypeStore.instance.role;
    String text;
    List<ChatAction> actions;
    if (_has(q, ['hello', 'hi ', 'hey']) && q.length < 20 || q.trim() == 'hi') {
      text =
          'Hello! I can help you find courses, products, our services, or explain how to use your account. What would you like to do?';
      actions = const [
        ChatAction('Browse courses', '/hub'),
        ChatAction('Our services', '/services'),
      ];
    } else if (_has(q, [
      'password',
      'forgot',
      'reset',
      'login',
      'sign in',
      'log in',
    ])) {
      text =
          'Use the Sign in page with your email and password. If you forgot your password, choose "Forgot password?" and we will email you a reset link. Learner and Employer accounts can be created on the Register page.';
      actions = const [
        ChatAction('Sign in', '/login'),
        ChatAction('Create account', '/register'),
      ];
    } else if (_has(q, ['register', 'sign up', 'create account', 'account'])) {
      text =
          'Individuals register as Learners to take courses. Organisations register as Employers to add employees, assign courses and view reports. Trainer and Admin accounts are created by MT Alchemy.';
      actions = const [ChatAction('Create account', '/register')];
    } else if (_has(q, ['certificate'])) {
      text =
          'Complete every lesson in a course, then pass its quiz with at least 60%. Your certificate then appears under Certificates on your Learner dashboard, where you can download it as a PDF.';
      actions = const [ChatAction('My dashboard', '/dashboard')];
    } else if (_has(q, [
      'quiz',
      'assessment',
      'exam',
      'pass mark',
      'feedback',
    ])) {
      text =
          'Each course ends with a quiz; the pass mark is 60% and you can retake it. Trainers review submissions and their feedback appears on your Learner dashboard.';
      actions = const [ChatAction('My dashboard', '/dashboard')];
    } else if (_has(q, [
      'course',
      'learn',
      'enrol',
      'enroll',
      'class',
      'training',
    ])) {
      final list = publishedCourses
          .take(8)
          .map((c) => '• ${c.title} (${c.level}, ${c.duration})')
          .join('\n');
      text =
          'Here are the courses in our Learning Hub:\n$list\n\nOpen a course to see its modules, prerequisites and how to enrol.';
      actions = const [ChatAction('Learning Hub', '/hub')];
    } else if (_has(q, [
      'order',
      'payment',
      'paid',
      'track',
      'shipping',
      'deliver',
    ])) {
      text =
          'Checkout is simulated: your order is created as Pending, then an admin marks it Paid. Physical items ship for RM 10 and get a tracking number when shipped; digital items unlock in your Digital Library once paid.';
      actions = const [
        ChatAction('My orders', '/orders'),
        ChatAction('Digital library', '/digital-library'),
      ];
    } else if (_has(q, [
      'buy',
      'shop',
      'store',
      'product',
      'workbook',
      'journal',
      'price',
      'cost',
    ])) {
      final products = CommercePrototypeStore.instance.publishedProducts
          .map(
            (p) =>
                '• ${p.name}: ${money(p.price)}${p.digital ? ' (digital)' : ''}',
          )
          .join('\n');
      text = products.isEmpty
          ? 'Our store offers workbooks, journals and team tools.'
          : 'Our store currently offers:\n$products';
      actions = const [ChatAction('Open store', '/store')];
    } else if (_has(q, [
      'quote',
      'bulk',
      'corporate',
      'company',
      'team',
      'organisation',
      'organization',
      'employee',
    ])) {
      text = role == 'Employer'
          ? 'In your Employer portal you can add employees, assign courses with due dates, view reports and request a quote for tailored programmes or bulk materials.'
          : 'For organisations we run EQ, leadership, communication, team-building and well-being programmes tailored to your people. Register an Employer account to assign courses and request quotes, or contact us to discuss a programme.';
      actions = role == 'Employer'
          ? const [
              ChatAction('Employer portal', '/employer'),
              ChatAction('Request a quote', '/quote-request'),
            ]
          : const [
              ChatAction('Corporate programmes', '/programmes'),
              ChatAction('Contact us', '/contact'),
            ];
    } else if (_has(q, ['coach', 'one-to-one', '1:1', 'personal'])) {
      text =
          'Individual Coaching offers one-to-one support for change, relationships, decisions and personal development with our EQ coach.';
      actions = const [
        ChatAction('Individual coaching', '/coaching'),
        ChatAction('Contact us', '/contact'),
      ];
    } else if (_has(q, [
      'contact',
      'email',
      'phone',
      'call',
      'enquir',
      'talk',
    ])) {
      text =
          'Send us a message through the Contact page and our team will get back to you. You will receive a reference number for your enquiry.';
      actions = const [ChatAction('Contact us', '/contact')];
    } else if (_has(q, [
      'about',
      'who',
      'founder',
      'mabel',
      'esther',
      'mission',
      'vision',
    ])) {
      text =
          'MT Alchemy is a people-development consultancy founded by EQ coach and HRDC-certified trainer Mabel Tan KH. We help individuals and organisations grow through emotional intelligence, mindfulness, leadership and well-being, and have reached 1,100+ participants.';
      actions = const [ChatAction('About us', '/about')];
    } else if (_has(q, ['service', 'offer', 'programme', 'program'])) {
      text =
          'Our services: Emotional Intelligence & Mindfulness, Leadership & Communication, Organization Well-being Assessment, Team Building & Effectiveness, community engagement and customised programmes.';
      actions = const [ChatAction('Our services', '/services')];
    } else {
      text =
          'I can help with courses, certificates, the store, orders, corporate programmes and your account. Could you tell me a little more about what you need?';
      actions = const [
        ChatAction('Browse courses', '/hub'),
        ChatAction('Contact us', '/contact'),
      ];
    }
    return ChatMessage(fromUser: false, text: text, actions: actions);
  }
}

/// Picks Gemini when a key is configured, falling back to offline answers.
class ChatAssistant {
  ChatAssistant({AssistantBackend? primary})
    : primary =
          primary ??
          (AppConfig.geminiApiKey.isEmpty
              ? null
              : GeminiAssistant(
                  apiKey: AppConfig.geminiApiKey,
                  model: AppConfig.geminiModel,
                ));

  final AssistantBackend? primary;
  final _offline = OfflineAssistant();

  bool get usingLlm => primary != null;
  String get engineName => primary?.name ?? _offline.name;

  Future<ChatMessage> reply(List<ChatMessage> history) async {
    final llm = primary;
    if (llm == null) return _offline.reply(history);
    try {
      return await llm.reply(history);
    } on AssistantException catch (e) {
      final fallback = await _offline.reply(history);
      return ChatMessage(
        fromUser: false,
        text: '${e.message}\n\nMeanwhile: ${fallback.text}',
        actions: fallback.actions,
      );
    } catch (_) {
      final fallback = await _offline.reply(history);
      return ChatMessage(
        fromUser: false,
        text:
            'I could not reach the AI service, so here is what I know:\n\n${fallback.text}',
        actions: fallback.actions,
      );
    }
  }
}
