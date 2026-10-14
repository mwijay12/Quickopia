import '../config/supabase_config.dart';
import '../models/cart_item_model.dart';
import '../models/checkout_data_model.dart';
import '../models/order_model.dart';

/// Thrown when the backend rejects the order — e.g., insufficient stock.
/// Carries a user-friendly message extracted from the Postgres exception.
class OrderPlacementException implements Exception {
  final String message;
  OrderPlacementException(this.message);

  @override
  String toString() => message;
}

class OrderService {
  final _client = SupabaseConfig.client;

  Future<String> _resolveValidBranchId(String candidateBranchId) async {
    if (candidateBranchId.isNotEmpty &&
        candidateBranchId != '00000000-0000-0000-0000-000000000000') {
      return candidateBranchId;
    }

    try {
      final res = await _client.from('branches').select('id').limit(1);
      if (res.isNotEmpty && res[0]['id'] != null) {
        return res[0]['id'] as String;
      }
    } catch (_) {}

    try {
      final prod = await _client.from('products').select('branch_id').limit(1);
      if (prod.isNotEmpty && prod[0]['branch_id'] != null) {
        return prod[0]['branch_id'] as String;
      }
    } catch (_) {}

    return candidateBranchId;
  }

  /// Places an order through the atomic `place_order` Postgres RPC — the ONLY
  /// sanctioned order-creation path.
  ///
  /// Security note: there is intentionally NO direct-insert fallback. Client
  /// INSERTs on `orders`/`order_items` are blocked by RLS (migration 0022)
  /// because direct inserts bypass `FOR UPDATE` stock locks, server-side price
  /// enforcement, and pickup-code generation — enabling price tampering and
  /// inventory corruption. If the RPC fails, surface the error to the user.
  Future<Order> placeOrder({
    required String customerId,
    required String branchId,
    required CheckoutData checkoutData,
    required List<CartItem> cartItems,
  }) async {
    final effectiveBranchId = await _resolveValidBranchId(branchId);

    final itemsPayload = cartItems
        .map((item) => {
              'product_id': item.productId,
              'quantity': item.quantity,
            })
        .toList();

    try {
      final orderIdResponse = await _client.rpc('place_order', params: {
        'p_customer_id': customerId,
        'p_branch_id': effectiveBranchId,
        'p_fulfillment_type': checkoutData.fulfillmentType,
        'p_delivery_city': checkoutData.city,
        'p_delivery_neighborhood': checkoutData.neighborhood,
        'p_delivery_landmark': checkoutData.landmark,
        'p_delivery_house_details': checkoutData.houseDetails,
        'p_delivery_latitude': checkoutData.latitude,
        'p_delivery_longitude': checkoutData.longitude,
        'p_customer_phone': checkoutData.customerPhone,
        'p_payment_method': checkoutData.paymentMethod,
        'p_delivery_fee_tzs': checkoutData.deliveryFeeTzs,
        'p_items': itemsPayload,
      });

      final orderId = orderIdResponse as String;
      return await fetchOrderById(orderId);
    } catch (e) {
      final rawError = e.toString();
      throw OrderPlacementException(_parseRpcError(rawError));
    }
  }

  Future<Order> fetchOrderById(String orderId) async {
    final response = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .single();
    return Order.fromMap(response);
  }

  String _parseRpcError(String rawError) {
    final lower = rawError.toLowerCase();
    if (lower.contains('insufficient stock')) {
      return 'Samahani, baadhi ya vitu vimeisha stoo wakati unaweka oda. Tafadhali hakiki kikapu chako na ujaribu tena.';
    }
    if (lower.contains('unavailable') || lower.contains('not found')) {
      return 'Moja ya bidhaa kwenye kikapu chako haipatikani kwa sasa. Tafadhali hakiki kikapu chako.';
    }
    if (lower.contains('network') || lower.contains('socket') || lower.contains('failed host lookup')) {
      return 'Kuna hitilafu ya mtandao. Tafadhali kagua intaneti yako na ujaribu tena.';
    }
    return 'Haikuwezekana kutuma oda yako kwa sasa. Tafadhali jaribu tena baada ya muda mfupi.';
  }
}
