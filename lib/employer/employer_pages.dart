import '../data/mock_data.dart';
import '../shared/notifications.dart';
import 'bulk_import.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../commerce/commerce_prototype_store.dart';
import '../shared/file_export.dart';
import '../shared/portal_components.dart';
import '../shared/report_document.dart';
import '../theme.dart';
import '../shared/auth_prototype_store.dart';
import '../shared/charts.dart';
import '../shared/ui_kit.dart';
import '../widgets.dart';

final _store = CommercePrototypeStore.instance;

class EmployerDashboardPage extends StatelessWidget {
  const EmployerDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) {
      final assignments = _store.assignments;
      final average = assignments.isEmpty
          ? 0
          : assignments
                    .map((a) => a['progress'] as int)
                    .reduce((a, b) => a + b) ~/
                assignments.length;
      final employees = _store.employees;
      final completed = assignments
          .where((a) => (a['progress'] as int) >= 100)
          .length;
      final inProgress = assignments
          .where(
            (a) => (a['progress'] as int) > 0 && (a['progress'] as int) < 100,
          )
          .length;
      final notStarted = assignments.length - completed - inProgress;
      final activeLearners = {
        for (final a in assignments)
          if ((a['progress'] as int) > 0) a['employee'],
      }.length;
      final hours = assignments.fold<num>(
        0,
        (t, a) => t + ((a['progress'] as int) / 100 * 10),
      );
      final seats = _store.purchasedSeats();
      final seatsLeft = seats.entries.fold<int>(
        0,
        (t, e) => t + (e.value - _store.assignedSeats(e.key)).clamp(0, 9999),
      );
      final byDept = <String, List<int>>{};
      for (final a in assignments) {
        byDept.putIfAbsent('${a['team']}', () => []).add(a['progress'] as int);
      }
      final deptValues = [
        for (final e in byDept.entries)
          (e.key, e.value.reduce((x, y) => x + y) / e.value.length),
      ];
      final upcoming =
          assignments.where((a) => (a['progress'] as int) < 100).toList()
            ..sort((x, y) => '${x['due']}'.compareTo('${y['due']}'));
      final orgName =
          AuthPrototypeStore.instance.displayName ?? 'Your organization';
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
      return PortalPage(
        title: 'Help your people grow.',
        eyebrow: 'Employer portal · $orgName',
        showTitle: false,
        children: [
          DashboardHeader(
            eyebrow: 'Employer portal · $orgName',
            title: 'Help your people grow.',
            subtitle:
                'Manage employees, buy course seats, assign learning and follow progress from one place.',
            image: 'assets/images/stock/team_discussion.jpg',
            actions: [
              HeaderButton(
                label: 'Add employees',
                icon: Icons.person_add_alt_1,
                primary: true,
                onPressed: () => go(context, '/employees'),
              ),
              HeaderButton(
                label: 'Assign course',
                icon: Icons.assignment_add,
                onPressed: () => go(context, '/assign-course'),
              ),
              HeaderButton(
                label: 'Buy seats',
                icon: Icons.shopping_cart_checkout,
                onPressed: () => go(context, '/purchase-courses'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TileGrid(
            maxColumns: 4,
            minTileWidth: 200,
            minColumns: 2,
            children: [
              StatTile(
                icon: Icons.people_outline,
                value: '${employees.length}',
                label: 'Total employees',
              ),
              StatTile(
                icon: Icons.school_outlined,
                value: '$activeLearners',
                label: 'Active learners',
                color: royalBlue,
              ),
              StatTile(
                icon: Icons.assignment_outlined,
                value: '${assignments.length}',
                label: 'Courses assigned',
                color: const Color(0xFF0E7490),
              ),
              StatTile(
                icon: Icons.verified_outlined,
                value: assignments.isEmpty
                    ? '0%'
                    : '${(completed / assignments.length * 100).round()}%',
                label: 'Completion rate',
                color: const Color(0xFF2E7D32),
                caption: 'Average progress $average%',
              ),
              StatTile(
                icon: Icons.workspace_premium_outlined,
                value: '$completed',
                label: 'Certificates earned',
                color: const Color(0xFFB7791F),
              ),
              StatTile(
                icon: Icons.schedule,
                value: hours.toStringAsFixed(0),
                label: 'Learning hours',
                color: const Color(0xFFC2410C),
              ),
              StatTile(
                icon: Icons.pending_actions_outlined,
                value: '${notStarted + inProgress}',
                label: 'Pending assignments',
                color: purple,
              ),
              StatTile(
                icon: Icons.event_seat_outlined,
                value: '$seatsLeft',
                label: 'Seats available',
                color: royalBlue,
              ),
            ],
          ),
          const SizedBox(height: 20),
          twoUp(
            DashboardPanel(
              title: 'Progress by department',
              subtitle: 'Average course progress',
              icon: Icons.bar_chart,
              child: LabelledBarChart(
                values: deptValues,
                maxY: 100,
                suffix: '%',
              ),
            ),
            DashboardPanel(
              title: 'Assignment status',
              icon: Icons.donut_large_outlined,
              child: StatusDonut(
                centerLabel: 'assignments',
                values: {
                  'Completed': completed,
                  'In progress': inProgress,
                  'Not started': notStarted,
                },
                colors: const [Color(0xFF2E7D32), purple, Color(0xFFD9D2EE)],
              ),
            ),
          ),
          const SizedBox(height: 20),
          DashboardPanel(
            title: 'Upcoming deadlines',
            icon: Icons.event_outlined,
            action: TextButton(
              onPressed: () => go(context, '/reports'),
              child: const Text('Full report'),
            ),
            child: upcoming.isEmpty
                ? const Text('No open assignments. Everyone is up to date.')
                : Column(
                    children: [
                      for (final a in upcoming.take(5))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFF1ECFB),
                            child: Text(
                              '${a['progress']}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: deepBlue,
                              ),
                            ),
                          ),
                          title: Text('${a['course']}'),
                          subtitle: Text(
                            '${a['employee']} · ${a['team']} · due ${a['due']}',
                          ),
                        ),
                    ],
                  ),
          ),
          const SectionTitle('Organization tools', eyebrow: 'Quick actions'),
          ResponsiveGrid(
            children: [
              PortalAction(
                title: 'Employee management',
                subtitle: 'Invite and manage people in your organization.',
                icon: Icons.groups_outlined,
                route: '/employees',
              ),
              PortalAction(
                title: 'Assign a course',
                subtitle: 'Choose a programme, audience and due date.',
                icon: Icons.assignment_add,
                route: '/assign-course',
              ),
              PortalAction(
                title: 'Learning reports',
                subtitle: 'Review progress by course and department.',
                icon: Icons.bar_chart,
                route: '/reports',
              ),
              PortalAction(
                title: 'Purchase courses',
                subtitle: 'Buy course seats for your employees.',
                icon: Icons.shopping_cart_checkout,
                route: '/purchase-courses',
              ),
              PortalAction(
                title: 'Store',
                subtitle: 'Workbooks, journals and team learning kits.',
                icon: Icons.storefront_outlined,
                route: '/store',
              ),
              PortalAction(
                title: 'My quote requests',
                subtitle: 'Track business pricing requests and team responses.',
                icon: Icons.request_quote_outlined,
                route: '/quote-requests',
              ),
            ],
          ),
          const SectionTitle(
            'Current assignments',
            eyebrow: 'Learning at a glance',
          ),
          if (assignments.isEmpty)
            const InfoCard(child: Text('No courses have been assigned yet.'))
          else
            for (final item in assignments)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['course'] as String,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text('${item['team']} · Due ${item['due']}'),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (item['progress'] as int) / 100,
                        minHeight: 8,
                        color: purple,
                        backgroundColor: purple.withValues(alpha: .12),
                      ),
                      const SizedBox(height: 5),
                      Text('${item['progress']}% complete'),
                    ],
                  ),
                ),
              ),
        ],
      );
    },
  );
}

