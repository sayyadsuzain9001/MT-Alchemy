import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import 'auth_layout.dart';
import 'auth_prototype_store.dart';
import 'learning_navigation.dart';

/// Profile for every role (Group 8 feedback): photo, personal and
/// professional details, preferences and password change.
class AccountProfilePage extends StatefulWidget {
  const AccountProfilePage({super.key});
  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  final _form = GlobalKey<FormState>();
  final _auth = AuthPrototypeStore.instance;
  late final Map<String, dynamic> _p = Map.of(_auth.profile);
  late final _name = _c(_auth.displayName);
  late final _phone = _c(_p['phone']);
  late final _country = _c(_p['country']);
  late final _jobTitle = _c(_p['jobTitle']);
  late final _company = _c(_p['company'] ?? _p['organizationName']);
  late final _industry = _c(_p['industry']);
  late final _years = _c(_p['yearsWorking']);
  late final _bio = _c(_p['bio']);
  late final _regNo = _c(_p['registrationNumber']);
  late final _employees = _c(_p['employeeCount']);
  late final _contact = _c(_p['contactPerson']);
  late DateTime? _dob = DateTime.tryParse('${_p['dateOfBirth'] ?? ''}');
  late String? _gender = _p['gender'] as String?;
  late String? _photo = _p['photoBase64'] as String?;
  late bool _newsletter = _p['newsletter'] == 'yes';
  late final Set<String> _areas = {
    for (final a in '${_p['learningAreas'] ?? ''}'.split(','))
      if (a.trim().isNotEmpty) a.trim(),
  };
  bool _saving = false;

  static TextEditingController _c(Object? v) =>
      TextEditingController(text: v == null ? '' : '$v');

