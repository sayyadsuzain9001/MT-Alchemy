import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../backend/backend.dart';
import '../data/mock_data.dart';
import '../widgets.dart';

class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({super.key});
  @override
  State<CourseManagementPage> createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage> {
  Future<void> edit([Course? course]) async {
    await showDialog(
      context: context,
      builder: (_) => CourseEditor(course: course),
    );
    if (mounted) setState(() {});
  }

  Future<void> remove(Course course) async {
    if (mockCourses.any((c) => c.prerequisites.contains(course.id))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remove this course from other prerequisites first.'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${course.title}?'),
        content: const Text(
          'This removes the course from the catalogue. Existing learning records are retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await saveCourseCatalogue(
        mockCourses.where((c) => c.id != course.id).toList(),
      );
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save changes. Please retry.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageWidth(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          'Build your learning catalogue.',
          eyebrow: 'Courses',
          subtitle:
              'Manage training, learning resources, assessments and prerequisites.',
        ),
        FilledButton.icon(
          onPressed: () => edit(),
          icon: const Icon(Icons.add),
          label: const Text('Add course'),
        ),
        const SizedBox(height: 24),
        if (mockCourses.isEmpty)
          const Text('Your catalogue is empty. Add your first course.'),
        for (final c in mockCourses)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        c.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Chip(
                        label: Text(c.status),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: switch (c.status) {
                          'Published' => const Color(0xFFE6F4EA),
                          'Draft' => const Color(0xFFFFF4CC),
                          _ => const Color(0xFFECECEC),
                        },
                      ),
                    ],
                  ),
                  Text(
                    '${c.instructor} · RM ${c.price.toStringAsFixed(0)} · pass mark ${c.passMark}%',
                  ),
                  _EnrolmentCount(courseId: c.id),
                  Text(
                    '${c.modules.length} modules · ${c.duration} · ${c.level}',
                  ),
                  Text(c.pdfName ?? 'No PDF attached'),
                  Text('${c.quiz.length} custom quiz questions'),
                  Wrap(
                    spacing: 12,
                    children: [
                      TextButton.icon(
                        onPressed: () => edit(c),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit course'),
                      ),
                      TextButton.icon(
                        onPressed: () => remove(c),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete course'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 32),
      ],
    ),
  );
}

class CourseEditor extends StatefulWidget {
  const CourseEditor({super.key, this.course});
  final Course? course;
  @override
  State<CourseEditor> createState() => _CourseEditorState();
}

