import 'package:flutter_test/flutter_test.dart';
import 'package:quickopia/models/profile_model.dart';

void main() {
  group('Profile Model Tests', () {
    test('Profile.fromMap parses customer role correctly', () {
      final map = {
        'id': 'user-123',
        'full_name': 'Baraka Juma',
        'phone': '+255712345678',
        'role': 'customer',
        'branch_id': null,
      };

      final profile = Profile.fromMap(map);

      expect(profile.id, 'user-123');
      expect(profile.fullName, 'Baraka Juma');
      expect(profile.phone, '+255712345678');
      expect(profile.role, 'customer');
      expect(profile.branchId, isNull);
      expect(profile.isCustomer, isTrue);
      expect(profile.isDriver, isFalse);
      expect(profile.isAdmin, isFalse);
    });

    test('Profile.fromMap parses driver role correctly', () {
      final map = {
        'id': 'driver-456',
        'full_name': 'Hassan Ali',
        'phone': '+255788112233',
        'role': 'driver',
        'branch_id': 'branch-001',
      };

      final profile = Profile.fromMap(map);

      expect(profile.id, 'driver-456');
      expect(profile.fullName, 'Hassan Ali');
      expect(profile.phone, '+255788112233');
      expect(profile.role, 'driver');
      expect(profile.branchId, 'branch-001');
      expect(profile.isCustomer, isFalse);
      expect(profile.isDriver, isTrue);
      expect(profile.isAdmin, isFalse);
    });

    test('Profile.fromMap parses admin role correctly', () {
      final map = {
        'id': 'admin-789',
        'full_name': 'System Administrator',
        'phone': '+255755998877',
        'role': 'admin',
        'branch_id': null,
      };

      final profile = Profile.fromMap(map);

      expect(profile.id, 'admin-789');
      expect(profile.fullName, 'System Administrator');
      expect(profile.role, 'admin');
      expect(profile.isCustomer, isFalse);
      expect(profile.isDriver, isFalse);
      expect(profile.isAdmin, isTrue);
    });

    test('Profile defaults to customer if role is missing or null', () {
      final map = {
        'id': 'default-user',
        'full_name': 'New User',
        'phone': null,
      };

      final profile = Profile.fromMap(map);

      expect(profile.role, 'customer');
      expect(profile.isCustomer, isTrue);
    });

    test('Profile.toMap encodes correctly', () {
      final profile = Profile(
        id: 'test-id',
        fullName: 'Test Person',
        phone: '+255655000111',
        role: 'customer',
        branchId: 'b-1',
      );

      final map = profile.toMap();

      expect(map['id'], 'test-id');
      expect(map['full_name'], 'Test Person');
      expect(map['phone'], '+255655000111');
      expect(map['role'], 'customer');
      expect(map['branch_id'], 'b-1');
    });
  });
}