  bool get _isOrg => _auth.role == 'Employer';

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _country,
      _jobTitle,
      _company,
      _industry,
      _years,
      _bio,
      _regNo,
      _employees,
      _contact,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    if (bytes.length > 8 * 1024 * 1024) {
      _snack('Choose an image smaller than 8 MB.');
      return;
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 256);
      final frame = await codec.getNextFrame();
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) throw StateError('encode');
      setState(() => _photo = base64Encode(png.buffer.asUint8List()));
    } catch (_) {
      _snack('That image could not be read. Try a JPG or PNG.');
    }
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final details = <String, String>{
      'phone': _phone.text,
      'country': _country.text,
      'bio': _bio.text,
      'photoBase64': _photo ?? '',
      'newsletter': _newsletter ? 'yes' : 'no',
      if (_isOrg) ...{
        'organizationName': _name.text,
        'registrationNumber': _regNo.text,
        'employeeCount': _employees.text,
        'contactPerson': _contact.text,
        'industry': _industry.text,
      } else ...{
        'gender': _gender ?? '',
        'dateOfBirth': _dob == null
            ? ''
            : _dob!.toIso8601String().substring(0, 10),
        'jobTitle': _jobTitle.text,
        'company': _company.text,
        'industry': _industry.text,
        'yearsWorking': _years.text,
        'learningAreas': _areas.join(', '),
      },
    };
    final ok = await _auth.updateProfile(_name.text, details: details);
    if (!mounted) return;
    setState(() => _saving = false);
    _snack(ok ? 'Profile saved.' : 'Your profile could not be saved.');
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final key = GlobalKey<FormState>();
    String? error;
    var busy = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) => AlertDialog(
          title: const Text('Change password'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: current,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                    ),
                    validator: (v) => (v ?? '').isEmpty
                        ? 'Enter your current password'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: next,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                    validator: (v) {
                      final value = v ?? '';
                      if (value.length < 8) return 'Use at least 8 characters';
                      if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                          !RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Include a letter and a number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                    validator: (v) =>
                        v != next.text ? 'Passwords do not match' : null,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    FormErrorBanner(error!),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) return;
                      setDialog(() => busy = true);
                      final result = await _auth.changePassword(
                        current.text,
                        next.text,
                      );
                      if (!dialogContext.mounted) return;
                      if (result == null) {
                        Navigator.pop(dialogContext);
                        _snack('Password updated.');
                      } else {
                        setDialog(() {
                          busy = false;
                          error = result;
                        });
                      }
                    },
              child: const Text('Update password'),
            ),
          ],
        ),
      ),
    );
    current.dispose();
    next.dispose();
    confirm.dispose();
  }

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );

  Widget _row(List<Widget> fields) => LayoutBuilder(
    builder: (context, box) => box.maxWidth < 560
        ? Column(children: fields)
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, f) in fields.indexed) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: f),
              ],
            ],
          ),
  );

  Widget _text(
    TextEditingController c,
    String label, {
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final photoBytes = _photo == null || _photo!.isEmpty
        ? null
        : base64Decode(_photo!);
    return PageWidth(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Eyebrow('My account'),
                  const SizedBox(height: 10),
                  Text(
                    'My profile',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 24),
                  _section('Photo and account', [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 20,
                      runSpacing: 14,
                      children: [
                        ProfileAvatar(
                          bytes: photoBytes,
                          name: _name.text,
                          radius: 44,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_auth.role} · ${_auth.email}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: deepBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickPhoto,
                                  icon: const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    photoBytes == null
                                        ? 'Add photo'
                                        : 'Change photo',
                                  ),
                                ),
                                if (photoBytes != null)
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _photo = null),
                                    child: const Text('Remove'),
                                  ),
                                TextButton.icon(
                                  onPressed: _changePassword,
                                  icon: const Icon(Icons.lock_reset, size: 18),
                                  label: const Text('Change password'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your sign-in email cannot be changed here. Contact MT Alchemy to move your account to a new email.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ]),
                  if (_isOrg)
                    _section('Organization details', [
                      _text(
                        _name,
                        'Organization name',
                        icon: Icons.apartment_outlined,
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Enter a name' : null,
                      ),
                      _row([
                        _text(
                          _regNo,
                          'Company registration no.',
                          icon: Icons.assignment_ind_outlined,
                        ),
                        _text(
                          _employees,
                          'Number of employees',
                          icon: Icons.groups_2_outlined,
                          keyboard: TextInputType.number,
                        ),
                      ]),
                      _row([
                        _text(
                          _contact,
                          'Contact person',
                          icon: Icons.person_outline,
                        ),
                        _text(
                          _industry,
                          'Industry',
                          icon: Icons.factory_outlined,
                        ),
                      ]),
                      _row([
                        _text(
                          _phone,
                          'Phone',
                          icon: Icons.phone_outlined,
                          keyboard: TextInputType.phone,
                        ),
                        _text(_country, 'Country', icon: Icons.public),
                      ]),
                      _text(_bio, 'About the organization', maxLines: 3),
                    ])
                  else ...[
                    _section('Personal details', [
                      _text(
                        _name,
                        'Full name',
                        icon: Icons.badge_outlined,
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                      ),
                      _row([
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _dob ?? DateTime(now.year - 25),
                                firstDate: DateTime(now.year - 100),
                                lastDate: DateTime(now.year - 13),
                              );
                              if (picked != null) setState(() => _dob = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date of birth',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              child: Text(
                                _dob == null
                                    ? 'Not set'
                                    : '${_dob!.day.toString().padLeft(2, '0')}/${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}',
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                const [
                                  'Female',
                                  'Male',
                                  'Prefer not to say',
                                ].contains(_gender)
                                ? _gender
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.wc_outlined),
                            ),
                            items: [
                              for (final g in const [
                                'Female',
                                'Male',
                                'Prefer not to say',
                              ])
                                DropdownMenuItem(value: g, child: Text(g)),
                            ],
                            onChanged: (v) => setState(() => _gender = v),
                          ),
                        ),
                      ]),
                      _row([
                        _text(
                          _phone,
                          'Contact number',
                          icon: Icons.phone_outlined,
                          keyboard: TextInputType.phone,
                        ),
                        _text(_country, 'Country', icon: Icons.public),
                      ]),
                      _text(_bio, 'About me', maxLines: 3),
                    ]),
                    _section('Employment', [
                      _row([
                        _text(_jobTitle, 'Job title', icon: Icons.work_outline),
                        _text(
                          _company,
                          'Company',
                          icon: Icons.apartment_outlined,
                        ),
                      ]),
                      _row([
                        _text(
                          _industry,
                          'Industry',
                          icon: Icons.factory_outlined,
                        ),
                        _text(
                          _years,
                          'Years of working experience',
                          icon: Icons.timeline,
                          keyboard: TextInputType.number,
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return null;
                            final n = int.tryParse(t);
                            return n == null || n < 0 || n > 60
                                ? 'Enter a number from 0 to 60'
                                : null;
                          },
                        ),
                      ]),
                    ]),
                    _section('Learning preferences', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final area in const [
                            'Emotional Intelligence',
                            'Mindfulness',
                            'Leadership',
                            'Communication',
                            'Team Effectiveness',
                            'Workplace Well-being',
                            'Personal Development',
                          ])
                            FilterChip(
                              label: Text(area),
                              selected: _areas.contains(area),
                              onSelected: (on) => setState(
                                () =>
                                    on ? _areas.add(area) : _areas.remove(area),
                              ),
                            ),
                        ],
                      ),
                    ]),
                  ],
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      value: _newsletter,
                      onChanged: (v) => setState(() => _newsletter = v),
                      title: const Text(
                        'Email me new courses, insights and events',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save profile'),
                      ),
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, accountDashboard),
                        child: const Text('Go to my dashboard'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round avatar showing the profile photo, or the person's initials.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.bytes,
    required this.name,
    this.radius = 17,
  });
  final Uint8List? bytes;
  final String name;
  final double radius;

  static Uint8List? fromProfile(Map<String, dynamic> profile) {
    final b64 = profile['photoBase64'];
    if (b64 is! String || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: deepBlue,
      backgroundImage: bytes == null ? null : MemoryImage(bytes!),
      child: bytes == null
          ? Text(
              initials.isEmpty ? '?' : initials,
              style: TextStyle(
                color: softYellow,
                fontSize: radius * 0.75,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}
