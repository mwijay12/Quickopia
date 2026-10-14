import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryService {
  static bool _isInitialized = false;

  /// Defensive Sentry Initialization for Quickopia Mobile App
  static Future<void> init(FutureOr<void> Function() appRunner) async {
    // 1. Try to load local .env if available
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env not bundled or missing in test runner - continue safely
    }

    final dsn = dotenv.env['SENTRY_DSN_MOBILE'] ??
        const String.fromEnvironment('SENTRY_DSN_MOBILE');

    if (dsn.isEmpty || dsn.contains('placeholder') || dsn.contains('your_sentry')) {
      // Sentry DSN not configured: run app directly without monitoring crashes
      debugPrint('ℹ️ Sentry: Mobile DSN not configured or placeholder. Running without Sentry.');
      await appRunner();
      return;
    }

    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = dsn;
          options.environment = kReleaseMode ? 'production' : 'development';
          options.tracesSampleRate = 0.1; // 10% sampling to protect free tier
          options.sendDefaultPii = false; // Strictly protect customer PII

          // Noise filter: suppress harmless expected client network retries
          options.beforeSend = (event, hint) {
            final exceptionStr = event.throwable?.toString().toLowerCase() ?? '';
            if (exceptionStr.contains('socketexception') ||
                exceptionStr.contains('clientexception') ||
                exceptionStr.contains('network is unreachable')) {
              // Rate-limit or suppress repetitive connection blips
              return null;
            }
            return event;
          };
        },
        appRunner: () async {
          _isInitialized = true;
          await appRunner();
        },
      );
    } catch (e) {
      debugPrint('⚠️ Sentry: Failed to initialize SDK: $e. Running app cleanly.');
      await appRunner();
    }
  }

  /// Attach non-PII user role and ID (never attach phone/name/address)
  static void setUserContext({required String userId, required String role}) {
    if (!_isInitialized) return;
    try {
      Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: userId,
          data: {'role': role, 'surface': 'mobile'},
        ));
        scope.setTag('user_role', role);
        scope.setTag('surface', 'mobile');
      });
    } catch (_) {}
  }

  /// Clear user context upon logout
  static void clearUserContext() {
    if (!_isInitialized) return;
    try {
      Sentry.configureScope((scope) {
        scope.setUser(null);
        scope.removeTag('user_role');
      });
    } catch (_) {}
  }

  /// Manually capture handled exceptions with business context
  static void captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? screen,
    String? orderId,
    Map<String, dynamic>? extra,
  }) {
    if (!_isInitialized) return;
    try {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (screen != null) scope.setTag('screen', screen);
          if (orderId != null) scope.setTag('order_id', orderId);
          scope.setTag('surface', 'mobile');
          if (extra != null) {
            extra.forEach((key, value) {
              // Ensure no PII strings are attached
              if (!key.toLowerCase().contains('phone') &&
                  !key.toLowerCase().contains('name') &&
                  !key.toLowerCase().contains('address')) {
                scope.setContexts(key, value);
              }
            });
          }
        },
      );
    } catch (_) {}
  }
}