class EmployeeManagementPage extends StatelessWidget {
  const EmployeeManagementPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) => PortalPage(
      title: 'Your people, learning together.',
      eyebrow: 'Employee management',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _AddEmployeeDialog(),
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Invite employee'),
            ),
            OutlinedButton.icon(
              onPressed: () => bulkInviteEmployees(context),
              icon: const Icon(Icons.upload_file),
              label: const Text('Bulk invite (Excel/CSV)'),
            ),
            TextButton.icon(
              onPressed: () => downloadTemplate(context, employees: true),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Template'),
            ),
            OutlinedButton(
              onPressed: () => go(context, '/assign-course'),
              child: const Text('Assign course'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_store.employees.isEmpty)
          const InfoCard(
            child: Text(
              'No employees yet. Invite a team member to get started.',
            ),
          )
        else
          InfoCard(
            padding: 12,
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: constraints.maxWidth >= 720
                    ? [
                        const _EmployeeRow(
                          name: 'Employee',
                          department: 'Department',
                          email: 'Email',
                          status: 'Status',
                          header: true,
                        ),
                        for (final employee in _store.employees)
                          _EmployeeRow(
                            name: employee['name']!,
                            department: employee['department']!,
                            email: employee['email']!,
                            status: employee['status'] ?? 'Active',
                          ),
                      ]
                    : [
                        for (final employee in _store.employees)
                          _EmployeeCard(employee: employee),
                      ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Employees appear in your organisation straight away. When they register or sign in with the same email, their assigned courses appear on their dashboard.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    required this.name,
    required this.department,
    required this.email,
    required this.status,
    this.header = false,
  });
  final String name;
  final String department;
  final String email;
  final String status;
  final bool header;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            name,
            style: TextStyle(
              fontWeight: header ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Text(department)),
        Expanded(flex: 2, child: Text(email, overflow: TextOverflow.ellipsis)),
        Expanded(child: Text(status)),
        if (!header)
          IconButton(
            tooltip: 'Remove employee',
            onPressed: () => _confirmRemoveEmployee(context, email),
            icon: const Icon(Icons.person_remove_outlined),
          )
        else
          const SizedBox(width: 48),
      ],
    ),
  );
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee});
  final Map<String, String> employee;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFF8F6FF),
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: Material(
      type: MaterialType.transparency,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(employee['name'] ?? ''),
        subtitle: Text(
          '${employee['department']}\n${employee['email']} · ${employee['status'] ?? 'Active'}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Remove employee',
          onPressed: () =>
              _confirmRemoveEmployee(context, employee['email'] ?? ''),
          icon: const Icon(Icons.person_remove_outlined),
        ),
      ),
    ),
  );
}

