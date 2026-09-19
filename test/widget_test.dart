import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validate_card_details/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders splash screen and transitions to main navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CreditCardValidationApp());

    // Verify splash screen branding
    expect(find.text('CardVault Pro'), findsOneWidget);

    // Fast-forward splash timer (2.2s + transition)
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify main navigation screen renders
    expect(find.text('CardVault Admin'), findsOneWidget);
    expect(find.text('Card Submission'), findsOneWidget);
  });
}
