import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickopia/models/order_item_model.dart';
import 'package:quickopia/models/order_model.dart';
import 'package:quickopia/models/profile_model.dart';
import 'package:quickopia/providers/auth_provider.dart';
import 'package:quickopia/screens/customer/live_order_tracking_screen.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  AuthStatus status = AuthStatus.authenticated;
  @override
  Profile? profile = Profile(
    id: 'user-1',
    fullName: 'Juma Mteja',
    phone: '+255712000000',
    role: 'customer',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
  );
  @override
  String? errorMessage;
  @override
  bool get isAuthenticated => true;
  @override
  Future<String?> signIn({required String email, required String password}) async => null;
  @override
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async => {'success': true, 'requiresEmailConfirmation': false, 'error': null};
  @override
  Future<void> signOut() async {}
  @override
  Future<void> reloadProfile() async {}
}

void main() {
  group('Profile Model Customization Tests', () {
    test('Profile serializes and deserializes avatarUrl, bio, and vehicleInfo', () {
      final map = {
        'id': 'p-1',
        'full_name': 'Bakari Dereva',
        'phone': '+255789123456',
        'role': 'driver',
        'avatar_url': 'https://example.com/avatar.jpg',
        'vehicle_info': 'Honda Ace 125 • T 412 DFG',
        'rating': 4.95,
        'referral_count': 3,
      };

      final profile = Profile.fromMap(map);
      expect(profile.id, 'p-1');
      expect(profile.fullName, 'Bakari Dereva');
      expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
      expect(profile.vehicleInfo, 'Honda Ace 125 • T 412 DFG');
      expect(profile.rating, 4.95);
      expect(profile.isDriver, isTrue);

      final backToMap = profile.toMap();
      expect(backToMap['avatar_url'], 'https://example.com/avatar.jpg');
      expect(backToMap['vehicle_info'], 'Honda Ace 125 • T 412 DFG');
      expect(backToMap['rating'], 4.95);
    });
  });

  group('Order Model Driver Metadata Tests', () {
    test('Order provides driver metadata and sensible fallbacks when assigned', () {
      final order = Order(
        id: 'o-1',
        orderNumber: 'ORD-2026-7890',
        fulfillmentType: 'delivery',
        status: 'out_for_delivery',
        pickupCode: '1234',
        subtotalTzs: 25000,
        deliveryFeeTzs: 3000,
        totalAmountTzs: 28000,
        paymentMethod: 'cod',
        paymentStatus: 'pending',
        createdAt: DateTime.now(),
        items: [
          OrderItem(
            id: 'oi-1',
            productId: 'prod-1',
            title: 'Fresh Milk',
            unitPriceTzs: 2500,
            quantity: 2,
            totalTzs: 5000,
          ),
        ],
        driverId: 'd-1',
        driverName: 'Khalid Omor',
        driverPhone: '+255711223344',
        driverVehicle: 'Boxer 150 • T 888 AAA',
      );

      expect(order.effectiveDriverName, 'Khalid Omor');
      expect(order.effectiveDriverPhone, '+255711223344');
      expect(order.effectiveDriverVehicle, 'Boxer 150 • T 888 AAA');
      expect(order.effectiveDriverRating, 4.9);
    });
  });

  group('LiveOrderTrackingScreen Widget Tests', () {
    testWidgets('Renders Location Tracking title, booking ID, status, and driver contact buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final order = Order(
        id: 'ord-track-1',
        orderNumber: 'ORD-2026-9999',
        fulfillmentType: 'delivery',
        status: 'out_for_delivery',
        pickupCode: '5678',
        subtotalTzs: 35000,
        deliveryFeeTzs: 3000,
        totalAmountTzs: 38000,
        paymentMethod: 'cod',
        paymentStatus: 'pending',
        createdAt: DateTime.now(),
        deliveryNeighborhood: 'Mikocheni B',
        deliveryLandmark: 'Opposite TotalEnergies',
        items: [
          OrderItem(
            id: 'oi-1',
            productId: 'p-1',
            title: 'Cooking Oil',
            unitPriceTzs: 15000,
            quantity: 1,
            totalTzs: 15000,
          ),
        ],
        driverId: 'drv-1',
        driverName: 'Khalid Omor',
        driverPhone: '+255712345678',
        driverVehicle: 'Honda Ace 125 • T 412 DFG',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
          ],
          child: MaterialApp(
            home: LiveOrderTrackingScreen(order: order),
          ),
        ),
      );

      await tester.pump();

      // Top bar check
      expect(find.text('Location Tracking'), findsOneWidget);

      // Booking ID check
      expect(find.text('#ORD-2026-9999'), findsOneWidget);

      // Route check
      expect(find.text('Quickopia Mikocheni Store'), findsOneWidget);
      expect(find.textContaining('Mikocheni B'), findsOneWidget);

      // Driver check
      expect(find.text('Khalid Omor'), findsOneWidget);
      expect(find.textContaining('Courier • Honda Ace 125'), findsOneWidget);

      // Call and SMS action buttons check
      expect(find.byIcon(Icons.call), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);

      // Tap call button (safe invocation)
      await tester.tap(find.byIcon(Icons.call));
      await tester.pump();
    });
  });
}
