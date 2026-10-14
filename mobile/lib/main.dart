import 'package:flutter/material.dart';
import 'app.dart';
import 'config/supabase_config.dart';
import 'services/notification_service.dart';
import 'services/sentry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SentryService.init(() async {
    await SupabaseConfig.initialize();
    await NotificationService().initialize();
    runApp(const QuickopiaApp());
  });
}
