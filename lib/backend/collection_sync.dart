import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'backend.dart';

/// Stable JSON text for a Firestore-compatible value (map keys sorted), used
/// to tell whether a record changed since it was last read or written.
String canonicalJson(Object? value) => jsonEncode(_canonical(value));

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return {for (final k in keys) k: _canonical(value[k])};
  }
  if (value is Iterable) return value.map(_canonical).toList();
  if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
  if (value is num && value == value.roundToDouble() && value.abs() < 1e15) {
    return value.toInt();
  }
  return value;
}

/// Keeps one Firestore collection in step with an in-memory list.
///
/// [listen] subscribes to the records the current user may read and reports
/// every snapshot. [push] writes only records that differ from what was last
/// read or written, and deletes records that were removed locally.
class CollectionSync {
  CollectionSync(this.collection);

  final String collection;
  final Map<String, String> _baseline = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  CollectionReference<Map<String, dynamic>> get ref =>
      Backend.db.collection(collection);

  static String docId(String raw) =>
      raw.replaceAll('/', '_').replaceAll(RegExp(r'\s+'), '_');

  void listen(
    Query<Map<String, dynamic>>? Function(
      CollectionReference<Map<String, dynamic>> ref,
    )
    query, {
    required void Function(List<Map<String, dynamic>> docs) onData,
    required void Function(Object error) onError,
  }) {
    stop();
    final q = query(ref);
    if (q == null) {
      onData(const []);
      return;
    }
    _subscription = q.snapshots().listen((snapshot) {
      _baseline.clear();
      final docs = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _baseline[doc.id] = canonicalJson(data);
        docs.add(data);
      }
      onData(docs);
    }, onError: onError);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _baseline.clear();
  }

  /// Records a document written outside [push] so it is not written again.
  void markSynced(String rawId, Map<String, dynamic> data) =>
      _baseline[docId(rawId)] = canonicalJson(data);

  /// Returns the number of documents written or deleted.
  Future<int> push(
    Map<String, Map<String, dynamic>> current, {
    bool deleteMissing = true,
  }) async {
    final batch = Backend.db.batch();
    var changes = 0;
    current.forEach((rawId, data) {
      final id = docId(rawId);
      final text = canonicalJson(data);
      if (_baseline[id] != text) {
        batch.set(ref.doc(id), data);
        _baseline[id] = text;
        changes++;
      }
    });
    if (deleteMissing) {
      final keep = current.keys.map(docId).toSet();
      for (final id in _baseline.keys.toList()) {
        if (!keep.contains(id)) {
          batch.delete(ref.doc(id));
          _baseline.remove(id);
          changes++;
        }
      }
    }
    if (changes > 0) await batch.commit();
    return changes;
  }
}

/// Runs async writes one after another. When idle it holds no future, so a
/// new write never waits on a future created in an earlier zone or test.
class SerialQueue {
  Future<void>? _tail;
  int _pending = 0;

  Future<void> add(Future<void> Function() op) {
    _pending++;
    final previous = _tail;
    final run = previous == null ? op() : previous.then((_) => op());
    final done = run.whenComplete(() {
      if (--_pending == 0) _tail = null;
    });
    _tail = done.catchError((Object _) {});
    return done;
  }

  Future<void> get idle => _tail ?? Future.value();

  bool get busy => _pending > 0;

  /// True when more operations are queued behind the one running now.
  bool get busyAfterThis => _pending > 1;
}
