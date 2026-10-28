import 'package:flutter/material.dart';

/// Lets [Category.copyWith] tell "limit not provided" apart from
/// "limit set to null".
const Object _unset = Object();

/// A user-editable spending category persisted on-device.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.limit,
    required this.colorValue,
    required this.iconCodePoint,
    required this.iconFontFamily,
    required this.isDefault,
  });

  /// Referenced by persisted purchases, so it must stay stable.
  final String id;

  final String name;

  /// Monthly limit in BRL. `null` or `0` means "no limit".
  final double? limit;

  /// Stored as ARGB color value and `IconData.codePoint` primitives so the
  /// whole category serializes to JSON.
  final int colorValue;
  final int iconCodePoint;
  final String? iconFontFamily;

  final bool isDefault;

  Color get color => Color(colorValue);

  IconData get icon {
    // Rebuilding IconData at runtime keeps icons from being tree-shaken,
    // which is required because they come from persisted data.
    // ignore: non_const_argument_for_const_parameter
    return IconData(iconCodePoint, fontFamily: iconFontFamily);
  }

  bool get hasLimit => limit != null && limit! > 0;

  Category copyWith({
    String? name,
    Object? limit = _unset,
    int? colorValue,
    int? iconCodePoint,
    String? iconFontFamily,
    bool? isDefault,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      limit: identical(limit, _unset)
          ? this.limit
          : (limit as num?)?.toDouble(),
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'limit': limit,
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'isDefault': isDefault,
      };

  factory Category.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    return Category(
      id: (rawId == null || rawId.isEmpty)
          ? 'category_${DateTime.now().microsecondsSinceEpoch}'
          : rawId,
      name: json['name'] as String? ?? 'Categoria',
      limit: (json['limit'] as num?)?.toDouble(),
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF5C6B73,
      iconCodePoint: (json['iconCodePoint'] as num?)?.toInt() ??
          Icons.home_work_rounded.codePoint,
      iconFontFamily: json['iconFontFamily'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

/// Seeded on first run.
final List<Category> defaultCategories = [
  Category(
    id: 'fixedCosts',
    name: 'Custos fixos',
    limit: null,
    colorValue: 0xFF5C6B73,
    iconCodePoint: Icons.home_work_rounded.codePoint,
    iconFontFamily: Icons.home_work_rounded.fontFamily,
    isDefault: true,
  ),
  Category(
    id: 'entertainment',
    name: 'Entretenimento',
    limit: null,
    colorValue: 0xFFE0764F,
    iconCodePoint: Icons.local_movies_rounded.codePoint,
    iconFontFamily: Icons.local_movies_rounded.fontFamily,
    isDefault: true,
  ),
  Category(
    id: 'investments',
    name: 'Investimentos',
    limit: null,
    colorValue: 0xFF2D6A4F,
    iconCodePoint: Icons.trending_up_rounded.codePoint,
    iconFontFamily: Icons.trending_up_rounded.fontFamily,
    isDefault: true,
  ),
  Category(
    id: 'dining',
    name: 'Alimentação',
    limit: null,
    colorValue: 0xFFC98A2C,
    iconCodePoint: Icons.restaurant_rounded.codePoint,
    iconFontFamily: Icons.restaurant_rounded.fontFamily,
    isDefault: true,
  ),
];

/// Amount spent in a single category for a single month.
class CategorySummary {
  const CategorySummary({required this.category, required this.spent});

  final Category category;
  final double spent;

  bool get hasLimit => category.hasLimit;

  /// Clamped to `[0, 1]` so progress indicators never overflow.
  double get ratio =>
      hasLimit ? (spent / category.limit!).clamp(0.0, 1.0).toDouble() : 0.0;

  bool get isOverLimit => hasLimit && spent > category.limit!;
}
