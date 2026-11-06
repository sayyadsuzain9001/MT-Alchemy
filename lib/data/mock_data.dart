import '../backend/backend.dart';

class Course {
  final String id;
  final String title;
  final String shortDescription;
  final String instructor;
  final String duration;
  final String level;
  final double rating;
  final double price;
  final List<String> modules;
  final int progress;
  final List<String> prerequisites;
  final String? pdfName;
  final String? pdfBase64;
  final List<Map<String, dynamic>> quiz;

  /// Draft → Published → Archived. Only Published courses are listed.
  final String status;

  /// Minimum quiz percentage needed to pass and earn a certificate.
  final int passMark;

  /// Optional lesson video (YouTube or MP4 link) shown in the course player.
  final String? videoUrl;
  bool get isPublished => status == 'Published';
  String get imageAsset =>
      'assets/images/${switch (id) {
        'mindfulness' || 'workplace-wellbeing' => 'impact_teachers_retreat.jpeg',
        'leadership' || 'organisational-development' => 'trainer_presenting.jpeg',
        'communication' => 'online_team_learning.jpg',
        'team-effectiveness' => 'workshop_team_creativity.jpeg',
        'personal-development' => 'impact_student_interaction.jpeg',
        _ => 'workshop_eq_facilitator.jpeg',
      }}';

  const Course({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.instructor,
    required this.duration,
    required this.level,
    required this.rating,
    required this.price,
    required this.modules,
    this.progress = 0,
    this.prerequisites = const [],
    this.pdfName,
    this.pdfBase64,
    this.quiz = const [],
    this.status = 'Published',
    this.passMark = 60,
    this.videoUrl,
  });
}

/// Courses visible to learners and buyers.
List<Course> get publishedCourses =>
    mockCourses.where((c) => c.isPublished).toList();

final List<Course> mockCourses = [...seedCourses];

const List<Course> seedCourses = [
  Course(
    id: 'ei-fundamentals',
    title: 'Emotional Intelligence Fundamentals',
    shortDescription:
        'Build self-awareness, emotional regulation, empathy, and stronger interpersonal skills.',
    instructor: 'MT Alchemy Learning Team',
    duration: '6 weeks',
    level: 'Beginner',
    rating: 4.8,
    price: 499.0,
    progress: 65,
    modules: [
      'Introduction to Emotional Intelligence',
      'Self-Awareness',
      'Emotional Regulation',
      'Empathy and Social Awareness',
      'Building Better Relationships',
    ],
  ),
  Course(
    id: 'mindfulness',
    title: 'Mindfulness at Work',
    shortDescription:
        'Learn practical mindfulness techniques for focus, resilience, and workplace well-being.',
    instructor: 'MT Alchemy Learning Team',
    duration: '4 weeks',
    level: 'Beginner',
    rating: 4.7,
    price: 399.0,
    modules: [
      'Introduction to Mindfulness',
      'Breathing and Attention',
      'Managing Workplace Stress',
      'Mindful Communication',
      'Building a Daily Practice',
    ],
  ),
  Course(
    id: 'leadership',
    prerequisites: ['ei-fundamentals'],
    title: 'Leadership Essentials',
    shortDescription:
        'Develop practical leadership skills for communication, decision-making, and team growth.',
    instructor: 'MT Alchemy Learning Team',
    duration: '8 weeks',
    level: 'Intermediate',
    rating: 4.9,
    price: 699.0,
    modules: [
      'Foundations of Leadership',
      'Leading Yourself',
      'Leading Teams',
      'Decision-Making',
      'Creating High-Performing Teams',
    ],
  ),
  Course(
    id: 'communication',
    title: 'Effective Communication',
    shortDescription:
        'Strengthen communication skills for clearer conversations, presentations, and professional relationships.',
    instructor: 'MT Alchemy Learning Team',
    duration: '5 weeks',
    level: 'Beginner',
    rating: 4.8,
    price: 449.0,
    modules: [
      'Foundations of Communication',
      'Active Listening',
      'Clear and Confident Speaking',
      'Difficult Conversations',
      'Professional Communication',
    ],
  ),
  Course(
    id: 'team-effectiveness',
    title: 'Team Effectiveness',
    shortDescription:
        'Learn how to build collaborative, productive, and high-performing teams.',
    instructor: 'MT Alchemy Learning Team',
    duration: '6 weeks',
    level: 'Intermediate',
    rating: 4.7,
    price: 549.0,
    modules: [
      'Understanding Team Dynamics',
      'Building Trust',
      'Collaboration and Cooperation',
      'Managing Team Conflict',
      'High-Performance Teams',
    ],
  ),
  Course(
    id: 'workplace-wellbeing',
    title: 'Workplace Well-being',
    shortDescription:
        'Explore practical approaches to creating healthier, happier, and more resilient workplaces.',
    instructor: 'MT Alchemy Learning Team',
    duration: '5 weeks',
    level: 'Beginner',
    rating: 4.6,
    price: 399.0,
    modules: [
      'Understanding Workplace Well-being',
      'Managing Stress',
      'Healthy Work Practices',
      'Resilience at Work',
      'Creating a Well-being Culture',
    ],
  ),
  Course(
    id: 'personal-development',
    title: 'Personal Development',
    shortDescription:
        'Develop self-awareness, confidence, goal-setting, and habits for continuous personal growth.',
    instructor: 'MT Alchemy Learning Team',
    duration: '6 weeks',
    level: 'Beginner',
    rating: 4.8,
    price: 429.0,
    modules: [
      'Self-Awareness',
      'Personal Goals',
      'Building Positive Habits',
      'Confidence and Growth',
      'Continuous Improvement',
    ],
  ),
  Course(
    id: 'organisational-development',
    prerequisites: ['leadership'],
    title: 'Organisational Development',
    shortDescription:
        'Understand people, culture, and change strategies that help organisations grow effectively.',
    instructor: 'MT Alchemy Learning Team',
    duration: '8 weeks',
    level: 'Advanced',
    rating: 4.9,
    price: 749.0,
    modules: [
      'Introduction to Organisational Development',
      'Organisational Culture',
      'Change Management',
      'People and Performance',
      'Building Sustainable Organisations',
    ],
  ),
];

