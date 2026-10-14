import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickopia/models/driver_profile_model.dart';
import 'package:quickopia/models/order_item_model.dart';
import 'package:quickopia/models/order_model.dart';
import 'package:quickopia/widgets/order_status_timeline.dart';

void main() {
  group('Order and OrderItem Models', () {
    test('OrderItem parses correctly from map', () {
      final itemMap = {
        'id': 'oi-1',
        'product_id': 'prod-10',
        'title': 'Red Apples 1kg',
        'unit_price_tzs': 5000,
        'quantity': 2,
        'total_tzs': 10000,
      };

      final item = OrderItem.fromMap(itemMap);
      expect(item.id, 'oi-1');
      expect(item.title, 'Red Apples 1kg');
      expect(item.unitPriceTzs, 5000.0);
      expect(item.quantity, 2);
      expect(item.totalTzs, 10000.0);
    });

    test('Order parses with nested items and driverId', () {
      final orderMap = {
        'id': 'ord-999',
        'order_number': 'ORD-2026-0042',
        'fulfillment_type': 'delivery',
        'status': 'out_for_delivery',
        'pickup_code': '8492',
        'subtotal_tzs': 15000.0,
        'delivery_fee_tzs': 3000.0,
        'total_amount_tzs': 18000.0,
        'payment_method': 'cod',
        'payment_status': 'pending',
        'created_at': '2026-09-03T12:00:00.000Z',
        'driver_id': 'driver-uuid-456',
        'order_items': [
          {
            'id': 'oi-1',
            'product_id': 'p-1',
            'title': 'Sunflower Oil',
            'unit_price_tzs': 15000.0,
            'quantity': 1,
            'total_tzs': 15000.0,
          }
        ],
      };

      final order = Order.fromMap(orderMap);
      expect(order.id, 'ord-999');
      expect(order.orderNumber, 'ORD-2026-0042');
      expect(order.fulfillmentType, 'delivery');
      expect(order.status, 'out_for_delivery');
      expect(order.pickupCode, '8492');
      expect(order.totalAmountTzs, 18000.0);
      expect(order.driverId, 'driver-uuid-456');
      expect(order.items.length, 1);
      expect(order.items.first.title, 'Sunflower Oil');
    });

    test('DriverProfile parses correctly', () {
      final map = {
        'id': 'drv-1',
        'full_name': 'Juma Rashid',
        'phone': '+255712998877',
      };

      final driver = DriverProfile.fromMap(map);
      expect(driver.id, 'drv-1');
      expect(driver.fullName, 'Juma Rashid');
      expect(driver.phone, '+255712998877');
    });
  });

  group('OrderStatusTimeline Widget', () {
    testWidgets('Renders delivery timeline steps properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderStatusTimeline(
              currentStatus: 'packing',
              fulfillmentType: 'delivery',
            ),
          ),
        ),
      );

      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('Packing'), findsOneWidget);
      expect(find.text('Out for Delivery'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('Renders pickup timeline steps properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderStatusTimeline(
              currentStatus: 'ready',
              fulfillmentType: 'pickup',
            ),
          ),
        ),
      );

      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('Packing'), findsOneWidget);
      expect(find.text('Ready for Pickup'), findsOneWidget);
      expect(find.text('Collected'), findsOneWidget);
    });

    testWidgets('Renders cancelled state banner when order is cancelled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderStatusTimeline(
              currentStatus: 'cancelled',
              fulfillmentType: 'delivery',
            ),
          ),
        ),
      );

      expect(find.text('This order was cancelled.'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });
  });
}
