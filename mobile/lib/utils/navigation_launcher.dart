import 'package:url_launcher/url_launcher.dart';

class NavigationLauncher {
  /// Zero-cost turn-by-turn navigation via the device's pre-installed map app.
  /// Tries the Google Maps navigation intent first (drops straight into voice-guided turn-by-turn),
  /// falls back to a universal maps URL that works on iOS/Android/any browser if the intent isn't handled.
  static Future<void> navigateTo({
    required double lat,
    required double lng,
  }) async {
    final googleNavUri = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(googleNavUri)) {
      await launchUrl(googleNavUri);
      return;
    }
    final fallbackUri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
  }

  static Future<void> callPhone(String phone) async {
    final cleaned = phone.replaceAll(' ', '').replaceAll('-', '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> whatsApp(String phone, {String message = ''}) async {
    // WhatsApp requires the number without a leading '+' in wa.me links.
    final cleaned = phone.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '');
    final textParam = message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : '';
    final uri = Uri.parse('https://wa.me/$cleaned$textParam');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
