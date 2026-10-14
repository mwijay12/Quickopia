import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickopia/config/supabase_config.dart';
import 'package:quickopia/models/address_model.dart';
import 'package:quickopia/models/order_item_model.dart';
import 'package:quickopia/models/order_model.dart';
import 'package:quickopia/providers/driver_orders_provider.dart';
import 'package:quickopia/providers/order_history_provider.dart';
import 'package:quickopia/services/driver_order_service.dart';
import 'package:quickopia/services/order_history_service.dart';
import 'package:quickopia/widgets/order_status_badge.dart';

class MockOrderHistoryService extends OrderHistoryService {
  final List<Order> mockOrders;
  MockOrderHistoryService(this.mockOrders);

  @override
  Future<List<Order>> fetchMyOrders(String customerId) async => mockOrders;
}

class MockDriverOrderService extends DriverOrderService {
  final List<Order> mockOrders;
  MockDriverOrderService(this.mockOrders);

  @override
  Future<List<Order>> fetchAssignedOrders(String driverId) async => mockOrders;

  @override
  Future<List<Order>> fetchAvailableOrders() async => [];

  @override
  Future<List<Order>> fetchCompletedOrders(String driverId) async => [];
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SupabaseConfig.initialize();
  });
  group('Prompt 8: Models and OrderHistoryProvider', () {
    test('Address model correctly parses and serializes isDefault', () {
      final json = {
        'id': 'addr-1',
        'label': 'Home',
        'city': 'Dar es Salaam',
        'neighborhood': 'Sinza',
        'landmark': 'Big Tree',
        'house_details': 'Gate 4',
        'latitude': -6.78,
        'longitude': 39.22,
        'is_default': true,
      };

      final addr = Address.fromMap(json);
      expect(addr.id, 'addr-1');
      expect(addr.isDefault, true);

      final map = addr.toMap();
      expect(map['is_default'], true);
    });

    test('Order model parses delivery snapshot and coordinates', () {
      final json = {
        'id': 'ord-1',
        'order_number': 'ORD-1001',
        'fulfillment_type': 'delivery',
        'status': 'out_for_delivery',
        'pickup_code': '4321',
        'subtotal_tzs': 15000,
        'delivery_fee_tzs': 3000,
        'total_amount_tzs': 18000,
        'payment_method': 'cod',
        'payment_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'driver_id': 'driver-99',
        'delivery_neighborhood': 'Mikocheni B',
        'delivery_landmark': 'Opposite Puma Station',
        'customer_phone': '+255712345678',
        'delivery_latitude': -6.76,
        'delivery_longitude': 39.24,
      };

      final order = Order.fromMap(json);
      expect(order.deliveryNeighborhood, 'Mikocheni B');
      expect(order.deliveryLandmark, 'Opposite Puma Station');
      expect(order.customerPhone, '+255712345678');
      expect(order.deliveryLatitude, -6.76);
      expect(order.deliveryLongitude, 39.24);
      expect(order.driverId, 'driver-99');
    });

    test('OrderHistoryProvider splits active and past orders properly', () async {
      final orders = [
        Order(
          id: '1',
          orderNumber: '101',
          fulfillmentType: 'delivery',
          status: 'placed',
          pickupCode: '1111',
          subtotalTzs: 5000,
          deliveryFeeTzs: 3000,
          totalAmountTzs: 8000,
          paymentMethod: 'cod',
          paymentStatus: 'pending',
          createdAt: DateTime.now(),
          items: [],
        ),
        Order(
          id: '2',
          orderNumber: '102',
          fulfillmentType: 'pickup',
          status: 'ready',
          pickupCode: '2222',
          subtotalTzs: 10000,
          deliveryFeeTzs: 0,
          totalAmountTzs: 10000,
          paymentMethod: 'cash_pickup',
          paymentStatus: 'pending',
          createdAt: DateTime.now(),
          items: [],
        ),
        Order(
          id: '3',
          orderNumber: '103',
          fulfillmentType: 'delivery',
          status: 'delivered',
          pickupCode: '3333',
          subtotalTzs: 7000,
          deliveryFeeTzs: 3000,
          totalAmountTzs: 10000,
          paymentMethod: 'cod',
          paymentStatus: 'paid',
          createdAt: DateTime.now(),
          items: [],
        ),
        Order(
          id: '4',
          orderNumber: '104',
          fulfillmentType: 'pickup',
          status: 'cancelled',
          pickupCode: '4444',
          subtotalTzs: 4000,
          deliveryFeeTzs: 0,
          totalAmountTzs: 4000,
          paymentMethod: 'cash_pickup',
          paymentStatus: 'cancelled',
          createdAt: DateTime.now(),
          items: [],
        ),
      ];

      final provider = OrderHistoryProvider(
        service: MockOrderHistoryService(orders),
      );

      expect(provider.status, HistoryStatus.idle);
      await provider.load('cust-1');

      expect(provider.status, HistoryStatus.loaded);
      expect(provider.orders.length, 4);
      expect(provider.activeOrders.length, 2); // placed, ready
      expect(provider.pastOrders.length, 2); // delivered, cancelled

      provider.clear();
      expect(provider.orders.isEmpty, true);
      expect(provider.status, HistoryStatus.idle);
    });
  });

  group('Prompt 9: DriverOrdersProvider & OrderStatusBadge', () {
    test('DriverOrdersProvider loads assigned orders and clears cleanly', () async {
      final assignedOrder = Order(
        id: 'ord-d1',
        orderNumber: 'D-101',
        fulfillmentType: 'delivery',
        status: 'out_for_delivery',
        pickupCode: '9876',
        subtotalTzs: 12000,
        deliveryFeeTzs: 3000,
        totalAmountTzs: 15000,
        paymentMethod: 'cod',
        paymentStatus: 'pending',
        createdAt: DateTime.now(),
        items: [
          OrderItem(
            id: 'item-1',
            productId: 'p-1',
            title: 'Sugar 1kg',
            unitPriceTzs: 3500,
            quantity: 2,
            totalTzs: 7000,
          ),
        ],
        driverId: 'driver-1',
        customerPhone: '+255712345678',
        deliveryNeighborhood: 'Kijitonyama',
        deliveryLandmark: 'Sayansi',
      );

      final provider = DriverOrdersProvider(
        service: MockDriverOrderService([assignedOrder]),
      );

      expect(provider.status, DriverOrdersStatus.loading);
      provider.start('driver-1');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.status, DriverOrdersStatus.loaded);
      expect(provider.orders.length, 1);
      expect(provider.orders.first.orderNumber, 'D-101');

      provider.clear();
      expect(provider.orders.isEmpty, true);
      provider.dispose();
    });

    testWidgets('OrderStatusBadge renders correct label and color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OrderStatusBadge(status: 'placed'),
                OrderStatusBadge(status: 'out_for_delivery'),
                OrderStatusBadge(status: 'delivered'),
                OrderStatusBadge(status: 'cancelled'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Placed'), findsOneWidget);
      expect(find.text('On the way'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });
  });
}
