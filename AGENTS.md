# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project overview

**tally** is a personal finance tracker built with Flutter. It lets a user log
purchases and see how much they spent each month, broken down by category.
Everything is stored locally on-device — there is no account, server, or
network requirement.

Categories are **user-editable data**, not a fixed enum. The app ships with
four default categories (seeded on first run) and the user can add, edit,
reorder, and delete categories from the Categories screen.

The UI is entirely in **Brazilian Portuguese (pt-BR)**, and the domain
(currency, dates, payment types, categories) is BRL/Brazil-specific. Keep user
facing strings in pt-BR.

## Tech stack

- **Flutter** (Dart SDK `>=3.0.0 <4.0.0`), Material 3 (`useMaterial3: true`)
- **State management:** `provider` (`ChangeNotifier`-based)
- **Persistence:** `shared_preferences` (three keys: two JSON lists + one double)
- **Formatting:** `intl` (BRL currency and pt-BR date handling)
- **Lints:** `flutter_lints` with `prefer_const_constructors` and
  `prefer_const_literals_to_create_immutables` enabled in
  `analysis_options.yaml`

There is no code generation step (`build_runner` is not configured).

## Commands

```bash
flutter pub get          # install dependencies
flutter analyze          # static analysis (run before finishing changes)
flutter test             # run tests
flutter run              # run on a device/emulator
flutter run -d chrome    # run in a browser
```

## Architecture and conventions

- **State management:** `PurchaseStore` is the single source of truth. It is
  provided once in `main.dart` via `ChangeNotifierProvider` and consumed with
  `context.watch<PurchaseStore>()` (reactive) or `context.read<PurchaseStore>()`
  (in callbacks/actions). Do not introduce a second store without a clear
  reason.
- **Data flow:** screens and widgets read derived data from the store
  (`purchasesForMonth`, `totalForMonth`, `categorySummariesForMonth`,
  `categoryById`, `categories`, `monthlyLimit`). Mutations go through the
  public methods — `addPurchase` / `updatePurchase` / `deletePurchase`,
  `addCategory` / `updateCategory` / `reorderCategory` / `deleteCategory`, and
  `setMonthlyLimit`. Mutations call `notifyListeners()` first, then `await` the
  relevant `_persist*` method.
- **Models:**
  - `lib/models/payment_type.dart` — `PaymentType` enum (`debit`, `credit`)
    with a `PaymentTypeLabel` extension for label, `storageValue`, and
    `fromStorage` (falls back to `debit` on unknown values).
  - `lib/models/category.dart` — `Category` is a user-editable class with a
    stable `id` (referenced by persisted purchases), `name`, optional monthly
    `limit` (`null`/`0` = no limit), ARGB `colorValue`, `iconCodePoint` +
    `iconFontFamily`, and `isDefault`. Also defines `defaultCategories` and
    `CategorySummary` (per-category monthly spend with a clamped progress
    ratio).
  - `lib/models/purchase.dart` — `Purchase` references a category by
    `categoryId` (string), not an enum.
- **Storage:** all persistence goes through `PurchaseStore` and
  `shared_preferences`, under three keys:
  - `purchases_v1` — JSON list of `Purchase`. `paymentType` is stored by its
    Dart `name`; `categoryId` is serialized under the JSON key `category`;
    `date` is ISO-8601. Decoding is tolerant (unknown payment type → `debit`,
    missing category → `fixedCosts`, missing installments → `1`).
  - `categories_v1` — JSON list of `Category`. First run seeds
    `defaultCategories`. `Category.fromJson` is tolerant of missing fields
    (generates an id, falls back to a default name/color/icon).
  - `monthly_limit_v1` — a single `double`, removed when unset.
- **UI strings:** pt-BR, with `R$` currency formatting via `formatBRL()` from
  `lib/utils/currency_formatter.dart`. Dates go through
  `lib/utils/date_utils.dart`. Currency inputs use `CurrencyInputFormatter`
  from `lib/utils/currency_input_formatter.dart`. Do not hard-code new
  BRL/date formatting inline.
- **Colors & icons:** category choices are deliberate, hand-picked values in
  `lib/utils/category_palette.dart` (`CategoryPalette.colors` and
  `CategoryPalette.icons`; the first four of each are the legacy default
  category colors/icons). The app theme seeds from `Color(0xFF1B4332)` (deep
  forest green) in `main.dart`. Do not switch to default Material colors.
