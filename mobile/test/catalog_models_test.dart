import 'package:flutter_test/flutter_test.dart';
import 'package:quickopia/models/category_model.dart';
import 'package:quickopia/models/product_model.dart';
import 'package:quickopia/utils/currency_formatter.dart';

void main() {
  group('Category Model', () {
    test('Category.fromMap parses successfully', () {
      final map = {
        'id': 'cat-1',
        'name': 'Fresh Produce',
        'name_sw': 'Mboga na Matunda',
        'icon': 'apple',
        'display_order': 1,
      };

      final cat = Category.fromMap(map);

      expect(cat.id, 'cat-1');
      expect(cat.name, 'Fresh Produce');
      expect(cat.nameSw, 'Mboga na Matunda');
      expect(cat.icon, 'apple');
      expect(cat.displayOrder, 1);
    });

    test('Category.fromMap handles default display_order and nulls', () {
      final map = {
        'id': 'cat-2',
        'name': 'Bakery',
      };

      final cat = Category.fromMap(map);

      expect(cat.id, 'cat-2');
      expect(cat.name, 'Bakery');
      expect(cat.nameSw, isNull);
      expect(cat.icon, isNull);
      expect(cat.displayOrder, 0);
    });
  });

  group('Product Model', () {
    test('Product.fromMap parses correctly', () {
      final map = {
        'id': 'prod-1',
        'category_id': 'cat-1',
        'title': 'Red Apples (Tanzania)',
        'description': 'Crisp organic red apples grown in Iringa',
        'price_tzs': 3500.0,
        'unit': '1 kg',
        'image_url': 'https://example.com/apples.jpg',
        'stock_quantity': 25,
        'is_available': true,
        'is_popular': true,
      };

      final prod = Product.fromMap(map);

      expect(prod.id, 'prod-1');
      expect(prod.categoryId, 'cat-1');
      expect(prod.title, 'Red Apples (Tanzania)');
      expect(prod.priceTzs, 3500.0);
      expect(prod.unit, '1 kg');
      expect(prod.stockQuantity, 25);
      expect(prod.isAvailable, isTrue);
      expect(prod.isPopular, isTrue);
      expect(prod.isInStock, isTrue);
    });

    test('Product.isInStock returns false when stock is 0 or unavailable', () {
      final prodOutOfStock = Product(
        id: 'p-2',
        categoryId: 'c-1',
        title: 'Out of stock item',
        priceTzs: 1000,
        stockQuantity: 0,
        isAvailable: true,
        isPopular: false,
      );
      expect(prodOutOfStock.isInStock, isFalse);

      final prodUnavailable = Product(
        id: 'p-3',
        categoryId: 'c-1',
        title: 'Unavailable item',
        priceTzs: 1000,
        stockQuantity: 50,
        isAvailable: false,
        isPopular: false,
      );
      expect(prodUnavailable.isInStock, isFalse);
    });
  });

  group('CurrencyFormatter', () {
    test('Formats TZS amounts with comma thousand separators and no decimals', () {
      expect(CurrencyFormatter.formatTzs(0), 'TZS 0');
      expect(CurrencyFormatter.formatTzs(500), 'TZS 500');
      expect(CurrencyFormatter.formatTzs(1500), 'TZS 1,500');
      expect(CurrencyFormatter.formatTzs(25000), 'TZS 25,000');
      expect(CurrencyFormatter.formatTzs(1250000), 'TZS 1,250,000');
    });
  });
}
