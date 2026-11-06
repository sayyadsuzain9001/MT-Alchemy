import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:publicwebsite/backend/backend.dart';
import 'package:publicwebsite/backend/collection_sync.dart';
import 'package:publicwebsite/chat/chat_widget.dart';
import 'package:publicwebsite/commerce/commerce_prototype_store.dart';
import 'package:publicwebsite/data/mock_data.dart';
import 'package:publicwebsite/shared/auth_prototype_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const demoAccounts = {
  'learner@mtalchemy.demo': (
    'AlchemyLearner!26',
    'Learner',
    'MT Alchemy Learner',
  ),
  'trainer@mtalchemy.demo': (
    'AlchemyTrainer!26',
    'Trainer',
    'MT Alchemy Trainer',
  ),
  'employer@mtalchemy.demo': ('AlchemyEmployer!26', 'Employer', 'ABC Sdn Bhd'),
  'admin@mtalchemy.demo': ('AlchemyAdmin!26', 'Admin', 'MT Alchemy Admin'),
};

late FakeFirebaseFirestore fakeDb;

/// Fresh in-memory Firestore + auth with the same seed data as the
/// emulator seed script.
Future<void> setUpFakeBackend() async {
  ChatOverlay.enabled = false;
  SharedPreferences.setMockInitialValues({});
  fakeDb = FakeFirebaseFirestore();
  Backend.configure(
    db: fakeDb,
    auth: InMemoryAuthGateway({
      for (final e in demoAccounts.entries) e.key: e.value.$1,
    }),
  );
  for (final e in demoAccounts.entries) {
    await fakeDb.collection('users').doc('uid-${e.key}').set({
      'email': e.key,
      'role': e.value.$2,
      'displayName': e.value.$3,
    });
  }
  for (final (i, p) in CommercePrototypeStore.starterProducts.indexed) {
    await fakeDb.collection('products').doc(p.id).set({
      ...p.toJson(),
      'position': i,
    });
  }
  for (final e in CommercePrototypeStore.starterEmployees) {
    await fakeDb
        .collection('employees')
        .doc(CollectionSync.docId(CommercePrototypeStore.employeeDocId(e)))
        .set(e);
  }
  for (final a in CommercePrototypeStore.starterAssignments) {
    await fakeDb
        .collection('assignments')
        .doc(CollectionSync.docId(CommercePrototypeStore.assignmentDocId(a)))
        .set(a);
  }
  mockCourses
    ..clear()
    ..addAll(seedCourses);
  await AuthPrototypeStore.instance.signOut();
  await CommercePrototypeStore.instance.load();
}

Future<String?> signInAs(String role) {
  final email = '${role.toLowerCase()}@mtalchemy.demo';
  return AuthPrototypeStore.instance.signIn(email, demoAccounts[email]!.$1);
}
