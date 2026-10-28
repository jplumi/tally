import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/payment_type.dart';
import '../models/purchase.dart';

class PurchaseStore extends ChangeNotifier {
  static const _purchasesKey = 'purchases_v1';
  static const _categoriesKey = 'categories_v1';
  static const _monthlyLimitKey = 'monthly_limit_v1';

  List<Purchase> _purchases = [];
  List<Category> _categories = [];
  double? _monthlyLimit;
  bool _isLoaded = false;

  List<Purchase> get purchases => List.unmodifiable(_purchases);
  List<Category> get categories => List.unmodifiable(_categories);
  double? get monthlyLimit => _monthlyLimit;
  bool get hasMonthlyLimit => _monthlyLimit != null && _monthlyLimit! > 0;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final rawPurchases = prefs.getString(_purchasesKey);
    if (rawPurchases != null && rawPurchases.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(rawPurchases) as List<dynamic>;
      _purchases = decoded
          .map((e) => Purchase.fromJson(e as Map<String, dynamic>))
          .toList();
      _sortPurchases();
    }

    final rawCategories = prefs.getString(_categoriesKey);
    if (rawCategories != null && rawCategories.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(rawCategories) as List<dynamic>;
      _categories = decoded
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _categories = List.of(defaultCategories);
      await _persistCategories();
    }

    final rawLimit = prefs.getDouble(_monthlyLimitKey);
    _monthlyLimit = (rawLimit != null && rawLimit > 0) ? rawLimit : null;

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _persistPurchases();
    await _persistCategories();
  }

  Future<void> _persistPurchases() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_purchases.map((p) => p.toJson()).toList());
    await prefs.setString(_purchasesKey, encoded);
  }

  Future<void> _persistCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_categories.map((c) => c.toJson()).toList());
    await prefs.setString(_categoriesKey, encoded);
  }

  Future<void> _persistMonthlyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    if (_monthlyLimit == null) {
      await prefs.remove(_monthlyLimitKey);
    } else {
      await prefs.setDouble(_monthlyLimitKey, _monthlyLimit!);
    }
  }

  Future<void> setMonthlyLimit(double? value) async {
    final normalized = (value != null && value > 0) ? value : null;
    if (normalized == _monthlyLimit) return;
    _monthlyLimit = normalized;
    notifyListeners();
    await _persistMonthlyLimit();
  }

  void _sortPurchases() {
    _purchases.sort((a, b) => b.date.compareTo(a.date));
  }

  String _generateId() {
    final rnd = Random();
    return '${DateTime.now().microsecondsSinceEpoch}${rnd.nextInt(9999)}';
  }

  Future<void> addPurchase({
    required String description,
    required double value,
    required PaymentType paymentType,
    required String categoryId,
    required DateTime date,
    int installments = 1,
  }) async {
    final purchase = Purchase(
      id: _generateId(),
      description: description,
      value: value,
      paymentType: paymentType,
      categoryId: categoryId,
      date: date,
      installments: installments,
    );
    _purchases.add(purchase);
    _sortPurchases();
    notifyListeners();
    await _persist();
  }

  Future<void> updatePurchase(Purchase updated) async {
    final index = _purchases.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;
    _purchases[index] = updated;
    _sortPurchases();
    notifyListeners();
    await _persist();
  }

  Future<void> deletePurchase(String id) async {
    _purchases.removeWhere((p) => p.id == id);
    notifyListeners();
    await _persist();
  }

  /// Purchases that have a billed installment landing in [month],
  /// ordered by day of the original purchase date, most recent first.
  List<Purchase> purchasesForMonth(DateTime month) {
    final list = _purchases.where((p) => p.touchesMonth(month)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Total amount billed in [month] across all purchases.
  double totalForMonth(DateTime month) {
    return purchasesForMonth(month)
        .fold(0.0, (sum, p) => sum + p.installmentValue);
  }

  /// Per-category spend for [month], including zero-spent categories,
  /// ordered by the user's category order.
  List<CategorySummary> categorySummariesForMonth(DateTime month) {
    final totals = <String, double>{};
    for (final p in purchasesForMonth(month)) {
      totals[p.categoryId] = (totals[p.categoryId] ?? 0) + p.installmentValue;
    }

    return _categories
        .map((c) => CategorySummary(category: c, spent: totals[c.id] ?? 0.0))
        .toList();
  }

  /// Resolves a category by [id], falling back to `fixedCosts` (or the first
  /// available category) so the UI never receives `null`.
  Category categoryById(String id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    for (final c in _categories) {
      if (c.id == 'fixedCosts') return c;
    }
    return _categories.isNotEmpty ? _categories.first : defaultCategories.first;
  }

  int purchaseCountForCategory(String id) {
    return _purchases.where((p) => p.categoryId == id).length;
  }

  bool isCategoryInUse(String id) {
    return _purchases.any((p) => p.categoryId == id);
  }

  Future<void> addCategory({
    required String name,
    double? limit,
    required int colorValue,
    required int iconCodePoint,
    String? iconFontFamily,
  }) async {
    final category = Category(
      id: _generateId(),
      name: name,
      limit: limit,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      iconFontFamily: iconFontFamily,
      isDefault: false,
    );
    _categories.add(category);
    notifyListeners();
    await _persistCategories();
  }

  Future<void> reorderCategory(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= _categories.length) return;
    if (newIndex < 0 || newIndex >= _categories.length) return;
    final category = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, category);
    notifyListeners();
    await _persistCategories();
  }

  Future<void> updateCategory(Category updated) async {
    final index = _categories.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;
    _categories[index] = updated;
    notifyListeners();
    await _persistCategories();
  }

  /// Deletes a category only when it is not the `fixedCosts` fallback and has
  /// no purchases referencing it. Returns `false` (and changes nothing) when
  /// the deletion is refused.
  Future<bool> deleteCategory(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return false;
    final category = _categories[index];
    if (category.id == 'fixedCosts' || isCategoryInUse(id)) return false;
    _categories.removeAt(index);
    notifyListeners();
    await _persistCategories();
    return true;
  }
}
