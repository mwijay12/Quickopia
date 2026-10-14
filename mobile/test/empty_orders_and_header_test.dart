import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickopia/models/category_model.dart';
import 'package:quickopia/models/order_model.dart';
import 'package:quickopia/models/product_model.dart';
import 'package:quickopia/models/profile_model.dart';
import 'package:quickopia/providers/auth_provider.dart';
import 'package:quickopia/providers/cart_provider.dart';
import 'package:quickopia/providers/catalog_provider.dart';
import 'package:quickopia/providers/order_history_provider.dart';
import 'package:quickopia/screens/customer/customer_home_screen.dart';
import 'package:quickopia/screens/customer/order_history_screen.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  AuthStatus status;
  @override
  Profile? profile;
  @override
  String? errorMessage;

  MockAuthProvider({this.status = AuthStatus.unauthenticated, this.profile});

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

class MockOrderHistoryProvider extends ChangeNotifier implements OrderHistoryProvider {
  @override
  HistoryStatus status;
  @override
  List<Order> orders;
  @override
  String? errorMessage;

  MockOrderHistoryProvider({this.status = HistoryStatus.loaded, this.orders = const []});

  @override
  List<Order> get activeOrders => [];
  @override
  List<Order> get pastOrders => [];

  @override
  Future<void> load(String customerId) async {
    status = HistoryStatus.loaded;
    orders = [];
    notifyListeners();
  }

  @override
  void clear() {}
}

class DummyCatalogProvider extends ChangeNotifier implements CatalogProvider {
  @override
  CatalogStatus status = CatalogStatus.loaded;
  @override
  String? errorMessage;
  @override
  List<Category> categories = const [];
  @override
  List<Product> products = const [];
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
  group('Beautified Header and Reassuring Empty Orders Experience', () {
    testWidgets('CustomerHomeScreen header renders gradient lockup, EXPRESS tag, and delivery subtitle', (tester) async {
      final auth = MockAuthProvider(status: AuthStatus.unauthenticated);
      final catalog = DummyCatalogProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<CatalogProvider>.value(value: catalog),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: CustomerHomeScreen(),
          ),
        ),
      );

      // Verify Header lockup
      expect(find.text('Quickopia'), findsOneWidget);
      expect(find.text('EXPRESS'), findsOneWidget);
      expect(find.text('Dar es Salaam • ~30 Mins Dispatch'), findsOneWidget);
      expect(find.text('AI Assistant'), findsOneWidget);
    });

    testWidgets('OrderHistoryScreen renders warm, reassuring empty state (not a mistake) and handles CTA click', (tester) async {
      final auth = MockAuthProvider(
        status: AuthStatus.authenticated,
        profile: Profile(id: 'usr-1', fullName: 'Juma Rashid', role: 'customer'),
      );
      final history = MockOrderHistoryProvider(status: HistoryStatus.loaded, orders: []);

      bool shoppingStarted = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<OrderHistoryProvider>.value(value: history),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ],
          child: MaterialApp(
            home: OrderHistoryScreen(
              onStartShopping: () {
                shoppingStarted = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top header
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('Order History & Live Receipts'), findsOneWidget);

      // Warm, reassuring empty state content (guarantees it does not sound like a mistake)
      expect(find.text('You Have No Orders Yet'), findsOneWidget);
      expect(find.text('START YOUR SHOPPING JOURNEY'), findsOneWidget);
      expect(find.textContaining('You haven\'t missed a thing!'), findsOneWidget);
      expect(find.text('30-Minute Express Delivery'), findsOneWidget);
      expect(find.text('Click & Collect (Skip the Queue)'), findsOneWidget);
      expect(find.text('100% Quality & Price Guarantee'), findsOneWidget);

      // CTA Button
      final ctaFinder = find.text('Start Shopping ➔');
      expect(ctaFinder, findsOneWidget);

      await tester.ensureVisible(ctaFinder);
      await tester.tap(ctaFinder);
      await tester.pump();

      expect(shoppingStarted, isTrue);
    });
  });
}
