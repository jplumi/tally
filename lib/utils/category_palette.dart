import 'package:flutter/material.dart';

/// Curated choices for custom category icons and colors.
abstract final class CategoryPalette {
  /// Hand-picked hues, including the four legacy category colors.
  static const List<Color> colors = [
    Color(0xFF5C6B73), // slate — Custos fixos
    Color(0xFFE0764F), // terracotta — Entretenimento
    Color(0xFF2D6A4F), // emerald — Investimentos
    Color(0xFFC98A2C), // amber — Alimentação
    Color(0xFF8E44AD), // purple
    Color(0xFF2980B9), // blue
    Color(0xFFC0392B), // red
    Color(0xFF16A085), // teal
    Color(0xFFD35400), // orange
    Color(0xFF7F8C8D), // slate gray
  ];

  /// Curated Material icons, including the four legacy category icons.
  static const List<IconData> icons = [
    Icons.home_work_rounded,
    Icons.local_movies_rounded,
    Icons.trending_up_rounded,
    Icons.restaurant_rounded,
    Icons.sports_esports_rounded,
    Icons.shopping_bag_rounded,
    Icons.directions_car_rounded,
    Icons.health_and_safety_rounded,
    Icons.school_rounded,
    Icons.pets_rounded,
    Icons.flight_rounded,
    Icons.fitness_center_rounded,
    Icons.child_care_rounded,
    Icons.receipt_long_rounded,
    Icons.card_giftcard_rounded,
    Icons.wifi_rounded,
  ];
}
