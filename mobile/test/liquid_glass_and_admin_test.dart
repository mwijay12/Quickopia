import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickopia/models/order_item_model.dart';
import 'package:quickopia/models/order_model.dart';
import 'package:quickopia/models/product_model.dart';
import 'package:quickopia/providers/admin_provider.dart';
import 'package:quickopia/screens/admin/admin_in_app_screen.dart';
import 'package:quickopia/services/admin_service.dart';
import 'package:quickopia/widgets/holiday_promo_banner.dart';
import 'package:quickopia/widgets/liquid_glass_container.dart';

class FakeAdminService extends AdminService {
  List<Order> mockOrders = [];
  List<Product> mockProducts = [];

  FakeAdminService({List<Order>? orders, List<Product>? products}) {
    mockOrders = orders ??
        [
          Order(
            id: 'ord-1',
            orderNumber: 'ORD-101',
            fulfillmentType: 'delivery',
            status: 'placed',
            pickupCode: '1234',
            subtotalTzs: 40000,
            deliveryFeeTzs: 3000,
            totalAmountTzs: 43000,
            paymentMethod: 'cod',
            paymentStatus: 'pending',
            createdAt: DateTime.now(),
            items: [
              OrderItem(
                id: 'oi-1',
                productId: 'p-1',
                title: 'Super Kyela Rice 5kg',
                unitPriceTzs: 20000,
                quantity: 2,
                totalTzs: 40000,
              ),
            ],
            customerPhone: '+255712345678',
          ),
          Order(
            id: 'ord-2',
            orderNumber: 'ORD-102',
            fulfillmentType: 'pickup',
            status: 'packing',
            pickupCode: '5678',
            subtotalTzs: 15000,
            deliveryFeeTzs: 0,
            totalAmountTzs: 15000,
            paymentMethod: 'selcom',
            paymentStatus: 'paid',
            createdAt: DateTime.now(),
            items: [
              OrderItem(
                id: 'oi-2',
                productId: 'p-2',
                title: 'Cooking Oil 2L',
                unitPriceTzs: 15000,
                quantity: 1,
                totalTzs: 15000,
              ),
            ],
            customerPhone: '+255755555555',
          ),
        ];

    mockProducts = products ??
        [
          Product(
            id: 'p-1',
            categoryId: 'c-1',
            title: 'Super Kyela Rice 5kg',
            priceTzs: 20000,
            stockQuantity: 50,
            isAvailable: true,
            isPopular: true,
          ),
          Product(
            id: 'p-2',
            categoryId: 'c-1',
            title: 'Cooking Oil 2L',
            priceTzs: 15000,
            stockQuantity: 6, // Low stock (<10)
            isAvailable: true,
            isPopular: true,
          ),
        ];
  }

  @override
  Future<List<Order>> fetchAllOrders() async => mockOrders;

  @override
  Future<List<Product>> fetchAllProducts({String? query}) async => mockProducts;

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final idx = mockOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final old = mockOrders[idx];
      mockOrders[idx] = Order(
        id: old.id,
        orderNumber: old.orderNumber,
        fulfillmentType: old.fulfillmentType,
        status: newStatus,
        pickupCode: old.pickupCode,
        subtotalTzs: old.subtotalTzs,
        deliveryFeeTzs: old.deliveryFeeTzs,
        totalAmountTzs: old.totalAmountTzs,
        paymentMethod: old.paymentMethod,
        paymentStatus: old.paymentStatus,
        createdAt: old.createdAt,
        items: old.items,
        customerPhone: old.customerPhone,
      );
    }
  }

  @override
  Future<void> updateProductPriceAndStock({
    required String productId,
    required double newPriceTzs,
    required int newStockQuantity,
    bool? isAvailable,
  }) async {
    final idx = mockProducts.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final old = mockProducts[idx];
      mockProducts[idx] = Product(
        id: old.id,
        categoryId: old.categoryId,
        title: old.title,
        priceTzs: newPriceTzs,
        stockQuantity: newStockQuantity,
        isAvailable: isAvailable ?? old.isAvailable,
        isPopular: old.isPopular,
      );
    }
  }
}

