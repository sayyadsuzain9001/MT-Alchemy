import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../commerce/commerce_prototype_store.dart';
import '../data/mock_data.dart';
import '../shared/file_export.dart';
import '../shared/notifications.dart';
import '../theme.dart';

/// Reads the first sheet of an .xlsx file, or a .csv file, into rows of
/// trimmed strings. Blank rows are dropped.
List<List<String>> readSpreadsheet(Uint8List bytes, String fileName) {
  final rows = <List<String>>[];
  if (fileName.toLowerCase().endsWith('.csv')) {
    final text = utf8.decode(bytes, allowMalformed: true);
    for (final line in const LineSplitter().convert(text)) {
      rows.add(_splitCsv(line));
    }
  } else {
    final book = Excel.decodeBytes(bytes);
    final sheet = book.tables.values.firstOrNull;
    for (final row in sheet?.rows ?? const <List<Data?>>[]) {
      rows.add([
        for (final cell in row)
          cell?.value == null ? '' : '${cell!.value}'.trim(),
      ]);
    }
  }
  return rows.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
}

List<String> _splitCsv(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      if (quoted && i + 1 < line.length && line[i + 1] == '"') {
        buf.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (ch == ',' && !quoted) {
      out.add(buf.toString().trim());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  out.add(buf.toString().trim());
  return out;
}

class _Row {
  _Row(this.values, this.error);
  final List<String> values;
  final String? error;
}

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
const _departments = [
  'Human Resources',
  'Finance',
  'Management',
  'Sales',
  'Operations',
  'Marketing',
  'IT',
];

Future<(Uint8List, String)?> _pick() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['xlsx', 'csv'],
    withData: true,
  );
  final file = result?.files.single;
  if (file?.bytes == null) return null;
  return (file!.bytes!, file.name);
}

/// Bulk employee invites: columns Name, Email, Department.
Future<void> bulkInviteEmployees(BuildContext context) async {
  final picked = await _pick();
  if (picked == null || !context.mounted) return;
  final store = CommercePrototypeStore.instance;
  List<List<String>> sheet;
  try {
    sheet = readSpreadsheet(picked.$1, picked.$2);
  } catch (_) {
    _toast(
      context,
      'That file could not be read. Use the .xlsx or .csv template.',
    );
    return;
  }
  final body = _skipHeader(sheet, 'email');
  final seen = <String>{};
  final rows = <_Row>[];
  for (final r in body) {
    final name = r.elementAtOrNull(0) ?? '';
    final email = (r.elementAtOrNull(1) ?? '').toLowerCase();
    final dept = r.elementAtOrNull(2) ?? '';
    String? error;
    if (name.isEmpty) {
      error = 'Missing name';
    } else if (!_email.hasMatch(email)) {
      error = 'Invalid email';
    } else if (!seen.add(email) ||
        store.employees.any((e) => e['email']?.toLowerCase() == email)) {
      error = 'Already invited';
    }
    rows.add(_Row([name, email, dept.isEmpty ? 'Unassigned' : dept], error));
  }
  if (!context.mounted) return;
  final ok = await _preview(
    context,
    title: 'Invite employees',
    headers: const ['Name', 'Email', 'Department'],
    rows: rows,
    action: 'Invite',
  );
  if (ok != true || !context.mounted) return;
  var count = 0;
  for (final r in rows.where((r) => r.error == null)) {
    store.addEmployee(
      name: r.values[0],
      email: r.values[1],
      department: r.values[2],
    );
    count++;
  }
  _toast(context, '$count employee(s) invited.');
}

