import 'package:flutter/material.dart';

import '../models/purchase_category.dart';
import '../utils/currency_formatter.dart';

class CategorySummaryRow extends StatelessWidget {
  const CategorySummaryRow({super.key, required this.totals});

  final Map<PurchaseCategory, double> totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grandTotal = totals.values.fold(0.0, (a, b) => a + b);

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: PurchaseCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = PurchaseCategory.values[index];
          final amount = totals[category] ?? 0.0;
          final share = grandTotal > 0 ? amount / grandTotal : 0.0;

          return Container(
            width: 132,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(category.icon, size: 16, color: category.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        category.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  formatBRL(amount),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0).toDouble(),
                    minHeight: 4,
                    backgroundColor: category.color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(category.color),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
