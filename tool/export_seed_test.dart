// Regenerates firebase_seed/seed_data.json from the app's starter data.
// Run: flutter test tool/export_seed_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/commerce/commerce_prototype_store.dart';
import 'package:publicwebsite/data/mock_data.dart';

void main() {
  test('export seed data', () {
    final data = {
      'products': {
        for (final (i, p) in CommercePrototypeStore.starterProducts.indexed)
          p.id: {...p.toJson(), 'position': i},
      },
      'courses': {
        for (final (i, c) in seedCourses.indexed)
          c.id: {...courseToJson(c), 'position': i, 'pdfChunks': 0},
      },
      'employees': {
        for (final e in CommercePrototypeStore.starterEmployees)
          CommercePrototypeStore.employeeDocId(e): e,
      },
      'assignments': {
        for (final a in CommercePrototypeStore.starterAssignments)
          CommercePrototypeStore.assignmentDocId(a).replaceAll(' ', '_'): a,
      },
    };
    File('firebase_seed/seed_data.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  });
}
