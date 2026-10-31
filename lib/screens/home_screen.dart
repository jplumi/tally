import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_screen.dart';
import 'chart_screen.dart';
import '../services/purchase_store.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_purchase_sheet.dart';
import '../widgets/category_summary_row.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_selector.dart';
import '../widgets/purchase_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedMonth;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PurchaseStore>();
    final theme = Theme.of(context);

    if (!store.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final allMonthPurchases = store.purchasesForMonth(_selectedMonth);
    final monthPurchases = _selectedCategoryId == null
        ? allMonthPurchases
        : allMonthPurchases
            .where((p) => p.categoryId == _selectedCategoryId)
            .toList();
    final total = store.totalForMonth(_selectedMonth);
    final categorySummaries = store.categorySummariesForMonth(_selectedMonth);
    final selectedCategory = _selectedCategoryId == null
        ? null
        : store.categoryById(_selectedCategoryId!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tally'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  MonthSelector(
                    month: _selectedMonth,
                    onChanged: (m) => setState(() => _selectedMonth = m),
                  ),
                  const SizedBox(height: 12),
                  _TotalCard(
                    total: total,
                    monthlyLimit: store.monthlyLimit,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChartScreen(initialMonth: _selectedMonth),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CategorySummaryRow(
                    summaries: categorySummaries,
                    selectedCategoryId: _selectedCategoryId,
                    onCategoryTap: (summary) {
                      setState(() {
                        _selectedCategoryId =
                            _selectedCategoryId == summary.category.id
                                ? null
                                : summary.category.id;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'Compras',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        if (monthPurchases.isNotEmpty)
                          Text(
                            '${monthPurchases.length}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (monthPurchases.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                    onAddPressed: () => AddPurchaseSheet.show(context)),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index.isOdd) {
                      return Divider(
                        height: 1,
                        indent: 20,
                        endIndent: 20,
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4),
                      );
                    }
                    final purchase = monthPurchases[index ~/ 2];
                    return PurchaseTile(
                      purchase: purchase,
                      category: store.categoryById(purchase.categoryId),
                      month: _selectedMonth,
                      onTap: () =>
                          AddPurchaseSheet.show(context, existing: purchase),
                      onDismissed: () => store.deletePurchase(purchase.id),
                    );
                  },
                  childCount: monthPurchases.length * 2 - 1,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddPurchaseSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova compra'),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    this.monthlyLimit,
    required this.onTap,
  });

  final double total;
  final double? monthlyLimit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLimit = monthlyLimit != null && monthlyLimit! > 0;
    final ratio =
        hasLimit ? (total / monthlyLimit!).clamp(0.0, 1.0).toDouble() : 0.0;
    final isOverLimit = hasLimit && total > monthlyLimit!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.82),
                ],
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total gasto no mês',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary
                            .withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatBRL(total),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (hasLimit) ...[
                      const SizedBox(height: 4),
                      Text(
                        'de ${formatBRL(monthlyLimit!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary
                              .withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 4,
                          backgroundColor: theme.colorScheme.onPrimary
                              .withValues(alpha: 0.18),
                          valueColor: AlwaysStoppedAnimation(
                            isOverLimit
                                ? theme.colorScheme.error
                                : theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
