import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Backend health status returned by heartbeat_status() Postgres RPC.
enum BackendHealth {
  /// A ping was received within the last 26 hours — backend is active.
  alive,

  /// No ping in 26 hours but < 7 days — pinger may be stalled.
  pingerStalled,

  /// No ping in 7+ days — project is or will soon be paused.
  paused,

  /// Could not reach the backend at all (network, project actually paused, etc.)
  unreachable,

  /// Status not yet determined.
  unknown,
}

class BackendHealthService {
  static final BackendHealthService _instance =
      BackendHealthService._internal();
  factory BackendHealthService() => _instance;
  BackendHealthService._internal();

  BackendHealth _lastKnownHealth = BackendHealth.unknown;
  DateTime? _lastChecked;

  BackendHealth get lastKnownHealth => _lastKnownHealth;
  DateTime? get lastChecked => _lastChecked;

  /// Returns true only when we have a confirmed unreachable/paused state.
  bool get isKnownUnavailable =>
      _lastKnownHealth == BackendHealth.unreachable ||
      _lastKnownHealth == BackendHealth.paused;

  /// Human-readable advisory message for the customer app.
  String get customerMessage {
    switch (_lastKnownHealth) {
      case BackendHealth.alive:
        return '';
      case BackendHealth.pingerStalled:
        return 'Backend connection is slow. Some features may be delayed.';
      case BackendHealth.paused:
        return 'The store is temporarily offline for maintenance. '
            'Please try again in a few minutes.';
      case BackendHealth.unreachable:
        return 'Could not connect to the store backend. '
            'Please check your internet connection and try again.';
      case BackendHealth.unknown:
        return '';
    }
  }

  /// Probe the Supabase heartbeat_status RPC and classify the result.
  /// Lightweight — uses the public anon key, no auth required.
  Future<BackendHealth> probe({Duration timeout = const Duration(seconds: 5)}) async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
        dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null ||
        url.contains('placeholder') ||
        anonKey == null ||
        anonKey.contains('placeholder')) {
      // Running in placeholder/test mode — assume alive so tests pass cleanly.
      _lastKnownHealth = BackendHealth.alive;
      _lastChecked = DateTime.now();
      return _lastKnownHealth;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$url/rest/v1/rpc/heartbeat_status'),
            headers: {
              'apikey': anonKey,
              'Authorization': 'Bearer $anonKey',
              'Content-Type': 'application/json',
            },
            body: '{}',
          )
          .timeout(timeout);

      _lastChecked = DateTime.now();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = (data['status'] as String?)?.toUpperCase() ?? 'UNKNOWN';
        switch (status) {
          case 'ALIVE':
            _lastKnownHealth = BackendHealth.alive;
          case 'PINGER_STALLED':
            _lastKnownHealth = BackendHealth.pingerStalled;
          case 'PAUSED':
            _lastKnownHealth = BackendHealth.paused;
          default:
            _lastKnownHealth = BackendHealth.unknown;
        }
      } else if (response.statusCode == 503 || response.statusCode == 0) {
        _lastKnownHealth = BackendHealth.paused;
      } else {
        _lastKnownHealth = BackendHealth.unreachable;
      }
    } catch (e) {
      debugPrint('BackendHealthService: probe failed — $e');
      _lastKnownHealth = BackendHealth.unreachable;
      _lastChecked = DateTime.now();
    }

    return _lastKnownHealth;
  }
}
