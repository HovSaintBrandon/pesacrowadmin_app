class FinancialStats {
  final double totalFees;
  final double realizedRevenue;
  final double withdrawableBalance;
  final double pendingFees;

  FinancialStats({
    required this.totalFees,
    required this.realizedRevenue,
    required this.withdrawableBalance,
    required this.pendingFees,
  });

  factory FinancialStats.fromJson(Map<String, dynamic> json) {
    return FinancialStats(
      totalFees: (json['totalFees'] ?? 0).toDouble(),
      realizedRevenue: (json['realizedRevenue'] ?? 0).toDouble(),
      withdrawableBalance: (json['withdrawableBalance'] ?? 0).toDouble(),
      pendingFees: (json['pendingFees'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalFees': totalFees,
      'realizedRevenue': realizedRevenue,
      'withdrawableBalance': withdrawableBalance,
      'pendingFees': pendingFees,
    };
  }
}
