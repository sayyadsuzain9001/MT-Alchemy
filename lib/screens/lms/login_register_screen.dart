import 'package:flutter/material.dart';

import '../../shared/auth_layout.dart';
import '../../shared/auth_prototype_store.dart';

/// Self-service registration for Learner (individual) and Employer
/// (organisation) accounts. Trainer and Admin accounts are created by an
/// administrator only.
class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key, this.employer = false});
  final bool employer;

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool isIndividual = !widget.employer;
  bool obscurePassword = true;
  bool acceptedTerms = false;
  bool termsError = false;
  bool _busy = false;
  String? _error;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final countryController = TextEditingController(text: 'Malaysia');
  final learningAreaController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final contactPersonController = TextEditingController();
  final registrationController = TextEditingController();
  final employeeCountController = TextEditingController();
  DateTime? dateOfBirth;
  bool dobError = false;

  static const _learningAreas = [
    'Emotional Intelligence',
    'Mindfulness',
    'Leadership',
    'Communication',
    'Team Effectiveness',
    'Workplace Well-being',
    'Personal Development',
  ];
  final Set<String> _selectedAreas = {};

  @override
  void dispose() {
    for (final c in [
      nameController,
      emailController,
      passwordController,
      phoneController,
      countryController,
      learningAreaController,
      confirmPasswordController,
      contactPersonController,
      registrationController,
      employeeCountController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? requiredValidator(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Enter $label' : null;

  String? phoneValidator(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Enter a phone number';
    if (digits.length < 8 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// 0 (empty) to 4 (strong).
  int get passwordScore {
    final p = passwordController.text;
    if (p.isEmpty) return 0;
    var score = 0;
    if (p.length >= 8) score++;
    if (p.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p) && RegExp(r'[^A-Za-z0-9]').hasMatch(p)) {
      score++;
    }
    return score.clamp(1, 4);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'Date of birth',
    );
    if (picked != null) {
      setState(() {
        dateOfBirth = picked;
        dobError = false;
      });
    }
  }

  Future<void> submitForm() async {
    final valid = _formKey.currentState!.validate();
    setState(() {
      termsError = !acceptedTerms;
      dobError = isIndividual && dateOfBirth == null;
    });
    if (!valid || !acceptedTerms || dobError || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final role = isIndividual ? 'Learner' : 'Employer';
    final error = await AuthPrototypeStore.instance.registerAccount(
      email: emailController.text,
      password: passwordController.text,
      role: role,
      displayName: nameController.text,
      details: {
        'accountType': isIndividual ? 'Individual' : 'Organization',
        'phone': phoneController.text,
        'country': countryController.text,
        if (isIndividual) 'learningAreas': _selectedAreas.join(', '),
        if (isIndividual && dateOfBirth != null)
          'dateOfBirth': dateOfBirth!.toIso8601String().substring(0, 10),
        if (!isIndividual) 'registrationNumber': registrationController.text,
        if (!isIndividual) 'employeeCount': employeeCountController.text,
        if (!isIndividual) 'organizationName': nameController.text,
        if (!isIndividual) 'industry': learningAreaController.text,
        if (!isIndividual) 'contactPerson': contactPersonController.text,
      },
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Welcome to MT Alchemy, ${nameController.text.trim()}! Your account is ready.',
        ),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      role == 'Employer' ? '/employer' : '/dashboard',
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return AuthLayout(
      panelTitle: isIndividual
          ? 'Grow your emotional intelligence, one lesson at a time.'
          : 'Build resilient, self-aware teams.',
      panelPoints: isIndividual
          ? const [
              (Icons.play_lesson_outlined, 'Self-paced courses with quizzes'),
              (Icons.workspace_premium_outlined, 'Certificates when you pass'),
              (Icons.insights_outlined, 'Progress saved to your account'),
            ]
          : const [
              (Icons.group_add_outlined, 'Invite employees and assign courses'),
              (Icons.bar_chart_outlined, 'Track progress and quiz scores'),
              (Icons.request_quote_outlined, 'Request quotes for programmes'),
            ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          child: const Text('Sign in'),
        ),
      ],
      child: AuthCard(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create your account',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you will use MT Alchemy.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 22),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Individual'),
                      icon: Icon(Icons.person_outline),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Organization'),
                      icon: Icon(Icons.business_outlined),
                    ),
                  ],
                  selected: {isIndividual},
                  onSelectionChanged: _busy
                      ? null
                      : (selection) =>
                            setState(() => isIndividual = selection.first),
                ),
                const SizedBox(height: 22),
                _field(
                  controller: nameController,
                  label: isIndividual ? 'Full name' : 'Organization name',
                  icon: isIndividual
                      ? Icons.badge_outlined
                      : Icons.apartment_outlined,
                  autofill: isIndividual
                      ? AutofillHints.name
                      : AutofillHints.organizationName,
                  validator: (v) => requiredValidator(
                    v,
                    isIndividual ? 'your full name' : 'the organization name',
                  ),
                ),
                if (!isIndividual)
                  _field(
                    controller: contactPersonController,
                    label: 'Contact person',
                    icon: Icons.person_outline,
                    autofill: AutofillHints.name,
                    validator: (v) => requiredValidator(v, 'a contact person'),
                  ),
                _field(
                  controller: emailController,
                  label: isIndividual ? 'Email' : 'Work email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  autofill: AutofillHints.email,
                  validator: validateEmail,
                ),
                _pair(
                  narrow,
                  _field(
                    controller: phoneController,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    autofill: AutofillHints.telephoneNumber,
                    validator: phoneValidator,
                  ),
                  _field(
                    controller: countryController,
                    label: 'Country',
                    icon: Icons.public,
                    autofill: AutofillHints.countryName,
                    validator: (v) => requiredValidator(v, 'your country'),
                  ),
                ),
                if (isIndividual)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _busy ? null : _pickDob,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date of birth',
                          prefixIcon: const Icon(Icons.cake_outlined),
                          suffixIcon: const Icon(Icons.calendar_month_outlined),
                          errorText: dobError
                              ? 'Select your date of birth'
                              : null,
                        ),
                        child: Text(
                          dateOfBirth == null
                              ? 'Select a date'
                              : '${dateOfBirth!.day.toString().padLeft(2, '0')}/${dateOfBirth!.month.toString().padLeft(2, '0')}/${dateOfBirth!.year}',
                          style: TextStyle(
                            color: dateOfBirth == null
                                ? Colors.black45
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!isIndividual)
                  _pair(
                    narrow,
                    _field(
                      controller: registrationController,
                      label: 'Company registration no.',
                      icon: Icons.assignment_ind_outlined,
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) {
                          return 'Enter the registration number';
                        }
                        if (!RegExp(
                          r'^[A-Za-z0-9\-/ ]{5,20}$',
                        ).hasMatch(value)) {
                          return 'Use 5-20 letters, digits or dashes';
                        }
                        return null;
                      },
                    ),
                    _field(
                      controller: employeeCountController,
                      label: 'Number of employees',
                      icon: Icons.groups_2_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n < 1 || n > 1000000) {
                          return 'Enter a number of employees';
                        }
                        return null;
                      },
                    ),
                  ),
                if (isIndividual)
                  FormField<Set<String>>(
                    validator: (_) => _selectedAreas.isEmpty
                        ? 'Pick at least one learning area'
                        : null,
                    builder: (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learning interests',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final area in _learningAreas)
                                FilterChip(
                                  label: Text(area),
                                  selected: _selectedAreas.contains(area),
                                  onSelected: _busy
                                      ? null
                                      : (on) {
                                          setState(
                                            () => on
                                                ? _selectedAreas.add(area)
                                                : _selectedAreas.remove(area),
                                          );
                                          field.didChange(_selectedAreas);
                                        },
                                ),
                            ],
                          ),
                          if (field.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                field.errorText!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  _field(
                    controller: learningAreaController,
                    label: 'Industry',
                    icon: Icons.factory_outlined,
                    validator: (v) => requiredValidator(v, 'your industry'),
                  ),
                _field(
                  controller: passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  autofill: AutofillHints.newPassword,
                  obscureText: obscurePassword,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Use at least 8 characters';
                    }
                    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                        !RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Include at least one letter and one number';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    tooltip: obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                  bottom: _PasswordStrength(score: passwordScore),
                ),
                _field(
                  controller: confirmPasswordController,
                  label: 'Confirm password',
                  icon: Icons.lock_reset_outlined,
                  obscureText: true,
                  validator: (value) => value != passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                Material(
                  type: MaterialType.transparency,
                  child: CheckboxListTile(
                    value: acceptedTerms,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() {
                            acceptedTerms = v ?? false;
                            if (acceptedTerms) termsError = false;
                          }),
                    title: const Text(
                      'I agree to the MT Alchemy terms of use and privacy notice.',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: termsError
                        ? Text(
                            'Please accept the terms to continue',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                if (_error != null) ...[
                  FormErrorBanner(_error!),
                  const SizedBox(height: 14),
                ],
                BusyButton(
                  busy: _busy,
                  onPressed: submitForm,
                  label: isIndividual
                      ? 'Create learner account'
                      : 'Create organization account',
                  icon: Icons.person_add_alt_1,
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Already registered?'),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
                const Text(
                  'Trainer and administrator accounts are created by MT Alchemy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black45, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pair(bool narrow, Widget a, Widget b) => narrow
      ? Column(children: [a, b])
      : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ],
        );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    IconData? icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? autofill,
    Widget? suffixIcon,
    Widget? bottom,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: !_busy,
            validator: validator,
            onChanged: onChanged,
            textInputAction: TextInputAction.next,
            autofillHints: autofill == null ? null : [autofill],
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: icon == null ? null : Icon(icon),
              suffixIcon: suffixIcon,
            ),
          ),
          ?bottom,
        ],
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    if (score == 0) return const SizedBox.shrink();
    const labels = ['Weak', 'Fair', 'Good', 'Strong'];
    const colors = [
      Color(0xFFC62828),
      Color(0xFFEF6C00),
      Color(0xFF2E7D32),
      Color(0xFF1B5E20),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
      child: Row(
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: i < score
                      ? colors[score - 1]
                      : const Color(0xFFE6E3EE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            labels[score - 1],
            style: TextStyle(
              fontSize: 12,
              color: colors[score - 1],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
