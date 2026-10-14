import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/order_model.dart';

class OrderTrackingService {
  final _client = SupabaseConfig.client;
  RealtimeChannel? _channel;

  /// Emits the initial order immediately, then a fresh Order snapshot
  /// every time this specific order row changes in Postgres.
  Stream<Order> subscribeToOrder(Order initialOrder) {
    final controller = StreamController<Order>.broadcast();
    controller.add(initialOrder);
    Order latest = initialOrder;

    _channel = _client
        .channel('order_tracking_${initialOrder.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: initialOrder.id,
          ),
          callback: (payload) {
            latest = _mergeUpdate(latest, payload.newRecord);
            controller.add(latest);
          },
        )
        .subscribe();

    controller.onCancel = () => _channel?.unsubscribe();
    return controller.stream;
  }

  /// Order fields we care about tracking are merged in;
  /// items/subtotal/etc. never change post-placement, so we keep the original snapshot for those.
  Order _mergeUpdate(Order base, Map<String, dynamic> newRecord) {
    return Order(
      id: base.id,
      orderNumber: base.orderNumber,
      fulfillmentType: base.fulfillmentType,
      status: newRecord['status'] as String? ?? base.status,
      pickupCode: base.pickupCode,
      subtotalTzs: base.subtotalTzs,
      deliveryFeeTzs: base.deliveryFeeTzs,
      totalAmountTzs: base.totalAmountTzs,
      paymentMethod: base.paymentMethod,
      paymentStatus: newRecord['payment_status'] as String? ?? base.paymentStatus,
      createdAt: base.createdAt,
      items: base.items,
      driverId: newRecord['driver_id'] as String?,
      deliveryNeighborhood: base.deliveryNeighborhood,
      deliveryLandmark: base.deliveryLandmark,
      customerPhone: base.customerPhone,
      deliveryLatitude: base.deliveryLatitude,
      deliveryLongitude: base.deliveryLongitude,
    );
  }

  void dispose() {
    _channel?.unsubscribe();
  }
}
