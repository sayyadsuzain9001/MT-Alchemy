import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../backend/backend.dart';
import '../theme.dart';
import 'auth_prototype_store.dart';

/// In-app notification stored in `notifications`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.route,
    this.read = false,
  });
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? route;
  final bool read;
}

class NotificationService {
  static CollectionReference<Map<String, dynamic>> get _ref =>
      Backend.db.collection('notifications');

  /// Best-effort: a failed notification never blocks the main action.
  static Future<void> send({
    required String recipient,
    required String title,
    required String body,
    String? route,
  }) async {
    if (!Backend.isReady) return;
    try {
      await _ref.add({
        'recipient': recipient.trim().toLowerCase(),
        'title': title,
        'body': body,
        'route': route,
        'read': false,
        'sender': AuthPrototypeStore.instance.email,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static Stream<List<AppNotification>> mine(String email) => _ref
      .where('recipient', isEqualTo: email)
      .snapshots()
      .map(
        (s) => s.docs.map((d) {
          final m = d.data();
          return AppNotification(
            id: d.id,
            title: m['title'] as String? ?? '',
            body: m['body'] as String? ?? '',
            route: m['route'] as String?,
            read: m['read'] as bool? ?? false,
            createdAt:
                DateTime.tryParse(m['createdAt'] as String? ?? '') ??
                DateTime(2026),
          );
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  static Future<void> markRead(Iterable<String> ids) async {
    final batch = Backend.db.batch();
    for (final id in ids) {
      batch.update(_ref.doc(id), {'read': true});
    }
    try {
      await batch.commit();
    } catch (_) {}
  }
}

/// Bell with unread count; opens the list of the user's notifications.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  Stream<List<AppNotification>>? _stream;
  String? _email;

  Stream<List<AppNotification>>? _streamFor(String? email) {
    if (email != _email) {
      _email = email;
      _stream = email == null || !Backend.isReady
          ? null
          : NotificationService.mine(email);
    }
    return _stream;
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AuthPrototypeStore.instance,
    builder: (context, _) {
      final stream = _streamFor(AuthPrototypeStore.instance.email);
      if (stream == null) return const SizedBox.shrink();
      return StreamBuilder<List<AppNotification>>(
        stream: stream,
        builder: (context, snap) {
          final items = snap.data ?? const <AppNotification>[];
          final unread = items.where((n) => !n.read).length;
          return PopupMenuButton<AppNotification?>(
            tooltip: unread == 0
                ? 'Notifications'
                : 'Notifications, $unread unread',
            position: PopupMenuPosition.under,
            onOpened: () {
              if (unread > 0) {
                NotificationService.markRead(
                  items.where((n) => !n.read).map((n) => n.id),
                );
              }
            },
            onSelected: (n) {
              if (n?.route != null) Navigator.pushNamed(context, n!.route!);
            },
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_none, color: deepBlue),
            ),
            itemBuilder: (_) => items.isEmpty
                ? [
                    const PopupMenuItem<AppNotification?>(
                      enabled: false,
                      child: SizedBox(
                        width: 300,
                        child: Text('You are all caught up.'),
                      ),
                    ),
                  ]
                : [
                    for (final n in items.take(8))
                      PopupMenuItem<AppNotification?>(
                        value: n,
                        child: SizedBox(
                          width: 320,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: n.read
                                      ? Colors.transparent
                                      : royalBlue,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: deepBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      n.body,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _ago(n.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
          );
        },
      );
    },
  );
}
