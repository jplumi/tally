import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/models/category.dart';

void main() {
  group('Category', () {
    test('JSON round-trip preserves fields', () {
      final category = Category(
        id: 'games',
        name: 'Games',
        limit: 100,
        colorValue: 0xFF112233,
        iconCodePoint: Icons.sports_esports_rounded.codePoint,
        iconFontFamily: Icons.sports_esports_rounded.fontFamily,
        isDefault: false,
      );

      final decoded = Category.fromJson(category.toJson());

      expect(decoded.id, 'games');
      expect(decoded.name, 'Games');
      expect(decoded.limit, 100);
      expect(decoded.colorValue, 0xFF112233);
      expect(decoded.iconCodePoint, Icons.sports_esports_rounded.codePoint);
      expect(decoded.iconFontFamily,
          Icons.sports_esports_rounded.fontFamily);
      expect(decoded.isDefault, false);
      expect(decoded.color, const Color(0xFF112233));
      expect(decoded.icon.codePoint, Icons.sports_esports_rounded.codePoint);
    });

    test('hasLimit treats null and zero as no limit', () {
      const withNull = Category(
        id: 'a',
        name: 'A',
        limit: null,
        colorValue: 0xFF000000,
        iconCodePoint: 0xe000,
        iconFontFamily: null,
        isDefault: false,
      );
      const withZero = Category(
        id: 'b',
        name: 'B',
        limit: 0,
        colorValue: 0xFF000000,
        iconCodePoint: 0xe000,
        iconFontFamily: null,
        isDefault: false,
      );
      const withLimit = Category(
        id: 'c',
        name: 'C',
        limit: 50,
        colorValue: 0xFF000000,
        iconCodePoint: 0xe000,
        iconFontFamily: null,
        isDefault: false,
      );

      expect(withNull.hasLimit, false);
      expect(withZero.hasLimit, false);
      expect(withLimit.hasLimit, true);
    });

    test('default categories keep the legacy enum names as ids', () {
      expect(
        defaultCategories.map((c) => c.id).toSet(),
        {'fixedCosts', 'entertainment', 'investments', 'dining'},
      );
      expect(defaultCategories.every((c) => c.isDefault), true);
      expect(defaultCategories, hasLength(4));
    });

    test('fromJson is tolerant of missing fields', () {
      final decoded = Category.fromJson(const {'name': 'X'});

      expect(decoded.name, 'X');
      expect(decoded.id, isNotEmpty);
      expect(decoded.hasLimit, false);
      expect(decoded.isDefault, false);
      expect(decoded.color, isA<Color>());
      expect(decoded.icon, isA<IconData>());
    });

    test('copyWith can set limit to null', () {
      const original = Category(
        id: 'x',
        name: 'X',
        limit: 100,
        colorValue: 0xFF000000,
        iconCodePoint: 0xe000,
        iconFontFamily: null,
        isDefault: false,
      );

      final cleared = original.copyWith(limit: null);
      expect(cleared.limit, null);
      expect(cleared.hasLimit, false);

      final renamed = original.copyWith(name: 'Y', limit: 200);
      expect(renamed.name, 'Y');
      expect(renamed.limit, 200);
      expect(renamed.id, 'x');
    });
  });

  group('CategorySummary', () {
    const category = Category(
      id: 'games',
      name: 'Games',
      limit: 100,
      colorValue: 0xFF000000,
      iconCodePoint: 0xe000,
      iconFontFamily: null,
      isDefault: false,
    );

    test('ratio is spent / limit', () {
      expect(const CategorySummary(category: category, spent: 25).ratio,
          closeTo(0.25, 0.001));
    });

    test('ratio clamps at 1.0 when over limit', () {
      expect(const CategorySummary(category: category, spent: 250).ratio, 1.0);
    });

    test('isOverLimit is true only when spent exceeds the limit', () {
      expect(const CategorySummary(category: category, spent: 100).isOverLimit, false);
      expect(const CategorySummary(category: category, spent: 100.01).isOverLimit, true);
    });

    test('no-limit categories have zero ratio and are never over limit', () {
      const unlimited = Category(
        id: 'u',
        name: 'U',
        limit: null,
        colorValue: 0xFF000000,
        iconCodePoint: 0xe000,
        iconFontFamily: null,
        isDefault: false,
      );
      const summary = CategorySummary(category: unlimited, spent: 500);
      expect(summary.hasLimit, false);
      expect(summary.ratio, 0.0);
      expect(summary.isOverLimit, false);
    });
  });
}
