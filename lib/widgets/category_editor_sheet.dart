import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../services/purchase_store.dart';
import '../utils/category_palette.dart';
import '../utils/currency_input_formatter.dart';

/// Bottom sheet used both to create a new category and to edit an existing
/// one. Each category has a name, optional monthly limit, curated icon and
/// curated color.
class CategoryEditorSheet extends StatefulWidget {
  const CategoryEditorSheet({super.key, this.existing});

  final Category? existing;

  static Future<void> show(BuildContext context, {Category? existing}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CategoryEditorSheet(existing: existing),
    );
  }

  @override
  State<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<CategoryEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  late bool _hasLimit;
  late int _colorValue;
  late int _iconCodePoint;
  late String? _iconFontFamily;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _hasLimit = existing?.hasLimit ?? false;
    _limitController = TextEditingController(
      text: existing?.limit != null
          ? existing!.limit!.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _colorValue =
        existing?.colorValue ?? CategoryPalette.colors.first.toARGB32();
    _iconCodePoint =
        existing?.iconCodePoint ?? CategoryPalette.icons.first.codePoint;
    _iconFontFamily =
        existing?.iconFontFamily ?? CategoryPalette.icons.first.fontFamily;
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final store = context.read<PurchaseStore>();
    final name = _nameController.text.trim();
    final limit = _hasLimit ? _parseLimit() : null;

    if (_isEditing) {
      await store.updateCategory(widget.existing!.copyWith(
        name: name,
        limit: limit,
        colorValue: _colorValue,
        iconCodePoint: _iconCodePoint,
        iconFontFamily: _iconFontFamily,
      ));
    } else {
      await store.addCategory(
        name: name,
        limit: limit,
        colorValue: _colorValue,
        iconCodePoint: _iconCodePoint,
        iconFontFamily: _iconFontFamily,
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
                    _isEditing ? 'Editar categoria' : 'Nova categoria',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      hintText: 'Ex: Games, Pets, Viagem',
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe um nome'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Limite mensal'),
                    subtitle: Text(
                      _hasLimit ? 'Defina um valor máximo por mês' : 'Sem limite',
                    ),
                    value: _hasLimit,
                    onChanged: (v) => setState(() => _hasLimit = v),
                  ),
                  if (_hasLimit) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _limitController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
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
                  ],
                  const SizedBox(height: 20),
                  Text('Ícone', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CategoryPalette.icons.map((icon) {
                      final selected = icon.codePoint == _iconCodePoint;
                      return ChoiceChip(
                        selected: selected,
                        showCheckmark: false,
                        avatar: Icon(
                          icon,
                          size: 18,
                          color: selected
                              ? theme.colorScheme.onSecondaryContainer
                              : Color(_colorValue),
                        ),
                        label: const SizedBox.shrink(),
                        onSelected: (_) => setState(() {
                          _iconCodePoint = icon.codePoint;
                          _iconFontFamily = icon.fontFamily;
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Cor', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: CategoryPalette.colors.map((color) {
                      final value = color.toARGB32();
                      final selected = value == _colorValue;
                      final checkColor = color.computeLuminance() > 0.5
                          ? Colors.black87
                          : Colors.white;
                      return InkWell(
                        onTap: () => setState(() => _colorValue = value),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.outlineVariant,
                              width: selected ? 2.5 : 1,
                            ),
                          ),
                          child: selected
                              ? Icon(Icons.check_rounded,
                                  size: 18, color: checkColor)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(
                        _isEditing ? 'Salvar alterações' : 'Criar categoria'),
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
