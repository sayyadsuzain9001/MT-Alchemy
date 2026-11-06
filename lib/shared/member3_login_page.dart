import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';
import '../backend/app_config.dart';
import 'auth_layout.dart';
import 'auth_prototype_store.dart';
import 'learning_navigation.dart';

class Member3LoginPage extends StatefulWidget {
  const Member3LoginPage({
    super.key,
    this.redirectRoute,
    this.redirectArguments,
    this.requiredRole,
    this.allowedRoles,
  });
  final String? redirectRoute;
  final Object? redirectArguments;
  final String? requiredRole;
  final List<String>? allowedRoles;

  @override
  State<Member3LoginPage> createState() => _Member3LoginPageState();
}

class Member3AccessDeniedPage extends StatelessWidget {
  const Member3AccessDeniedPage({super.key, required this.requiredRole});
  final String requiredRole;

  @override
  Widget build(BuildContext context) => PageWidth(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: InfoCard(
        child: Column(
          children: [
            const Icon(
              Icons.admin_panel_settings_outlined,
              size: 54,
              color: deepBlue,
            ),
            const SizedBox(height: 18),
            Text(
              'Workspace access required',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'This page is for a $requiredRole account. Sign out and sign in with an account that has access.',
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                AuthPrototypeStore.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.switch_account_outlined),
              label: const Text('Switch account'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Member3LoginPageState extends State<Member3LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _busy = false;
  String? _error;

  static const _demoAccounts = [
    (
      'Learner',
      'learner@mtalchemy.demo',
      'AlchemyLearner!26',
      Icons.school_outlined,
    ),
    (
      'Trainer',
      'trainer@mtalchemy.demo',
      'AlchemyTrainer!26',
      Icons.co_present_outlined,
    ),
    (
      'Employer',
      'employer@mtalchemy.demo',
      'AlchemyEmployer!26',
      Icons.business_center_outlined,
    ),
    (
      'Admin',
      'admin@mtalchemy.demo',
      'AlchemyAdmin!26',
      Icons.admin_panel_settings_outlined,
    ),
  ];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = AuthPrototypeStore.instance;
    final role = await auth.signIn(_email.text, _password.text);
    if (!mounted) return;
    if (role == null) {
      setState(() {
        _busy = false;
        _error = auth.lastError ?? 'Email or password is incorrect.';
      });
      return;
    }
    if (widget.allowedRoles != null && !widget.allowedRoles!.contains(role)) {
      await auth.signOut();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            'This page requires a ${widget.requiredRole} account. You signed in as $role.';
      });
      return;
    }
    final destination = widget.redirectRoute ?? accountDashboard;
    Navigator.pushNamedAndRemoveUntil(
      context,
      destination,
      (route) => route.isFirst && destination != '/',
      arguments: widget.redirectArguments,
    );
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text.trim());
    final key = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset your password'),
        content: Form(
          key: key,
          child: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your account email and we will send you a reset link.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: validateEmail,
                ),
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
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || !mounted) return;
    final error = await AuthPrototypeStore.instance.sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              'If an account exists for $email, a reset link is on its way.',
        ),
      ),
    );
  }

  void _useDemo(String email, String password) {
    setState(() {
      _email.text = email;
      _password.text = password;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthLayout(
      panelTitle: 'One sign-in for every MT Alchemy workspace.',
      panelPoints: const [
        (
          Icons.school_outlined,
          'Learners continue courses, quizzes and certificates',
        ),
        (
          Icons.co_present_outlined,
          'Trainers review assessments and learner progress',
        ),
        (
          Icons.business_center_outlined,
          'Employers assign courses and track team reports',
        ),
        (
          Icons.admin_panel_settings_outlined,
          'Admins manage products, orders, quotes and enquiries',
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
          child: const Text('Create account'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthCard(
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome back', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text(
                      widget.requiredRole == null
                          ? 'Sign in to continue to your workspace.'
                          : 'Sign in with a ${widget.requiredRole} account to continue.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: validateEmail,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _hidePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _forgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    if (_error != null) ...[
                      FormErrorBanner(_error!),
                      const SizedBox(height: 14),
                    ],
                    BusyButton(
                      busy: _busy,
                      onPressed: _submit,
                      label: 'Sign in',
                      icon: Icons.login,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('New to MT Alchemy?'),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            '/register',
                          ),
                          child: const Text('Create an account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (AppConfig.showDemoAccounts) ...[
            const SizedBox(height: 18),
            _DemoAccounts(accounts: _demoAccounts, onPick: _useDemo),
          ],
        ],
      ),
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.accounts, required this.onPick});
  final List<(String, String, String, IconData)> accounts;
  final void Function(String email, String password) onPick;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F1FB),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo accounts',
          style: TextStyle(fontWeight: FontWeight.w700, color: deepBlue),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap a role to fill in its details, then sign in.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (role, email, password, icon) in accounts)
              ActionChip(
                avatar: Icon(icon, size: 18, color: deepBlue),
                label: Text(role),
                tooltip: email,
                backgroundColor: Colors.white,
                onPressed: () => onPick(email, password),
              ),
          ],
        ),
      ],
    ),
  );
}
