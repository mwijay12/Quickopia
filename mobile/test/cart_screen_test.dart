import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickopia/models/product_model.dart';
import 'package:quickopia/providers/cart_provider.dart';
import 'package:quickopia/screens/customer/cart_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(CartProvider cartProvider) {
    return ChangeNotifierProvider<CartProvider>.value(
      value: cartProvider,
      child: const MaterialApp(
        home: CartScreen(),
      ),
    );
  }

  group('CartScreen Widget', () {
    testWidgets('Renders empty state when cart has no items', (tester) async {
      final cart = CartProvider();

      await tester.pumpWidget(buildTestableWidget(cart));
      await tester.pumpAndSettle();

      expect(find.text('Your Cart is Empty'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);
      expect(find.text('Proceed to Checkout'), findsNothing);
    });

    testWidgets('Renders items and checkout button when cart has items', (tester) async {
      final cart = CartProvider();
      cart.addItem(Product(
        id: 'p1',
        categoryId: 'c1',
        title: 'Premium Basmati Rice 5kg',
        priceTzs: 24000.0,
        stockQuantity: 10,
        isAvailable: true,
        isPopular: true,
      ));

      await tester.pumpWidget(buildTestableWidget(cart));
      await tester.pumpAndSettle();

      expect(find.text('Shopping Cart'), findsOneWidget);
      expect(find.text('Premium Basmati Rice 5kg'), findsOneWidget);
      expect(find.text('Proceed to Checkout'), findsOneWidget);
      expect(find.text('TZS 24,000'), findsWidgets); // line total & subtotal
    });

    testWidgets('Clear cart button triggers confirmation dialog', (tester) async {
      final cart = CartProvider();
      cart.addItem(Product(
        id: 'p1',
        categoryId: 'c1',
        title: 'Premium Basmati Rice 5kg',
        priceTzs: 24000.0,
        stockQuantity: 10,
        isAvailable: true,
        isPopular: true,
      ));

      await tester.pumpWidget(buildTestableWidget(cart));
      await tester.pumpAndSettle();

      // Tap clear cart icon in AppBar
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Clear Cart?'), findsOneWidget);
      expect(find.text('Are you sure you want to remove all items from your cart?'), findsOneWidget);

      // Tap 'Clear'
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(cart.isEmpty, isTrue);
      expect(find.text('Your Cart is Empty'), findsOneWidget);
    });
  });
}
