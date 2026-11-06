import '../../shared/learning_navigation.dart';
import '../../shared/file_export.dart';
import '../../shared/report_document.dart';
import '../../shared/auth_prototype_store.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'certificate_verify.dart';

import '../../data/mock_data.dart';
import '../../data/progress_store.dart';
import '../../theme.dart';
import '../../widgets.dart'; // Eyebrow

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class CertificateScreen extends StatelessWidget {
  const CertificateScreen({
    super.key,
    this.courseId = 'ei-fundamentals',
    this.score = '',
  });

  final String courseId;
  final String score;

  Course get _course => mockCourses.firstWhere(
    (c) => c.id == courseId,
    orElse: () => mockCourses.first,
  );

  void _mock(BuildContext context, String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final course = _course;
    if (!completedCourses.contains(course.id)) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          actions: const [LearningNavigation()],
          title: const Text('Certificate'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pass the course quiz to earn your certificate.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    '/quiz',
                    arguments: course.id,
                  ),
                  child: const Text('Take quiz'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final now =
        DateTime.tryParse(completionDates[course.id] ?? '') ?? DateTime.now();
    final date = '${now.day} ${_months[now.month - 1]} ${now.year}';
    final certId =
        'MTA-${now.year}-${course.id.toUpperCase()}-${(AuthPrototypeStore.instance.email ?? '').codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff).toRadixString(36).toUpperCase()}';
    final learnerName = AuthPrototypeStore.instance.displayName ?? 'Learner';
    final verifyUrl = certificateVerifyUrl(certId);
    recordCertificate(
      certificateId: certId,
      learnerName: learnerName,
      learnerEmail: AuthPrototypeStore.instance.email ?? '',
      courseId: course.id,
      courseTitle: course.title,
      trainer: course.instructor,
      completedOn: date,
    );

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        actions: const [LearningNavigation()],
        title: const Text('Certificate'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                const Icon(Icons.celebration_outlined, size: 56, color: purple),
                const SizedBox(height: 12),
                Text(
                  'Congratulations!',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 8),
                Text(
                  score.isEmpty
                      ? 'You have completed the course.'
                      : 'You passed the assessment with a score of $score.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),

                // Certificate frame: outer Container = border, inner = paper
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: deepBlue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: canvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: softYellow, width: 3),
                    ),
                    child: Column(
                      children: [
                        const Eyebrow('MT Alchemy'),
                        const SizedBox(height: 14),
                        const Text(
                          'Certificate of Completion',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: deepBlue,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text('This is to certify that'),
                        const SizedBox(height: 10),
                        Text(
                          AuthPrototypeStore.instance.displayName ?? 'Learner',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: deepBlue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('has successfully completed'),
                        const SizedBox(height: 10),
                        Text(
                          course.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: purple,
                          ),
                        ),
                        const Divider(height: 44),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 24,
                          runSpacing: 20,
                          children: [
                            _Fact(label: 'Generated date', value: date),
                            _Fact(label: 'Certificate ID', value: certId),
                            _Fact(label: 'Trainer', value: course.instructor),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: deepBlue),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: QrImageView(
                                    data: verifyUrl,
                                    size: 96,
                                    padding: EdgeInsets.zero,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: deepBlue,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: deepBlue,
                                    ),
                                    semanticsLabel:
                                        'QR code to verify certificate $certId',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Scan to verify',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _mock(
                        context,
                        'Your certificate preview is shown above',
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('View Certificate'),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: softYellow,
                        foregroundColor: deepBlue,
                      ),
                      onPressed: () async {
                        try {
                          final destination = await saveLocalFile(
                            'certificate-${course.id}.pdf',
                            createReportPdf([
                              'MT Alchemy - Certificate of Completion',
                              'Awarded to: ${AuthPrototypeStore.instance.displayName ?? "Learner"}',
                              'Course: ${course.title}',
                              'Assessment: Passed',
                              'Completed: $date',
                              'Trainer: ${course.instructor}',
                              'Certificate ID: $certId',
                              'Verify at: $verifyUrl',
                            ]),
                          );
                          if (context.mounted) {
                            _mock(
                              context,
                              destination ??
                                  'Download is unavailable on this device.',
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            _mock(
                              context,
                              'Certificate could not be downloaded. Please try again.',
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Download Certificate'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/verify',
                        arguments: certId,
                      ),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Verify'),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/dashboard',
                        arguments: course.id,
                      ),
                      child: const Text('Back to dashboard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, color: deepBlue),
      ),
    ],
  );
}
