import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickopia/models/broadcast_notification_model.dart';
import 'package:quickopia/models/supermarket_settings_model.dart';
import 'package:quickopia/providers/supermarket_provider.dart';
import 'package:quickopia/screens/customer/notifications_sheet.dart';
import 'package:quickopia/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supermarket Settings & Profile Tests', () {
    test('SupermarketSettings model initializes with default Quickopia identity', () {
      const defaultSettings = SupermarketSettings();
      expect(defaultSettings.supermarketName, 'Quickopia');
      expect(defaultSettings.branchAddress, contains('Dar es Salaam'));
      expect(defaultSettings.currencySymbol, 'TZS');
      expect(defaultSettings.phone, '+255 712 345 678');
      expect(defaultSettings.isActive, isTrue);
    });

    test('SupermarketSettings fromMap correctly extracts custom supermarket name and address', () {
      final map = {
        'id': 'branch_settings',
        'supermarket_name': 'Village Supermarket Masaki',
        'tagline': 'Gourmet grocer & bakery',
        'branch_address': 'Sea Cliff Village, Toure Dr, Masaki',
        'city': 'Dar es Salaam',
        'phone': '+255 788 123 456',
        'operating_hours': '08:00 AM - 11:00 PM',
        'currency_symbol': 'TZS',
      };

      final settings = SupermarketSettings.fromMap(map);
      expect(settings.supermarketName, 'Village Supermarket Masaki');
      expect(settings.tagline, 'Gourmet grocer & bakery');
      expect(settings.branchAddress, 'Sea Cliff Village, Toure Dr, Masaki');
      expect(settings.phone, '+255 788 123 456');
    });

    test('SupermarketSettings fromMap falls back to restaurant_name if supermarket_name is null', () {
      final map = {
        'restaurant_name': 'Bongo Fresh Mart',
      };
      final settings = SupermarketSettings.fromMap(map);
      expect(settings.supermarketName, 'Bongo Fresh Mart');
    });

    test('SupermarketProvider provides default supermarket details in testing mode', () {
      final provider = SupermarketProvider();
      expect(provider.supermarketName, 'Quickopia');
      expect(provider.branchAddress, contains('Dar es Salaam'));
    });
  });

  group('Broadcast Notifications Tests', () {
    test('BroadcastNotification model parses offer, reminder, and alert payloads', () {
      final offerMap = {
        'id': 'notif-101',
        'title': 'Weekend Farm Fresh Sale! 🥦',
        'body': '25% OFF all fresh veggies and organic fruit baskets.',
        'type': 'offer',
        'target_audience': 'all',
        'image_url': 'https://example.com/banner.jpg',
        'created_at': '2026-09-05T01:00:00Z',
      };

      final notif = BroadcastNotification.fromMap(offerMap);
      expect(notif.id, 'notif-101');
      expect(notif.title, contains('Weekend Farm Fresh'));
      expect(notif.type, 'offer');
      expect(notif.imageUrl, 'https://example.com/banner.jpg');
      expect(notif.isRead, isFalse);
    });

    testWidgets('NotificationsSheet renders empty state gracefully', (tester) async {
      NotificationService().broadcastsNotifier.value = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationsSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Broadcasts & Alerts'), findsOneWidget);
      expect(find.text('No notifications right now'), findsOneWidget);
    });

    testWidgets('NotificationsSheet renders active broadcasts cards with type badges', (tester) async {
      final sampleNotif = BroadcastNotification(
        id: 'notif-999',
        title: 'Fresh Croissants Alert 🥐',
        body: 'Hot bakery items ready for morning dispatch!',
        type: 'offer',
        createdAt: DateTime.now(),
      );

      NotificationService().broadcastsNotifier.value = [sampleNotif];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationsSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Broadcasts & Alerts'), findsOneWidget);
      expect(find.text('Fresh Croissants Alert 🥐'), findsOneWidget);
      expect(find.text('Hot bakery items ready for morning dispatch!'), findsOneWidget);
      expect(find.text('OFFER'), findsOneWidget);
    });
  });
}
