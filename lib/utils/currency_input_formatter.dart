import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// A [TextInputFormatter] that formats digits typed into a text field
/// as a currency value, always keeping the last two digits as cents.
///
/// Example: typing "50000" results in "500,00" (or "500.00" depending
/// on locale/symbols configured below).
class CurrencyInputFormatter extends TextInputFormatter {
  CurrencyInputFormatter({
    this.decimalSeparator = ',',
    this.thousandSeparator = '.',
    this.symbol = '',
  });

  final String decimalSeparator;
  final String thousandSeparator;
  final String symbol;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip everything except digits.
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Treat the digit string as an integer number of cents.
    double value = double.parse(digitsOnly) / 100;

    // Build a NumberFormat using the requested separators.
    final formatter = NumberFormat.currency(
      decimalDigits: 2,
      symbol: symbol,
    );

    // NumberFormat uses locale-based separators by default; override
    // them manually since we want explicit control regardless of locale.
    String formatted = formatter.format(value).trim();
    formatted = formatted
        .replaceAll(',', '#') // temp placeholder
        .replaceAll('.', thousandSeparator == '.' ? '.' : thousandSeparator)
        .replaceAll('#', decimalSeparator);

    // If symbol is empty, NumberFormat may leave stray currency spacing.
    formatted = formatted.trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
