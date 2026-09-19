import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validate_card_details/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders main navigation screen with submission title',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CreditCardValidationApp());
    await tester.pumpAndSettle();

    expect(find.text('CardVault Admin'), findsOneWidget);
    expect(find.text('Card Submission'), findsOneWidget);
  });
}
