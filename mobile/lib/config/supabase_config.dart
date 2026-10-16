import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralised Supabase configuration with explicit failure diagnostics.
///
/// Changes versus the original:
/// - [configProblem] records the exact reason credentials were rejected.
/// - Refuses to boot with a `service_role` key in the client bundle.
/// - Prints a bordered banner with a three-step fix on misconfiguration.
/// - Idempotent via a bootstrap guard (safe to call from main() AND tests).
/// - [isConfigured] correctly detects placeholder or empty credentials.
class SupabaseConfig {
  static bool _initialized = false;

  // ── Problem Description ────────────────────────────────────────────────────

  /// Non-null when [initialize] detected a misconfigured .env.
  /// Use this to surface a developer-friendly message rather than crashing.
  static String? configProblem;

  // ── Public Accessors ───────────────────────────────────────────────────────

  static bool get isConfigured {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
        dotenv.env['SUPABASE_ANON_KEY'] ??
        '';
    return url.isNotEmpty &&
        url.startsWith('https://') &&
        !url.contains('placeholder') &&
        key.isNotEmpty &&
        !key.contains('placeholder') &&
        key != 'YOUR_SUPABASE_ANON_KEY_HERE';
  }

  static SupabaseClient get client => Supabase.instance.client;

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Idempotent. Safe to call from both main() and test setUpAll().
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // ── 1. Load .env ────────────────────────────────────────────────────────
    bool envLoaded = false;
    try {
      await dotenv.load(fileName: '.env');
      envLoaded = true;
    } catch (e) {
      // Missing .env is expected on fresh clones and in CI.
      // Fall through to placeholder mode rather than crashing.
      debugPrint('ℹ️  Quickopia: .env not found ($e). Starting in placeholder mode.');
    }

    // ── 2. Resolve credentials ──────────────────────────────────────────────
    // New Supabase projects use sb_publishable_* keys. Support both:
    // SUPABASE_PUBLISHABLE_KEY (new) falls back to SUPABASE_ANON_KEY (legacy).
    final rawUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final rawKey = (dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim().isNotEmpty ==
            true
        ? dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim()
        : dotenv.env['SUPABASE_ANON_KEY']?.trim()) ??
        '';

    String url;
    String anonKey;

    if (!envLoaded || rawUrl.isEmpty) {
      configProblem = envLoaded
          ? 'SUPABASE_URL is missing from .env'
          : '.env file not found — copy .env.example to mobile/.env and fill in your Supabase credentials';
      url = 'https://placeholder.supabase.co';
      anonKey = 'placeholder-anon-key';
    } else if (rawUrl.contains('placeholder') ||
        rawKey.isEmpty ||
        rawKey.contains('placeholder') ||
        rawKey == 'YOUR_SUPABASE_ANON_KEY_HERE') {
      configProblem = rawKey.isEmpty || rawKey == 'YOUR_SUPABASE_ANON_KEY_HERE'
          ? 'SUPABASE_ANON_KEY is missing or still set to placeholder text'
          : 'SUPABASE_URL still contains placeholder text';
      url = rawUrl.isNotEmpty ? rawUrl : 'https://placeholder.supabase.co';
      anonKey = rawKey.isNotEmpty ? rawKey : 'placeholder-anon-key';
    } else if (!rawUrl.startsWith('https://')) {
      configProblem = 'SUPABASE_URL must use HTTPS (got: $rawUrl)';
      url = 'https://placeholder.supabase.co';
      anonKey = 'placeholder-anon-key';
    } else {
      // ── 3. Guard: refuse service_role key in client bundle ─────────────────
      if (_isServiceRoleJwt(rawKey)) {
        configProblem =
            'SUPABASE_SERVICE_ROLE_KEY detected in SUPABASE_ANON_KEY! '
            'This key bypasses Row-Level Security. '
            'Replace it with your anon key immediately.';
        _printConfigBanner(configProblem!);
        // Hard fail in debug to force an immediate fix.
        assert(false, configProblem);
        url = 'https://placeholder.supabase.co';
        anonKey = 'placeholder-anon-key';
      } else {
        url = rawUrl;
        anonKey = rawKey;
        configProblem = null;
      }
    }

    if (configProblem != null && envLoaded) {
      _printConfigBanner(configProblem!);
    }

    // ── 4. Initialize Supabase ─────────────────────────────────────────────
    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
      );
      if (isConfigured) {
        debugPrint('✅ Quickopia: Supabase initialized with project credentials.');
      } else {
        debugPrint('ℹ️  Quickopia: Supabase running in placeholder mode.');
      }
    } catch (e) {
      debugPrint('❌ Quickopia: Supabase.initialize() threw: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Decodes the JWT payload (second segment) and checks the `role` claim.
  /// Also rejects new-format `sb_secret_*` keys which must never ship in the app.
  static bool _isServiceRoleJwt(String jwt) {
    if (jwt.startsWith('sb_secret_')) return true;
    // Publishable keys are safe for client use.
    if (jwt.startsWith('sb_publishable_')) return false;
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return false;
      // Base64-url decode (pad to multiple of 4)
      final payload = parts[1];
      final padded = payload + '=' * ((4 - payload.length % 4) % 4);
      final decoded = utf8.decode(base64Url.decode(padded));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return map['role'] == 'service_role';
    } catch (_) {
      return false;
    }
  }

  static void _printConfigBanner(String problem) {
    final line = '=' * 68;
    debugPrint('\n$line');
    debugPrint('  ⚠️  QUICKOPIA CONFIG PROBLEM');
    debugPrint(line);
    debugPrint('  $problem');
    debugPrint('');
    debugPrint('  Fix:');
    debugPrint('  1. Copy the template:  cp .env.example mobile/.env');
    debugPrint('  2. Fill in SUPABASE_URL and SUPABASE_ANON_KEY');
    debugPrint('     (get them from Supabase Dashboard → Project Settings → API)');
    debugPrint('  3. Use the ANON key, not the service_role key.');
    debugPrint('$line\n');
  }
}
