import 'package:intl/intl.dart';

final NumberFormat _brl = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

String formatBRL(double value) => _brl.format(value);
