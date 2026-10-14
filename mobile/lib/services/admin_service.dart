import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class AdminDashboardStats {
  final int totalOrders;
  final double totalRevenueTzs;
  final int placedCount;
  final int packingCount;
  final int readyCount;
  final int outForDeliveryCount;
  final int deliveredCount;
  final int lowStockCount;

  const AdminDashboardStats({
    this.totalOrders = 0,
    this.totalRevenueTzs = 0.0,
    this.placedCount = 0,
    this.packingCount = 0,
    this.readyCount = 0,
    this.outForDeliveryCount = 0,
    this.deliveredCount = 0,
    this.lowStockCount = 0,
  });
}

class AdminService {
  final SupabaseClient? _customClient;

  AdminService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  /// Fetch all supermarket orders across the platform
  Future<List<Order>> fetchAllOrders() async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => Order.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Update the status of any order (Confirm, Pack, Ready, Dispatch)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _client.from('orders').update({
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// Update product price and stock quantity directly from mobile app
  Future<void> updateProductPriceAndStock({
    required String productId,
    required double newPriceTzs,
    required int newStockQuantity,
    bool? isAvailable,
  }) async {
    final updates = <String, dynamic>{
      'price_tzs': newPriceTzs,
      'stock_quantity': newStockQuantity,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (isAvailable != null) {
      updates['is_available'] = isAvailable;
    }

    await _client.from('products').update(updates).eq('id', productId);
  }

  /// Fetch all products for stock management
  Future<List<Product>> fetchAllProducts({String? query}) async {
    var dbQuery = _client.from('products').select();
    if (query != null && query.trim().isNotEmpty) {
      dbQuery = dbQuery.ilike('title', '%${query.trim()}%');
    }
    final response = await dbQuery.order('stock_quantity', ascending: true);
    return (response as List)
        .map((e) => Product.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Compute live store metrics from current orders and products
  AdminDashboardStats computeStats(List<Order> orders, List<Product> products) {
    int total = orders.length;
    double revenue = 0.0;
    int placed = 0;
    int packing = 0;
    int ready = 0;
    int outForDelivery = 0;
    int delivered = 0;

    for (final o in orders) {
      if (o.status != 'cancelled') {
        revenue += o.totalAmountTzs;
      }
      switch (o.status) {
        case 'placed':
          placed++;
          break;
        case 'packing':
          packing++;
          break;
        case 'ready':
          ready++;
          break;
        case 'out_for_delivery':
          outForDelivery++;
          break;
        case 'delivered':
        case 'completed':
          delivered++;
          break;
      }
    }

    final lowStock = products.where((p) => p.stockQuantity < 10).length;

    return AdminDashboardStats(
      totalOrders: total,
      totalRevenueTzs: revenue,
      placedCount: placed,
      packingCount: packing,
      readyCount: ready,
      outForDeliveryCount: outForDelivery,
      deliveredCount: delivered,
      lowStockCount: lowStock,
    );
  }
}
