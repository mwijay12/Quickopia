import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickopia/data/dar_locations_repository.dart';
import 'package:quickopia/models/address_model.dart';
import 'package:quickopia/services/notification_service.dart';
import 'package:quickopia/utils/validators.dart';

void main() {
  group('Dar es Salaam Cascading Locations from Tanzania Locations DB', () {
    test('All 5 official districts exist with exact official ward counts', () {
      final districts = DarLocationsRepository.districtNames;
      expect(districts, ['Kinondoni', 'Ilala', 'Ubungo', 'Temeke', 'Kigamboni']);

      // Kinondoni official wards
      final kinondoniWards = DarLocationsRepository.getWards('Kinondoni');
      expect(kinondoniWards.length, 20);
      final kinondoniNames = kinondoniWards.map((w) => w.wardName).toList();
      expect(kinondoniNames, containsAll([
        'Bunju', 'Hananasif', 'Kawe', 'Kigogo', 'Kijitonyama', 'Kinondoni',
        'Kunduchi', 'Mabwepande', 'Magomeni', 'Makongo', 'Makumbusho',
        'Mbezi Juu', 'Mbweni', 'Mikocheni', 'Msasani', 'Mwananyamala',
        'Mzimuni', 'Ndugumbi', 'Tandale', 'Wazo'
      ]));

      // Ilala official wards
      final ilalaWards = DarLocationsRepository.getWards('Ilala');
      expect(ilalaWards.length, 36);
      final ilalaNames = ilalaWards.map((w) => w.wardName).toList();
      expect(ilalaNames, containsAll([
        'Bonyokwa', 'Buguruni', 'Buyuni', 'Chanika', 'Gerezani', 'Gongo la Mboto',
        'Ilala', 'Jangwani', 'Kariakoo', 'Kimanga', 'Kinyerezi', 'Kipawa',
        'Kipunguni', 'Kisukulu', 'Kisutu', 'Kitunda', 'Kivukoni', 'Kivule',
        'Kiwalani', 'Liwiti', 'Majohe', 'Mchafukoge', 'Mchikichini',
        'Minazi Mirefu', 'Mnyamani', 'Msongola', 'Mzinga', 'Pugu',
        'Pugu Station', 'Segerea', 'Tabata', 'Ukonga', 'Upanga Magharibi',
        'Upanga Mashariki', 'Vingunguti', 'Zingiziwa'
      ]));

      // Ubungo official wards
      final ubungoWards = DarLocationsRepository.getWards('Ubungo');
      expect(ubungoWards.length, 14);
      final ubungoNames = ubungoWards.map((w) => w.wardName).toList();
      expect(ubungoNames, containsAll([
        'Goba', 'Kibamba', 'Kimara', 'Kwembe', 'Mabibo', 'Makuburi',
        'Makurumla', 'Manzese', 'Mbezi', 'Mburahati', 'Msigani',
        'Saranga', 'Sinza', 'Ubungo'
      ]));

      // Temeke official wards
      final temekeWards = DarLocationsRepository.getWards('Temeke');
      expect(temekeWards.length, 23);
      final temekeNames = temekeWards.map((w) => w.wardName).toList();
      expect(temekeNames, containsAll([
        'Azimio', 'Buza', 'Chamazi', "Chang'ombe", 'Charambe', 'Keko',
        'Kibondemaji', 'Kiburugwa', 'Kijichi', 'Kilakala', 'Kilungule',
        'Kurasini', 'Makangarawe', 'Mbagala', 'Mbagala Kuu', 'Mianzini',
        'Miburani', 'Mtoni', 'Sandali', 'Tandika', 'Temeke', 'Toangoma',
        'Yombo Vituka'
      ]));

      // Kigamboni official wards
      final kigamboniWards = DarLocationsRepository.getWards('Kigamboni');
      expect(kigamboniWards.length, 9);
      final kigamboniNames = kigamboniWards.map((w) => w.wardName).toList();
      expect(kigamboniNames, containsAll([
        'Kibada', 'Kigamboni', 'Kimbiji', 'Kisarawe II', 'Mjimwema',
        'Pembamnazi', 'Somangila', 'Tungi', 'Vijibweni'
      ]));
    });

    test('Cascading dropdown logic: selecting district gives constituent wards and streets', () {
      final kinondoniWards = DarLocationsRepository.getWardsForDistrict('Kinondoni');
      final msasani = kinondoniWards.firstWhere((w) => w.wardName == 'Msasani');
      expect(msasani.popularStreets, contains('Oysterbay'));
      expect(msasani.popularStreets, contains('Masaki'));

      final sinza = DarLocationsRepository.findWard('Sinza', 'Ubungo');
      expect(sinza, isNotNull);
      expect(sinza!.popularStreets, contains('Shekilango Rd'));
      expect(sinza.popularStreets, contains('Sinza Mori'));
    });
  });

  group('Address and Phone Persistence Tests', () {
    test('Address model serialization includes phone number', () {
      final address = Address(
        id: 'addr-123',
        label: 'Home',
        city: 'Dar es Salaam',
        neighborhood: 'Mikocheni, Kinondoni',
        landmark: 'Near Mwai Kibaki Rd',
        houseDetails: 'Gate 42, Black Gate',
        latitude: -6.7725,
        longitude: 39.2450,
        isDefault: true,
        phone: '+255712345678',
      );

      expect(address.phone, '+255712345678');

      final map = address.toMap();
      expect(map['phone'], '+255712345678');
      expect(map['neighborhood'], 'Mikocheni, Kinondoni');

      final deserialized = Address.fromMap(map);
      expect(deserialized.phone, '+255712345678');
      expect(deserialized.label, 'Home');
      expect(deserialized.isDefault, isTrue);
    });

    test('Tanzanian phone number validation and normalization', () {
      expect(Validators.isValidTzPhone('0712345678'), isTrue);
      expect(Validators.isValidTzPhone('+255712345678'), isTrue);
      expect(Validators.isValidTzPhone('255712345678'), isTrue);
      expect(Validators.isValidTzPhone('0655123456'), isTrue);
      expect(Validators.isValidTzPhone('12345'), isFalse);
      expect(Validators.isValidTzPhone(''), isFalse);

      expect(Validators.normalizeTzPhone('0712345678'), '+255712345678');
      expect(Validators.normalizeTzPhone('255712345678'), '+255712345678');
      expect(Validators.normalizeTzPhone('+255712345678'), '+255712345678');
    });
  });

  group('Notification Service and Top Banner Tests', () {
    test('NotificationService singleton initializes without crashing in test', () async {
      final service = NotificationService();
      await service.initialize();
      expect(service, isNotNull);
    });

    testWidgets('Top In-App banner displays with Quickopia theme and copy', (tester) async {
      final key = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      NotificationService().showTopInAppBanner(
                        title: 'Order Confirmed! 🎉 #ORD-2026-0001',
                        body: 'Your supermarket order has been received.',
                        context: context,
                      );
                    },
                    child: const Text('Show Notification'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Notification'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Order Confirmed! 🎉 #ORD-2026-0001'), findsOneWidget);
      expect(find.text('Your supermarket order has been received.'), findsOneWidget);
      expect(find.text('NOW'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    });
  });
}