class _CourseEditorState extends State<CourseEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.course?.title);
  late final description = TextEditingController(
    text: widget.course?.shortDescription,
  );
  late final duration = TextEditingController(
    text: widget.course?.duration ?? '4 weeks',
  );
  late final modules = TextEditingController(
    text: widget.course?.modules.join('\n'),
  );
  late final quiz = TextEditingController(
    text: widget.course?.quiz
        .map(
          (q) =>
              '${q['prompt']} | ${(q['options'] as List).join(' | ')} | ${q['answer']}',
        )
        .join('\n'),
  );
  late final instructor = TextEditingController(
    text: widget.course?.instructor ?? 'MT Alchemy Learning Team',
  );
  late final price = TextEditingController(
    text: (widget.course?.price ?? 0).toStringAsFixed(0),
  );
  late final passMark = TextEditingController(
    text: '${widget.course?.passMark ?? 60}',
  );
  late final videoUrl = TextEditingController(text: widget.course?.videoUrl);
  late String level = widget.course?.level ?? 'Beginner';
  late String status = widget.course?.status ?? 'Draft';
  late final prerequisites = {...?widget.course?.prerequisites};
  late String? pdfName = widget.course?.pdfName;
  late String? pdfData = widget.course?.pdfBase64;
  String? error;
  bool saving = false;
  @override
  void dispose() {
    for (final c in [
      title,
      description,
      duration,
      modules,
      quiz,
      instructor,
      price,
      passMark,
      videoUrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> upload() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null ||
          bytes.length > 3 * 1024 * 1024 ||
          bytes.length < 5 ||
          utf8.decode(bytes.take(5).toList(), allowMalformed: true) !=
              '%PDF-') {
        setState(() => error = 'Choose a valid PDF smaller than 3 MB.');
        return;
      }
      setState(() {
        pdfName = file.name;
        pdfData = base64Encode(bytes);
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'PDF upload failed. Please try again.');
      }
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final questions = <Map<String, dynamic>>[];
    for (final line
        in quiz.text.split('\n').where((l) => l.trim().isNotEmpty)) {
      final parts = line.split('|').map((s) => s.trim()).toList();
      if (parts.length != 4 ||
          parts.any((p) => p.isEmpty) ||
          !parts.sublist(1, 3).contains(parts.last) ||
          parts[1] == parts[2]) {
        setState(
          () => error =
              'Each quiz line needs: Question | Option A | Option B | Correct option (exact text).',
        );
        return;
      }
      questions.add({
        'prompt': parts[0],
        'options': parts.sublist(1, 3),
        'answer': parts[3],
      });
    }
    if (widget.course == null && questions.isEmpty) {
      setState(() => error = 'Add at least one quiz question.');
      return;
    }
    final list = modules.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (list.isEmpty || list.length > 100) {
      setState(() => error = 'Enter between 1 and 100 modules.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final c = Course(
      id:
          widget.course?.id ??
          'course-${DateTime.now().microsecondsSinceEpoch}',
      title: title.text.trim(),
      shortDescription: description.text.trim(),
      instructor: instructor.text.trim(),
      duration: duration.text.trim(),
      level: level,
      rating: widget.course?.rating ?? 0,
      price: double.parse(price.text.trim()),
      status: status,
      passMark: int.parse(passMark.text.trim()),
      videoUrl: videoUrl.text.trim().isEmpty ? null : videoUrl.text.trim(),
      modules: list,
      prerequisites: prerequisites.toList(),
      pdfName: pdfName,
      pdfBase64: pdfData,
      quiz: questions,
    );
    try {
      await saveCourseCatalogue([
        ...mockCourses.where((item) => item.id != c.id),
        c,
      ]);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          error =
              'Could not save. Check prerequisites for circular dependencies and available device storage.';
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.course == null ? 'Add course' : 'Edit course'),
    content: SizedBox(
      width: 600,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final field in [
                (title, 'Course title'),
                (description, 'Description'),
                (duration, 'Duration'),
                (instructor, 'Instructor / trainer'),
                (modules, 'Modules — one per line'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: field.$1,
                    maxLines: field.$1 == modules ? 5 : null,
                    decoration: InputDecoration(labelText: field.$2),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (RM)',
                      ),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return n == null || n < 0 || n > 100000
                            ? 'Enter a price from 0'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: passMark,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Passing score (%)',
                      ),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        return n == null || n < 1 || n > 100
                            ? '1 to 100'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: level,
                      decoration: const InputDecoration(labelText: 'Level'),
                      items: [
                        for (final l in const [
                          'Beginner',
                          'Intermediate',
                          'Advanced',
                        ])
                          DropdownMenuItem(value: l, child: Text(l)),
                      ],
                      onChanged: (v) => setState(() => level = v ?? level),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: [
                        for (final st in const [
                          'Draft',
                          'Published',
                          'Archived',
                        ])
                          DropdownMenuItem(value: st, child: Text(st)),
                      ],
                      onChanged: (v) => setState(() => status = v ?? status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: videoUrl,
                decoration: const InputDecoration(
                  labelText: 'Lesson video link (optional)',
                  helperText: 'YouTube or MP4 link shown in the course player',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  final u = Uri.tryParse(t);
                  return u == null || !u.isScheme('https')
                      ? 'Use an https:// link'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Prerequisites'),
              for (final c in mockCourses.where(
                (c) => c.id != widget.course?.id,
              ))
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.title),
                  value: prerequisites.contains(c.id),
                  onChanged: (v) => setState(() {
                    v == true
                        ? prerequisites.add(c.id)
                        : prerequisites.remove(c.id);
                  }),
                ),
              OutlinedButton.icon(
                onPressed: saving ? null : upload,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload PDF (up to 3 MB)'),
              ),
              if (pdfName != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(pdfName!),
                  trailing: IconButton(
                    tooltip: 'Remove PDF',
                    onPressed: () => setState(() {
                      pdfName = null;
                      pdfData = null;
                    }),
                    icon: const Icon(Icons.close),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quiz,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Quiz questions',
                  helperText:
                      'One per line: Question | Option A | Option B | Correct option',
                  helperMaxLines: 3,
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: saving ? null : save,
        child: Text(saving ? 'Saving…' : 'Save course'),
      ),
    ],
  );
}

class _EnrolmentCount extends StatelessWidget {
  const _EnrolmentCount({required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context) => FutureBuilder<int>(
    future: Backend.isReady
        ? Backend.db
              .collection('progress')
              .where('enrolled', arrayContains: courseId)
              .count()
              .get()
              .then((r) => r.count ?? 0)
        : Future.value(0),
    builder: (context, snap) => Text(
      snap.hasData
          ? '${snap.data} enrolment(s)'
          : snap.hasError
          ? 'Enrolments unavailable'
          : 'Counting enrolments…',
      style: const TextStyle(color: Colors.black54),
    ),
  );
}