/// Bulk course assignment: columns Email, Course, Due date (YYYY-MM-DD).
Future<void> bulkAssignCourses(BuildContext context) async {
  final picked = await _pick();
  if (picked == null || !context.mounted) return;
  final store = CommercePrototypeStore.instance;
  List<List<String>> sheet;
  try {
    sheet = readSpreadsheet(picked.$1, picked.$2);
  } catch (_) {
    _toast(
      context,
      'That file could not be read. Use the .xlsx or .csv template.',
    );
    return;
  }
  final body = _skipHeader(sheet, 'email');
  final seatsLeft = {
    for (final e in store.purchasedSeats().entries)
      e.key: e.value - store.assignedSeats(e.key),
  };
  final rows = <_Row>[];
  for (final r in body) {
    final email = (r.elementAtOrNull(0) ?? '').toLowerCase();
    final courseText = r.elementAtOrNull(1) ?? '';
    final dueText = r.elementAtOrNull(2) ?? '';
    final course = mockCourses
        .where(
          (c) =>
              c.title.toLowerCase() == courseText.toLowerCase() ||
              c.id == courseText,
        )
        .firstOrNull;
    final due = DateTime.tryParse(dueText.split(' ').first);
    String? error;
    if (!store.employees.any((e) => e['email']?.toLowerCase() == email)) {
      error = 'Not an employee';
    } else if (course == null) {
      error = 'Unknown course';
    } else if (due == null) {
      error = 'Due date must be YYYY-MM-DD';
    } else if (store.assignments.any(
      (a) => a['employee'] == email && a['course'] == course.title,
    )) {
      error = 'Already assigned';
    } else if ((seatsLeft[course.title] ?? 0) <= 0) {
      error = 'No seats left';
    } else {
      seatsLeft[course.title] = seatsLeft[course.title]! - 1;
    }
    rows.add(_Row([email, course?.title ?? courseText, dueText], error));
  }
  if (!context.mounted) return;
  final ok = await _preview(
    context,
    title: 'Assign courses',
    headers: const ['Email', 'Course', 'Due'],
    rows: rows,
    action: 'Assign',
  );
  if (ok != true || !context.mounted) return;
  var count = 0;
  for (final r in rows.where((r) => r.error == null)) {
    final email = r.values[0];
    final due = DateTime.parse(r.values[2].split(' ').first);
    final dueText = '${due.day} ${_months[due.month - 1]} ${due.year}';
    final employee = store.employees.firstWhere(
      (e) => e['email']?.toLowerCase() == email,
    );
    store.assignCourse(
      course: r.values[1],
      team: employee['department'] ?? 'Unassigned',
      due: dueText,
      employeeEmail: employee['email']!,
    );
    NotificationService.send(
      recipient: email,
      title: 'New course assigned',
      body: '${r.values[1]} is due on $dueText. Open your dashboard to start.',
      route: '/dashboard',
    );
    count++;
  }
  _toast(context, '$count assignment(s) created.');
}

Future<void> downloadTemplate(
  BuildContext context, {
  required bool employees,
}) async {
  final csv = employees
      ? 'Name,Email,Department\nJane Tan,jane.tan@company.com,${_departments.first}\n'
      : 'Email,Course,Due date (YYYY-MM-DD)\njane.tan@company.com,${mockCourses.first.title},2026-12-31\n';
  final name = employees
      ? 'employee_invites_template.csv'
      : 'course_assignments_template.csv';
  await saveLocalFile(name, utf8.encode(csv));
  if (context.mounted) _toast(context, 'Template downloaded: $name');
}

const _months = [
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

List<List<String>> _skipHeader(List<List<String>> rows, String key) =>
    rows.isNotEmpty && rows.first.any((c) => c.toLowerCase().contains(key))
    ? rows.skip(1).toList()
    : rows;

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<bool?> _preview(
  BuildContext context, {
  required String title,
  required List<String> headers,
  required List<_Row> rows,
  required String action,
}) {
  final valid = rows.where((r) => r.error == null).length;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 620,
        height: 380,
        child: rows.isEmpty
            ? const Center(child: Text('The file has no data rows.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$valid of ${rows.length} row(s) ready. Rows with problems are skipped.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 40,
                          dataRowMinHeight: 36,
                          dataRowMaxHeight: 44,
                          columns: [
                            for (final h in headers) DataColumn(label: Text(h)),
                            const DataColumn(label: Text('Check')),
                          ],
                          rows: [
                            for (final r in rows)
                              DataRow(
                                cells: [
                                  for (final v in r.values) DataCell(Text(v)),
                                  DataCell(
                                    Text(
                                      r.error ?? 'Ready',
                                      style: TextStyle(
                                        color: r.error == null
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFC62828),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: valid == 0
              ? null
              : () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(backgroundColor: deepBlue),
          child: Text('$action $valid'),
        ),
      ],
    ),
  );
}
