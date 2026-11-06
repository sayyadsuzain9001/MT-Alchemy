import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/main.dart';
import 'support/fake_backend.dart';

void main() {
  setUp(setUpFakeBackend);
  testWidgets('loads the Member 1 home page and navigation', (tester) async {
    await tester.pumpWidget(const MtAlchemyApp());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Elevate your value: Master human intelligence in a rapidly evolving AI-driven world.',
      ),
      findsOneWidget,
    );
    expect(find.text('MT ALCHEMY'), findsWidgets);
  });
}
