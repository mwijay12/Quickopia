import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickopia/models/order_item_model.dart';
import 'package:quickopia/models/order_model.dart';
import 'package:quickopia/models/product_model.dart';
import 'package:quickopia/providers/cart_provider.dart';
import 'package:quickopia/providers/favorites_provider.dart';
import 'package:quickopia/widgets/order_receipt_sheet.dart';
import 'package:quickopia/widgets/parallax_hero_banner.dart';
import 'package:quickopia/widgets/product_card.dart';
import 'package:quickopia/widgets/product_detail_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Product Model Experience Extensions', () {
    test('Calculates deterministic ratings and stock labels faithfully', () {
      final product = Product(
        id: 'p-sugar-1',
        categoryId: 'cat-groceries',
        title: 'Kilombero Sugar',
        priceTzs: 3200,
        stockQuantity: 4,
        isAvailable: true,
        isPopular: true,
      );

      expect(product.displayRating, inInclusiveRange(4.0, 5.0));
      expect(product.displayReviewCount, greaterThanOrEqualTo(16));
      expect(product.stockStatusLabel, 'Only 4 left!');
      expect(product.displayGallery, isEmpty);
    });

    test('Identifies out of stock items correctly', () {
      final outOfStockProd = Product(
        id: 'p-out-1',
        categoryId: 'cat-dairy',
        title: 'Expired Milk',
        priceTzs: 2000,
        stockQuantity: 0,
        isAvailable: true,
        isPopular: false,
      );

      expect(outOfStockProd.isInStock, isFalse);
      expect(outOfStockProd.stockStatusLabel, 'Out of stock');
    });
  });

  group('FavoritesProvider', () {
    test('Toggles and persists favorite status', () async {
      final favProvider = FavoritesProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(favProvider.isFavorite('p-100'), isFalse);
      expect(favProvider.count, 0);

      final isNowFav = await favProvider.toggleFavorite('p-100');
      expect(isNowFav, isTrue);
      expect(favProvider.isFavorite('p-100'), isTrue);
      expect(favProvider.count, 1);

      final isNowUnfav = await favProvider.toggleFavorite('p-100');
      expect(isNowUnfav, isFalse);
      expect(favProvider.isFavorite('p-100'), isFalse);
      expect(favProvider.count, 0);
    });
  });

  group('Stock Ceiling Enforcement in CartProvider', () {
    test('Clamps quantity strictly to stockQuantity when ordering 200 units on 100 stock', () {
      final cart = CartProvider();
      final productLimited = Product(
        id: 'p-flour-limited',
        categoryId: 'cat-flour',
        title: 'Azam Wheat Flour 1kg',
        priceTzs: 2200,
        stockQuantity: 100, // only 100 units in store!
        isAvailable: true,
        isPopular: true,
      );

      // User tries to order 200 units!
      final added = cart.addItem(productLimited, quantity: 200);

      // System must clamp strictly to 100!
      expect(added, 100);
      expect(cart.quantityOf('p-flour-limited'), 100);
      expect(cart.canIncrement('p-flour-limited'), isFalse);

      // Further attempt to add more returns 0 units added
      final secondTry = cart.addItem(productLimited, quantity: 10);
      expect(secondTry, 0);
      expect(cart.quantityOf('p-flour-limited'), 100);

      // Directly set custom quantity to 250 (must clamp to 100)
      final setCustom = cart.setQuantity('p-flour-limited', 250);
      expect(setCustom, 100);
      expect(cart.quantityOf('p-flour-limited'), 100);

      // Directly set quantity to 25 (valid within range)
      final setValid = cart.setQuantity('p-flour-limited', 25);
      expect(setValid, 25);
      expect(cart.quantityOf('p-flour-limited'), 25);

      // Directly set quantity to 0 (removes item)
      final setZero = cart.setQuantity('p-flour-limited', 0);
      expect(setZero, 0);
      expect(cart.quantityOf('p-flour-limited'), 0);
    });
  });

  group('ProductCard and ProductDetailSheet Widgets', () {
    testWidgets('ProductCard displays rating and favorite heart icon', (tester) async {
      final product = Product(
        id: 'prod-test-card',
        categoryId: 'cat-test',
        title: 'Sunflower Cooking Oil 1L',
        priceTzs: 5500,
        stockQuantity: 15,
        isAvailable: true,
        isPopular: true,
      );

      final cart = CartProvider();
      final fav = FavoritesProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<FavoritesProvider>.value(value: fav),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 180,
                  height: 280,
                  child: ProductCard(product: product),
                ),
              ),
            ),
          ),
        ),
      );

      // Check title and price
      expect(find.text('Sunflower Cooking Oil 1L'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget); // eye icon
      expect(find.byIcon(Icons.favorite_border), findsOneWidget); // love icon

      // Tap favorite icon
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      expect(fav.isFavorite('prod-test-card'), isTrue);
    });

    testWidgets('ProductDetailSheet renders stock pill and clamped controls', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final product = Product(
        id: 'prod-test-sheet',
        categoryId: 'cat-test',
        title: 'Mo Premium Rice 5kg',
        priceTzs: 18000,
        stockQuantity: 3, // Low stock: only 3 left!
        isAvailable: true,
        isPopular: true,
      );

      final cart = CartProvider();
      final fav = FavoritesProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<FavoritesProvider>.value(value: fav),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProductDetailSheet(product: product),
            ),
          ),
        ),
      );

      expect(find.text('Mo Premium Rice 5kg'), findsOneWidget);
      expect(find.text('Only 3 left!'), findsOneWidget);
      expect(find.text('Available: 3 units'), findsOneWidget);

      // Increment up to ceiling (3)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Quantity should be 3
      expect(find.text('3'), findsOneWidget);

      // Tap Add to Cart
      await tester.tap(find.textContaining('Add to Cart'));
      await tester.pump();

      expect(cart.quantityOf('prod-test-sheet'), 3);
    });
  });

  group('OrderReceiptSheet Widget', () {
    testWidgets('Renders professional retail receipt for customer and admin', (tester) async {
      final testOrder = Order(
        id: 'ord-123456',
        orderNumber: 'QKP-8821',
        fulfillmentType: 'pickup',
        status: 'ready',
        pickupCode: '9421',
        subtotalTzs: 15000,
        deliveryFeeTzs: 0,
        totalAmountTzs: 15000,
        paymentMethod: 'cash',
        paymentStatus: 'paid',
        createdAt: DateTime(2026, 9, 4, 11, 30),
        items: [
          OrderItem(
            id: 'item-1',
            productId: 'p-1',
            title: 'Kilombero Rice 5kg',
            unitPriceTzs: 15000,
            quantity: 1,
            totalTzs: 15000,
          ),
        ],
        customerPhone: '+255712345678',
        deliveryLandmark: 'Makumbusho Stand',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderReceiptSheet(order: testOrder),
          ),
        ),
      );

      expect(find.text('QUICKOPIA EXPRESS'), findsOneWidget);
      expect(find.text('TAX INVOICE / RISITI'), findsOneWidget);
      expect(find.text('#QKP-8821'), findsOneWidget);
      expect(find.text('9421'), findsOneWidget); // pickup PIN
      expect(find.text('Kilombero Rice 5kg'), findsOneWidget);
      expect(find.text('×1'), findsOneWidget);
      expect(find.text('PAID'), findsOneWidget);
      expect(find.text('Share WhatsApp Receipt'), findsOneWidget);
    });
  });

  group('ParallaxHeroBanner Widget', () {
    testWidgets('Renders hero banner slides with parallax typography', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ParallaxHeroBanner(),
          ),
        ),
      );

      expect(find.textContaining('Fresh Groceries'), findsOneWidget);
      expect(find.textContaining('30 Mins'), findsOneWidget);
      expect(find.text('ORDER NOW ➔'), findsOneWidget);
    });
  });
}
