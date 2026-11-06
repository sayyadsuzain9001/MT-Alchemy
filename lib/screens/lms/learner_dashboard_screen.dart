import 'package:flutter/material.dart';
import '../../widgets.dart';
import '../../commerce/commerce_prototype_store.dart';
import '../../shared/profile_page.dart';
import '../../shared/ui_kit.dart';
import '../../data/mock_data.dart';
import '../../data/progress_store.dart';
import '../../widgets/lms/course_card.dart';
import '../../shared/auth_prototype_store.dart';
import '../../shared/learning_navigation.dart';
import '../../theme.dart';
import '../../data/quiz_attempts.dart';

class LearnerDashboardScreen extends StatefulWidget {
  const LearnerDashboardScreen({
    super.key,
    this.courseId = 'ei-fundamentals',
    this.enroll = false,
  });
  final String courseId;
  final bool enroll;
  @override
  State<LearnerDashboardScreen> createState() => _LearnerDashboardScreenState();
}

class _LearnerDashboardScreenState extends State<LearnerDashboardScreen> {
  String filter = 'In progress';
  @override
  void initState() {
    super.initState();
    if (widget.enroll) enrollCourse(widget.courseId);
  }

  Future<void> open(String route, {Object? arguments}) async {
    await Navigator.pushNamed(context, route, arguments: arguments);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mine = mockCourses
        .where((c) => enrolledCourses.contains(c.id))
        .toList();
    final finished = mine
        .where((c) => completedCourses.contains(c.id))
        .toList();
    final active = mine.where((c) => !completedCourses.contains(c.id)).toList();
    final suggested = publishedCourses
        .where(
          (c) =>
              !enrolledCourses.contains(c.id) &&
              c.prerequisites.every(completedCourses.contains),
        )
        .take(3)
        .toList();
    final email = AuthPrototypeStore.instance.email ?? '';
    final lessonsDone = completedLessons.values.fold<int>(
      0,
      (t, s) => t + s.length,
    );
    final hours = (lessonsDone * 0.5).toStringAsFixed(
      lessonsDone % 2 == 0 ? 0 : 1,
    );
    final current = active.isEmpty
        ? null
        : (List.of(
            active,
          )..sort((a, b) => progressFor(b).compareTo(progressFor(a)))).first;
    final orders = CommercePrototypeStore.instance.ordersFor(email);
    final wide = MediaQuery.sizeOf(context).width >= 980;
    Widget twoUp(Widget a, Widget b) => wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: 20),
              Expanded(child: b),
            ],
          )
        : Column(children: [a, const SizedBox(height: 20), b]);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: '/'),
        title: const Text('Learner Dashboard'),
        actions: const [LearningNavigation()],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Greeting.
                DashboardHeader(
                  eyebrow: 'Your learning journey',
                  title:
                      'Welcome, ${AuthPrototypeStore.instance.displayName ?? 'Learner'}',
                  subtitle: current == null
                      ? 'Small steps. Stronger skills. Pick a course to begin.'
                      : 'You are ${progressFor(current)}% through ${current.title}. Keep going!',
                  image: 'assets/images/stock/online_learning.jpg',
                  actions: [
                    if (current != null)
                      HeaderButton(
                        label: 'Continue learning',
                        icon: Icons.play_arrow_rounded,
                        primary: true,
                        onPressed: () =>
                            open('/course-player', arguments: current.id),
                      ),
                    HeaderButton(
                      label: 'Explore courses',
                      icon: Icons.explore_outlined,
                      primary: current == null,
                      onPressed: () => open('/hub'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 2. Key figures.
                TileGrid(
                  maxColumns: 5,
                  minTileWidth: 190,
                  minColumns: 2,
                  children: [
                    StatTile(
                      icon: Icons.menu_book_outlined,
                      value: '${mine.length}',
                      label: 'Enrolled',
                    ),
                    StatTile(
                      icon: Icons.play_circle_outline,
                      value: '${active.length}',
                      label: 'In Progress',
                      color: royalBlue,
                    ),
                    StatTile(
                      icon: Icons.task_alt,
                      value: '${finished.length}',
                      label: 'Completed',
                      color: const Color(0xFF2E7D32),
                    ),
                    StatTile(
                      icon: Icons.workspace_premium_outlined,
                      value: '${finished.length}',
                      label: 'Certificates',
                      color: const Color(0xFFB7791F),
                    ),
                    StatTile(
                      icon: Icons.schedule,
                      value: hours,
                      label: 'Learning hours',
                      color: const Color(0xFF0E7490),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 3. Continue + progress overview.
                twoUp(
                  DashboardPanel(
                    title: 'Continue learning',
                    icon: Icons.play_lesson_outlined,
                    child: current == null
                        ? _EmptyHint(
                            text:
                                'No course in progress. Browse the Learning Hub to start one.',
                            action: 'Browse courses',
                            onTap: () => open('/hub'),
                          )
                        : Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  current.imageAsset,
                                  width: 120,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      current.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: deepBlue,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progressFor(current) / 100,
                                        minHeight: 8,
                                        color: purple,
                                        backgroundColor: const Color(
                                          0xFFECE8F5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Course Progress: ${progressFor(current)}%',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    FilledButton(
                                      onPressed: () => open(
                                        '/course-player',
                                        arguments: current.id,
                                      ),
                                      child: const Text('Continue Course'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  DashboardPanel(
                    title: 'Progress overview',
                    icon: Icons.donut_large_outlined,
                    child: mine.isEmpty
                        ? const Text('Enrol in a course to see progress here.')
                        : Column(
                            children: [
                              for (final c in mine.take(4))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value: progressFor(c) / 100,
                                              strokeWidth: 5,
                                              color:
                                                  completedCourses.contains(
                                                    c.id,
                                                  )
                                                  ? const Color(0xFF2E7D32)
                                                  : purple,
                                              backgroundColor: const Color(
                                                0xFFECE8F5,
                                              ),
                                            ),
                                            Text(
                                              '${progressFor(c)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(c.title)),
                                      Text(
                                        completedCourses.contains(c.id)
                                            ? 'Completed'
                                            : 'In progress',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: completedCourses.contains(c.id)
                                              ? const Color(0xFF2E7D32)
                                              : purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                // 4. My learning.
                Text(
                  'My Learning',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final label in [
                      'In progress',
                      'Completed',
                      'Certificates',
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: filter == label,
                        onSelected: (_) => setState(() => filter = label),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if ((filter == 'In progress' ? active : finished).isEmpty)
                  DashboardPanel(
                    title: filter == 'In progress'
                        ? 'Your next chapter starts here.'
                        : 'Your achievements will appear here.',
                    icon: filter == 'In progress'
                        ? Icons.auto_stories
                        : Icons.workspace_premium_outlined,
                    child: _EmptyHint(
                      text:
                          'Explore a course, complete the lessons and pass its assessment.',
                      action: 'Browse learning hub',
                      onTap: () => open('/hub'),
                    ),
                  ),
                if (filter != 'Certificates')
                  grid(filter == 'In progress' ? active : finished),
                if (filter == 'Certificates')
                  for (final course in finished)
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        leading: const Icon(
                          Icons.workspace_premium,
                          color: purple,
                          size: 40,
                        ),
                        title: Text(course.title),
                        subtitle: const Text(
                          'Training completed · Certificate available',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => open(
                          '/certificate',
                          arguments: {'courseId': course.id},
                        ),
                      ),
                    ),
                const SizedBox(height: 32),
                // 5. Feedback + orders.
                twoUp(
                  const DashboardPanel(
                    title: 'Quiz results & trainer feedback',
                    icon: Icons.rate_review_outlined,
                    child: TrainerFeedbackSection(compact: true),
                  ),
                  DashboardPanel(
                    title: 'My orders',
                    icon: Icons.receipt_long_outlined,
                    action: TextButton(
                      onPressed: () => open('/orders'),
                      child: const Text('View all'),
                    ),
                    child: orders.isEmpty
                        ? _EmptyHint(
                            text:
                                'Workbooks, journals and digital resources you buy appear here.',
                            action: 'Visit the store',
                            onTap: () => open('/store'),
                          )
                        : Column(
                            children: [
                              for (final o in orders.take(3))
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    o.hasPhysical
                                        ? Icons.local_shipping_outlined
                                        : Icons.download_outlined,
                                    color: purple,
                                  ),
                                  title: Text(
                                    o.lines
                                        .map((l) => l.product.name)
                                        .join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${money(o.total)} · ${o.paymentStatus} · ${o.fulfilmentStatus}',
                                  ),
                                  onTap: () => open(
                                    '/order-details',
                                    arguments: o.number,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed: () => open('/digital-library'),
                                  icon: const Icon(
                                    Icons.cloud_download_outlined,
                                  ),
                                  label: const Text('My Digital Products'),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                // 6. Recommendations.
                Text(
                  'Recommended next',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Courses you are ready to start, based on your completed prerequisites.',
                ),
                const SizedBox(height: 20),
                grid(suggested),
                const SizedBox(height: 32),
                Card(
                  child: ListTile(
                    leading: ProfileAvatar(
                      bytes: ProfileAvatar.fromProfile(
                        AuthPrototypeStore.instance.profile,
                      ),
                      name: AuthPrototypeStore.instance.displayName ?? '',
                      radius: 20,
                    ),
                    title: Text(
                      AuthPrototypeStore.instance.displayName ?? 'My profile',
                    ),
                    subtitle: Text(
                      '${AuthPrototypeStore.instance.email ?? ''} · Edit your profile and preferences',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => open('/profile'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget grid(List<Course> courses) => LayoutBuilder(
    builder: (context, box) {
      final count = box.maxWidth >= 900
          ? 3
          : box.maxWidth >= 600
          ? 2
          : 1;
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          for (final c in courses)
            SizedBox(
              width: (box.maxWidth - (count - 1) * 20) / count,
              child: CourseCard(
                course: c,
                onViewCourse: () => open('/course-detail', arguments: c.id),
                onContinueCourse: () => open('/course-player', arguments: c.id),
              ),
            ),
        ],
      );
    },
  );
}

/// Quiz results and trainer feedback for the signed-in learner.
class TrainerFeedbackSection extends StatelessWidget {
  const TrainerFeedbackSection({super.key, this.compact = false});

  /// Compact mode drops the heading (used inside a dashboard panel).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final email = AuthPrototypeStore.instance.email;
    if (email == null) return const SizedBox.shrink();
    return StreamBuilder<List<QuizAttempt>>(
      stream: QuizAttemptService.mine(email),
      builder: (context, snapshot) {
        final attempts = snapshot.data ?? const <QuizAttempt>[];
        if (attempts.isEmpty) {
          return compact
              ? const Text(
                  'Finish a course quiz and your result and trainer feedback will appear here.',
                )
              : const SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsets.only(bottom: compact ? 0 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) ...[
                Text(
                  'Quiz results & trainer feedback',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
              ],
              for (final a in attempts.take(5))
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8E5F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        a.passed
                            ? Icons.verified_outlined
                            : Icons.replay_outlined,
                        color: a.passed ? const Color(0xFF2E7D32) : purple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${a.courseTitle} · ${a.percent}% ${a.passed ? '(passed)' : '(not passed)'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: deepBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.reviewed
                                  ? 'Feedback from ${a.reviewedBy ?? 'your trainer'}: ${a.feedback}'
                                  : 'Waiting for trainer feedback.',
                              style: TextStyle(
                                color: a.reviewed
                                    ? Colors.black87
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.text,
    required this.action,
    required this.onTap,
  });
  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text, style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 10),
      OutlinedButton(onPressed: onTap, child: Text(action)),
    ],
  );
}
