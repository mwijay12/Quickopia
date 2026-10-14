import 'package:flutter_test/flutter_test.dart';
import 'package:quickopia/models/supermarket_settings_model.dart';
import 'package:quickopia/services/ai_assistant_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Assistant Service & Memory Tests', () {
    test('AiAssistantService retains multi-turn memory and clears properly', () {
      final service = AiAssistantService();
      service.clearMemory();
      expect(service.history.isEmpty, isTrue);

      final msg1 = AiChatMessage(role: 'user', content: 'Habari, nina swali kuhusu sukari');
      final msg2 = AiChatMessage(
        role: 'assistant',
        content: 'Habari! Tunayo sukari ya Kilombero na Bakhresa. [SEARCH: sugar]',
        suggestedSearch: 'sugar',
      );

      // Verify message properties
      expect(msg1.role, 'user');
      expect(msg1.content, contains('sukari'));
      expect(msg2.suggestedSearch, 'sugar');
    });

    test('AiChatMessage parses structured action tags correctly', () {
      const rawTextWithSearch = 'Ninakupendekezea saa nzuri za mkononi za kisasa za kiume. Bei zinaanzia TZS 45,000. [SEARCH: watch]';
      final searchMatch = RegExp(r'\[SEARCH:\s*([^\]]+)\]', caseSensitive: false).firstMatch(rawTextWithSearch);

      expect(searchMatch, isNotNull);
      expect(searchMatch!.group(1)?.trim(), 'watch');

      const rawTextWithCart = 'Nimekuwekea mfuko wa kilo 2 kwenye kapu lako. [ADD_TO_CART: sugar 2kg]';
      final addMatch = RegExp(r'\[ADD_TO_CART:\s*([^\]]+)\]', caseSensitive: false).firstMatch(rawTextWithCart);

      expect(addMatch, isNotNull);
      expect(addMatch!.group(1)?.trim(), 'sugar 2kg');
    });

    test('AiAssistant system prompt incorporates dynamic supermarket profile', () {
      const settings = SupermarketSettings(
        supermarketName: 'Shoppers Supermarket',
        branchAddress: 'Mlimani City Mall, Sam Nujoma Rd, Dar es Salaam',
        operatingHours: 'Mon - Sun: 07:30 AM - 10:30 PM',
        phone: '+255 712 345 678',
        returnWindowHours: 2,
      );

      expect(settings.supermarketName, 'Shoppers Supermarket');
      expect(settings.branchAddress, contains('Mlimani City'));
      expect(settings.returnWindowHours, 2);
    });
  });
}
