import 'package:flutter/material.dart';
import '../widgets.dart';
import 'notifications.dart';
import 'auth_prototype_store.dart';

String get accountDashboard => switch (AuthPrototypeStore.instance.role) {
  'Admin' => '/admin',
  'Employer' => '/employer',
  'Trainer' => '/trainer-dashboard',
  _ => '/dashboard',
};

class LearningNavigation extends StatelessWidget {
  const LearningNavigation({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [const NotificationBell(), _menu(context)],
  );

  Widget _menu(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Account navigation',
    icon: const Icon(Icons.menu),
    onSelected: (route) {
      if (route == 'logout') {
        AuthPrototypeStore.instance.signOut();
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      } else {
        navTo(context, route);
      }
    },
    itemBuilder: (_) => [
      const PopupMenuItem(value: '/', child: Text('Home')),
      const PopupMenuItem(value: '/hub', child: Text('Browse courses')),
      if (AuthPrototypeStore.instance.isSignedIn) ...[
        PopupMenuItem(
          value: accountDashboard,
          child: const Text('My dashboard'),
        ),
        const PopupMenuItem(value: '/dashboard', child: Text('My learning')),
        const PopupMenuItem(value: '/profile', child: Text('My profile')),
        const PopupMenuItem(value: 'logout', child: Text('Sign out')),
      ] else
        const PopupMenuItem(value: '/login', child: Text('Sign in')),
    ],
  );
}
