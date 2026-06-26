import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment_type.dart';
import '../models/purchase.dart';
import '../models/purchase_category.dart';

class PurchaseStore extends ChangeNotifier {
  static const _storageKey = 'purchases_v1';

  List<Purchase> _purchases = [];
  bool _isLoaded = false;

  List<Purchase> get purchases => List.unmodifiable(_purchases);
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      _purchases = decoded
          .map((e) => Purchase.fromJson(e as Map<String, dynamic>))
          .toList();
      _sort();
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_purchases.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void _sort() {
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
    required PurchaseCategory category,
    required DateTime date,
    int installments = 1,
  }) async {
    final purchase = Purchase(
      id: _generateId(),
      description: description,
      value: value,
      paymentType: paymentType,
      category: category,
      date: date,
      installments: installments,
    );
    _purchases.add(purchase);
    _sort();
    notifyListeners();
    await _persist();
  }

  Future<void> updatePurchase(Purchase updated) async {
    final index = _purchases.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;
    _purchases[index] = updated;
    _sort();
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

  /// Totals billed in [month], grouped by category.
  Map<PurchaseCategory, double> totalsByCategoryForMonth(DateTime month) {
    final totals = <PurchaseCategory, double>{
      for (final c in PurchaseCategory.values) c: 0.0,
    };
    for (final p in purchasesForMonth(month)) {
      totals[p.category] = (totals[p.category] ?? 0) + p.installmentValue;
    }
    return totals;
  }
}
