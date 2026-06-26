import 'package:flutter/material.dart';

/// The four spending buckets this app tracks.
enum PurchaseCategory { fixedCosts, entertainment, investments, dining }

extension PurchaseCategoryMeta on PurchaseCategory {
  String get label {
    switch (this) {
      case PurchaseCategory.fixedCosts:
        return 'Custos fixos';
      case PurchaseCategory.entertainment:
        return 'Entretenimento';
      case PurchaseCategory.investments:
        return 'Investimentos';
      case PurchaseCategory.dining:
        return 'Alimentação';
    }
  }

  IconData get icon {
    switch (this) {
      case PurchaseCategory.fixedCosts:
        return Icons.home_work_rounded;
      case PurchaseCategory.entertainment:
        return Icons.local_movies_rounded;
      case PurchaseCategory.investments:
        return Icons.trending_up_rounded;
      case PurchaseCategory.dining:
        return Icons.restaurant_rounded;
    }
  }

  /// Distinct, deliberate hues per category — not the Material defaults.
  Color get color {
    switch (this) {
      case PurchaseCategory.fixedCosts:
        return const Color(0xFF5C6B73); // slate
      case PurchaseCategory.entertainment:
        return const Color(0xFFE0764F); // terracotta
      case PurchaseCategory.investments:
        return const Color(0xFF2D6A4F); // emerald
      case PurchaseCategory.dining:
        return const Color(0xFFC98A2C); // amber
    }
  }

  String get storageValue => name;

  static PurchaseCategory fromStorage(String value) {
    return PurchaseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PurchaseCategory.fixedCosts,
    );
  }
}
