import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  static const _storageKey = 'quickopia_cart_v1';

  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotalTzs =>
      _items.values.fold(0.0, (sum, item) => sum + item.lineTotalTzs);

  bool get isEmpty => _items.isEmpty;

  CartProvider() {
    _loadFromDisk();
  }

  int quantityOf(String productId) => _items[productId]?.quantity ?? 0;

  bool canIncrement(String productId) {
    final item = _items[productId];
    if (item == null) return true;
    return item.quantity < item.stockCeiling;
  }

  /// Adds [quantity] units of [product] to the cart, strictly clamped by [product.stockQuantity].
  /// Returns the number of units added (0 if stock is exhausted or at maximum ceiling).
  int addItem(Product product, {int quantity = 1}) {
    if (!product.isInStock || product.stockQuantity <= 0 || quantity <= 0) {
      return 0;
    }
    final existing = _items[product.id];
    if (existing != null) {
      final int availableSpace = existing.stockCeiling - existing.quantity;
      if (availableSpace <= 0) {
        return 0;
      }
      final int toAdd = quantity.clamp(1, availableSpace);
      existing.quantity += toAdd;
      _persist();
      notifyListeners();
      return toAdd;
    } else {
      final int initialQty = quantity.clamp(1, product.stockQuantity);
      _items[product.id] = CartItem(
        productId: product.id,
        title: product.title,
        priceTzs: product.priceTzs,
        unit: product.unit,
        imageUrl: product.imageUrl,
        stockCeiling: product.stockQuantity,
        quantity: initialQty,
      );
      _persist();
      notifyListeners();
      return initialQty;
    }
  }

  /// Sets the exact quantity for an item in the cart.
  /// If [targetQuantity] <= 0, the item is removed from the cart.
  /// If [targetQuantity] exceeds the item's stock ceiling, it is clamped to [item.stockCeiling].
  /// Returns the actual resulting quantity in cart.
  int setQuantity(String productId, int targetQuantity) {
    final item = _items[productId];
    if (item == null) return 0;

    if (targetQuantity <= 0) {
      _items.remove(productId);
      _persist();
      notifyListeners();
      return 0;
    }

    final int clamped = targetQuantity.clamp(1, item.stockCeiling);
    item.quantity = clamped;
    _persist();
    notifyListeners();
    return clamped;
  }

  void increment(String productId) {
    final item = _items[productId];
    if (item != null && item.quantity < item.stockCeiling) {
      item.quantity += 1;
      _persist();
      notifyListeners();
    }
  }

  void decrement(String productId) {
    final item = _items[productId];
    if (item == null) return;
    if (item.quantity <= 1) {
      _items.remove(productId);
    } else {
      item.quantity -= 1;
    }
    _persist();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _persist();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _persist();
    notifyListeners();
  }

  /// Re-populates the cart from a past order's items.
  /// Uses CURRENT live catalog pricing and skips out-of-stock or deactivated items.
  Future<Map<String, dynamic>> reorderFromPastOrder(List<dynamic> pastItems) async {
    final client = SupabaseConfig.client;
    final List<String> productIds = pastItems
        .map((i) => (i.productId ?? i['product_id'] ?? '') as String)
        .where((id) => id.isNotEmpty)
        .toList();

    if (productIds.isEmpty) {
      return {'added': 0, 'skipped': <String>[]};
    }

    try {
      final response = await client
          .from('products')
          .select('id, title, price_tzs, unit, image_url, stock_quantity, is_available')
          .inFilter('id', productIds);

      final liveProducts = {
        for (var row in (response as List))
          row['id'] as String: row as Map<String, dynamic>
      };

      int addedCount = 0;
      final List<String> skippedTitles = [];

      for (final pastItem in pastItems) {
        final pid = (pastItem.productId ?? pastItem['product_id'] ?? '') as String;
        final title = (pastItem.title ?? pastItem['title'] ?? 'Product') as String;
        final requestedQty = (pastItem.quantity ?? pastItem['quantity'] ?? 1) as int;

        final liveProd = liveProducts[pid];
        if (liveProd != null &&
            (liveProd['is_available'] as bool? ?? false) &&
            ((liveProd['stock_quantity'] as num?)?.toInt() ?? 0) > 0) {
          final currentStock = (liveProd['stock_quantity'] as num).toInt();
          final currentPrice = (liveProd['price_tzs'] as num).toDouble();
          final addQty = requestedQty > currentStock ? currentStock : requestedQty;

          _items[pid] = CartItem(
            productId: pid,
            title: liveProd['title'] as String? ?? title,
            priceTzs: currentPrice, // Always uses current live catalog price!
            unit: liveProd['unit'] as String?,
            imageUrl: liveProd['image_url'] as String?,
            stockCeiling: currentStock,
            quantity: addQty,
          );
          addedCount++;
        } else {
          skippedTitles.add(title);
        }
      }

      await _persist();
      notifyListeners();

      return {
        'added': addedCount,
        'skipped': skippedTitles,
      };
    } catch (_) {
      return {'added': 0, 'skipped': <String>[]};
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.values.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Graceful error handling for storage issues
    }
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final List decoded = jsonDecode(raw);
      for (final entry in decoded) {
        final item = CartItem.fromJson(entry as Map<String, dynamic>);
        _items[item.productId] = item;
      }
      notifyListeners();
    } catch (_) {
      // Corrupted local cart data — fail safe by clearing rather than crashing
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_storageKey);
      } catch (_) {}
    }
  }
}

