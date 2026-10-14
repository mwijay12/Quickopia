import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickopia/models/cart_item_model.dart';
import 'package:quickopia/models/product_model.dart';
import 'package:quickopia/providers/cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CartItem Model', () {
    test('Calculates line total correctly', () {
      final item = CartItem(
        productId: 'prod-1',
        title: 'Fresh Milk',
        priceTzs: 2500.0,
        unit: '1L',
        stockCeiling: 10,
        quantity: 3,
      );

      expect(item.lineTotalTzs, 7500.0);
    });

    test('Serializes to and from JSON faithfully', () {
      final original = CartItem(
        productId: 'prod-2',
        title: 'Local Eggs',
        priceTzs: 8000.0,
        unit: 'Tray of 30',
        imageUrl: 'https://example.com/eggs.jpg',
        stockCeiling: 5,
        quantity: 2,
      );

      final json = original.toJson();
      final restored = CartItem.fromJson(json);

      expect(restored.productId, original.productId);
      expect(restored.title, original.title);
      expect(restored.priceTzs, original.priceTzs);
      expect(restored.unit, original.unit);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.stockCeiling, original.stockCeiling);
      expect(restored.quantity, original.quantity);
      expect(restored.lineTotalTzs, 16000.0);
    });
  });

  group('CartProvider Operations', () {
    late CartProvider cart;

    final productA = Product(
      id: 'prod-a',
      categoryId: 'cat-dairy',
      title: 'Whole Milk',
      priceTzs: 3000.0,
      unit: '1 Litre',
      stockQuantity: 3,
      isAvailable: true,
      isPopular: false,
    );

    final productB = Product(
      id: 'prod-b',
      categoryId: 'cat-bakery',
      title: 'Sliced Bread',
      priceTzs: 2000.0,
      unit: 'Loaf',
      stockQuantity: 5,
      isAvailable: true,
      isPopular: true,
    );

    setUp(() {
      cart = CartProvider();
    });

    test('Initializes empty', () {
      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
      expect(cart.subtotalTzs, 0.0);
      expect(cart.items, isEmpty);
    });

    test('Adds new product to cart', () {
      cart.addItem(productA);

      expect(cart.isEmpty, isFalse);
      expect(cart.itemCount, 1);
      expect(cart.quantityOf('prod-a'), 1);
      expect(cart.subtotalTzs, 3000.0);
    });

    test('Increment increases quantity and enforces stock ceiling', () {
      cart.addItem(productA);
      expect(cart.quantityOf('prod-a'), 1);

      cart.increment('prod-a');
      expect(cart.quantityOf('prod-a'), 2);
      expect(cart.subtotalTzs, 6000.0);

      cart.increment('prod-a');
      expect(cart.quantityOf('prod-a'), 3);
      expect(cart.subtotalTzs, 9000.0);

      // Attempt to exceed stock ceiling (stockQuantity = 3)
      cart.increment('prod-a');
      expect(cart.quantityOf('prod-a'), 3);
      expect(cart.subtotalTzs, 9000.0);
    });

    test('Decrement reduces quantity and removes when dropping below 1', () {
      cart.addItem(productA);
      cart.increment('prod-a');
      expect(cart.quantityOf('prod-a'), 2);

      cart.decrement('prod-a');
      expect(cart.quantityOf('prod-a'), 1);
      expect(cart.isEmpty, isFalse);

      cart.decrement('prod-a');
      expect(cart.quantityOf('prod-a'), 0);
      expect(cart.isEmpty, isTrue);
    });

    test('Computes multi-item subtotal and total count correctly', () {
      cart.addItem(productA); // 1 x 3000 = 3000
      cart.addItem(productB); // 1 x 2000 = 2000
      cart.increment(productB.id); // 2 x 2000 = 4000

      expect(cart.itemCount, 3);
      expect(cart.subtotalTzs, 7000.0);
      expect(cart.items.length, 2);
    });

    test('Removes item directly', () {
      cart.addItem(productA);
      cart.addItem(productB);
      expect(cart.items.length, 2);

      cart.removeItem(productA.id);
      expect(cart.items.length, 1);
      expect(cart.quantityOf(productA.id), 0);
      expect(cart.quantityOf(productB.id), 1);
    });

    test('Clears all items in cart', () {
      cart.addItem(productA);
      cart.addItem(productB);
      expect(cart.isEmpty, isFalse);

      cart.clearCart();
      expect(cart.isEmpty, isTrue);
      expect(cart.items, isEmpty);
      expect(cart.subtotalTzs, 0.0);
      expect(cart.itemCount, 0);
    });
  });
}
