import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/main.dart';
import 'package:tally/widgets/category_summary_row.dart';

void main() {
  testWidgets('app renders the home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TallyApp());
    await tester.pumpAndSettle();

    expect(find.text('Tally'), findsOneWidget);
    expect(find.text('Total gasto no mês'), findsOneWidget);
  });

  testWidgets('tapping the total card opens the chart screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TallyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Total gasto no mês'));
    await tester.pumpAndSettle();

    expect(find.text('Gráfico'), findsOneWidget);
    expect(find.text('Total gasto no mês'), findsOneWidget);
    expect(find.text('Nada registrado neste mês'), findsOneWidget);
  });

  testWidgets('tapping a category card filters the purchase list',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final purchases = jsonEncode([
      {
        'id': 'p1',
        'description': 'Assinatura streaming',
        'value': 100.0,
        'paymentType': 'debit',
        'category': 'fixedCosts',
        'date': DateTime(now.year, now.month, 10).toIso8601String(),
        'installments': 1,
      },
      {
        'id': 'p2',
        'description': 'Almoço fora',
        'value': 50.0,
        'paymentType': 'credit',
        'category': 'dining',
        'date': DateTime(now.year, now.month, 15).toIso8601String(),
        'installments': 1,
      },
    ]);
    SharedPreferences.setMockInitialValues({'purchases_v1': purchases});

    await tester.pumpWidget(const TallyApp());
    await tester.pumpAndSettle();

    expect(find.text('Assinatura streaming'), findsOneWidget);
    expect(find.text('Almoço fora'), findsOneWidget);

    final diningCard = find.descendant(
      of: find.byType(CategorySummaryRow),
      matching: find.text('Alimentação'),
    );
    await tester.tap(diningCard);
    await tester.pumpAndSettle();

    expect(find.text('Assinatura streaming'), findsNothing);
    expect(find.text('Almoço fora'), findsOneWidget);
    expect(find.byType(InputChip), findsOneWidget);

    await tester.tap(diningCard);
    await tester.pumpAndSettle();

    expect(find.text('Assinatura streaming'), findsOneWidget);
    expect(find.text('Almoço fora'), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('category cards with a limit do not overflow',
      (WidgetTester tester) async {
    final categories = jsonEncode([
      {
        'id': 'fixedCosts',
        'name': 'Custos fixos',
        'limit': 100.0,
        'colorValue': 0xFF5C6B73,
        'iconCodePoint': Icons.home_work_rounded.codePoint,
        'iconFontFamily': Icons.home_work_rounded.fontFamily,
        'isDefault': true,
      },
    ]);
    SharedPreferences.setMockInitialValues({'categories_v1': categories});

    await tester.pumpWidget(const TallyApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
