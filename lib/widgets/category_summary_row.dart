import 'package:flutter/material.dart';

import '../models/category.dart';
import '../utils/currency_formatter.dart';

class CategorySummaryRow extends StatelessWidget {
  const CategorySummaryRow({super.key, required this.summaries});

  final List<CategorySummary> summaries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: summaries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final summary = summaries[index];
          final category = summary.category;

          return Container(
            width: 148,
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
                        category.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatBRL(summary.spent),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (summary.hasLimit) ...[
                  const SizedBox(height: 2),
                  Text(
                    'de ${formatBRL(category.limit!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: summary.ratio,
                      minHeight: 4,
                      backgroundColor: category.color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(
                        summary.isOverLimit
                            ? theme.colorScheme.error
                            : category.color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
