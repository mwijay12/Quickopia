import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'en_US', // formatting style with thousand separators
    symbol: '',
    decimalDigits: 0,
  );

  static String formatTzs(double amount) {
    return 'TZS ${_formatter.format(amount).trim()}';
  }
}
