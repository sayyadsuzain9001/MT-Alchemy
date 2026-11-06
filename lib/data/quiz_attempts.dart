import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/notifications.dart';

import '../backend/backend.dart';
import '../shared/auth_prototype_store.dart';

/// A submitted quiz, stored in `quizAttempts`. Trainers add feedback.
class QuizAttempt {
  const QuizAttempt({
    required this.id,
    required this.learner,
    required this.learnerName,
    required this.courseId,
    required this.courseTitle,
    required this.score,
    required this.total,
    required this.passed,
    required this.submittedAt,
    this.status = 'Submitted',
    this.feedback,
    this.reviewedBy,
    this.reviewedAt,
    this.answers = const [],
  });

  final String id;
  final String learner;
  final String learnerName;
  final String courseId;
  final String courseTitle;
  final int score;
  final int total;
  final bool passed;
  final DateTime submittedAt;
  final String status;
  final String? feedback;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final List<Map<String, dynamic>> answers;

  int get percent => total == 0 ? 0 : (score / total * 100).round();
  bool get reviewed => status == 'Reviewed';

  factory QuizAttempt.fromDoc(String id, Map<String, dynamic> d) => QuizAttempt(
    id: id,
    learner: d['learner'] as String? ?? '',
    learnerName: d['learnerName'] as String? ?? d['learner'] as String? ?? '',
    courseId: d['courseId'] as String? ?? '',
    courseTitle: d['courseTitle'] as String? ?? '',
    score: (d['score'] as num?)?.toInt() ?? 0,
    total: (d['total'] as num?)?.toInt() ?? 0,
    passed: d['passed'] as bool? ?? false,
    submittedAt:
        DateTime.tryParse(d['submittedAt'] as String? ?? '') ?? DateTime(2026),
    status: d['status'] as String? ?? 'Submitted',
    feedback: d['feedback'] as String?,
    reviewedBy: d['reviewedBy'] as String?,
    reviewedAt: DateTime.tryParse(d['reviewedAt'] as String? ?? ''),
    answers: [
      for (final a in d['answers'] as List? ?? const [])
        Map<String, dynamic>.from(a as Map),
    ],
  );
}

class QuizAttemptService {
  static CollectionReference<Map<String, dynamic>> get _ref =>
      Backend.db.collection('quizAttempts');

  static Future<void> record({
    required String courseId,
    required String courseTitle,
    required int score,
    required int total,
    required bool passed,
    List<Map<String, dynamic>> answers = const [],
  }) async {
    final auth = AuthPrototypeStore.instance;
    if (!Backend.isReady || auth.email == null) return;
    try {
      await _ref.add({
        'learner': auth.email,
        'learnerName': auth.displayName ?? auth.email,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'score': score,
        'total': total,
        'passed': passed,
        'answers': answers,
        'status': 'Submitted',
        'submittedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      /* The quiz result still shows; the record is best effort. */
    }
  }

  static List<QuizAttempt> _map(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => QuizAttempt.fromDoc(d.id, d.data())).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  /// Every attempt (trainers and admins).
  static Stream<List<QuizAttempt>> all() => _ref.snapshots().map(_map);

  /// The signed-in learner's own attempts.
  static Stream<List<QuizAttempt>> mine(String email) =>
      _ref.where('learner', isEqualTo: email).snapshots().map(_map);

  static Future<void> review(
    String id,
    String feedback, {
    String? learner,
    String? courseTitle,
  }) async {
    await _ref.doc(id).update({
      'feedback': feedback.trim(),
      'status': 'Reviewed',
      'reviewedBy': AuthPrototypeStore.instance.displayName,
      'reviewedAt': DateTime.now().toIso8601String(),
    });
    if (learner != null) {
      await NotificationService.send(
        recipient: learner,
        title: 'Trainer feedback',
        body: 'Your trainer reviewed your ${courseTitle ?? 'quiz'} submission.',
        route: '/dashboard',
      );
    }
  }
}
