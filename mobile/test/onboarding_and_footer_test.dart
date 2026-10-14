import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickopia/config/supabase_config.dart';
import 'package:quickopia/models/category_model.dart';
import 'package:quickopia/models/product_model.dart';
import 'package:quickopia/models/profile_model.dart';
import 'package:quickopia/providers/admin_provider.dart';
import 'package:quickopia/providers/auth_provider.dart';
import 'package:quickopia/providers/cart_provider.dart';
import 'package:quickopia/providers/catalog_provider.dart';
import 'package:quickopia/providers/driver_orders_provider.dart';
import 'package:quickopia/providers/favorites_provider.dart';
import 'package:quickopia/providers/order_history_provider.dart';
import 'package:quickopia/screens/customer/customer_shell.dart';
import 'package:quickopia/screens/onboarding/onboarding_screen.dart';
import 'package:quickopia/widgets/floating_pill_bottom_bar.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  AuthStatus status = AuthStatus.authenticated;
  @override
  Profile? profile = Profile(
    id: 'cust-99',
    fullName: 'Fatma Ally',
    role: 'customer',
    phone: '+255711223344',
  );
  @override
  String? errorMessage;

  @override
  bool get isAuthenticated => true;
  @override
  Future<String?> signIn({required String email, required String password}) async => null;
  @override
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async => {'success': true};
  @override
  Future<void> signOut() async {}
  @override
  Future<void> reloadProfile() async {}
}

class MockCatalogProvider extends ChangeNotifier implements CatalogProvider {
  @override
  CatalogStatus status = CatalogStatus.loaded;
  @override
  String? errorMessage;
  @override
  List<Category> categories = [Category(id: 'cat-1', name: 'Fresh Vegetables', displayOrder: 1)];
  @override
  List<Product> products = [
    Product(
      id: 'prod-1',
      categoryId: 'cat-1',
      title: 'Fresh Carrots',
      priceTzs: 1500,
      unit: '1 bundle',
      stockQuantity: 25,
      isAvailable: true,
      isPopular: true,
    ),
  ];
  @override
  String? selectedCategoryId;
  @override
  String searchQuery = '';

  @override
  Future<void> loadInitialData() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> search(String query) async {}
  @override
  Future<void> selectCategory(String? categoryId) async {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SupabaseConfig.initialize();
  });

  group('FloatingPillBottomBar Widget Tests', () {
    testWidgets('renders 4 items and shows ONLY active tab label while inactive tabs hide labels', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingPillBottomBar(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
              cartBadgeCount: 3,
            ),
          ),
        ),
      );

      // Only tab 0 ('Shop') label is visible!
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Cart'), findsNothing);
      expect(find.text('My Orders'), findsNothing);
      expect(find.text('Account'), findsNothing);

      // All 4 icons exist
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);

      // Cart badge is visible on inactive cart icon
      expect(find.text('3'), findsOneWidget);

      // Tap on Cart (index 1)
      await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
      expect(tappedIndex, 1);
    });

    testWidgets('when currentIndex is 1 (Cart), reveals Cart label and hides others', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingPillBottomBar(
              currentIndex: 1,
              onTap: (_) {},
              cartBadgeCount: 0,
            ),
          ),
        ),
      );

      expect(find.text('Cart'), findsOneWidget);
      expect(find.text('Shop'), findsNothing);
      expect(find.text('My Orders'), findsNothing);
      expect(find.text('Account'), findsNothing);
      expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget);
    });
  });

  group('CustomerShell with 4 Tabs', () {
    testWidgets('CustomerShell navigates through all 4 tabs and displays corresponding active capsule labels', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final authProvider = MockAuthProvider();
      final catalogProvider = MockCatalogProvider();
      final cartProvider = CartProvider();
      final favoritesProvider = FavoritesProvider();
      final orderHistoryProvider = OrderHistoryProvider();
      final adminProvider = AdminProvider();
      final driverOrdersProvider = DriverOrdersProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<CatalogProvider>.value(value: catalogProvider),
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<FavoritesProvider>.value(value: favoritesProvider),
            ChangeNotifierProvider<OrderHistoryProvider>.value(value: orderHistoryProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
            ChangeNotifierProvider<DriverOrdersProvider>.value(value: driverOrdersProvider),
          ],
          child: const MaterialApp(
            home: CustomerShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts on tab 0 (Shop)
      expect(find.descendant(of: find.byType(FloatingPillBottomBar), matching: find.text('Shop')), findsOneWidget);
      expect(find.text('Quickopia'), findsWidgets);

      // Tap tab 1 (Cart)
      await tester.tap(find.descendant(
        of: find.byType(FloatingPillBottomBar),
        matching: find.byIcon(Icons.shopping_bag_outlined),
      ));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(FloatingPillBottomBar), matching: find.text('Cart')), findsOneWidget);
      expect(find.text('Your Cart is Empty'), findsOneWidget);

      // Empty cart 'Start Shopping' button returns to tab 0 (Shop)
      await tester.tap(find.text('Start Shopping'));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(FloatingPillBottomBar), matching: find.text('Shop')), findsOneWidget);

      // Tap tab 2 (My Orders)
      await tester.tap(find.descendant(
        of: find.byType(FloatingPillBottomBar),
        matching: find.byIcon(Icons.receipt_long_outlined),
      ));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(FloatingPillBottomBar), matching: find.text('My Orders')), findsOneWidget);

      // Tap tab 3 (Account)
      await tester.tap(find.descendant(
        of: find.byType(FloatingPillBottomBar),
        matching: find.byIcon(Icons.person_outline),
      ));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(FloatingPillBottomBar), matching: find.text('Account')), findsOneWidget);
      expect(find.text('Fatma Ally'), findsOneWidget);
      expect(find.text('App Welcome & Onboarding'), findsOneWidget);
    });
  });

  group('OnboardingScreen Tests', () {
    testWidgets('renders headline, hero visual, and Get Started/Explore buttons', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Top branding
      expect(find.text('Quickopia'), findsOneWidget);

      // Headline
      expect(find.text('Explore the\nfreshness you love,\nall in one place'), findsOneWidget);

      // Buttons
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
    });

    testWidgets('tapping Explore marks onboarding completed', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final authProvider = MockAuthProvider();
      final catalogProvider = MockCatalogProvider();
      final cartProvider = CartProvider();
      final favoritesProvider = FavoritesProvider();
      final orderHistoryProvider = OrderHistoryProvider();
      final adminProvider = AdminProvider();
      final driverOrdersProvider = DriverOrdersProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<CatalogProvider>.value(value: catalogProvider),
            ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
            ChangeNotifierProvider<FavoritesProvider>.value(value: favoritesProvider),
            ChangeNotifierProvider<OrderHistoryProvider>.value(value: orderHistoryProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
            ChangeNotifierProvider<DriverOrdersProvider>.value(value: driverOrdersProvider),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();

      // Verify that onboarding was completed
      final completed = await OnboardingScreen.hasSeenOnboarding();
      expect(completed, isTrue);

      // Customer storefront is now rendered with Shop active
      expect(find.text('Shop'), findsOneWidget);
    });
  });
}
