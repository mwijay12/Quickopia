import 'package:flutter_test/flutter_test.dart';
import 'package:quickopia/config/app_constants.dart';
import 'package:quickopia/models/address_model.dart';
import 'package:quickopia/models/branch_model.dart';
import 'package:quickopia/models/checkout_data_model.dart';
import 'package:quickopia/models/delivery_zone_model.dart';
import 'package:quickopia/utils/validators.dart';

void main() {
  group('Branch Model', () {
    test('Maps from and to database map', () {
      final map = {
        'id': 'b123',
        'name': 'Quickopia Mikocheni',
        'city': 'Dar es Salaam',
        'neighborhood': 'Mikocheni B',
        'landmark': 'Near Shoppers Plaza',
        'phone': '+255755123456',
      };

      final branch = Branch.fromMap(map);
      expect(branch.id, 'b123');
      expect(branch.name, 'Quickopia Mikocheni');
      expect(branch.city, 'Dar es Salaam');
      expect(branch.neighborhood, 'Mikocheni B');
      expect(branch.landmark, 'Near Shoppers Plaza');
      expect(branch.phone, '+255755123456');

      final serialized = branch.toMap();
      expect(serialized['id'], 'b123');
      expect(serialized['phone'], '+255755123456');
    });
  });

  group('Address Model', () {
    test('Maps from and to database map with double precision coords', () {
      final map = {
        'id': 'addr-1',
        'label': 'Home Sinza',
        'city': 'Dar es Salaam',
        'neighborhood': 'Sinza Mori',
        'landmark': 'Opposite TotalEnergies',
        'house_details': 'House #4B, White gate',
        'latitude': -6.7820,
        'longitude': 39.2210,
      };

      final address = Address.fromMap(map);
      expect(address.id, 'addr-1');
      expect(address.label, 'Home Sinza');
      expect(address.city, 'Dar es Salaam');
      expect(address.neighborhood, 'Sinza Mori');
      expect(address.landmark, 'Opposite TotalEnergies');
      expect(address.houseDetails, 'House #4B, White gate');
      expect(address.latitude, -6.7820);
      expect(address.longitude, 39.2210);

      final backToMap = address.toMap();
      expect(backToMap['neighborhood'], 'Sinza Mori');
      expect(backToMap['latitude'], -6.7820);
    });
  });

  group('CheckoutData Model', () {
    test('Assembles delivery payload correctly', () {
      final data = CheckoutData(
        fulfillmentType: 'delivery',
        city: 'Dar es Salaam',
        neighborhood: 'Oysterbay',
        landmark: 'Near Coco Beach',
        houseDetails: 'Plot 12',
        latitude: -6.7680,
        longitude: 39.2740,
        customerPhone: '+255712345678',
        paymentMethod: 'cod',
        paymentReference: null,
        subtotalTzs: 15000.0,
        deliveryFeeTzs: AppConstants.flatDeliveryFeeTzs,
        totalTzs: 18000.0,
      );

      expect(data.fulfillmentType, 'delivery');
      expect(data.deliveryFeeTzs, 3000.0);
      expect(data.totalTzs, 18000.0);
      expect(data.customerPhone, '+255712345678');
    });

    test('Assembles pickup payload correctly with 0 fee', () {
      final data = CheckoutData(
        fulfillmentType: 'pickup',
        customerPhone: '+255712345678',
        paymentMethod: 'lipa_namba',
        paymentReference: 'TXN998822',
        subtotalTzs: 10000.0,
        deliveryFeeTzs: 0.0,
        totalTzs: 10000.0,
      );

      expect(data.fulfillmentType, 'pickup');
      expect(data.city, isNull);
      expect(data.landmark, isNull);
      expect(data.deliveryFeeTzs, 0.0);
      expect(data.totalTzs, 10000.0);
      expect(data.paymentReference, 'TXN998822');
    });
  });

  group('Validators Utility', () {
    test('requiredField validates null and empty strings', () {
      expect(Validators.requiredField(null, label: 'Name'), 'Name is required');
      expect(Validators.requiredField('   ', label: 'City'), 'City is required');
      expect(Validators.requiredField('Dar es Salaam'), isNull);
    });

    test('isValidTzPhone and normalizeTzPhone handle local and international formats', () {
      expect(Validators.isValidTzPhone('0712345678'), isTrue);
      expect(Validators.isValidTzPhone('+255712345678'), isTrue);
      expect(Validators.isValidTzPhone('0812345678'), isFalse);

      expect(Validators.normalizeTzPhone('0712345678'), '+255712345678');
      expect(Validators.normalizeTzPhone('+255712345678'), '+255712345678');
    });
  });

  group('DeliveryZone Model', () {
    test('Calculates total delivery fee with fuel surcharge correctly', () {
      final zone1 = DeliveryZone.defaultZones.first;
      expect(zone1.baseDeliveryFeeTzs, 2500.0);
      expect(zone1.fuelSurchargeTzs, 500.0);
      expect(zone1.totalDeliveryFeeTzs, 3000.0);

      final zone4 = DeliveryZone.defaultZones.last;
      expect(zone4.baseDeliveryFeeTzs, 10000.0);
      expect(zone4.fuelSurchargeTzs, 2500.0);
      expect(zone4.totalDeliveryFeeTzs, 12500.0);
    });

    test('Finds delivery zone by ward name or defaults correctly', () {
      final kinondoniZone = DeliveryZone.findByWard('Sinza');
      expect(kinondoniZone.code, 'ZONE_1');

      final bunjuZone = DeliveryZone.findByWard('Bunju');
      expect(bunjuZone.code, 'ZONE_4');

      final unknownWardZone = DeliveryZone.findByWard('Unknown Area');
      expect(unknownWardZone.code, 'ZONE_2'); // Default fallback
    });
  });
}
