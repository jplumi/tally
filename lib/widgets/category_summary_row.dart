import 'package:flutter/material.dart';

import '../models/category.dart';
import '../utils/currency_formatter.dart';

class CategorySummaryRow extends StatelessWidget {
  const CategorySummaryRow({
    super.key,
    required this.summaries,
    required this.selectedCategoryId,
    required this.onCategoryTap,
  });

  final List<CategorySummary> summaries;
  final String? selectedCategoryId;
  final ValueChanged<CategorySummary> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: summaries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final summary = summaries[index];
          final category = summary.category;
          final isSelected = category.id == selectedCategoryId;

          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: isSelected
                  ? category.color.withValues(alpha: 0.14)
                  : theme.colorScheme.surfaceContainerHigh,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? category.color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () => onCategoryTap(summary),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 148,
                    padding: const EdgeInsets.all(12),
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
                              backgroundColor:
                                  category.color.withValues(alpha: 0.12),
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
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
