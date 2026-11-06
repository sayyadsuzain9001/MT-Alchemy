import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../backend/backend.dart';
import '../../data/mock_data.dart';
import '../../data/quiz_attempts.dart';
import '../../shared/auth_prototype_store.dart';
import '../../shared/learning_navigation.dart';
import '../../theme.dart';
import '../../shared/charts.dart';
import '../../shared/ui_kit.dart';
import '../../widgets.dart';

/// Trainer workspace: live quiz submissions to review, every learner's
/// course progress and the course catalogue, all read from Firestore.
class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _LearnerProgress {
  _LearnerProgress(this.email, this.name, this.course, this.percent, this.done);
  final String email;
  final String name;
  final Course course;
  final int percent;
  final bool done;
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  int _tab = 0;
  String _attemptFilter = 'Submitted';
  final _attempts = QuizAttemptService.all();
  final _progress = Backend.db.collection('progress').snapshots();
  final _learners = Backend.db
      .collection('users')
      .where('role', isEqualTo: 'Learner')
      .snapshots();

  List<_LearnerProgress> _rows(
    QuerySnapshot<Map<String, dynamic>>? progress,
    Map<String, String> names,
  ) {
    final rows = <_LearnerProgress>[];
    for (final doc in progress?.docs ?? const []) {
      final data = doc.data();
      final done = Map<String, dynamic>.from(data['done'] as Map? ?? {});
      final completed = List<String>.from(data['completed'] as List? ?? []);
      final enrolled = {
        ...List<String>.from(data['enrolled'] as List? ?? []),
        ...done.keys,
      };
      for (final id in enrolled) {
        final course = mockCourses.where((c) => c.id == id).firstOrNull;
        if (course == null) continue;
        final lessons = (done[id] as List?)?.length ?? 0;
        final percent = (lessons / (course.modules.length * 4) * 100)
            .round()
            .clamp(0, 100);
        rows.add(
          _LearnerProgress(
            doc.id,
            names[doc.id] ?? doc.id,
            course,
            percent,
            completed.contains(id),
          ),
        );
      }
    }
    rows.sort((a, b) => b.percent.compareTo(a.percent));
    return rows;
  }

