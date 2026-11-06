import 'auth_prototype_store.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

class PortalPage extends StatelessWidget {
  const PortalPage({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.children,
    this.showTitle = true,
  });

  /// Dashboards show their own header instead of the section title.
  final bool showTitle;
  final String title;
  final String eyebrow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => PageWidth(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle)
          SectionTitle(title, eyebrow: eyebrow)
        else
          const SizedBox(height: 32),
        ...children,
      ],
    ),
  );
}

Widget portalLinks(BuildContext context) => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    if (AuthPrototypeStore.instance.hasRole('Learner') ||
        AuthPrototypeStore.instance.hasRole('Employer'))
      _smallRoute(context, 'My Orders', '/orders', Icons.receipt_long_outlined),
    if (AuthPrototypeStore.instance.hasRole('Learner'))
      _smallRoute(
        context,
        'Digital library',
        '/digital-library',
        Icons.download_outlined,
      ),
    if (AuthPrototypeStore.instance.hasRole('Employer'))
      _smallRoute(
        context,
        'Employer portal',
        '/employer',
        Icons.business_outlined,
      ),
    if (AuthPrototypeStore.instance.hasRole('Admin'))
      _smallRoute(
        context,
        'Admin portal',
        '/admin',
        Icons.admin_panel_settings_outlined,
      ),
  ],
);

Widget _smallRoute(
  BuildContext context,
  String label,
  String route,
  IconData icon,
) => OutlinedButton.icon(
  onPressed: () => go(context, route),
  icon: Icon(icon, size: 18),
  label: Text(label),
);

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => InfoCard(
    child: Row(
      children: [
        Icon(icon, color: purple, size: 32),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  color: deepBlue,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      ],
    ),
  );
}

class PortalAction extends StatelessWidget {
  const PortalAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  @override
  Widget build(BuildContext context) => InfoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: purple, size: 34),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(subtitle),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => go(context, route),
          child: const Text('Open →'),
        ),
      ],
    ),
  );
}
