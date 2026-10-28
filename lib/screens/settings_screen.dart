import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/purchase_store.dart';
import '../utils/currency_formatter.dart';
import '../utils/currency_input_formatter.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController;
  late bool _hasLimit;

  @override
  void initState() {
    super.initState();
    final store = context.read<PurchaseStore>();
    _hasLimit = store.hasMonthlyLimit;
    _limitController = TextEditingController(
      text: store.monthlyLimit != null
          ? store.monthlyLimit!.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
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

  double? _parseLimit() =>
      double.tryParse(_normalizeNumber(_limitController.text));

  Future<void> _saveLimit() async {
    if (!_formKey.currentState!.validate()) return;

    final store = context.read<PurchaseStore>();
    await store.setMonthlyLimit(_parseLimit());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Limite mensal salvo')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PurchaseStore>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  'Gastos',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                title: const Text('Limite mensal de gastos'),
                subtitle: Text(
                  store.hasMonthlyLimit
                      ? 'Máximo de ${formatBRL(store.monthlyLimit!)} por mês'
                      : 'Defina um valor máximo por mês',
                ),
                value: _hasLimit,
                onChanged: (value) {
                  setState(() => _hasLimit = value);
                  if (!value) {
                    store.setMonthlyLimit(null);
                  }
                },
              ),
              if (_hasLimit)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _limitController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Valor do limite',
                          prefixText: 'R\$ ',
                          hintText: '0,00',
                        ),
                        validator: (_) {
                          if (!_hasLimit) return null;
                          final value = _parseLimit();
                          if (value == null || value <= 0) {
                            return 'Informe um limite válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: _saveLimit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Salvar limite'),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.category_outlined),
                title: const Text('Categorias'),
                subtitle: const Text('Limites por categoria'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
