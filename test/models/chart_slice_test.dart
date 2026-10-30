import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/models/category.dart';
import 'package:tally/models/chart_slice.dart';

void main() {
  CategorySummary summary({
    required String id,
    required String name,
    required double spent,
    int colorValue = 0xFF000000,
  }) {
    return CategorySummary(
      category: Category(
        id: id,
        name: name,
        limit: null,
        colorValue: colorValue,
        iconCodePoint: Icons.home_rounded.codePoint,
        iconFontFamily: Icons.home_rounded.fontFamily,
        isDefault: false,
      ),
      spent: spent,
    );
  }

  group('buildChartData', () {
    test('without a limit scales to the total and skips zero-spent categories',
        () {
      final data = buildChartData(
        total: 150,
        monthlyLimit: null,
        summaries: [
          summary(id: 'a', name: 'A', spent: 100),
          summary(id: 'b', name: 'B', spent: 0),
          summary(id: 'c', name: 'C', spent: 50),
        ],
      );

      expect(data.total, 150);
      expect(data.slices.map((s) => s.label), ['A', 'C']);
      expect(data.slices.map((s) => s.value), [100, 50]);
      expect(data.slices.any((s) => s.label == remainingLabel), false);
    });

    test('below the limit scales to the limit and adds a Restante slice', () {
      final data = buildChartData(
        total: 60,
        monthlyLimit: 100,
        summaries: [summary(id: 'a', name: 'A', spent: 60)],
      );

      expect(data.total, 100);
      expect(data.slices, hasLength(2));
      expect(data.slices.last.label, remainingLabel);
      expect(data.slices.last.value, 40);
      expect(data.slices.last.color, remainingSliceColor);
    });

    test('exactly at the limit does not add a Restante slice', () {
      final data = buildChartData(
        total: 100,
        monthlyLimit: 100,
        summaries: [summary(id: 'a', name: 'A', spent: 100)],
      );

      expect(data.total, 100);
      expect(data.slices, hasLength(1));
      expect(data.slices.single.value, 100);
      expect(data.slices.any((s) => s.label == remainingLabel), false);
    });

    test('over the limit scales to the spent total without Restante', () {
      final data = buildChartData(
        total: 180,
        monthlyLimit: 100,
        summaries: [summary(id: 'a', name: 'A', spent: 180)],
      );

      expect(data.total, 180);
      expect(data.slices, hasLength(1));
      expect(data.slices.any((s) => s.label == remainingLabel), false);
    });

    test('a zero limit is treated as no limit', () {
      final data = buildChartData(
        total: 50,
        monthlyLimit: 0,
        summaries: [summary(id: 'a', name: 'A', spent: 50)],
      );

      expect(data.total, 50);
      expect(data.slices.single.label, 'A');
    });

    test('zero spending without a limit yields no slices', () {
      final data = buildChartData(
        total: 0,
        monthlyLimit: null,
        summaries: [summary(id: 'a', name: 'A', spent: 0)],
      );

      expect(data.total, 0);
      expect(data.slices, isEmpty);
    });
  });

  group('formatPercent', () {
    test('uses one decimal with a comma separator', () {
      expect(formatPercent(50, 100), '50,0%');
      expect(formatPercent(1, 3), '33,3%');
    });

    test('handles a zero denominator', () {
      expect(formatPercent(0, 0), '0,0%');
    });
  });
}