Future<void> _confirmRemoveEmployee(BuildContext context, String email) async {
  final employee = _store.employees.firstWhere(
    (item) => item['email'] == email,
    orElse: () => {'name': 'this employee'},
  );
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove employee?'),
      content: Text(
        'Remove ${employee['name']} and their local assignments from this demo organization?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed == true) _store.removeEmployee(email);
}

class _AddEmployeeDialog extends StatefulWidget {
  const _AddEmployeeDialog();
  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  String department = 'Human Resources';
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Invite employee'),
    content: Form(
      key: _key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Work email'),
            validator: (v) =>
                v == null ||
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                ? 'Enter a valid work email'
                : _store.employees.any(
                    (employee) =>
                        employee['email']?.toLowerCase() ==
                        v.trim().toLowerCase(),
                  )
                ? 'This email is already in the organization'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: department,
            decoration: const InputDecoration(labelText: 'Department'),
            items: const [
              DropdownMenuItem(
                value: 'Human Resources',
                child: Text('Human Resources'),
              ),
              DropdownMenuItem(value: 'Finance', child: Text('Finance')),
              DropdownMenuItem(value: 'Management', child: Text('Management')),
              DropdownMenuItem(value: 'Sales', child: Text('Sales')),
            ],
            onChanged: (v) => setState(() => department = v ?? department),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_key.currentState!.validate()) {
            _store.addEmployee(
              name: _name.text.trim(),
              email: _email.text.trim(),
              department: department,
            );
            Navigator.pop(context);
          }
        },
        child: const Text('Create invitation'),
      ),
    ],
  );
}

class CourseAssignmentPage extends StatefulWidget {
  const CourseAssignmentPage({super.key});
  @override
  State<CourseAssignmentPage> createState() => _CourseAssignmentPageState();
}

