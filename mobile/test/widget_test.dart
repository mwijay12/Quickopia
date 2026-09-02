import 'package:flutter_test/flutter_test.dart';
import 'package:quickopia/app.dart';

void main() {
  testWidgets('QuickopiaApp boots to splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuickopiaApp());

    // Verify that the splash screen shows the Quickopia brand name
    expect(find.text('Quickopia'), findsOneWidget);
    expect(find.text('On-Demand Shopping & Fast Delivery'), findsOneWidget);
  });
}
