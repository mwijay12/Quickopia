import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickopia/models/category_model.dart';
import 'package:quickopia/models/product_model.dart';
import 'package:quickopia/models/support_message_model.dart';
import 'package:quickopia/providers/cart_provider.dart';
import 'package:quickopia/providers/catalog_provider.dart';
import 'package:quickopia/screens/customer/terms_and_conditions_screen.dart';
import 'package:quickopia/widgets/product_detail_sheet.dart';

class DummyCatalogForSheet extends ChangeNotifier implements CatalogProvider {
  @override
  CatalogStatus status = CatalogStatus.loaded;
  @override
  String? errorMessage;
  @override
  List<Product> products;
  @override
  List<Category> categories = const [];
  @override
  String? selectedCategoryId;
  @override
  String searchQuery = '';

  DummyCatalogForSheet({this.products = const []});

  @override
  Future<void> loadInitialData() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> search(String query) async {}
  @override
  Future<void> selectCategory(String? categoryId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Terms and Conditions Screen Tests', () {
    testWidgets('TermsAndConditionsScreen renders welcome card, clauses, and language toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TermsAndConditionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Official Service Agreement'), findsOneWidget);
      expect(find.textContaining('Welcome to Quickopia'), findsOneWidget);
      expect(find.text('I Understand & Agree'), findsOneWidget);
      expect(find.text('Customer Terms'), findsOneWidget);
      expect(find.text('Driver Guidelines'), findsOneWidget);

      // Switch to Driver Guidelines tab
      await tester.tap(find.text('Driver Guidelines'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Hygiene & Cold-Chain Grocery Transport'), findsOneWidget);
      expect(find.textContaining('Mandatory 6-Digit OTP Delivery Confirmation'), findsOneWidget);

      // Toggle to Swahili
      await tester.tap(find.text('Kiswahili'));
      await tester.pumpAndSettle();

      expect(find.text('Vigezo na Masharti'), findsOneWidget);
      expect(find.text('Mkataba Rasmi wa Huduma'), findsOneWidget);
      expect(find.text('Nimeelewa na Kukubaliana'), findsOneWidget);
      expect(find.textContaining('Uthibitisho wa Msimbo wa OTP'), findsOneWidget);
    });
  });

  group('Product Detail Sheet Variations & Similar Products Tests', () {
    testWidgets('ProductDetailSheet renders packaging variants chips and similar products', (tester) async {
      final sugarProduct = Product(
        id: 'prod-sugar-1',
        categoryId: 'cat-pantry',
        title: 'Kilombero Pure Cane White Sugar',
        priceTzs: 3200,
        unit: '1kg',
        stockQuantity: 50,
        isAvailable: true,
        isPopular: true,
      );

      final alternativeSugar = Product(
        id: 'prod-sugar-2',
        categoryId: 'cat-pantry',
        title: 'Bakhresa Fine Granulated Sugar',
        priceTzs: 3100,
        unit: '1kg',
        stockQuantity: 40,
        isAvailable: true,
        isPopular: false,
      );

      final catalog = DummyCatalogForSheet(products: [sugarProduct, alternativeSugar]);
      final cart = CartProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CatalogProvider>.value(value: catalog),
            ChangeNotifierProvider<CartProvider>.value(value: cart),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ProductDetailSheet(product: sugarProduct),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Title and Packaging Options
      expect(find.text('Kilombero Pure Cane White Sugar'), findsOneWidget);
      expect(find.text('Packaging & Size Options / Chaguzi za Ufungashaji:'), findsOneWidget);
      expect(find.text('500g Trial'), findsOneWidget);
      expect(find.text('1kg Standard'), findsOneWidget);
      expect(find.text('2kg Family'), findsOneWidget);
      expect(find.text('5kg Value'), findsOneWidget);

      // Verify Similar Products section rendered alternative sugar
      expect(find.text('Similar Products & Options / Bidhaa Zinazofanana'), findsOneWidget);
      expect(find.text('Bakhresa Fine Granulated Sugar'), findsOneWidget);
    });
  });

  group('In-App Support Message Model Tests', () {
    test('SupportMessage serialization and deserialization work correctly', () {
      final now = DateTime.now();
      final msg = SupportMessage(
        id: 'msg-101',
        conversationId: 'conv-55',
        senderId: 'user-001',
        senderRole: 'admin',
        senderName: 'Shoppers Support Desk',
        content: 'Habari! Order yako inafungashwa sasa hivi.',
        isRead: false,
        createdAt: now,
      );

      final map = msg.toMap();
      expect(map['id'], 'msg-101');
      expect(map['sender_role'], 'admin');
      expect(map['content'], contains('inafungashwa'));

      final restored = SupportMessage.fromMap(map);
      expect(restored.id, 'msg-101');
      expect(restored.conversationId, 'conv-55');
      expect(restored.senderName, 'Shoppers Support Desk');
      expect(restored.senderRole, 'admin');
      expect(restored.content, contains('inafungashwa'));
    });
  });
}
