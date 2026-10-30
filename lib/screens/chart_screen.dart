import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chart_slice.dart';
import '../services/purchase_store.dart';
import '../utils/currency_formatter.dart';
import '../widgets/add_purchase_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_selector.dart';
import '../widgets/pie_chart.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key, required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth =
        DateTime(widget.initialMonth.year, widget.initialMonth.month);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PurchaseStore>();
    final theme = Theme.of(context);

    if (!store.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final total = store.totalForMonth(_selectedMonth);
    final data = buildChartData(
      total: total,
      monthlyLimit: store.monthlyLimit,
      summaries: store.categorySummariesForMonth(_selectedMonth),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Gráfico'), centerTitle: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            MonthSelector(
              month: _selectedMonth,
              onChanged: (m) => setState(() => _selectedMonth = m),
            ),
            const SizedBox(height: 12),
            Text(
              'Total gasto no mês',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              formatBRL(total),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 20),
            if (data.slices.isEmpty)
              EmptyState(onAddPressed: () => AddPurchaseSheet.show(context))
            else ...[
              Center(
                child: PieChart(
                  data: data,
                  nameStyle: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(),
                  percentStyle: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ) ??
                      const TextStyle(),
                  lineColor:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              _Legend(data: data),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.data});

  final ChartData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final slice in data.slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: slice.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    slice.label,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatBRL(slice.value),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 52,
                  child: Text(
                    formatPercent(slice.value, data.total),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
