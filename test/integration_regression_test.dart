import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/main.dart';
import 'support/fake_backend.dart';
import 'package:publicwebsite/shared/auth_prototype_store.dart';
import 'package:publicwebsite/commerce/commerce_prototype_store.dart';
import 'package:publicwebsite/data/progress_store.dart';
import 'package:publicwebsite/screens/lms/learner_dashboard_screen.dart';

void main() {
  final auth = AuthPrototypeStore.instance;
  final store = CommercePrototypeStore.instance;
  setUp(setUpFakeBackend);

  testWidgets('certificate deep link cannot award completion', (tester) async {
    await auth.signIn('learner@mtalchemy.demo', 'AlchemyLearner!26');
    await tester.pumpWidget(const MtAlchemyApp());
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed('/certificate', arguments: {'courseId': 'mindfulness'});
    await tester.pumpAndSettle();
    expect(
      find.text('Pass the course quiz to earn your certificate.'),
      findsOneWidget,
    );
    expect(completedCourses, isEmpty);
  });

  testWidgets('selected course survives login and enrollment redirect', (
    tester,
  ) async {
    await tester.pumpWidget(const MtAlchemyApp());
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed('/enroll', arguments: 'mindfulness');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'learner@mtalchemy.demo',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'AlchemyLearner!26',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    // Paid course: the selected course's payment page opens after sign-in.
    expect(find.text('Mindfulness at Work'), findsWidgets);
    expect(enrolledCourses, isNot(contains('mindfulness')));
    final pay = find.textContaining('and enrol');
    await tester.ensureVisible(pay);
    await tester.tap(pay);
    await tester.pumpAndSettle();
    Future<void> type(String label, String value) =>
        tester.enterText(find.widgetWithText(TextFormField, label), value);
    await type('Name on card', 'Aisha Rahman');
    await type('Card number', '4242 4242 4242 4242');
    await type('Expiry', '12/30');
    await type('CVC', '123');
    await tester.tap(find.text('Pay RM 399.00'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(enrolledCourses, contains('mindfulness'));
    expect(
      CommercePrototypeStore.instance.paidCourseIdsFor(
        'learner@mtalchemy.demo',
      ),
      contains('mindfulness'),
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('public and portal routes render at width $width', (
      tester,
    ) async {
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        previousErrorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MtAlchemyApp());
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      for (final route in [
        '/',
        '/about',
        '/coaching',
        '/upskilling',
        '/product',
        '/register',
        '/services',
        '/organizations',
        '/programmes',
        '/impact',
        '/insights',
        '/contact',
        '/sitemap',
        '/hub',
        '/course-detail',
        '/store',
        '/cart',
        '/quote-request',
      ]) {
        navigator.pushNamed(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
        navigator.pop();
        await tester.pumpAndSettle();
      }
      for (final account in [
        (
          'learner',
          'AlchemyLearner!26',
          [
            '/dashboard',
            '/course-player',
            '/quiz',
            '/orders',
            '/digital-library',
          ],
        ),
        (
          'employer',
          'AlchemyEmployer!26',
          [
            '/employer',
            '/employees',
            '/assign-course',
            '/reports',
            '/quote-requests',
          ],
        ),
        (
          'admin',
          'AlchemyAdmin!26',
          [
            '/admin',
            '/admin/products',
            '/admin/courses',
            '/profile',
            '/admin/orders',
            '/admin/quotes',
            '/admin/enquiries',
          ],
        ),
        ('trainer', 'AlchemyTrainer!26', ['/trainer-dashboard']),
      ]) {
        await auth.signIn('${account.$1}@mtalchemy.demo', account.$2);
        for (final route in account.$3) {
          navigator.pushNamed(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: route);
          navigator.pop();
          await tester.pumpAndSettle();
        }
      }
    });
  }
  testWidgets('quiz requires answers and passing quiz unlocks certificate', (
    tester,
  ) async {
    await auth.signIn('learner@mtalchemy.demo', 'AlchemyLearner!26');
    enrollCourse('ei-fundamentals');
    completedLessons['ei-fundamentals'] = {for (var i = 0; i < 20; i++) i};
    await tester.pumpWidget(const MtAlchemyApp());
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const LearnerDashboardScreen()),
    );
    await tester.pumpAndSettle();
    final viewCourse = find
        .widgetWithText(FilledButton, 'Continue Course')
        .first;
    await tester.ensureVisible(viewCourse);
    await tester.tap(viewCourse);
    await tester.pumpAndSettle();
    navigator.pushNamed('/quiz', arguments: 'ei-fundamentals');
    await tester.pumpAndSettle();
    Future<void> click(String label) async {
      final target = find.text(label).last;
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await click('Next');
    expect(find.text('Choose an answer to continue'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await click('Self-awareness');
    await click('Next');
    await click('True');
    await click('Next');
    await click('Self-regulation');
    await click('Empathy');
    await click('Social skills');
    await click('Next');
    await tester.enterText(find.byType(TextFormField), 'Empathy');
    await click('Next');
    await click('Pause, breathe and ask for specific examples');
    await click('Submit');
    expect(completedCourses, contains('ei-fundamentals'));
    navigator.pop();
    await tester.pumpAndSettle();
    navigator.pop();
    await tester.pumpAndSettle();
    final completedStat = find
        .ancestor(of: find.text('Completed'), matching: find.byType(Column))
        .first;
    expect(
      find.descendant(of: completedStat, matching: find.text('1')),
      findsOneWidget,
    );
    final inProgressStat = find
        .ancestor(of: find.text('In Progress'), matching: find.byType(Column))
        .first;
    expect(
      find.descendant(of: inProgressStat, matching: find.text('0')),
      findsOneWidget,
    );
    expect(find.text('Certificates'), findsWidgets);
    await saveProgress();
    await selectLearner(null);
    await selectLearner('learner@mtalchemy.demo');
    expect(completedCourses, contains('ei-fundamentals'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('contact validates empty fields and stores an enquiry', (
    tester,
  ) async {
    await tester.pumpWidget(const MtAlchemyApp());
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed('/contact');
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Submit enquiry');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(store.contactEnquiries, isEmpty);
    final values = [
      'Demo Visitor',
      'visitor@example.test',
      '0123456789',
      'Demo Org',
      'Please send programme information.',
    ];
    for (var i = 0; i < values.length; i++) {
      final field = find.byType(TextFormField).at(i);
      await tester.ensureVisible(field);
      await tester.enterText(field, values[i]);
    }
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corporate Training').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(store.contactEnquiries, hasLength(1));
    expect(store.contactEnquiries.single.email, 'visitor@example.test');
    expect(tester.takeException(), isNull);
  });
}
