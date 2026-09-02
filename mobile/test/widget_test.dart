import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickopia/app.dart';
import 'package:quickopia/config/supabase_config.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SupabaseConfig.initialize();
  });

  testWidgets('QuickopiaApp boots to AuthGate and renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const QuickopiaApp());
    await tester.pumpAndSettle();

    expect(find.text('Quickopia'), findsWidgets);
    expect(find.text('Log In'), findsOneWidget);
  });
}
