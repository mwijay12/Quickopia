import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/supermarket_settings_model.dart';

class SupermarketProvider extends ChangeNotifier {
  SupermarketSettings _settings = const SupermarketSettings();
  bool _isLoading = false;
  RealtimeChannel? _realtimeChannel;

  SupermarketSettings get settings => _settings;
  bool get isLoading => _isLoading;

  String get supermarketName => _settings.supermarketName;
  String get tagline => _settings.tagline;
  String get logoUrl => _settings.logoUrl;
  String get branchAddress => _settings.branchAddress;
  String get city => _settings.city;
  String get phone => _settings.phone;
  String get email => _settings.email;
  String get operatingHours => _settings.operatingHours;
  String get currencySymbol => _settings.currencySymbol;

  SupermarketProvider() {
    loadSettings();
    _subscribeToRealtime();
  }

  bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  Future<void> loadSettings() async {
    if (_isTesting || !SupabaseConfig.isConfigured) return;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await SupabaseConfig.client
          .from('settings')
          .select()
          .eq('id', 'branch_settings')
          .maybeSingle();

      if (res != null) {
        _settings = SupermarketSettings.fromMap(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      debugPrint('SupermarketProvider: Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToRealtime() {
    if (_isTesting || !SupabaseConfig.isConfigured) return;

    try {
      _realtimeChannel = SupabaseConfig.client
          .channel('public:settings')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'settings',
            filter: const PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: 'branch_settings',
            ),
            callback: (payload) {
              if (payload.newRecord.isNotEmpty) {
                _settings = SupermarketSettings.fromMap(
                  Map<String, dynamic>.from(payload.newRecord),
                );
                notifyListeners();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('SupermarketProvider: Realtime subscription failed: $e');
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
