import '../../shared/learning_navigation.dart';
import 'package:flutter/material.dart';
import '../../widgets.dart';
import '../../shared/ui_kit.dart';

import '../../data/mock_data.dart';
import '../../widgets/lms/course_card.dart';

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  String selectedCategory = 'All';
  String search = '';

  final categories = const [
    'All',
    'Emotional Intelligence',
    'Mindfulness',
    'Leadership',
    'Communication',
    'Team Effectiveness',
    'Workplace Well-being',
    'Personal Development',
    'Organisational Development',
  ];

  List<Course> get filteredCourses {
    if (selectedCategory == 'All') {
      return publishedCourses
          .where(
            (c) => ('${c.title} ${c.shortDescription}').toLowerCase().contains(
              search,
            ),
          )
          .toList();
    }

    return publishedCourses.where((course) {
      final text = '${course.title} ${course.shortDescription}'.toLowerCase();

      return text.contains(selectedCategory.toLowerCase().split(' ').first) &&
          text.contains(search);
    }).toList();
  }

  Future<void> openCourse(Course course) async {
    await Navigator.pushNamed(context, '/course-detail', arguments: course.id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallback: '/'),
        actions: const [LearningNavigation()],
        title: const Text('Learning Hub'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardHeader(
                  eyebrow: 'Learning Hub',
                  title: 'Learn. Apply. Grow.',
                  subtitle:
                      'Self-paced courses in emotional intelligence, mindfulness, leadership and well-being, each with a quiz and a certificate.',
                  image: 'assets/images/stock/online_learning.jpg',
                ),
                const SizedBox(height: 32),

                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search courses',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) =>
                      setState(() => search = value.trim().toLowerCase()),
                ),
                const SizedBox(height: 24),
                Text(
                  'Explore by category',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categories.map((category) {
                    final selected = selectedCategory == category;

                    return FilterChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 36),

                Text(
                  'Featured courses',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 600
                        ? 2
                        : 1;

                    final cardWidth =
                        (constraints.maxWidth - ((columns - 1) * 20)) / columns;

                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: filteredCourses.map((course) {
                        return SizedBox(
                          width: cardWidth,
                          child: CourseCard(
                            course: course,
                            onViewCourse: () => openCourse(course),
                            onContinueCourse: () => Navigator.pushNamed(
                              context,
                              '/course-player',
                              arguments: course.id,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                if (filteredCourses.isEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text('No courses found for this category.'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
