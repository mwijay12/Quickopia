import '../config/supabase_config.dart';
import '../models/driver_profile_model.dart';

class DriverInfoService {
  final _client = SupabaseConfig.client;

  Future<DriverProfile?> fetchDriverProfile(String driverId) async {
    final response = await _client
        .from('profiles')
        .select('id, full_name, phone')
        .eq('id', driverId)
        .maybeSingle();
    if (response == null) return null;
    return DriverProfile.fromMap(response);
  }
}