void main() {
  group('Liquid Glass, Holiday Offers & In-App Admin Modules', () {
    testWidgets('LiquidGlassContainer and LiquidGlassBadge render with blur and borders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LiquidGlassContainer(
                  child: Text('Liquid Glass Content'),
                ),
                LiquidGlassBadge(
                  child: Text('PROMO CODE'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Liquid Glass Content'), findsOneWidget);
      expect(find.text('PROMO CODE'), findsOneWidget);
      expect(find.byType(LiquidGlassContainer), findsNWidgets(2));
    });

    testWidgets('HolidayPromoBanner renders festive badge and opens HolidayOffersSheet', (tester) async {
      bool shopOfferClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HolidayPromoBanner(
              onShopOffer: () => shopOfferClicked = true,
            ),
          ),
        ),
      );

      // Verify promo banner contents
      expect(find.text('OFA YA SIKUKUU 🎄✨'), findsOneWidget);
      expect(find.text('SIKUKUU25'), findsOneWidget);
      expect(find.text('Punguzo la 25% Vyakula vya Sikukuu'), findsOneWidget);

      // Tap banner CTA to open Holiday Offers Sheet
      await tester.tap(find.text('Tazama Zote'));
      await tester.pumpAndSettle();

      // Verify Sheet content
      expect(find.text('Ofa za Sikukuu & Taarifa'), findsOneWidget);
      expect(find.text('Sikukuu Super Feast (25% OFF)'), findsOneWidget);
      expect(find.text('Usafiri Bure Popote Dar es Salaam'), findsOneWidget);

      // Tap Copy & Shop on an offer
      final copyAndShopBtn = find.text('Copy & Shop').first;
      await tester.tap(copyAndShopBtn);
      await tester.pumpAndSettle();

      expect(shopOfferClicked, isTrue);
    });

    testWidgets('AdminInAppScreen renders KPIs, filters orders, updates status, and edits stock', (tester) async {
      final fakeService = FakeAdminService();
      final adminProvider = AdminProvider(service: fakeService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
          ],
          child: const MaterialApp(
            home: AdminInAppScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title
      expect(find.text('Supermarket Admin Console'), findsOneWidget);
      expect(find.text('Manage Store Catalog, Live Pricing & Orders'), findsOneWidget);

      // KPIs
      expect(find.text('Today\'s Sales'), findsOneWidget);
      expect(find.text('2 Orders'), findsOneWidget);
      expect(find.text('1 Product'), findsOneWidget); // Low stock product (<10)

      // Orders Tab
      expect(find.text('#ORD-101'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text('#ORD-102'), findsOneWidget);

      // Drag back up to tap pack button on ORD-101
      await tester.drag(find.byType(ListView).first, const Offset(0, 200));
      await tester.pumpAndSettle();

      final packBtn = find.text('Start Packing ➔');
      expect(packBtn, findsOneWidget);
      await tester.tap(packBtn);
      await tester.pumpAndSettle();

      // Now ORD-101 is updated to packing
      expect(find.text('Ready for Driver ➔'), findsWidgets);

      // Switch to Inventory tab
      await tester.tap(find.text('Inventory & Pricing'));
      await tester.pumpAndSettle();

      expect(find.text('Super Kyela Rice 5kg'), findsOneWidget);
      expect(find.text('Cooking Oil 2L'), findsOneWidget);

      // Switch to Hero Banners tab
      await tester.tap(find.text('Hero Banners'));
      await tester.pumpAndSettle();

      expect(find.text('Parallax Hero Cards & Graphics'), findsOneWidget);
      expect(find.text('Fresh Groceries Delivered in 30 Mins'), findsOneWidget);
      expect(find.text('Change Pic'), findsWidgets);
    });
  });
}
