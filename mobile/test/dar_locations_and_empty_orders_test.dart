import 'package:flutter_test/flutter_test.dart';
import 'package:quickopia/data/dar_locations_repository.dart';
import 'package:quickopia/providers/order_history_provider.dart';

void main() {
  group('DarLocationsRepository Unit Tests', () {
    test('Contains all 5 official Dar es Salaam districts', () {
      final districts = DarLocationsRepository.districtNames;
      expect(districts, containsAll(['Kinondoni', 'Ilala', 'Ubungo', 'Temeke', 'Kigamboni']));
      expect(districts.length, 5);
    });

    test('Kinondoni has essential wards with valid GPS coordinates', () {
      final wards = DarLocationsRepository.getWardsForDistrict('Kinondoni');
      expect(wards.isNotEmpty, isTrue);

      final wardNames = wards.map((w) => w.wardName).toList();
      expect(wardNames.any((name) => name.contains('Mikocheni')), isTrue);
      expect(wardNames.any((name) => name.contains('Msasani')), isTrue);
      expect(wardNames.any((name) => name.contains('Kijitonyama')), isTrue);

      for (final w in wards) {
        // Dar es Salaam coordinates bounding box
        expect(w.center.latitude, lessThan(-6.5));
        expect(w.center.latitude, greaterThan(-7.2));
        expect(w.center.longitude, greaterThan(39.0));
        expect(w.center.longitude, lessThan(39.5));
      }
    });

    test('findWard successfully locates ward across districts and provides popular streets', () {
      final mikocheni = DarLocationsRepository.findWard('Mikocheni');
      expect(mikocheni, isNotNull);
      expect(mikocheni!.wardName, 'Mikocheni');
      expect(mikocheni.popularStreets, isNotEmpty);
      expect(mikocheni.popularStreets, contains('Mwai Kibaki Road'));

      final kariakoo = DarLocationsRepository.findWard('Kariakoo');
      expect(kariakoo, isNotNull);
      expect(kariakoo!.wardName, 'Kariakoo');
      expect(kariakoo.popularStreets, contains('Msimbazi St'));
    });

    test('findWard returns null for non-existent ward name gracefully', () {
      final notFound = DarLocationsRepository.findWard('NonExistentWardXYZ');
      expect(notFound, isNull);
    });
  });

  group('OrderHistoryProvider Empty State & Error Resilience Tests', () {
    test('Provider initializes with idle status and empty orders list', () {
      final provider = OrderHistoryProvider();
      expect(provider.status, HistoryStatus.idle);
      expect(provider.orders, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.activeOrders, isEmpty);
      expect(provider.pastOrders, isEmpty);
    });
  });
}
