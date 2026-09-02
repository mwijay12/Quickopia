import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("⚠️ Quickopia: .env file not found or empty: $e");
    }

    final url = dotenv.env['SUPABASE_URL'] ??
        const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://placeholder.supabase.co',
        );

    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
        const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue: 'placeholder-anon-key',
        );

    final isPlaceholder = url.isEmpty ||
        url.contains('placeholder') ||
        anonKey.isEmpty ||
        anonKey.contains('placeholder');

    if (isPlaceholder) {
      debugPrint("⚠️ Quickopia: Supabase keys not set in .env. Running in offline/starter mode.");
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
      );
      debugPrint("✅ Quickopia: Supabase client initialized successfully.");
    } catch (e) {
      debugPrint("❌ Quickopia: Supabase initialization error: $e");
    }
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
