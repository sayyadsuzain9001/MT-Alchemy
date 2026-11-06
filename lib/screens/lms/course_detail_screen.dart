import '../../shared/learning_navigation.dart';
import 'package:flutter/material.dart';
import '../../widgets.dart';

import '../../data/mock_data.dart';
import '../../data/progress_store.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final course = mockCourses.firstWhere(
      (item) => item.id == courseId,
      orElse: () => mockCourses.first,
    );
    final enrolled = enrolledCourses.contains(course.id);
    final missing = course.prerequisites
        .where((id) => !completedCourses.contains(id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: '/hub'),
        actions: const [LearningNavigation()],
        title: const Text('Course Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    course.imageAsset,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                if (missing.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complete these prerequisites first',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          for (final id in missing)
                            TextButton.icon(
                              icon: const Icon(Icons.lock_outline),
                              label: Text(
                                mockCourses.firstWhere((c) => c.id == id).title,
                              ),
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/course-detail',
                                arguments: id,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16105B),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        course.shortDescription,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                _sectionCard(
                  context,
                  title: 'Course Overview',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow(
                        Icons.person_outline,
                        'Instructor',
                        course.instructor,
                      ),
                      _detailRow(
                        Icons.schedule_outlined,
                        'Duration',
                        course.duration,
                      ),
                      _detailRow(
                        Icons.signal_cellular_alt_outlined,
                        'Level',
                        course.level,
                      ),
                      _detailRow(
                        Icons.star_outline,
                        'Rating',
                        course.rating.toString(),
                      ),
                      _detailRow(
                        Icons.payments_outlined,
                        'Price',
                        'RM ${course.price.toStringAsFixed(0)}',
                      ),
                      _detailRow(
                        Icons.workspace_premium_outlined,
                        'Certificate',
                        'Certificate available',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _sectionCard(
                  context,
                  title: 'Learning Objectives',
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BulletText('Build practical knowledge and skills.'),
                      _BulletText('Apply learning to real-world situations.'),
                      _BulletText(
                        'Improve personal and professional effectiveness.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _sectionCard(
                  context,
                  title: 'Target Audience',
                  child: const Text(
                    'Learners, professionals, and individuals who want '
                    'to develop practical skills for personal and workplace growth.',
                  ),
                ),

                const SizedBox(height: 20),

                _sectionCard(
                  context,
                  title: 'Requirements',
                  child: const Text(
                    'No previous experience is required. A willingness to '
                    'learn and participate is recommended.',
                  ),
                ),

                const SizedBox(height: 20),

                _sectionCard(
                  context,
                  title: 'Curriculum',
                  child: Column(
                    children: [
                      for (
                        int index = 0;
                        index < course.modules.length;
                        index++
                      )
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFECE9FF),
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            course.modules[index],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: missing.isNotEmpty
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              enrolled ? '/course-player' : '/enroll',
                              arguments: course.id,
                            );
                          },
                    icon: Icon(
                      enrolled
                          ? Icons.play_circle_outline
                          : Icons.school_outlined,
                    ),
                    label: Text(enrolled ? 'Continue Course' : 'Enrol now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E5F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7655B7)),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;

  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
