import 'package:flutter/material.dart';

import 'category.dart';

const String remainingLabel = 'Restante';
const Color remainingSliceColor = Color(0xFFD0D0D0);

class ChartSlice {
  const ChartSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class ChartData {
  const ChartData({required this.total, required this.slices});

  /// Denominator for slice angles and percentages.
  final double total;
  final List<ChartSlice> slices;
}

String formatPercent(double value, double total) {
  if (total <= 0) return '0,0%';
  final percent = value / total * 100;
  return '${percent.toStringAsFixed(1).replaceAll('.', ',')}%';
}

ChartData buildChartData({
  required double total,
  required double? monthlyLimit,
  required List<CategorySummary> summaries,
}) {
  final slices = summaries
      .where((summary) => summary.spent > 0)
      .map(
        (summary) => ChartSlice(
          label: summary.category.name,
          value: summary.spent,
          color: summary.category.color,
        ),
      )
      .toList();

  final limit = (monthlyLimit != null && monthlyLimit > 0) ? monthlyLimit : null;
  var chartTotal = total;

  if (limit != null && total < limit) {
    chartTotal = limit;
    slices.add(
      ChartSlice(
        label: remainingLabel,
        value: limit - total,
        color: remainingSliceColor,
      ),
    );
  }

  if (chartTotal <= 0) {
    return const ChartData(total: 0, slices: []);
  }

  return ChartData(total: chartTotal, slices: slices);
}
