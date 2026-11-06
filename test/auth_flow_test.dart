import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/main.dart';
import 'package:publicwebsite/shared/auth_prototype_store.dart';
import 'support/fake_backend.dart';

void main() {
  setUp(setUpFakeBackend);

  testWidgets('admin login opens the protected admin dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const MtAlchemyApp());
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pushNamed('/admin');
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@mtalchemy.demo',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'AlchemyAdmin!26');
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();

    expect(find.text('Platform operations at a glance.'), findsOneWidget);
    expect(AuthPrototypeStore.instance.role, 'Admin');
  });

  testWidgets('registration creates and signs in a learner account', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MtAlchemyApp());
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pushNamed('/register');
    await tester.pumpAndSettle();

    final email = 'new-${DateTime.now().microsecondsSinceEpoch}@example.test';
    Future<void> type(String label, String value) async {
      final field = find.widgetWithText(TextFormField, label);
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }

    await type('Full name', 'Test Learner');
    await type('Email', email);
    await type('Phone', '0123456789');
    await type('Password', 'CorrectHorse1!');
    await type('Confirm password', 'CorrectHorse1!');
    await tester.tap(find.text('Leadership'));
    await tester.tap(find.text('Select a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final submit = find.text('Create learner account');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Learner Dashboard'), findsOneWidget);
    expect(AuthPrototypeStore.instance.email, email);
    expect(AuthPrototypeStore.instance.role, 'Learner');
    final profile = await fakeDb.collection('users').doc('uid-$email').get();
    expect(profile.data()!['role'], 'Learner');
    expect(profile.data()!['learningAreas'], 'Leadership');
    expect(profile.data()!['dateOfBirth'], isNotNull);
  });

  testWidgets('registration validates required fields and terms', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MtAlchemyApp());
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed('/register');
    await tester.pumpAndSettle();
    final submit = find.text('Create learner account');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Pick at least one learning area'), findsOneWidget);
    expect(find.text('Please accept the terms to continue'), findsOneWidget);
    expect(find.text('Select your date of birth'), findsOneWidget);
    expect(AuthPrototypeStore.instance.isSignedIn, isFalse);
  });

  testWidgets('learner credentials cannot open the admin dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const MtAlchemyApp());
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pushNamed('/admin');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'learner@mtalchemy.demo',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'AlchemyLearner!26',
    );
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('This page requires a Admin account.'),
      findsOneWidget,
    );
    expect(find.text('Platform operations at a glance.'), findsNothing);
    expect(AuthPrototypeStore.instance.isSignedIn, isFalse);
  });
}
