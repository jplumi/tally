/// How a purchase was paid for.
enum PaymentType { debit, credit }

extension PaymentTypeLabel on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.debit:
        return 'Débito';
      case PaymentType.credit:
        return 'Crédito';
    }
  }

  String get storageValue => name;

  static PaymentType fromStorage(String value) {
    return PaymentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentType.debit,
    );
  }
}
