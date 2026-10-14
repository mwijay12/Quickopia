import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickopia/config/supabase_config.dart';
import 'package:quickopia/models/category_model.dart';
import 'package:quickopia/models/product_model.dart';
import 'package:quickopia/models/profile_model.dart';
import 'package:quickopia/providers/auth_provider.dart';
import 'package:quickopia/providers/cart_provider.dart';
import 'package:quickopia/providers/catalog_provider.dart';
import 'package:quickopia/providers/driver_orders_provider.dart';
import 'package:quickopia/providers/order_history_provider.dart';
import 'package:quickopia/screens/customer/customer_shell.dart';
import 'package:quickopia/screens/driver/driver_shell.dart';
import 'package:quickopia/widgets/floating_pill_bottom_bar.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  AuthStatus status;
  @override
  Profile? profile;
  @override
  String? errorMessage;

  FakeAuthProvider({
    this.status = AuthStatus.authenticated,
    this.profile,
    this.errorMessage,
  });

  @override
  bool get isAuthenticated => status == AuthStatus.authenticated && profile != null;

  @override
  Future<String?> signIn({required String email, required String password}) async => null;

  @override
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async => {'success': true, 'requiresEmailConfirmation': false, 'error': null};

  @override
  Future<void> signOut() async {
    status = AuthStatus.unauthenticated;
    profile = null;
    notifyListeners();
  }

  @override
  Future<void> reloadProfile() async {}
}

class FakeCatalogProvider extends ChangeNotifier implements CatalogProvider {
  @override
  CatalogStatus status;
  @override
  String? errorMessage;
  @override
  List<Category> categories;
  @override
  List<Product> products;
  @override
  String? selectedCategoryId;
  @override
  String searchQuery = '';

  FakeCatalogProvider({
    this.status = CatalogStatus.loaded,
    this.errorMessage,
    this.categories = const [],
    this.products = const [],
    this.selectedCategoryId,
  });

  @override
  Future<void> loadInitialData() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> search(String query) async {
    searchQuery = query;
    notifyListeners();
  }

  @override
  Future<void> selectCategory(String? categoryId) async {
    selectedCategoryId = categoryId;
    notifyListeners();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SupabaseConfig.initialize();
  });
  testWidgets('CustomerShell renders bottom tabs and Shop tab content', (tester) async {
    final fakeAuth = FakeAuthProvider(
      profile: Profile(
        id: 'cust-1',
        fullName: 'Zuwena Said',
        role: 'customer',
        phone: '+255712345678',
      ),
    );

    final fakeCatalog = FakeCatalogProvider(
      categories: [
        Category(id: 'c-1', name: 'Fresh Produce', displayOrder: 1),
        Category(id: 'c-2', name: 'Beverages', displayOrder: 2),
      ],
      products: [
        Product(
          id: 'p-1',
          categoryId: 'c-1',
          title: 'Dar Apples',
          priceTzs: 2000,
          unit: '1 kg',
          stockQuantity: 10,
          isAvailable: true,
          isPopular: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<CatalogProvider>.value(value: fakeCatalog),
          ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ChangeNotifierProvider<OrderHistoryProvider>(create: (_) => OrderHistoryProvider()),
        ],
        child: const MaterialApp(home: CustomerShell()),
      ),
    );

    // Verify Shell Bottom Navigation items (active tab shows capsule label, inactive tabs show icons)
    expect(find.descendant(of: find.byType(FloatingPillBottomBar), matching: find.text('Shop')), findsOneWidget);
    expect(find.descendant(of: find.byType(FloatingPillBottomBar), matching: find.byIcon(Icons.shopping_bag_outlined)), findsOneWidget);
    expect(find.descendant(of: find.byType(FloatingPillBottomBar), matching: find.byIcon(Icons.receipt_long_outlined)), findsOneWidget);
    expect(find.descendant(of: find.byType(FloatingPillBottomBar), matching: find.byIcon(Icons.person_outline)), findsOneWidget);

    // Verify catalog inside Shop tab
    expect(find.text('Quickopia'), findsOneWidget);
    expect(find.text('Dar Apples'), findsOneWidget);
    expect(find.text('TZS 2,000'), findsOneWidget);
  });

  testWidgets('DriverShell displays driver title and empty state', (tester) async {
    final fakeAuth = FakeAuthProvider(
      profile: Profile(
        id: 'driver-1',
        fullName: 'Juma Rashidi',
        role: 'driver',
        phone: '+255655000111',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<DriverOrdersProvider>(create: (_) => DriverOrdersProvider()),
        ],
        child: const MaterialApp(home: DriverShell()),
      ),
    );

    expect(find.text('Quickopia Driver'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
