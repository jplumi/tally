# Minhas Finanças

A focused personal finance tracker built in Flutter. Log a purchase in a few taps, then check how much you spent each month, broken down by category.

## Features

- **Quick entry** — a bottom sheet (opened from the floating "+" button) with description and value as the only required fields. Payment type defaults to **débito**, category defaults to **custos fixos**, and date defaults to **today**, so logging a routine debit purchase is just two taps and a save.
- **Credit + installments** — switch to **crédito** and a "Número de parcelas" field appears. A parcelled purchase is automatically spread across the following months: an R$300 purchase in 3x logged in June shows R$100 in June, R$100 in July, and R$100 in August, each tagged "Parcela 1/3", "2/3", "3/3".
- **Four categories** — custos fixos, entretenimento, investimentos, alimentação — each with its own color and icon.
- **Monthly view** — swipe between months, see the total spent, a per-category breakdown with share bars, and the full list of purchases billed that month.
- **Edit & delete** — tap any purchase to edit it, or swipe it left to delete (with a confirmation dialog).
- **Local storage** — everything is saved on-device with `shared_preferences`. No account, no server, no internet connection required.

## Project structure

```
lib/
  models/        Purchase, PaymentType, PurchaseCategory
  services/      PurchaseStore — persistence + monthly aggregation logic
  screens/       HomeScreen — the monthly overview
  widgets/       AddPurchaseSheet (the quick-entry form) and supporting UI
  utils/         BRL currency formatting, pt-BR date formatting
```

## Running it

This package ships only the Dart source (`lib/`) and `pubspec.yaml` — it doesn't include the generated `android/`, `ios/`, `web/`, etc. platform folders, since those are large, mostly-boilerplate, and best generated fresh by your local Flutter SDK. To run:

1. Make sure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (`flutter --version` to check).
2. Unzip this project, then from inside the folder run:
   ```bash
   flutter create .
   ```
   This generates the platform folders without touching `lib/` or `pubspec.yaml`.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run it:
   ```bash
   flutter run
   ```
   Pick a connected device/emulator, or run `flutter run -d chrome` to try it in a browser, or `flutter run -d macos` / `-d windows` / `-d linux` for desktop.

## Notes & possible next steps

- Installment math: a purchase "touches" every month from its purchase date through `purchase date + installments - 1`, each month billed at `value / installments`. This mirrors how Brazilian credit card statements (faturas) usually work.
- All data lives in `shared_preferences` as a single JSON blob — fine for personal use at this scale. If the list grows very large, swapping in `sqflite` would be a natural upgrade.
- Categories, colors, and icons are defined in `lib/models/purchase_category.dart` if you want to add a fifth category or change the palette.
