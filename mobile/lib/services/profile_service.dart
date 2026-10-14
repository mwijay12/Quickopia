import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ProfileService {
  final SupabaseClient? _customClient;

  ProfileService({SupabaseClient? client}) : _customClient = client;

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  String? get currentEmail {
    try {
      return _client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateBasicInfo({
    required String profileId,
    required String fullName,
    required String phone,
    String? avatarUrl,
    String? bio,
    String? vehicleInfo,
  }) async {
    final data = <String, dynamic>{
      'full_name': fullName,
      'phone': phone,
    };
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (bio != null) data['bio'] = bio;
    if (vehicleInfo != null) data['vehicle_info'] = vehicleInfo;

    await _client.from('profiles').update(data).eq('id', profileId);
  }
}