- **Const correctness:** prefer `const` constructors and const literals — the
  linter enforces this.

## Domain logic: installments

This is the trickiest part of the app and must be preserved exactly.

- A purchase "touches" every month from its purchase date through
  `purchase date + installments - 1`, each month billed at
  `value / installments`.
- Debit purchases always have `installments = 1`. Installments only apply to
  `PaymentType.credit` with `installments > 1` (`Purchase.isInstallment`).
- Key logic lives in `Purchase`:
  - `installmentValue` = `value / installments`
  - `startMonth` / `endMonth` = first/last affected month (inclusive)
  - `touchesMonth(month)` = whether a billed installment lands in that month
  - `installmentNumberForMonth(month)` = 1-based "n/m" label for the tile
- Monthly aggregation in `PurchaseStore` (`purchasesForMonth`,
  `totalForMonth`, `categorySummariesForMonth`) is built on top of these and
  always sums `installmentValue`, never the full `value`.

## Entry/edit sheet behavior

`AddPurchaseSheet` serves both create and edit modes (via optional `existing`).
Defaults: `PaymentType.debit`, `categoryId = 'fixedCosts'`, today's date, and
`installments = 1`. The installment count dropdown only appears for credit.
Switching back to debit resets installments to 1. Category is chosen from a
`ChoiceChip` per category. Value input uses `CurrencyInputFormatter`
(digits-only, last two digits are cents).

## Category & monthly limit behavior

- `deleteCategory` refuses to delete the `fixedCosts` fallback and any category
  still referenced by a purchase; it returns `false` (and changes nothing) when
  refused. `isCategoryInUse` / `purchaseCountForCategory` back the guard.
- `categoryById` always resolves to a category (falls back to `fixedCosts`,
  then the first category, then `defaultCategories.first`) so the UI never
  gets `null`.
- `setMonthlyLimit` normalizes non-positive values to `null` (unset). A
  monthly limit and per-category limits are both optional and independent.

## Testing

Tests are real (not the stale Flutter template):

- `test/models/category_test.dart` — `Category` JSON round-trip, `hasLimit`
  semantics, default category ids, `copyWith(limit: null)`, `CategorySummary`
  ratio/clamp/over-limit.
- `test/services/purchase_store_test.dart` — uses
  `SharedPreferences.setMockInitialValues`; covers first-run seeding, category
  CRUD/reorder/delete guards, monthly-limit persistence, and installment
  aggregation across months.
- `test/widget_test.dart` — smoke test that pumps `TallyApp` and checks the
  home screen renders.

Prefer testing domain logic in `Purchase`, `Category`, and `PurchaseStore`
(installment math, monthly aggregation, storage round-trips) over UI-only
tests.

## Pitfalls

- `Purchase.endMonth` uses month arithmetic (`date.month - 2 + installments`);
  be careful when refactoring — off-by-one errors here silently change which
  months an installment appears in.
- `PurchaseStore.purchases` and `.categories` are unmodifiable; mutate only via
  the public methods so persistence and sorting stay consistent.
- Purchases are sorted by date descending in `_sortPurchases()`; keep that
  ordering. `purchasesForMonth` re-sorts the filtered list rather than relying
  on `_purchases` order.
- `Category.copyWith` uses a sentinel (`_unset`) so `limit: null` actually
  clears the limit, distinct from "not provided". Preserve this when changing
  `copyWith`.
- `lib/utils/date_utils.dart` shadows Dart's own `DateTime` helpers; it defines
  project-local formatters only — do not confuse it with `dart:core`.
- The codebase targets a recent Flutter and uses `Color.withValues`,
  `ColorScheme.surfaceContainerHigh` / `onSurfaceVariant`, and
  `ReorderableDelayedDragStartListener`. Do not "clean up" these to deprecated
  equivalents (`withOpacity`, `surface`, etc.).
- Keep the `pubspec.lock` file committed (this is an app, not a package).

`android/`, `build/`, and other generated/platform folders are generated output
and should be ignored when reading or editing the project. Platform folders are
regenerated with `flutter create .` if missing.
