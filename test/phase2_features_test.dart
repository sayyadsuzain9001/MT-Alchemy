import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/commerce/commerce_prototype_store.dart';
import 'package:publicwebsite/data/mock_data.dart';
import 'package:publicwebsite/data/progress_store.dart';
import 'package:publicwebsite/employer/bulk_import.dart';
import 'package:publicwebsite/shared/auth_prototype_store.dart';

import 'support/fake_backend.dart';

void main() {
  setUp(setUpFakeBackend);
  final store = CommercePrototypeStore.instance;

  test('bulk import reads CSV with quotes and skips blank rows', () {
    final rows = readSpreadsheet(
      Uint8List.fromList(
        utf8.encode(
          'Name,Email,Department\n"Tan, Jane",jane@x.com,Sales\n\nAli,ali@x.com,\n',
        ),
      ),
      'staff.csv',
    );
    expect(rows, hasLength(3));
    expect(rows[1], ['Tan, Jane', 'jane@x.com', 'Sales']);
  });

  test('bulk import reads the first sheet of an xlsx file', () {
    final book = Excel.createExcel();
    final sheet = book[book.getDefaultSheet()!];
    sheet.appendRow([TextCellValue('Name'), TextCellValue('Email')]);
    sheet.appendRow([TextCellValue('Jane'), TextCellValue('jane@x.com')]);
    final rows = readSpreadsheet(
      Uint8List.fromList(book.encode()!),
      'staff.xlsx',
    );
    expect(rows.last, ['Jane', 'jane@x.com']);
  });

  test(
    'paid course purchase enrols; failed payment keeps cart and stock',
    () async {
      await signInAs('learner');
      final course = mockCourses.firstWhere((c) => c.id == 'mindfulness');
      final order = store.placeOrder(
        customerName: 'A',
        customerEmail: 'learner@mtalchemy.demo',
        customerPhone: '1',
        billingAddress: 'KL',
        address: '',
        paymentMethod: 'Card •••• 4242',
        paymentStatus: 'Paid',
        items: [
          CartLine(
            product: CommercePrototypeStore.courseProduct(
              courseId: course.id,
              title: course.title,
              price: course.price,
            ),
            quantity: 1,
          ),
        ],
      )!;
      expect(order.fulfilmentStatus, 'Available');
      expect(store.paidCourseIdsFor('learner@mtalchemy.demo'), {'mindfulness'});
      expect(store.digitalOrdersFor('learner@mtalchemy.demo'), isEmpty);
      await selectLearner('learner@mtalchemy.demo');
      expect(enrolledCourses, contains('mindfulness'));

      final stock = store.productById('mindful-journal')!.stock;
      store.addToCart('mindful-journal');
      final failed = store.placeOrder(
        customerName: 'A',
        customerEmail: 'learner@mtalchemy.demo',
        customerPhone: '1',
        billingAddress: 'KL',
        address: 'KL',
        paymentMethod: 'Card •••• 0002',
        paymentStatus: 'Failed',
      )!;
      expect(failed.stockReserved, isFalse);
      expect(store.cartCount, 1);
      expect(store.productById('mindful-journal')!.stock, stock);
    },
  );

  test('employer seats come from paid course orders', () async {
    await signInAs('employer');
    expect(AuthPrototypeStore.instance.role, 'Employer');
    expect(store.purchasedSeats(), isEmpty);
    store.placeOrder(
      customerName: 'ABC',
      customerEmail: 'employer@mtalchemy.demo',
      customerPhone: '1',
      billingAddress: 'KL',
      address: '',
      paymentMethod: 'FPX',
      paymentStatus: 'Paid',
      items: [
        CartLine(
          product: CommercePrototypeStore.courseProduct(
            courseId: 'leadership',
            title: 'Leadership Essentials',
            price: 699,
          ),
          quantity: 4,
        ),
      ],
    );
    expect(store.purchasedSeats()['Leadership Essentials'], 4);
    expect(store.assignedSeats('Leadership Essentials'), 1);
  });

  test('archived and draft courses are hidden from the catalogue', () {
    expect(publishedCourses.length, mockCourses.length);
    expect(
      courseFromJson({
        ...courseToJson(mockCourses.first),
        'status': 'Archived',
      }).isPublished,
      isFalse,
    );
  });
}
