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
    print('📦 MpesaBalance.fromJson: $json');
    return MpesaBalance(
      accountType: json['name'] ?? json['accountType'] ?? '',
      amount: double.tryParse((json['available'] ?? json['working'] ?? json['amount'] ?? '0').toString()) ?? 0.0,
      currency: json['currency'] ?? 'KES',
    );
  }
}