class _CourseAssignmentPageState extends State<CourseAssignmentPage> {
  final _key = GlobalKey<FormState>();
  String course = 'Emotional Intelligence Fundamentals';
  DateTime? deadline;
  final selected = <String>{};
  @override
  Widget build(BuildContext context) => PortalPage(
    title: 'Put learning into motion.',
    eyebrow: 'Corporate course assignment',
    children: [
      ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final seats = _store.purchasedSeats();
          final left = (seats[course] ?? 0) - _store.assignedSeats(course);
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                avatar: const Icon(Icons.event_seat_outlined, size: 18),
                label: Text(
                  '$course: ${seats[course] ?? 0} seats purchased · $left available',
                ),
              ),
              TextButton.icon(
                onPressed: () => go(context, '/purchase-courses'),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Buy seats'),
              ),
              OutlinedButton.icon(
                onPressed: () => bulkAssignCourses(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Bulk assign (Excel/CSV)'),
              ),
              TextButton.icon(
                onPressed: () => downloadTemplate(context, employees: false),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Template'),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      InfoCard(
        child: Form(
          key: _key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: course,
                decoration: const InputDecoration(labelText: 'Course'),
                isExpanded: true,
                items: [
                  for (final item in publishedCourses)
                    DropdownMenuItem(
                      value: item.title,
                      child: Text(item.title),
                    ),
                ],
                onChanged: (v) => setState(() => course = v ?? course),
              ),
              const SizedBox(height: 16),
              Text(
                'Assign to employees',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final employee in _store.employees)
                    FilterChip(
                      label: Text(
                        '${employee['name']} · ${employee['department']}',
                      ),
                      selected: selected.contains(employee['email']),
                      onSelected: (value) => setState(() {
                        value
                            ? selected.add(employee['email']!)
                            : selected.remove(employee['email']!);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final chosen = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate:
                        deadline ??
                        DateTime.now().add(const Duration(days: 14)),
                  );
                  if (chosen != null) setState(() => deadline = chosen);
                },
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  deadline == null
                      ? 'Choose a deadline'
                      : 'Due ${deadline!.day}/${deadline!.month}/${deadline!.year}',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _assign,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Assign Course'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Assigned courses appear on the employee\'s Learner dashboard as soon as they sign in with this email.',
        style: const TextStyle(color: Colors.black54),
      ),
    ],
  );
  void _assign() {
    if (!_key.currentState!.validate()) return;
    if (deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a deadline for this assignment.')),
      );
      return;
    }
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one employee.')),
      );
      return;
    }
    final newPeople = selected
        .where(
          (email) => !_store.assignments.any(
            (a) => a['employee'] == email && a['course'] == course,
          ),
        )
        .length;
    final available =
        (_store.purchasedSeats()[course] ?? 0) - _store.assignedSeats(course);
    if (newPeople > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You have $available unassigned seat(s) for $course. Buy more seats to assign $newPeople employee(s).',
          ),
          action: SnackBarAction(
            label: 'Buy seats',
            onPressed: () => Navigator.pushNamed(context, '/purchase-courses'),
          ),
        ),
      );
      return;
    }
    final due = '${deadline!.day} ${_month(deadline!.month)} ${deadline!.year}';
    for (final email in selected) {
      final employee = _store.employees.firstWhere(
        (item) => item['email'] == email,
        orElse: () => {'department': 'Unassigned'},
      );
      _store.assignCourse(
        course: course,
        team: employee['department'] ?? 'Unassigned',
        due: due,
        employeeEmail: email,
      );
      NotificationService.send(
        recipient: email,
        title: 'New course assigned',
        body: '$course is due on $due. Open your dashboard to start.',
        route: '/dashboard',
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$course assigned to ${selected.length} employee(s).'),
      ),
    );
    go(context, '/reports');
  }

  String _month(int value) => const [
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
  ][value - 1];
}

