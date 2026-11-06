import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../backend/backend.dart';
import '../commerce/commerce_prototype_store.dart';
import '../shared/auth_layout.dart';
import '../shared/auth_prototype_store.dart';
import '../shared/portal_components.dart';
import '../shared/profile_page.dart';
import '../theme.dart';
import '../widgets.dart';

/// Admin → Users and Organizations: create accounts for any role, change
/// roles, suspend or reactivate accounts, and review employer organizations.
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key, this.organizations = false});
  final bool organizations;

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _users = Backend.db.collection('users').snapshots();
  String _query = '';
  String _role = 'All';

  Future<void> _setField(
    String uid,
    Map<String, dynamic> data,
    String done,
  ) async {
    try {
      await Backend.db.collection('users').doc(uid).update(data);
      _toast(done);
    } catch (_) {
      _toast('The change could not be saved.');
    }
  }

  void _toast(String t) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
    }
  }

  Future<void> _delete(String uid, String email) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete user profile?'),
        content: Text(
          'Remove $email from MT Alchemy? Their profile and role are deleted and they can no longer use the platform. Orders and certificates are kept for records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Backend.db.collection('users').doc(uid).delete();
      _toast('$email was removed.');
    } catch (_) {
      _toast('The user could not be removed.');
    }
  }

  @override
  Widget build(BuildContext context) => PortalPage(
    eyebrow: widget.organizations ? 'Admin · Organizations' : 'Admin · Users',
    title: widget.organizations
        ? 'Employer organizations.'
        : 'People with access to MT Alchemy.',
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search name or email',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          if (!widget.organizations)
            for (final r in const [
              'All',
              'Learner',
              'Employer',
              'Trainer',
              'Admin',
            ])
              ChoiceChip(
                label: Text(r),
                selected: _role == r,
                onSelected: (_) => setState(() => _role = r),
              ),
          if (!widget.organizations)
            FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _CreateUserDialog(),
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add user'),
            ),
        ],
      ),
      const SizedBox(height: 18),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _users,
        builder: (context, snap) {
          if (snap.hasError) {
            return const InfoCard(child: Text('Users could not be loaded.'));
          }
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final docs =
              snap.data!.docs.where((d) {
                final m = d.data();
                final role = m['role'] as String? ?? '';
                if (widget.organizations && role != 'Employer') return false;
                if (!widget.organizations && _role != 'All' && role != _role) {
                  return false;
                }
                final hay = '${m['displayName']} ${m['email']}'.toLowerCase();
                return _query.isEmpty || hay.contains(_query);
              }).toList()..sort(
                (a, b) => '${a.data()['displayName']}'.compareTo(
                  '${b.data()['displayName']}',
                ),
              );
          if (docs.isEmpty) {
            return const InfoCard(child: Text('No matching accounts.'));
          }
          final store = CommercePrototypeStore.instance;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${docs.length} ${widget.organizations ? 'organization' : 'account'}(s)',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              for (final d in docs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _userCard(d.id, d.data(), store),
                ),
            ],
          );
        },
      ),
    ],
  );

  Widget _userCard(
    String uid,
    Map<String, dynamic> m,
    CommercePrototypeStore store,
  ) {
    final email = m['email'] as String? ?? '';
    final role = m['role'] as String? ?? 'Learner';
    final suspended = m['status'] == 'Suspended';
    final me = uid == AuthPrototypeStore.instance.uid;
    final employees = store.allEmployees
        .where((e) => e['organization'] == email)
        .length;
    final assignments = store.allAssignments
        .where((a) => a['organization'] == email)
        .length;
    return InfoCard(
      padding: 16,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileAvatar(
                  bytes: ProfileAvatar.fromProfile(m),
                  name: '${m['displayName'] ?? email}',
                  radius: 22,
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${m['displayName'] ?? email}${suspended ? ' (suspended)' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: suspended ? Colors.black45 : deepBlue,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (widget.organizations)
                        Text(
                          'Reg. no ${m['registrationNumber'] ?? '-'} · ${m['industry'] ?? 'Industry not set'} · ${m['employeeCount'] ?? '?'} staff · $employees on platform · $assignments assignments',
                          style: const TextStyle(fontSize: 13),
                        )
                      else if ((m['phone'] ?? '') != '')
                        Text(
                          '${m['phone']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!widget.organizations)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value: role,
                  underline: const SizedBox.shrink(),
                  onChanged: me
                      ? null
                      : (v) {
                          if (v != null && v != role) {
                            _setField(uid, {'role': v}, '$email is now $v.');
                          }
                        },
                  items: [
                    for (final r in AuthPrototypeStore.allRoles)
                      DropdownMenuItem(value: r, child: Text(r)),
                  ],
                ),
                OutlinedButton(
                  onPressed: me
                      ? null
                      : () => _setField(
                          uid,
                          {'status': suspended ? 'Active' : 'Suspended'},
                          suspended
                              ? '$email reactivated.'
                              : '$email suspended.',
                        ),
                  child: Text(suspended ? 'Reactivate' : 'Suspend'),
                ),
                IconButton(
                  tooltip: 'Delete $email',
                  onPressed: me ? null : () => _delete(uid, email),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();
  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'Trainer';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = _email.text.trim().toLowerCase();
      final uid = await Backend.auth.createAccountForOther(
        email,
        _password.text,
      );
      await Backend.db.collection('users').doc(uid).set({
        'email': email,
        'role': _role,
        'displayName': _name.text.trim(),
        'status': 'Active',
        'createdBy': AuthPrototypeStore.instance.email,
        'createdAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_role account created for $email.')),
      );
    } on AuthFailure catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'The account could not be created.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add user'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: 'Temporary password',
                helperText:
                    'Share it securely; they can change it in My profile.',
              ),
              validator: (v) =>
                  (v ?? '').length < 8 ? 'Use at least 8 characters' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [
                for (final r in AuthPrototypeStore.allRoles)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              FormErrorBanner(_error!),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy ? null : _create,
        child: Text(_busy ? 'Creating…' : 'Create account'),
      ),
    ],
  );
}
