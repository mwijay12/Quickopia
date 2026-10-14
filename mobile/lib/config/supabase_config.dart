import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static bool get isConfigured {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    return url.isNotEmpty &&
        !url.contains('placeholder') &&
        key.isNotEmpty &&
        !key.contains('placeholder');
  }

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("⚠️ Quickopia: .env file not loaded: $e");
    }

    final url = dotenv.env['SUPABASE_URL']?.trim().isNotEmpty == true
        ? dotenv.env['SUPABASE_URL']!.trim()
        : 'https://placeholder.supabase.co';

    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim().isNotEmpty == true
        ? dotenv.env['SUPABASE_ANON_KEY']!.trim()
        : 'YOUR_SUPABASE_ANON_KEY_HERE';

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
      );
      if (isConfigured) {
        debugPrint("✅ Quickopia: Supabase initialized with project credentials.");
      } else {
        debugPrint("ℹ️ Quickopia: Supabase initialized with placeholder credentials (ready for keys).");
      }
    } catch (e) {
      debugPrint("❌ Quickopia: Supabase initialization error: $e");
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
