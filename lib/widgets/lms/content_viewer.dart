import 'package:flutter/material.dart';

import '../../theme.dart';

/// Every kind of lesson the player can show. Add a new value here and a new
/// case in ContentViewer.build() to support another content type later.
enum LessonType { video, text, pdf, presentation, audio, image, externalLink }

extension LessonTypeInfo on LessonType {
  IconData get icon => switch (this) {
    LessonType.video => Icons.play_circle_outline,
    LessonType.text => Icons.article_outlined,
    LessonType.pdf => Icons.picture_as_pdf_outlined,
    LessonType.presentation => Icons.slideshow_outlined,
    LessonType.audio => Icons.headphones_outlined,
    LessonType.image => Icons.image_outlined,
    LessonType.externalLink => Icons.open_in_new,
  };

  String get label => switch (this) {
    LessonType.video => 'Video lesson',
    LessonType.text => 'Reading',
    LessonType.pdf => 'PDF document',
    LessonType.presentation => 'Presentation',
    LessonType.audio => 'Audio lesson',
    LessonType.image => 'Image',
    LessonType.externalLink => 'External resource',
  };
}

/// Named PlayerLesson so it does not clash with Lesson in mock_data.dart.
class PlayerLesson {
  const PlayerLesson({
    required this.moduleIndex,
    required this.moduleTitle,
    required this.title,
    required this.type,
    this.body = '',
  });

  final int moduleIndex;
  final String moduleTitle;
  final String title;
  final LessonType type;
  final String body;
}

class ContentViewer extends StatelessWidget {
  const ContentViewer({super.key, required this.lesson});
  final PlayerLesson lesson;

  @override
  Widget build(BuildContext context) => switch (lesson.type) {
    LessonType.text => _TextView(lesson: lesson),
    LessonType.externalLink => _PlaceholderView(
      lesson: lesson,
      hint: 'This lesson opens a resource outside the platform.',
      action: OutlinedButton.icon(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prototype: external link not opened')),
        ),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Open resource'),
      ),
    ),
    _ => _PlaceholderView(
      lesson: lesson,
      hint: 'Placeholder for the ${lesson.type.label.toLowerCase()} player.',
    ),
  };
}

class _TextView extends StatelessWidget {
  const _TextView({required this.lesson});
  final PlayerLesson lesson;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(lesson.title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      Text(
        lesson.moduleTitle,
        style: const TextStyle(color: purple, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 18),
      Text(lesson.body, style: Theme.of(context).textTheme.bodyLarge),
    ],
  );
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({
    required this.lesson,
    required this.hint,
    this.action,
  });
  final PlayerLesson lesson;
  final String hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: deepBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(lesson.type.icon, size: 64, color: softYellow),
            const SizedBox(height: 12),
            Text(
              lesson.type.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text(lesson.title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      Text(
        lesson.moduleTitle,
        style: const TextStyle(color: purple, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Text(
        lesson.body.isEmpty ? hint : lesson.body,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      if (action != null) ...[const SizedBox(height: 16), action!],
    ],
  );
}
