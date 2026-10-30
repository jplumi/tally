import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/main.dart';

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
}
