import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/order_model.dart';

class DeliveryCompletionException implements Exception {
  final String message;
  DeliveryCompletionException(this.message);

  @override
  String toString() => message;
}

class DriverOrderService {
  final SupabaseClient? _customClient;

  DriverOrderService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  static const _activeStatuses = [
    'placed',
    'packing',
    'ready',
    'out_for_delivery',
  ];

  /// Fetch active deliveries assigned to this driver
  Future<List<Order>> fetchAssignedOrders(String driverId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('driver_id', driverId)
        .inFilter('status', _activeStatuses)
        .order('created_at', ascending: true);
    return (response as List)
        .map((e) => Order.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch unassigned orders waiting for pickup
  Future<List<Order>> fetchAvailableOrders() async {
    try {
      final rpcRes = await _client.rpc('get_available_deliveries');
      if (rpcRes is List) {
        return rpcRes.map((e) => Order.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Fallback to direct query
    }

    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .isFilter('driver_id', null)
          .eq('fulfillment_type', 'delivery')
          .inFilter('status', ['ready', 'packing', 'placed', 'out_for_delivery'])
          .order('created_at', ascending: true);

      return (response as List)
          .map((e) => Order.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Claim / Accept an order for delivery
  Future<void> acceptOrder({
    required String orderId,
    required String driverId,
  }) async {
    try {
      await _client.rpc('accept_order_delivery', params: {
        'p_order_id': orderId,
      });
    } catch (e) {
      final err = e.toString();
      if (err.toLowerCase().contains('already been claimed')) {
        throw DeliveryCompletionException('Oda hii tayari imechukuliwa na dereva mwingine.');
      }
      throw DeliveryCompletionException('Haikuwezekana kupokea oda hii: $err');
    }
  }

  /// Fetch delivered/completed orders for history, earnings, and payout reports
  Future<List<Order>> fetchCompletedOrders(String driverId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('driver_id', driverId)
          .eq('status', 'delivered')
          .order('updated_at', ascending: false)
          .limit(100);

      return (response as List)
          .map((e) => Order.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Mark delivery complete with pickup code
  Future<void> completeDelivery({
    required String orderId,
    required String enteredCode,
    required String paymentStatus,
  }) async {
    try {
      await _client.rpc('complete_delivery', params: {
        'p_order_id': orderId,
        'p_entered_code': enteredCode,
        'p_payment_status': paymentStatus,
      });
    } catch (e) {
      throw DeliveryCompletionException(_parseError(e.toString()));
    }
  }

  String _parseError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('locked') || lower.contains('too many failed')) {
      return 'Oda imefungwa kwa sababu ya majaribio mengi yasiyo sahihi. Wasiliana na meneja wa supermarket.';
    }
    if (lower.contains('incorrect confirmation code')) {
      // Extract remaining attempts if provided by backend
      final match = RegExp(r'\((\d+)\s+attempt\(s\)\s+remaining\)', caseSensitive: false).firstMatch(raw);
      if (match != null) {
        return 'Namba ya uthibitisho si sahihi (${match.group(1)} nafasi zimebaki). Uliza mteja namba sahihi.';
      }
      return 'Namba ya uthibitisho si sahihi. Tafadhali kagua tena na mteja.';
    }
    if (lower.contains('already marked') || lower.contains('already closed')) {
      return 'Oda hii tayari imekamilika au imefungwa.';
    }
    if (lower.contains('not authorized') || lower.contains('not assigned')) {
      return 'Huna idhini ya kukamilisha oda hii.';
    }
    return 'Haikuwezekana kukamilisha oda. Tafadhali jaribu tena.';
  }
}
