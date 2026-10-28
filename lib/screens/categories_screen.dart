import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../services/purchase_store.dart';
import '../utils/currency_formatter.dart';
import '../widgets/category_editor_sheet.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Future<void> _handleDelete(BuildContext context, Category category) async {
    final store = context.read<PurchaseStore>();

    String? blockedMessage;
    if (category.id == 'fixedCosts') {
      blockedMessage =
          'Custos fixos é a categoria padrão e não pode ser excluída.';
    } else if (store.isCategoryInUse(category.id)) {
      blockedMessage = 'Esta categoria tem compras registradas.';
    }

    if (blockedMessage != null) {
      final message = blockedMessage;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Não foi possível excluir'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    await store.deleteCategory(category.id);
  }

  void _onReorder(int oldIndex, int newIndex) {
    context.read<PurchaseStore>().reorderCategory(oldIndex, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PurchaseStore>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: store.categories.isEmpty
            ? const Center(child: Text('Nenhuma categoria cadastrada.'))
            : ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                buildDefaultDragHandles: false,
                itemCount: store.categories.length,
                onReorderItem: _onReorder,
                itemBuilder: (context, index) {
                  final category = store.categories[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(category.id),
                    index: index,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(category.icon,
                                color: category.color, size: 20),
                          ),
                          title: Text(category.name),
                          subtitle: Text(
                            category.hasLimit
                                ? 'Limite: ${formatBRL(category.limit!)}'
                                : 'Sem limite',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () => _handleDelete(context, category),
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: 'Excluir categoria',
                          ),
                          onTap: () => CategoryEditorSheet.show(
                            context,
                            existing: category,
                          ),
                        ),
                        if (index < store.categories.length - 1)
                          Divider(
                            height: 1,
                            indent: 72,
                            endIndent: 20,
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CategoryEditorSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova categoria'),
      ),
    );
  }
}
