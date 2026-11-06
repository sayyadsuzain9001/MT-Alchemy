import 'package:flutter/material.dart';

import '../theme.dart';

/// Split layout shared by Sign in and Register: a brand panel with the
/// platform's promise on wide screens, and the form card on the right.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    required this.panelTitle,
    required this.panelPoints,
    this.actions = const [],
  });

  final Widget child;
  final String panelTitle;
  final List<(IconData, String)> panelPoints;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final form = Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width < 500 ? 16 : 32,
          vertical: 32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: InkWell(
          onTap: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
          borderRadius: BorderRadius.circular(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo_mt_alchemy.jpeg',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MT Alchemy',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        actions: [...actions, const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  Expanded(flex: 5, child: _BrandPanel(this)),
                  Expanded(flex: 6, child: form),
                ],
              )
            : form,
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel(this.layout);
  final AuthLayout layout;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(24, 8, 0, 24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      image: const DecorationImage(
        image: AssetImage('assets/images/workshop_group_activity.jpeg'),
        fit: BoxFit.cover,
      ),
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            deepBlue.withValues(alpha: 0.72),
            deepBlue.withValues(alpha: 0.96),
          ],
        ),
      ),
      padding: const EdgeInsets.all(44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'PEOPLE FIRST. POSSIBILITY ALWAYS.',
            style: TextStyle(
              color: softYellow,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            layout.panelTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 28),
          for (final (icon, text) in layout.panelPoints)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: softYellow.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: softYellow, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// White rounded card that holds an auth form.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 500 ? 22 : 36),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8E5F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F16105B),
          blurRadius: 30,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: child,
  );
}

/// Inline error banner for form-level failures.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB3261E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF8C1D18), height: 1.35),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Filled button that shows a spinner and blocks repeat taps while busy.
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.busy,
    required this.onPressed,
    required this.label,
    this.icon,
  });
  final bool busy;
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      disabledBackgroundColor: deepBlue.withValues(alpha: 0.7),
      disabledForegroundColor: Colors.white,
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: busy
          ? const SizedBox(
              key: ValueKey('busy'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Row(
              key: const ValueKey('idle'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
    ),
  );
}

final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Enter your email address';
  return emailPattern.hasMatch(value.trim())
      ? null
      : 'Enter a valid email address';
}
