import 'mpesa_balance.dart';

class MpesaBalanceSnapshot {
  final DateTime timestamp;
  final List<MpesaBalance> balances;

  MpesaBalanceSnapshot({
    required this.timestamp,
    required this.balances,
  });

  factory MpesaBalanceSnapshot.fromJson(Map<String, dynamic> json) {
    print('📦 MpesaBalanceSnapshot.fromJson: $json');
    final rawBalances = (json['accounts'] ?? json['balances']) as List? ?? [];
    return MpesaBalanceSnapshot(
      timestamp: DateTime.parse(json['createdAt'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()),
      balances: rawBalances.map((e) => MpesaBalance.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
