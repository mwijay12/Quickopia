import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/order_model.dart';

class OrderHistoryService {
  final SupabaseClient? _customClient;

  OrderHistoryService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  Future<List<Order>> fetchMyOrders(String customerId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .limit(50);
    return (response as List)
        .map((e) => Order.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
