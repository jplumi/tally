# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project overview

**tally** is a personal finance tracker built with Flutter. It lets a user log
purchases and see how much they spent each month, broken down by category.
Everything is stored locally on-device — there is no account, server, or
network requirement.

The UI is entirely in **Brazilian Portuguese (pt-BR)**, and the domain
(currency, dates, payment types, categories) is BRL/Brazil-specific. Keep user
facing strings in pt-BR.

## Tech stack

- **Flutter** (Dart SDK `>=3.0.0 <4.0.0`), Material 3 (`useMaterial3: true`)
- **State management:** `provider` (`ChangeNotifier`-based)
- **Persistence:** `shared_preferences` (single JSON blob)
- **Formatting:** `intl` (BRL currency and pt-BR date handling)
- **Lints:** `flutter_lints` with `prefer_const_constructors` and
  `prefer_const_literals_to_create_immutables` enabled in
  `analysis_options.yaml`

## Commands

```bash
flutter pub get          # install dependencies
flutter analyze          # static analysis (run before finishing changes)
flutter test             # run tests
flutter run              # run on a device/emulator
flutter run -d chrome    # run in a browser
```

There is no code generation step (build_runner is not configured).

## Architecture and conventions

- **State management:** `PurchaseStore` is the single source of truth. It is
  provided once in `main.dart` via `ChangeNotifierProvider` and consumed with
  `context.watch<PurchaseStore>()` (reactive) or `context.read<PurchaseStore>()`
  (in callbacks/actions). Do not introduce a second store without a clear
  reason.
- **Data flow:** screens and widgets read derived data (e.g.
  `purchasesForMonth`, `totalForMonth`, `totalsByCategoryForMonth`) from the
  store; mutations go through `addPurchase` / `updatePurchase` / `deletePurchase`.
  Mutations call `notifyListeners()` first, then `await _persist()`.
- **Models:** enums use Dart extension methods (`PaymentTypeLabel`,
  `PurchaseCategoryMeta`) for labels, icons, colors, and storage mapping rather
  than switch statements spread across the UI. Follow this pattern for new
  enum metadata.
- **Storage:** all purchases serialize to JSON and persist under the
  `shared_preferences` key `purchases_v1`. Enum values are stored by their Dart
  `name` (`storageValue`) and decoded via `fromStorage`, which falls back to
  `debit` / `fixedCosts` on unknown values. Keep this backward-compatible
  approach when adding enum members.
- **UI strings:** pt-BR, with `R$` currency formatting via `formatBRL()` from
  `lib/utils/currency_formatter.dart`. Dates go through
  `lib/utils/date_utils.dart`. Do not hard-code new BRL/date formatting inline.
- **Colors:** category colors are deliberate, hand-picked hues defined in
  `lib/models/purchase_category.dart`. The app theme seeds from `Color(0xFF1B4332)`
  (deep forest green) in `main.dart`. Do not switch to default Material colors.
- **Const correctness:** prefer `const` constructors and const literals — the
  linter enforces this.

## Domain logic: installments

This is the trickiest part of the app and must be preserved exactly.

- A purchase "touches" every month from its purchase date through
  `purchase date + installments - 1`, each month billed at
  `value / installments`.
- Debit purchases always have `installments = 1`. Installments only apply to
  `PaymentType.credit` with `installments > 1`.
- Key logic lives in `Purchase`:
  - `installmentValue` = `value / installments`
  - `startMonth` / `endMonth` = first/last affected month
  - `touchesMonth(month)` = whether a billed installment lands in that month
  - `installmentNumberForMonth(month)` = 1-based "n/m" label for the tile
- Monthly aggregation in `PurchaseStore` (`purchasesForMonth`,
  `totalForMonth`, `totalsByCategoryForMonth`) is built on top of these and
  always sums `installmentValue`, not the full `value`.

## Entry/edit sheet behavior

`AddPurchaseSheet` serves both create and edit modes (via optional `existing`).
Defaults: `PaymentType.debit`, `PurchaseCategory.fixedCosts`, today's date, and
`installments = 1`. The installment count dropdown only appears for credit.
Switching back to debit resets installments to 1. Value input uses
`CurrencyInputFormatter` (digits-only, last two digits are cents).

## Testing

The only test file (`test/widget_test.dart`) is the **default Flutter template
smoke test and is currently stale/broken**: it imports and pumps `MyApp`, which
no longer exists (the widget is now `TallyApp`). If you touch tests, replace
this with real tests rather than fixing the template. Prefer testing the domain
logic in `Purchase` and `PurchaseStore` (installment math, monthly aggregation)
over UI-only tests. Note `shared_preferences` has a test mock
(`SharedPreferences.setMockInitialValues`) for store tests.

## Pitfalls

- `Purchase.endMonth` uses month arithmetic (`date.month - 2 + installments`);
  be careful when refactoring — off-by-one errors here silently change which
  months an installment appears in.
- `PurchaseStore.purchases` is unmodifiable; mutate only via the public
  `addPurchase` / `updatePurchase` / `deletePurchase` methods so persistence
  and sorting stay consistent.
- Purchases are sorted by date descending in `_sort()`; keep that ordering.
- `lib/utils/date_utils.dart` shadows Dart's own `DateTime` helpers — do not
  `import 'dart:core'` `date_utils` confusion; it defines project-local
  formatters only.
- Keep the `pubspec.lock` file committed (this is an app, not a package).

`android/`, `build/`, and other generated/platform folders are generated output
and should be ignored when reading or editing the project. Platform folders are
regenerated with `flutter create .` if missing.
