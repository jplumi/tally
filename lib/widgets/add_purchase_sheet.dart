import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/payment_type.dart';
import '../models/purchase.dart';
import '../models/purchase_category.dart';
import '../services/purchase_store.dart';
import '../utils/date_utils.dart';

/// Bottom sheet used both to register a new purchase and to edit an
/// existing one. Defaults to debit, "Custos fixos" and today, so a new
/// purchase can be logged with just a description and a value.
class AddPurchaseSheet extends StatefulWidget {
  const AddPurchaseSheet({super.key, this.existing});

  final Purchase? existing;

  static Future<void> show(BuildContext context, {Purchase? existing}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddPurchaseSheet(existing: existing),
    );
  }

  @override
  State<AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends State<AddPurchaseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _valueController;
  late PaymentType _paymentType;
  late PurchaseCategory _category;
  late DateTime _date;
  late int _installments;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _valueController = TextEditingController(
      text: existing != null
          ? existing.value.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _paymentType = existing?.paymentType ?? PaymentType.debit;
    _category = existing?.category ?? PurchaseCategory.fixedCosts;
    _date = existing?.date ?? DateTime.now();
    _installments = existing?.installments ?? 1;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  String _normalizeNumber(String input) {
    var s = input.trim().replaceAll(' ', '').replaceAll(',', '.');
    final parts = s.split('.');
    if (parts.length > 2) {
      final decimal = parts.removeLast();
      s = '${parts.join()}.$decimal';
    }
    return s;
  }

  double? _parseValue() =>
      double.tryParse(_normalizeNumber(_valueController.text));

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      helpText: 'Data da compra',
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final value = _parseValue()!;
    final installments = _paymentType == PaymentType.credit ? _installments : 1;
    final store = context.read<PurchaseStore>();

    if (_isEditing) {
      await store.updatePurchase(widget.existing!.copyWith(
        description: _descriptionController.text.trim(),
        value: value,
        paymentType: _paymentType,
        category: _category,
        date: _date,
        installments: installments,
      ));
    } else {
      await store.addPurchase(
        description: _descriptionController.text.trim(),
        value: value,
        paymentType: _paymentType,
        category: _category,
        date: _date,
        installments: installments,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    _isEditing ? 'Editar compra' : 'Nova compra',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _valueController,
                    autofocus: !_isEditing,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                      hintText: '0,00',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (_) {
                      final value = _parseValue();
                      if (value == null || value <= 0)
                        return 'Informe um valor válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Ex: mercado, Uber, cinema',
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe uma descrição'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text('Forma de pagamento', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<PaymentType>(
                    segments: const [
                      ButtonSegment(
                        value: PaymentType.debit,
                        label: Text('Débito'),
                        icon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      ButtonSegment(
                        value: PaymentType.credit,
                        label: Text('Crédito'),
                        icon: Icon(Icons.credit_card_outlined),
                      ),
                    ],
                    selected: {_paymentType},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _paymentType = selection.first;
                        if (_paymentType == PaymentType.debit)
                          _installments = 1;
                      });
                    },
                  ),
                  if (_paymentType == PaymentType.credit) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: _installments,
                      decoration: const InputDecoration(
                          labelText: 'Número de parcelas'),
                      items: List.generate(24, (i) => i + 1)
                          .map((n) => DropdownMenuItem(
                                value: n,
                                child: Text(n == 1 ? '1x (à vista)' : '${n}x'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _installments = v ?? 1),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Categoria', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PurchaseCategory.values.map((c) {
                      final selected = c == _category;
                      return ChoiceChip(
                        selected: selected,
                        showCheckmark: false,
                        label: Text(c.label),
                        avatar: Icon(
                          c.icon,
                          size: 18,
                          color: selected
                              ? theme.colorScheme.onSecondaryContainer
                              : c.color,
                        ),
                        onSelected: (_) => setState(() => _category = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Data', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      isToday(_date)
                          ? 'Hoje, ${formatDayMonth(_date)}'
                          : formatWeekdayDayMonth(_date),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(
                        _isEditing ? 'Salvar alterações' : 'Registrar compra'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
