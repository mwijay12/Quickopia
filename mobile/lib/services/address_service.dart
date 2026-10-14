import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/address_model.dart';

class AddressService {
  final SupabaseClient? _customClient;

  AddressService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  Future<List<Address>> fetchSavedAddresses(String profileId) async {
    final response = await _client
        .from('addresses')
        .select()
        .eq('profile_id', profileId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => Address.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> saveAddress({
    required String profileId,
    required String label,
    required String city,
    required String neighborhood,
    required String landmark,
    String? houseDetails,
    double? latitude,
    double? longitude,
    bool isDefault = false,
    String? phone,
  }) async {
    if (isDefault) {
      await _client
          .from('addresses')
          .update({'is_default': false})
          .eq('profile_id', profileId);
    }

    final payload = <String, dynamic>{
      'profile_id': profileId,
      'label': label,
      'city': city,
      'neighborhood': neighborhood,
      'landmark': landmark,
      'house_details': houseDetails,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
    };

    if (phone != null && phone.trim().isNotEmpty) {
      payload['phone'] = phone.trim();
    }

    final response = await _client
        .from('addresses')
        .insert(payload)
        .select('id')
        .single();

    // Also keep profile phone updated so user contact is never lost
    if (phone != null && phone.trim().isNotEmpty) {
      try {
        await _client
            .from('profiles')
            .update({'phone': phone.trim()})
            .eq('id', profileId);
      } catch (_) {}
    }

    return response['id'] as String;
  }

  Future<void> deleteAddress(String addressId) async {
    await _client.from('addresses').delete().eq('id', addressId);
  }

  Future<void> setDefaultAddress({
    required String profileId,
    required String addressId,
  }) async {
    await _client
        .from('addresses')
        .update({'is_default': false})
        .eq('profile_id', profileId);

    await _client
        .from('addresses')
        .update({'is_default': true})
        .eq('id', addressId);
  }
}
