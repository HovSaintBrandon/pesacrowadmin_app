class MpesaBalance {
  final String accountType;
  final double amount;
  final String currency;

  MpesaBalance({
    required this.accountType,
    required this.amount,
    required this.currency,
  });

  factory MpesaBalance.fromJson(Map<String, dynamic> json) {
    return MpesaBalance(
      accountType: json['AccountType'] ?? json['accountType'] ?? '',
      amount: (json['Amount'] ?? json['amount'] ?? 0).toDouble(),
      currency: json['Currency'] ?? json['currency'] ?? 'KES',
    );
  }
}
