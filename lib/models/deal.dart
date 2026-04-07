class Deal {
  final String transactionId;
  final double amount;
  final String description;
  final String sellerPhone;
  final String buyerPhone;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double transactionFee;
  final double releaseFee;
  final String? mpesaReceipt;
  final String? disputeReason;
  final List<Map<String, String>> proofs;
  final List<Map<String, String>> statusHistory;

  Deal({
    required this.transactionId,
    required this.amount,
    required this.description,
    required this.sellerPhone,
    required this.buyerPhone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.transactionFee,
    required this.releaseFee,
    this.mpesaReceipt,
    this.disputeReason,
    this.proofs = const [],
    this.statusHistory = const [],
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      transactionId: json['transactionId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      sellerPhone: json['sellerPhone'] ?? '',
      buyerPhone: json['buyerPhone'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      transactionFee: (json['transactionFee'] ?? 0).toDouble(),
      releaseFee: (json['releaseFee'] ?? 0).toDouble(),
      mpesaReceipt: json['mpesaReceipt'],
      disputeReason: json['disputeReason'],
      proofs: List<Map<String, String>>.from(json['proofs'] ?? []),
      statusHistory: List<Map<String, String>>.from(json['statusHistory'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'amount': amount,
      'description': description,
      'sellerPhone': sellerPhone,
      'buyerPhone': buyerPhone,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'transactionFee': transactionFee,
      'releaseFee': releaseFee,
      'mpesaReceipt': mpesaReceipt,
      'disputeReason': disputeReason,
      'proofs': proofs,
      'statusHistory': statusHistory,
    };
  }
}
