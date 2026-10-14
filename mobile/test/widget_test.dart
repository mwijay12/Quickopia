import 'package:flutter/material.dart';
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

  testWidgets('QuickopiaApp boots to AuthGate, presents Onboarding, and transitions to storefront', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const QuickopiaApp());
    await tester.pumpAndSettle();

    // First boot presents Onboarding with brand and Get Started / Explore
    expect(find.text('Quickopia'), findsWidgets);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);

    // Tap Explore to enter storefront
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();

    // Storefront is visible with active Shop capsule and 4-tab footer
    expect(find.text('Shop'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
}
