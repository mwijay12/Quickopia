import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickopia/models/category_model.dart';
import 'package:quickopia/models/product_model.dart';
import 'package:quickopia/models/profile_model.dart';
import 'package:quickopia/providers/auth_provider.dart';
import 'package:quickopia/providers/cart_provider.dart';
import 'package:quickopia/providers/catalog_provider.dart';
import 'package:quickopia/screens/customer/customer_home_screen.dart';
import 'package:quickopia/widgets/skeleton_loading.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  AuthStatus status = AuthStatus.authenticated;
  @override
  Profile? profile;
  @override
  String? errorMessage;

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
  Future<void> signOut() async {}
  @override
  Future<void> reloadProfile() async {}
}

class TestCatalogProvider extends ChangeNotifier implements CatalogProvider {
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
  bool refreshCalled = false;

  TestCatalogProvider({
    this.status = CatalogStatus.loaded,
    this.errorMessage,
    this.categories = const [],
    this.products = const [],
    this.selectedCategoryId,
  });

  @override
  Future<void> loadInitialData() async {}

  @override
  Future<void> refresh() async {
    refreshCalled = true;
  }

  @override
  Future<void> search(String query) async {
    searchQuery = query;
  }

  @override
  Future<void> selectCategory(String? categoryId) async {
    selectedCategoryId = categoryId;
  }
}

void main() {
  Widget buildTestApp(TestCatalogProvider catalogProvider, [CartProvider? cartProvider]) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
        ChangeNotifierProvider<CatalogProvider>.value(value: catalogProvider),
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider ?? CartProvider()),
      ],
      child: const MaterialApp(
        home: CustomerHomeScreen(),
      ),
    );
  }

  testWidgets('Renders loading indicator when status is loading', (tester) async {
    final catalog = TestCatalogProvider(status: CatalogStatus.loading);
    await tester.pumpWidget(buildTestApp(catalog));

    expect(find.byType(SkeletonProductGrid), findsOneWidget);
  });

  testWidgets('Renders error state with retry button when status is error', (tester) async {
    final catalog = TestCatalogProvider(
      status: CatalogStatus.error,
      errorMessage: 'Network error loading catalog',
    );
    await tester.pumpWidget(buildTestApp(catalog));

    expect(find.text('Network error loading catalog'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(catalog.refreshCalled, isTrue);
  });

  testWidgets('Renders empty state when products list is empty', (tester) async {
    final catalog = TestCatalogProvider(
      status: CatalogStatus.loaded,
      products: [],
    );
    await tester.pumpWidget(buildTestApp(catalog));

    expect(find.text('No products found.'), findsOneWidget);
  });

  testWidgets('Renders out of stock badge and disables add button for 0 stock items', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final catalog = TestCatalogProvider(
      status: CatalogStatus.loaded,
      products: [
        Product(
          id: 'p-out',
          categoryId: 'c-1',
          title: 'Out of stock milk',
          priceTzs: 2500,
          stockQuantity: 0,
          isAvailable: true,
          isPopular: false,
        ),
      ],
    );
    await tester.pumpWidget(buildTestApp(catalog));

    expect(find.text('Out of stock milk'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);

    // Tap add button on out-of-stock item (should be disabled)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('View Cart'), findsNothing);
  });

  testWidgets('Tapping add button on in-stock item adds to cart and shows sticky bar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cart = CartProvider();
    final catalog = TestCatalogProvider(
      status: CatalogStatus.loaded,
      products: [
        Product(
          id: 'p-in',
          categoryId: 'c-1',
          title: 'Available Bread',
          priceTzs: 1500,
          stockQuantity: 10,
          isAvailable: true,
          isPopular: true,
        ),
      ],
    );
    await tester.pumpWidget(buildTestApp(catalog, cart));

    expect(find.text('Available Bread'), findsOneWidget);
    expect(find.text('Out of stock'), findsNothing);

    // Initial cart is empty, sticky bar not visible
    expect(find.text('View Cart'), findsNothing);

    // Tap '+' add button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Now in cart: quantity stepper is displayed and sticky bar appears
    expect(cart.quantityOf('p-in'), 1);
    expect(find.text('View Cart'), findsOneWidget);
    expect(find.text('1 item · TZS 1,500'), findsOneWidget);
  });
}
