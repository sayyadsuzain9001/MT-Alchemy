import '../../data/mock_data.dart';
import '../../shared/learning_navigation.dart';
import 'package:flutter/material.dart';

import '../../data/progress_store.dart';
import '../../data/quiz_attempts.dart';
import '../../theme.dart';
import '../../widgets.dart'; // InfoCard, Eyebrow

enum QuestionType { multipleChoice, trueFalse, multipleAnswer, shortAnswer }

extension on QuestionType {
  String get label => switch (this) {
    QuestionType.multipleChoice => 'Multiple choice',
    QuestionType.trueFalse => 'True or false',
    QuestionType.multipleAnswer => 'Select all that apply',
    QuestionType.shortAnswer => 'Short answer',
  };
}

class QuizQuestion {
  const QuizQuestion({
    required this.type,
    required this.prompt,
    required this.correct,
    required this.explanation,
    this.options = const [],
    this.displayAnswer,
  });

  final QuestionType type;
  final String prompt;
  final List<String> options;

  /// Choice questions: the correct option texts.
  /// Short answer: lowercase keywords. Any keyword found in the answer counts.
  final List<String> correct;
  final String explanation;

  /// Text shown as "Correct answer" for short-answer questions.
  final String? displayAnswer;
}

const _sampleQuestions = [
  QuizQuestion(
    type: QuestionType.multipleChoice,
    prompt: 'Which skill is the foundation of emotional intelligence?',
    options: [
      'Self-awareness',
      'Public speaking',
      'Time management',
      'Negotiation',
    ],
    correct: ['Self-awareness'],
    explanation:
        'Noticing your own emotions is the starting point for managing them and for understanding others.',
  ),
  QuizQuestion(
    type: QuestionType.trueFalse,
    prompt: 'Emotional intelligence can be developed with practice.',
    options: ['True', 'False'],
    correct: ['True'],
    explanation:
        'Emotional skills grow through reflection, feedback and repeated practice.',
  ),
  QuizQuestion(
    type: QuestionType.multipleAnswer,
    prompt: 'Which of these are core parts of emotional intelligence?',
    options: [
      'Self-regulation',
      'Empathy',
      'Memorising facts',
      'Social skills',
    ],
    correct: ['Self-regulation', 'Empathy', 'Social skills'],
    explanation:
        'Self-regulation, empathy and social skills are core parts. Memorising facts is not.',
  ),
  QuizQuestion(
    type: QuestionType.shortAnswer,
    prompt:
        'What is the word for understanding and sharing another person\'s feelings?',
    correct: ['empath'],
    displayAnswer: 'Empathy',
    explanation:
        'Empathy lets us see a situation from another person\'s point of view and respond with care.',
  ),
  QuizQuestion(
    type: QuestionType.multipleChoice,
    prompt:
        'A colleague criticises your work. Which response shows emotional regulation?',
    options: [
      'Pause, breathe and ask for specific examples',
      'Reply straight away to defend yourself',
      'Ignore the feedback',
      'Complain about it to other colleagues',
    ],
    correct: ['Pause, breathe and ask for specific examples'],
    explanation:
        'A short pause lets you respond on purpose instead of reacting, and specific examples turn criticism into useful feedback.',
  ),
];

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.courseId = 'ei-fundamentals'});
  final String courseId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  double get _passMark =>
      mockCourses
          .firstWhere(
            (c) => c.id == widget.courseId,
            orElse: () => mockCourses.first,
          )
          .passMark /
      100;
  late final List<QuizQuestion> _questions = () {
    final course = mockCourses.firstWhere((c) => c.id == widget.courseId);
    if (course.quiz.isNotEmpty) {
      return course.quiz
          .map(
            (q) => QuizQuestion(
              type: QuestionType.multipleChoice,
              prompt: q['prompt'] as String,
              options: List<String>.from(q['options']),
              correct: [q['answer'] as String],
              explanation:
                  'Review the course material and the correct answer above.',
            ),
          )
          .toList();
    }
    if (course.id == 'ei-fundamentals') return _sampleQuestions;
    return course.modules
        .map(
          (m) => QuizQuestion(
            type: QuestionType.multipleChoice,
            prompt: 'Which practice supports $m?',
            options: [
              'Reflect, practise and seek constructive feedback',
              'Avoid feedback and repeat the same habits',
            ],
            correct: ['Reflect, practise and seek constructive feedback'],
            explanation:
                'Applying the learning and reflecting on feedback supports ${course.title}.',
          ),
        )
        .toList();
  }();

  final _formKey = GlobalKey<FormState>();
  final _shortController = TextEditingController();
  late List<Set<String>> _answers = _blankAnswers();
  int _index = 0;
  bool _submitted = false;

  List<Set<String>> _blankAnswers() =>
      List.generate(_questions.length, (_) => <String>{});

  @override
  void dispose() {
    _shortController.dispose();
    super.dispose();
  }

  bool _isCorrect(int i) {
    final q = _questions[i];
    final a = _answers[i];
    if (q.type == QuestionType.shortAnswer) {
      final text = a.isEmpty ? '' : a.first.toLowerCase();
      return q.correct.any(text.contains);
    }
    return a.length == q.correct.length && a.containsAll(q.correct);
  }

  int get _score => [
    for (var i = 0; i < _questions.length; i++)
      if (_isCorrect(i)) i,
  ].length;

  void _select(String option, bool multi) {
    setState(() {
      final set = _answers[_index];
      if (multi) {
        set.contains(option) ? set.remove(option) : set.add(option);
      } else {
        set
          ..clear()
          ..add(option);
      }
    });
  }

  void _next() {
    final q = _questions[_index];
    if (q.type == QuestionType.shortAnswer) {
      if (!_formKey.currentState!.validate()) return;
      _answers[_index] = {_shortController.text.trim()};
    } else if (_answers[_index].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose an answer to continue')),
      );
      return;
    }
    if (_index == _questions.length - 1) {
      setState(() => _submitted = true);
      final passed = _score / _questions.length >= _passMark;
      if (passed) {
        completeCourse(
          widget.courseId,
          score: (_score / _questions.length * 100).round(),
        );
      }
      final course = mockCourses.firstWhere((c) => c.id == widget.courseId);
      QuizAttemptService.record(
        courseId: course.id,
        courseTitle: course.title,
        score: _score,
        total: _questions.length,
        passed: passed,
        answers: [
          for (var i = 0; i < _questions.length; i++)
            {
              'question': _questions[i].prompt,
              'answer': _answers[i].join(', '),
              'correct': _isCorrect(i),
            },
        ],
      );
    } else {
      setState(() => _index++);
      _shortController.clear();
    }
  }

  void _retake() {
    setState(() {
      _answers = _blankAnswers();
      _index = 0;
      _submitted = false;
    });
    _shortController.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      actions: const [LearningNavigation()],
      title: const Text('Assessment'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child:
              progressFor(
                    mockCourses.firstWhere((c) => c.id == widget.courseId),
                  ) <
                  100
              ? Column(
                  children: [
                    const Icon(Icons.auto_stories, size: 64),
                    const SizedBox(height: 20),
                    const Text(
                      'Complete all lessons before taking the assessment.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/course-player',
                        arguments: widget.courseId,
                      ),
                      child: const Text('Continue learning'),
                    ),
                  ],
                )
              : _submitted
              ? _result(context)
              : _question(context),
        ),
      ),
    ),
  );

  Widget _question(BuildContext context) {
    final q = _questions[_index];
    final last = _index == _questions.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 16,
          runSpacing: 8,
          children: [
            Text(
              'Question ${_index + 1} of ${_questions.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: deepBlue,
              ),
            ),
            Text('Pass mark: ${(_passMark * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_index + 1) / _questions.length,
            minHeight: 10,
            color: purple,
            backgroundColor: softYellow.withValues(alpha: .35),
          ),
        ),
        const SizedBox(height: 24),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(q.type.label),
              const SizedBox(height: 12),
              Text(q.prompt, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              if (q.type == QuestionType.shortAnswer)
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _shortController,
                    decoration: const InputDecoration(labelText: 'Your answer'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Please type an answer'
                        : null,
                    onFieldSubmitted: (_) => _next(),
                  ),
                )
              else
                for (final option in q.options)
                  _OptionTile(
                    label: option,
                    selected: _answers[_index].contains(option),
                    multi: q.type == QuestionType.multipleAnswer,
                    onTap: () =>
                        _select(option, q.type == QuestionType.multipleAnswer),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _next,
            child: Text(last ? 'Submit' : 'Next'),
          ),
        ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    final score = _score;
    final total = _questions.length;
    final passed = score / total >= _passMark;
    final errorColor = Theme.of(context).colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoCard(
          color: passed ? const Color(0xFFFFF0B9) : const Color(0xFFECE6FA),
          child: Column(
            children: [
              Icon(
                passed ? Icons.emoji_events_outlined : Icons.refresh,
                size: 48,
                color: deepBlue,
              ),
              const SizedBox(height: 12),
              Text(
                'Score: $score / $total',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                passed
                    ? 'You passed. Well done!'
                    : 'Not quite there yet. You need 60% to pass.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (passed)
                    FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/certificate',
                        arguments: {
                          'courseId': widget.courseId,
                          'score': '$score/$total',
                        },
                      ),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('View Certificate'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _retake,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake Assessment'),
                    ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to course'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Review your answers',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < total; i++) ...[
          InfoCard(
            padding: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isCorrect(i) ? Icons.check_circle : Icons.cancel,
                      color: _isCorrect(i) ? purple : errorColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Question ${i + 1}: ${_questions[i].prompt}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _line(
                  'Your answer',
                  _answers[i].isEmpty ? '-' : _answers[i].join(', '),
                ),
                _line(
                  'Correct answer',
                  _questions[i].displayAnswer ??
                      _questions[i].correct.join(', '),
                ),
                _line('Explanation', _questions[i].explanation),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _line(String label, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text),
        ],
      ),
    ),
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.multi,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? softYellow.withValues(alpha: .3) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? deepBlue : deepBlue.withValues(alpha: .15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              multi
                  ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
                  : (selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked),
              color: selected ? deepBlue : Colors.black45,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    ),
  );
}