Map<String, dynamic> courseToJson(Course c) => {
  'id': c.id,
  'title': c.title,
  'description': c.shortDescription,
  'instructor': c.instructor,
  'duration': c.duration,
  'level': c.level,
  'rating': c.rating,
  'price': c.price,
  'modules': c.modules,
  'prerequisites': c.prerequisites,
  'pdfName': c.pdfName,
  'quiz': c.quiz,
  'status': c.status,
  'passMark': c.passMark,
  'videoUrl': c.videoUrl,
};

Course courseFromJson(Map<String, dynamic> c, {String? pdfBase64}) => Course(
  id: c['id'] as String,
  title: c['title'] as String,
  shortDescription: c['description'] as String,
  instructor: c['instructor'] as String,
  duration: c['duration'] as String,
  level: c['level'] as String,
  rating: (c['rating'] as num).toDouble(),
  price: (c['price'] as num).toDouble(),
  modules: List<String>.from(c['modules'] as List),
  prerequisites: List<String>.from(c['prerequisites'] as List? ?? []),
  pdfName: c['pdfName'] as String?,
  pdfBase64: pdfBase64,
  status: c['status'] as String? ?? 'Published',
  passMark: (c['passMark'] as num?)?.toInt() ?? 60,
  videoUrl: c['videoUrl'] as String?,
  quiz: [
    for (final q in c['quiz'] as List? ?? [])
      Map<String, dynamic>.from(q as Map),
  ],
);

/// Firestore keeps documents under 1 MB, so course PDFs are stored as
/// base64 chunks in `courseFiles/{courseId}/chunks/{n}`.
const _pdfChunkSize = 700000;

/// Loads the course catalogue from Firestore. An empty database keeps the
/// built-in seed courses so the site still renders before seeding.
Future<void> loadCourseCatalogue() async {
  if (!Backend.isReady) return;
  try {
    final snapshot = await Backend.db
        .collection('courses')
        .orderBy('position')
        .get();
    if (snapshot.docs.isEmpty) return;
    final courses = <Course>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      String? pdf;
      if (data['pdfChunks'] is num && (data['pdfChunks'] as num) > 0) {
        final chunks = await Backend.db
            .collection('courseFiles')
            .doc(doc.id)
            .collection('chunks')
            .orderBy('index')
            .get();
        pdf = chunks.docs.map((d) => d.data()['data'] as String).join();
      }
      courses.add(courseFromJson(data, pdfBase64: pdf));
    }
    mockCourses
      ..clear()
      ..addAll(courses);
  } catch (_) {
    /* Keep the built-in catalogue when the database is unreachable. */
  }
}

void validateCourseCatalogue(List<Course> courses) {
  final byId = {for (final course in courses) course.id: course};
  bool cycle(String id, Set<String> visiting) {
    if (!visiting.add(id)) return true;
    for (final prerequisite in byId[id]!.prerequisites) {
      if (!byId.containsKey(prerequisite) ||
          cycle(prerequisite, {...visiting})) {
        return true;
      }
    }
    return false;
  }

  if (byId.length != courses.length ||
      courses.any((c) => c.modules.isEmpty || cycle(c.id, {}))) {
    throw ArgumentError(
      'Courses need modules and prerequisites without circular dependencies.',
    );
  }
}

/// Saves the full catalogue (admin only). Removed courses are deleted.
Future<void> saveCourseCatalogue(List<Course> courses) async {
  validateCourseCatalogue(courses);
  if (Backend.isReady) {
    try {
      final db = Backend.db;
      final existing = await db.collection('courses').get();
      final keep = courses.map((c) => c.id).toSet();
      final batch = db.batch();
      for (final doc in existing.docs) {
        if (!keep.contains(doc.id)) batch.delete(doc.reference);
      }
      for (final (i, c) in courses.indexed) {
        final pdf = c.pdfBase64 ?? '';
        final chunkCount = (pdf.length / _pdfChunkSize).ceil();
        batch.set(db.collection('courses').doc(c.id), {
          ...courseToJson(c),
          'position': i,
          'pdfChunks': chunkCount,
        });
      }
      await batch.commit();
      for (final c in courses) {
        final previous = mockCourses.where((m) => m.id == c.id).firstOrNull;
        if (previous?.pdfBase64 == c.pdfBase64 && previous != null) continue;
        final chunks = db
            .collection('courseFiles')
            .doc(c.id)
            .collection('chunks');
        final old = await chunks.get();
        final pdf = c.pdfBase64 ?? '';
        final write = db.batch();
        for (final doc in old.docs) {
          write.delete(doc.reference);
        }
        for (var i = 0; i * _pdfChunkSize < pdf.length; i++) {
          final end = ((i + 1) * _pdfChunkSize).clamp(0, pdf.length);
          write.set(chunks.doc('$i'), {
            'index': i,
            'data': pdf.substring(i * _pdfChunkSize, end),
          });
        }
        await write.commit();
      }
    } catch (e) {
      throw StateError('Course changes could not be saved: $e');
    }
  }
  mockCourses
    ..clear()
    ..addAll(courses);
}
