import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    final monthPurchases = store.purchasesForMonth(_selectedMonth);
    final total = store.totalForMonth(_selectedMonth);
    final totalsByCategory = store.totalsByCategoryForMonth(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas finanças'),
        centerTitle: false,
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
                  _TotalCard(total: total),
                  const SizedBox(height: 16),
                  CategorySummaryRow(totals: totalsByCategory),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'Compras',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                child: EmptyState(onAddPressed: () => AddPurchaseSheet.show(context)),
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
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      );
                    }
                    final purchase = monthPurchases[index ~/ 2];
                    return PurchaseTile(
                      purchase: purchase,
                      month: _selectedMonth,
                      onTap: () => AddPurchaseSheet.show(context, existing: purchase),
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
  const _TotalCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.82),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total gasto no mês',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
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
          ],
        ),
      ),
    );
  }
}
