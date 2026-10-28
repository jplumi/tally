import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/models/payment_type.dart';
import 'package:tally/models/purchase.dart';
import 'package:tally/services/purchase_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<PurchaseStore> loadStore() async {
    final store = PurchaseStore();
    await store.load();
    return store;
  }

  test('first load seeds the four default categories', () async {
    final store = await loadStore();

    expect(store.categories, hasLength(4));
    expect(
      store.categories.map((c) => c.id).toSet(),
      {'fixedCosts', 'entertainment', 'investments', 'dining'},
    );
  });

  test('legacy purchases resolve against seeded categories', () async {
    final legacyPurchase = Purchase(
      id: 'p1',
      description: 'Mercado',
      value: 100,
      paymentType: PaymentType.debit,
      categoryId: 'dining',
      date: DateTime(2025, 1, 5),
    );
    SharedPreferences.setMockInitialValues({
      'purchases_v1': jsonEncode([legacyPurchase.toJson()]),
    });

    final store = await loadStore();

    expect(store.purchases.single.categoryId, 'dining');
    expect(store.categoryById('dining').name, 'Alimentação');
  });

  test('category CRUD persists across loads', () async {
    final store = await loadStore();

    await store.addCategory(
      name: 'Games',
      limit: 150,
      colorValue: 0xFFAA0000,
      iconCodePoint: Icons.sports_esports_rounded.codePoint,
      iconFontFamily: Icons.sports_esports_rounded.fontFamily,
    );

    final games = store.categories.firstWhere((c) => c.name == 'Games');
    expect(games.limit, 150);
    expect(games.isDefault, false);

    await store.updateCategory(games.copyWith(name: 'Jogos', limit: null));
    final updated = store.categories.firstWhere((c) => c.id == games.id);
    expect(updated.name, 'Jogos');
    expect(updated.hasLimit, false);

    final reloaded = await loadStore();
    final persisted = reloaded.categories.firstWhere((c) => c.id == games.id);
    expect(persisted.name, 'Jogos');
    expect(persisted.hasLimit, false);
  });

  test('delete guard blocks in-use and default categories', () async {
    final store = await loadStore();

    await store.addPurchase(
      description: 'Cinema',
      value: 40,
      paymentType: PaymentType.debit,
      categoryId: 'entertainment',
      date: DateTime(2025, 1, 10),
    );

    await store.addCategory(
      name: 'Pets',
      limit: null,
      colorValue: 0xFF00AA00,
      iconCodePoint: Icons.pets_rounded.codePoint,
      iconFontFamily: Icons.pets_rounded.fontFamily,
    );
    final pets = store.categories.firstWhere((c) => c.name == 'Pets');

    expect(store.isCategoryInUse('entertainment'), true);
    expect(store.purchaseCountForCategory('entertainment'), 1);
    expect(store.isCategoryInUse(pets.id), false);

    expect(await store.deleteCategory('entertainment'), false);
    expect(await store.deleteCategory('fixedCosts'), false);
    expect(await store.deleteCategory('investments'), true);
    expect(await store.deleteCategory(pets.id), true);
    expect(store.categories.any((c) => c.id == pets.id), false);
    expect(store.categories.any((c) => c.id == 'investments'), false);
  });

  test('monthly limit defaults to unset', () async {
    final store = await loadStore();

    expect(store.monthlyLimit, isNull);
    expect(store.hasMonthlyLimit, false);
  });

  test('monthly limit persists across loads', () async {
    final store = await loadStore();

    await store.setMonthlyLimit(1200);
    expect(store.monthlyLimit, 1200);
    expect(store.hasMonthlyLimit, true);

    final reloaded = await loadStore();
    expect(reloaded.monthlyLimit, 1200);
    expect(reloaded.hasMonthlyLimit, true);
  });

  test('monthly limit is cleared with null or non-positive values', () async {
    final store = await loadStore();

    await store.setMonthlyLimit(1200);
    await store.setMonthlyLimit(null);
    expect(store.monthlyLimit, isNull);
    expect(store.hasMonthlyLimit, false);
    expect((await loadStore()).monthlyLimit, isNull);

    await store.setMonthlyLimit(500);
    await store.setMonthlyLimit(0);
    expect(store.monthlyLimit, isNull);
    expect((await loadStore()).monthlyLimit, isNull);
  });

  test('categorySummariesForMonth sums installment values per category',
      () async {
    final store = await loadStore();

    await store.addPurchase(
      description: 'Compras parceladas',
      value: 300,
      paymentType: PaymentType.credit,
      categoryId: 'dining',
      date: DateTime(2025, 1, 10),
      installments: 3,
    );
    await store.addPurchase(
      description: 'Conta fixa',
      value: 100,
      paymentType: PaymentType.debit,
      categoryId: 'fixedCosts',
      date: DateTime(2025, 2, 1),
    );

    final jan = store.categorySummariesForMonth(DateTime(2025, 1));
    expect(jan.firstWhere((s) => s.category.id == 'dining').spent, 100);
    expect(jan.firstWhere((s) => s.category.id == 'fixedCosts').spent, 0);
    expect(jan, hasLength(4)); // every category appears, even with zero spent

    final feb = store.categorySummariesForMonth(DateTime(2025, 2));
    expect(feb.firstWhere((s) => s.category.id == 'dining').spent, 100);
    expect(feb.firstWhere((s) => s.category.id == 'fixedCosts').spent, 100);

    final mar = store.categorySummariesForMonth(DateTime(2025, 3));
    expect(mar.firstWhere((s) => s.category.id == 'dining').spent, 100);
    expect(mar.firstWhere((s) => s.category.id == 'fixedCosts').spent, 0);

    final apr = store.categorySummariesForMonth(DateTime(2025, 4));
    expect(apr.firstWhere((s) => s.category.id == 'dining').spent, 0);
  });
}
