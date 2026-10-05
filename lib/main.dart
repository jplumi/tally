import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/purchase_store.dart';

void main() {
  runApp(const TallyApp());
}

class TallyApp extends StatelessWidget {
  const TallyApp({super.key});

  // Deliberate palette: deep forest green reads as "money / growth" without
  // being the generic Material blue, paired with a warm neutral surface.
  static const _seed = Color(0xFF1B4332);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );

    return ChangeNotifierProvider(
      create: (_) => PurchaseStore()..load(),
      child: MaterialApp(
        title: 'Tally',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          scaffoldBackgroundColor: const Color(0xFFFAF8F4),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFAF8F4),
            foregroundColor: Color(0xFF1B1B1B),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(letterSpacing: -0.5),
            titleLarge: TextStyle(letterSpacing: -0.3),
            titleMedium: TextStyle(letterSpacing: -0.2),
          ).apply(
            bodyColor: const Color(0xFF1B1B1B),
            displayColor: const Color(0xFF1B1B1B),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            filled: false,
          ),
          chipTheme: ChipThemeData(
            selectedColor: colorScheme.secondaryContainer,
            shape: const StadiumBorder(),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