  Future<void> _review(QuizAttempt attempt) async {
    final controller = TextEditingController(text: attempt.feedback ?? '');
    final form = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Review: ${attempt.courseTitle}'),
        content: SizedBox(
          width: 560,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${attempt.learnerName} · ${attempt.score}/${attempt.total} (${attempt.percent}%) · ${attempt.passed ? 'Passed' : 'Not passed'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  for (final a in attempt.answers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            a['correct'] == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 18,
                            color: a['correct'] == true
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${a['question']}\nAnswer: ${a['answer']}',
                              style: const TextStyle(fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Feedback for the learner',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => v == null || v.trim().length < 5
                        ? 'Write at least a short sentence of feedback'
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save feedback'),
          ),
        ],
      ),
    );
    final text = controller.text;
    controller.dispose();
    if (saved != true || !mounted) return;
    try {
      await QuizAttemptService.review(
        attempt.id,
        text,
        learner: attempt.learner,
        courseTitle: attempt.courseTitle,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feedback sent to ${attempt.learnerName}.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback could not be saved.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: '/'),
        title: const Text('Trainer Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Browse learning hub',
            onPressed: () => Navigator.pushNamed(context, '/hub'),
            icon: const Icon(Icons.explore_outlined),
          ),
          const LearningNavigation(),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder(
        stream: _learners,
        builder: (context, learnerSnap) => StreamBuilder(
          stream: _progress,
          builder: (context, progressSnap) => StreamBuilder<List<QuizAttempt>>(
            stream: _attempts,
            builder: (context, attemptSnap) {
              final names = {
                for (final d in learnerSnap.data?.docs ?? const [])
                  (d.data()['email'] as String? ?? ''):
                      (d.data()['displayName'] as String? ?? ''),
              };
              final attempts = attemptSnap.data ?? const <QuizAttempt>[];
              final rows = _rows(progressSnap.data, names);
              final waiting = attempts.where((a) => !a.reviewed).length;
              final passRate = attempts.isEmpty
                  ? 0
                  : (attempts.where((a) => a.passed).length /
                            attempts.length *
                            100)
                        .round();
              final avg = rows.isEmpty
                  ? 0
                  : (rows.fold<int>(0, (t, r) => t + r.percent) / rows.length)
                        .round();
              final loading =
                  attemptSnap.connectionState == ConnectionState.waiting &&
                  !attemptSnap.hasData;
              return SingleChildScrollView(
                padding: EdgeInsets.all(width < 600 ? 16 : 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _hero(context),
                        const SizedBox(height: 24),
                        _stats(context, [
                          (
                            Icons.groups_outlined,
                            '${names.length}',
                            'Learners',
                          ),
                          (
                            Icons.rate_review_outlined,
                            '$waiting',
                            'Awaiting review',
                          ),
                          (
                            Icons.verified_outlined,
                            '$passRate%',
                            'Quiz pass rate',
                          ),
                          (Icons.trending_up, '$avg%', 'Average progress'),
                        ]),
                        const SizedBox(height: 20),
                        _scoreChart(attempts),
                        const SizedBox(height: 28),
                        SegmentedButton<int>(
                          segments: [
                            ButtonSegment(
                              value: 0,
                              icon: const Icon(Icons.fact_check_outlined),
                              label: Text(
                                width < 520 ? 'Reviews' : 'Assessments',
                              ),
                            ),
                            ButtonSegment(
                              value: 1,
                              icon: const Icon(Icons.insights_outlined),
                              label: Text(
                                width < 520 ? 'Progress' : 'Learner progress',
                              ),
                            ),
                            const ButtonSegment(
                              value: 2,
                              icon: Icon(Icons.menu_book_outlined),
                              label: Text('Courses'),
                            ),
                          ],
                          selected: {_tab},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) =>
                              setState(() => _tab = s.first),
                        ),
                        const SizedBox(height: 20),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          switch (_tab) {
                            0 => _assessmentList(attempts),
                            1 => _progressList(rows),
                            _ => _courses(context),
                          },
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) => DashboardHeader(
    eyebrow: 'Trainer workspace',
    title: 'Welcome, ${AuthPrototypeStore.instance.displayName ?? 'Trainer'}',
    subtitle:
        'Review quiz submissions, give feedback, follow learner progress and keep courses up to date.',
    image: 'assets/images/stock/facilitator.jpg',
    actions: [
      HeaderButton(
        label: 'Review submissions',
        icon: Icons.rate_review_outlined,
        primary: true,
        onPressed: () => setState(() {
          _tab = 0;
          _attemptFilter = 'Submitted';
        }),
      ),
      HeaderButton(
        label: 'Manage courses',
        icon: Icons.edit_note,
        onPressed: () => Navigator.pushNamed(context, '/admin/courses'),
      ),
    ],
  );

  Widget _scoreChart(List<QuizAttempt> attempts) {
    final byCourse = <String, List<int>>{};
    for (final a in attempts) {
      byCourse.putIfAbsent(a.courseTitle, () => []).add(a.percent);
    }
    return DashboardPanel(
      title: 'Average quiz score by course',
      subtitle: 'All submissions',
      icon: Icons.bar_chart,
      child: LabelledBarChart(
        values: [
          for (final e in byCourse.entries)
            (e.key, e.value.reduce((x, y) => x + y) / e.value.length),
        ],
        maxY: 100,
        suffix: '%',
        height: 200,
      ),
    );
  }

  Widget _stats(BuildContext context, List<(IconData, String, String)> stats) =>
      LayoutBuilder(
        builder: (context, box) {
          final cols = box.maxWidth >= 900 ? 4 : 2;
          final w = (box.maxWidth - (cols - 1) * 16) / cols;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final s in stats)
                SizedBox(
                  width: w,
                  child: InfoCard(
                    padding: 20,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1ECFB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(s.$1, color: purple),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.$2,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                s.$3,
                                style: const TextStyle(color: Colors.black54),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );

  Widget _empty(IconData icon, String title, String body) => InfoCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: purple),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );

  Widget _assessmentList(List<QuizAttempt> attempts) {
    final shown = attempts.where(
      (a) => switch (_attemptFilter) {
        'Submitted' => !a.reviewed,
        'Reviewed' => a.reviewed,
        _ => true,
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final f in ['Submitted', 'Reviewed', 'All'])
              ChoiceChip(
                label: Text(f == 'Submitted' ? 'Awaiting review' : f),
                selected: _attemptFilter == f,
                onSelected: (_) => setState(() => _attemptFilter = f),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (shown.isEmpty)
          _empty(
            Icons.inbox_outlined,
            _attemptFilter == 'Submitted'
                ? 'All caught up'
                : 'No submissions yet',
            'Quiz submissions from learners appear here as soon as they finish a course quiz.',
          )
        else
          for (final a in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InfoCard(
                padding: 18,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 12,
                  spacing: 16,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            backgroundColor: a.passed
                                ? const Color(0xFFE6F4EA)
                                : const Color(0xFFFDECEC),
                            child: Text(
                              '${a.percent}%',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: a.passed
                                    ? const Color(0xFF1E6B34)
                                    : const Color(0xFF9F1D1D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.learnerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: deepBlue,
                                  ),
                                ),
                                Text(
                                  '${a.courseTitle} · ${a.score}/${a.total} correct · ${_date(a.submittedAt)}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                if (a.reviewed)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '“${a.feedback}”',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    a.reviewed
                        ? OutlinedButton.icon(
                            onPressed: () => _review(a),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit feedback'),
                          )
                        : FilledButton.icon(
                            onPressed: () => _review(a),
                            icon: const Icon(
                              Icons.rate_review_outlined,
                              size: 18,
                            ),
                            label: const Text('Review'),
                          ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _progressList(List<_LearnerProgress> rows) => rows.isEmpty
      ? _empty(
          Icons.insights_outlined,
          'No learner activity yet',
          'Progress appears when learners enrol and complete lessons.',
        )
      : InfoCard(
          padding: 8,
          child: Column(
            children: [
              for (final r in rows)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: deepBlue,
                    child: Text(
                      r.name.isEmpty ? '?' : r.name[0].toUpperCase(),
                      style: const TextStyle(color: softYellow),
                    ),
                  ),
                  title: Text(
                    r.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.course.title),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: r.percent / 100,
                          minHeight: 6,
                          color: r.done ? const Color(0xFF2E7D32) : purple,
                          backgroundColor: const Color(0xFFECE8F5),
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    r.done ? 'Completed' : '${r.percent}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: r.done ? const Color(0xFF2E7D32) : deepBlue,
                    ),
                  ),
                ),
            ],
          ),
        );

  Widget _courses(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FilledButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/admin/courses'),
        icon: const Icon(Icons.edit_note),
        label: const Text('Add or edit courses'),
      ),
      const SizedBox(height: 16),
      _courseGrid(context),
    ],
  );

  Widget _courseGrid(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = box.maxWidth >= 900 ? 3 : (box.maxWidth >= 560 ? 2 : 1);
      final w = (box.maxWidth - (cols - 1) * 16) / cols;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final c in mockCourses)
            SizedBox(
              width: w,
              child: InfoCard(
                padding: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Image.asset(
                        c.imageAsset,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: deepBlue,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${c.modules.length} modules · ${c.level} · ${c.duration}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/course-player',
                              arguments: c.id,
                            ),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                            label: const Text('Preview'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );

  static String _date(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}
