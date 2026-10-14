class Validators {
  static bool isValidTzPhone(String value) {
    final cleaned = value.replaceAll(' ', '').replaceAll('-', '');
    return RegExp(r'^(\+255|255|0)[67]\d{8}$').hasMatch(cleaned);
  }

  static String normalizeTzPhone(String value) {
    String cleaned = value.replaceAll(' ', '').replaceAll('-', '');
    if (cleaned.startsWith('0')) {
      return '+255${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('255')) {
      return '+$cleaned';
    }
    if (!cleaned.startsWith('+')) {
      return '+$cleaned';
    }
    return cleaned;
  }

  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }
}