class LearningReportsPage extends StatelessWidget {
  const LearningReportsPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) => PortalPage(
      title: 'See how learning is progressing.',
      eyebrow: 'Corporate learning reports',
      children: [
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'Employee enrolments',
              value: '${_store.assignments.length}',
              icon: Icons.assignment_outlined,
            ),
            MetricCard(
              label: 'Completion',
              value: '${_average()}%',
              icon: Icons.task_alt,
            ),
            MetricCard(
              label: 'Average score',
              value: '${_averageScore()}%',
              icon: Icons.grade_outlined,
            ),
            MetricCard(
              label: 'Learning hours',
              value: '${_learningHours()}',
              icon: Icons.schedule_outlined,
            ),
          ],
        ),
        const SectionTitle(
          'Department performance',
          eyebrow: 'Progress by team',
        ),
        for (final department in [
          'Human Resources',
          'Finance',
          'Management',
          'Sales',
        ])
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(department, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _departmentProgress(department) / 100,
                  minHeight: 9,
                  color: purple,
                  backgroundColor: purple.withValues(alpha: .12),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_departmentProgress(department)}% average progress · ${_store.assignments.where((a) => a['team'] == department).length} enrolments',
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const SectionTitle(
          'Individual performance',
          eyebrow: 'Learner progress and certificates',
        ),
        if (_store.employees.isEmpty)
          const InfoCard(
            child: Text('Add employees to see individual learning progress.'),
          )
        else
          for (final employee in _store.employees)
            Builder(
              builder: (context) {
                final email = employee['email']!;
                final assigned = _store.assignments
                    .where((a) => a['employee'] == email)
                    .toList();
                final progress = assigned.isEmpty
                    ? 0
                    : assigned
                              .map((a) => a['progress'] as int)
                              .reduce((a, b) => a + b) ~/
                          assigned.length;
                final certificates = assigned
                    .where((a) => (a['progress'] as int) >= 100)
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InfoCard(
                    padding: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee['name']!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text('${employee['department']} · $email'),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 8,
                          color: purple,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${assigned.length} enrolments · $progress% average · $certificates certificates',
                        ),
                        for (final item in assigned)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${item['course']} · Due ${item['due']} · ${item['progress']}%',
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showReportPreview(context),
              icon: const Icon(Icons.description_outlined),
              label: const Text('View report'),
            ),
            OutlinedButton.icon(
              onPressed: () => _copyReport(
                context,
                'CSV report copied to clipboard',
                _csvReport(),
              ),
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Copy CSV'),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadCsv(context),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download CSV'),
            ),
            FilledButton.icon(
              onPressed: () => _downloadPdf(context),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Download PDF'),
            ),
          ],
        ),
      ],
    ),
  );
  int _average() {
    final values = _store.assignments.map((a) => a['progress'] as int).toList();
    return values.isEmpty ? 0 : values.reduce((a, b) => a + b) ~/ values.length;
  }

  int _averageScore() {
    final values = _store.assignments
        .map((assignment) => assignment['score'] as int? ?? 0)
        .where((score) => score > 0)
        .toList();
    return values.isEmpty ? 0 : values.reduce((a, b) => a + b) ~/ values.length;
  }

  int _learningHours() => _store.assignments.fold<int>(
    0,
    (total, assignment) => total + (assignment['hours'] as int? ?? 0),
  );

  int _departmentProgress(String department) {
    final values = _store.assignments
        .where((a) => a['team'] == department)
        .map((a) => a['progress'] as int)
        .toList();
    return values.isEmpty ? 0 : values.reduce((a, b) => a + b) ~/ values.length;
  }

  String _csvReport() {
    String escape(Object? value) =>
        '"${'${value ?? ''}'.replaceAll('"', '""')}"';
    final rows = <List<Object?>>[
      [
        'Course',
        'Department',
        'Employee name',
        'Employee email',
        'Due date',
        'Progress',
        'Score',
        'Hours',
        'Certificate',
      ],
      ..._store.assignments.map(
        (a) => [
          a['course'],
          a['team'],
          _employeeName(a['employee']),
          a['employee'],
          a['due'],
          a['progress'],
          a['score'],
          a['hours'],
          (a['progress'] as int) >= 100 ? 'Earned' : 'Not earned',
        ],
      ),
    ];
    return rows.map((row) => row.map(escape).join(',')).join('\n');
  }

  List<String> _reportLines() => [
    'MT Alchemy Corporate Learning Report',
    'Generated: ${DateTime.now().toLocal()}',
    'Enrolments: ${_store.assignments.length}',
    'Average completion: ${_average()}%',
    'Average score: ${_averageScore()}%',
    'Learning hours: ${_learningHours()}',
    'Course | Department | Employee | Email | Deadline | Progress | Score | Hours',
    ..._store.assignments.map(
      (a) =>
          '${a['course']} | ${a['team']} | ${_employeeName(a['employee'])} | ${a['employee']} | ${a['due']} | ${a['progress']}% | ${a['score']}% | ${a['hours']}',
    ),
  ];

  String _employeeName(Object? email) {
    for (final employee in _store.employees) {
      if (employee['email'] == email) return employee['name'] ?? 'Unknown';
    }
    return 'Unknown employee';
  }

  Future<void> _downloadCsv(BuildContext context) async {
    try {
      final path = await saveLocalFile(
        'mt_alchemy_learning_report.csv',
        utf8.encode(_csvReport()),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'File saving is unavailable on this platform.'
                : 'CSV saved to $path',
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save CSV: $error')));
      }
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final path = await saveLocalFile(
        'mt_alchemy_learning_report.pdf',
        createReportPdf(_reportLines()),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'File saving is unavailable on this platform.'
                : 'PDF saved to $path',
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save PDF: $error')));
      }
    }
  }

  Future<void> _copyReport(
    BuildContext context,
    String title,
    String content,
  ) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(title)));
  }

  void _showReportPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corporate learning report'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(
              _csvReport().replaceAll(',', '  ·  ').replaceAll('"', ''),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _csvReport()));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Copy CSV data'),
          ),
        ],
      ),
    );
  }
}
