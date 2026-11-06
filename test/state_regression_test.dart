import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/commerce/commerce_prototype_store.dart';
import 'package:publicwebsite/data/progress_store.dart';
import 'support/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = CommercePrototypeStore.instance;
  setUp(() async {
    await setUpFakeBackend();
    await store.attach(role: 'Admin', email: 'admin@mtalchemy.demo');
    store.resetDemoData();
    await store.flush();
  });
  test(
    'physical stock is reserved, restored once on failure, and persisted',
    () async {
      final initial = store.productById('mindful-journal')!.stock;
      store.setQuantity('mindful-journal', initial + 10);
      expect(store.cartQuantityFor('mindful-journal'), initial);
      store.setQuantity('mindful-journal', 2);
      final order = store.placeOrder(
        customerName: 'Learner',
        customerEmail: 'learner@mtalchemy.demo',
        customerPhone: '0123456789',
        billingAddress: 'Test',
        address: 'Test street',
        paymentMethod: 'Prototype',
      )!;
      expect(store.productById('mindful-journal')!.stock, initial - 2);
      store.updatePaymentStatus(order.number, 'Failed');
      store.updatePaymentStatus(order.number, 'Failed');
      expect(store.productById('mindful-journal')!.stock, initial);
      expect(store.updatePaymentStatus(order.number, 'Paid'), isTrue);
      expect(store.productById('mindful-journal')!.stock, initial - 2);
      await store.flush();
      await store.load();
      expect(store.orderByNumber(order.number)!.paymentStatus, 'Paid');
      expect(store.productById('mindful-journal')!.stock, initial - 2);
    },
  );

  test(
    'digital resources require paid orders and stay scoped to customer',
    () async {
      store.addToCart('clarity-workbook');
      expect(store.shipping, 0);
      final order = store.placeOrder(
        customerName: 'Learner',
        customerEmail: 'one@example.test',
        customerPhone: '0123456789',
        billingAddress: '',
        address: '',
        paymentMethod: 'Prototype',
      )!;
      expect(order.shippingAddress, isNull);
      expect(store.digitalOrdersFor('one@example.test'), isEmpty);
      store.updatePaymentStatus(order.number, 'Paid');
      expect(store.digitalOrdersFor('one@example.test'), hasLength(1));
      expect(store.digitalOrdersFor('two@example.test'), isEmpty);
    },
  );

  test('progress survives reload and is isolated between learners', () async {
    await selectLearner('one@example.test');
    enrollCourse('mindfulness');
    completedLessons['mindfulness'] = {for (var i = 0; i < 20; i++) i};
    completeCourse('mindfulness', score: 80);
    await saveProgress();
    await selectLearner('two@example.test');
    expect(completedCourses, isEmpty);
    expect(enrolledCourses, isEmpty);
    await selectLearner('one@example.test');
    expect(completedCourses, contains('mindfulness'));
    expect(completedLessons['mindfulness'], hasLength(20));
  });

  test(
    'employer employees and assignments stay scoped to organization',
    () async {
      store.activeEmployer = 'employer@mtalchemy.demo';
      expect(store.employees, isNotEmpty);
      store.activeEmployer = 'another@example.test';
      expect(store.employees, isEmpty);
      expect(store.assignments, isEmpty);
      store.addEmployee(
        name: 'New Learner',
        department: 'Sales',
        email: 'new@example.test',
      );
      store.assignCourse(
        course: 'Mindfulness at Work',
        team: 'Sales',
        due: '30 Nov 2026',
        employeeEmail: 'new@example.test',
      );
      await selectLearner('new@example.test');
      expect(enrolledCourses, contains('mindfulness'));
      completedLessons['mindfulness'] = {0, 1};
      await saveProgress();
      expect(store.assignments.single['progress'], 10);
      store.activeEmployer = 'employer@mtalchemy.demo';
      expect(
        store.employees.any((e) => e['email'] == 'new@example.test'),
        isFalse,
      );
    },
  );

  test(
    'quotation review status survives reload and is customer scoped',
    () async {
      final quote = store.createQuoteRequest(
        customerName: 'Demo',
        organizationName: 'Org',
        email: 'employer@example.test',
        phone: '0123456789',
        lines: [CartLine(product: store.products.first, quantity: 3)],
        requirements: 'Team workshop',
        ownerEmail: 'employer@example.test',
      );
      store.updateQuoteRequest(
        quote.reference,
        status: 'Quoted',
        quotedTotal: 100,
        adminNote: 'Demo response',
      );
      await store.flush();
      await store.load();
      expect(
        store.quoteRequestsFor('employer@example.test').single.status,
        'Quoted',
      );
      expect(store.quoteRequestsFor('someone@example.test'), isEmpty);
    },
  );

  test('enquiry and admin response survive storage reload', () async {
    final enquiry = store.createContactEnquiry(
      name: 'Visitor',
      email: 'visitor@example.test',
      phone: '0123456789',
      organization: 'Example',
      enquiryType: 'Corporate Training',
      message: 'Please send details.',
    );
    store.updateContactEnquiry(
      enquiry.reference,
      status: 'Reviewed',
      adminNote: 'Demo follow-up',
    );
    await store.flush();
    await store.load();
    expect(store.contactEnquiries.single.email, 'visitor@example.test');
    expect(store.contactEnquiries.single.adminNote, 'Demo follow-up');
  });
}
