import 'package:flutter_test/flutter_test.dart';

bool isValidTzPhone(String v) {
  final cleaned = v.replaceAll(' ', '').replaceAll('-', '');
  return RegExp(r'^(\+255|0)[67]\d{8}$').hasMatch(cleaned);
}

String normalizeTzPhone(String v) {
  String cleaned = v.replaceAll(' ', '').replaceAll('-', '');
  if (cleaned.startsWith('0')) {
    return '+255${cleaned.substring(1)}';
  }
  if (!cleaned.startsWith('+')) {
    return '+$cleaned';
  }
  return cleaned;
}

void main() {
  group('Tanzanian Phone Validation & Normalization', () {
    test('Accepts valid 07XX and 06XX local format phone numbers', () {
      expect(isValidTzPhone('0712345678'), isTrue);
      expect(isValidTzPhone('0754123456'), isTrue);
      expect(isValidTzPhone('0655123456'), isTrue);
      expect(isValidTzPhone('0688990011'), isTrue);
    });

    test('Accepts valid +255 international format phone numbers', () {
      expect(isValidTzPhone('+255712345678'), isTrue);
      expect(isValidTzPhone('+255655123456'), isTrue);
    });

    test('Accepts valid phone numbers with spaces or dashes', () {
      expect(isValidTzPhone('0712 345 678'), isTrue);
      expect(isValidTzPhone('0712-345-678'), isTrue);
      expect(isValidTzPhone('+255 712 345 678'), isTrue);
    });

    test('Rejects invalid phone numbers', () {
      expect(isValidTzPhone('123456'), isFalse);
      expect(isValidTzPhone('0812345678'), isFalse); // Invalid prefix (not 6 or 7)
      expect(isValidTzPhone('0112345678'), isFalse);
      expect(isValidTzPhone('071234567'), isFalse); // Too short (8 digits)
      expect(isValidTzPhone('07123456789'), isFalse); // Too long (10 digits)
      expect(isValidTzPhone('+1712345678'), isFalse); // Not Tanzania code
      expect(isValidTzPhone('abcdefghij'), isFalse);
    });

    test('Normalizes local numbers to +255 international standard', () {
      expect(normalizeTzPhone('0712345678'), '+255712345678');
      expect(normalizeTzPhone('0655123456'), '+255655123456');
      expect(normalizeTzPhone('0712 345 678'), '+255712345678');
    });

    test('Keeps already international numbers intact', () {
      expect(normalizeTzPhone('+255712345678'), '+255712345678');
      expect(normalizeTzPhone('+255 655 123 456'), '+255655123456');
    });
  });
}
