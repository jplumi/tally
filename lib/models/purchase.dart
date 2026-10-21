import 'payment_type.dart';

class Purchase {
  final String id;
  final String description;

  /// Total value of the purchase, in BRL. For installment purchases this
  /// is the full amount; divide by [installments] to get the monthly bite.
  final double value;
  final PaymentType paymentType;
  final String categoryId;
  final DateTime date;

  /// Number of installments. Always 1 for debit purchases.
  final int installments;

  Purchase({
    required this.id,
    required this.description,
    required this.value,
    required this.paymentType,
    required this.categoryId,
    required this.date,
    this.installments = 1,
  });

  double get installmentValue => value / installments;

  bool get isInstallment => paymentType == PaymentType.credit && installments > 1;

  /// The first month this purchase affects.
  DateTime get startMonth => DateTime(date.year, date.month);

  /// The last month this purchase affects (inclusive).
  DateTime get endMonth {
    final totalMonths = date.month - 2 + installments;
    return DateTime(date.year + totalMonths ~/ 12, totalMonths % 12 + 1);
  }

  /// Whether this purchase has a billed installment in [month].
  bool touchesMonth(DateTime month) {
    final target = DateTime(month.year, month.month);
    return !target.isBefore(startMonth) && !target.isAfter(endMonth);
  }

  /// 1-based installment number that lands in [month], e.g. 2 of 3.
  int installmentNumberForMonth(DateTime month) {
    final target = DateTime(month.year, month.month);
    return (target.year - startMonth.year) * 12 + (target.month - startMonth.month) + 1;
  }

  Purchase copyWith({
    String? description,
    double? value,
    PaymentType? paymentType,
    String? categoryId,
    DateTime? date,
    int? installments,
  }) {
    return Purchase(
      id: id,
      description: description ?? this.description,
      value: value ?? this.value,
      paymentType: paymentType ?? this.paymentType,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      installments: installments ?? this.installments,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'value': value,
        'paymentType': paymentType.storageValue,
        'category': categoryId,
        'date': date.toIso8601String(),
        'installments': installments,
      };

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as String,
      description: json['description'] as String,
      value: (json['value'] as num).toDouble(),
      paymentType: PaymentTypeLabel.fromStorage(json['paymentType'] as String),
      categoryId: json['category'] as String? ?? 'fixedCosts',
      date: DateTime.parse(json['date'] as String),
      installments: (json['installments'] as num?)?.toInt() ?? 1,
    );
  }
}
