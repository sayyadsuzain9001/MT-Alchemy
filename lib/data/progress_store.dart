import '../backend/backend.dart';
import '../backend/collection_sync.dart';
import '../commerce/commerce_prototype_store.dart';
import 'mock_data.dart';

/// Learner progress for the signed-in account, stored in Firestore at
/// `progress/{email}`. Screens read the in-memory collections below.
const lessonsPerCourse = 20;
final Map<String, Set<int>> completedLessons = {};
final Map<String, int> lastLesson = {};
final Set<String> completedCourses = {};
final Map<String, String> completionDates = {};
final Set<String> enrolledCourses = {};
String? _learner;
String? progressStorageError;
final _progressSaves = SerialQueue();

/// Kept for start-up compatibility; progress loads when a learner signs in.
Future<void> loadProgress() async {}

/// Waits for queued progress writes (used by tests and sign-out).
Future<void> flushProgress() => _progressSaves.idle;

Future<void> selectLearner(String? email) async {
  _learner = email?.toLowerCase();
  completedLessons.clear();
  lastLesson.clear();
  completedCourses.clear();
  completionDates.clear();
  enrolledCourses.clear();
  final learner = _learner;
  if (learner == null || !Backend.isReady) return;
  try {
    final snapshot = await Backend.db.collection('progress').doc(learner).get();
    if (_learner != learner) return;
    final data = snapshot.data() ?? const <String, dynamic>{};
    final done = Map<String, dynamic>.from(data['done'] as Map? ?? {});
    done.forEach((course, lessons) {
      completedLessons[course] = {
        for (final n in lessons as List)
          if (n is num && n >= 0 && n < 400) n.toInt(),
      };
    });
    final last = Map<String, dynamic>.from(data['last'] as Map? ?? {});
    last.forEach((course, index) {
      lastLesson[course] = ((index as num?)?.toInt() ?? 0).clamp(0, 399);
    });
    completedCourses.addAll(List<String>.from(data['completed'] ?? []));
    completionDates.addAll(
      Map<String, String>.from(data['completionDates'] as Map? ?? {}),
    );
    enrolledCourses.addAll(List<String>.from(data['enrolled'] ?? []));
    progressStorageError = null;
  } catch (_) {
    progressStorageError = 'Learning progress could not be loaded.';
  }
  final store = CommercePrototypeStore.instance;
  final assigned = store.assignedCoursesFor(learner);
  enrolledCourses.addAll(
    mockCourses.where((c) => assigned.contains(c.title)).map((c) => c.id),
  );
  // Courses bought (including pending orders later confirmed by an admin).
  enrolledCourses.addAll(store.paidCourseIdsFor(learner));
}

Future<void> saveProgress() {
  final learner = _learner;
  if (learner == null) return Future.value();
  for (final course in mockCourses.where(
    (c) => enrolledCourses.contains(c.id),
  )) {
    CommercePrototypeStore.instance.updateLearningProgress(
      learner,
      course.title,
      progressFor(course),
    );
  }
  final data = <String, dynamic>{
    'email': learner,
    'done': {
      for (final e in completedLessons.entries)
        e.key: (e.value.toList()..sort()),
    },
    'last': Map<String, int>.of(lastLesson),
    'completed': completedCourses.toList(),
    'completionDates': Map<String, String>.of(completionDates),
    'enrolled': enrolledCourses.toList(),
    'updatedAt': DateTime.now().toIso8601String(),
  };
  return _progressSaves.add(() async {
    if (!Backend.isReady) return;
    try {
      await Backend.db.collection('progress').doc(learner).set(data);
      progressStorageError = null;
    } catch (_) {
      progressStorageError =
          'Progress could not be saved. Check your connection.';
    }
  });
}

void enrollCourse(String courseId) {
  final course = mockCourses.where((c) => c.id == courseId).firstOrNull;
  if (course == null ||
      !course.prerequisites.every(completedCourses.contains)) {
    return;
  }
  enrolledCourses.add(courseId);
  saveProgress();
}

void completeCourse(String courseId, {int? score}) {
  final selected = mockCourses.where((c) => c.id == courseId).firstOrNull;
  if (selected == null ||
      score == null ||
      score < selected.passMark ||
      !selected.prerequisites.every(completedCourses.contains) ||
      progressFor(selected) < 100) {
    return;
  }
  enrolledCourses.add(courseId);
  completedCourses.add(courseId);
  completionDates.putIfAbsent(courseId, () => DateTime.now().toIso8601String());
  if (_learner != null) {
    CommercePrototypeStore.instance.updateLearningProgress(
      _learner!,
      selected.title,
      progressFor(selected),
      score: score,
    );
  }
  saveProgress();
}

int progressFor(Course course) =>
    ((completedLessons[course.id]?.length ?? 0) /
            (course.modules.length * 4) *
            100)
        .round();
