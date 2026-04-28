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
    final fees = json['feesApplied'] as Map<String, dynamic>? ?? {};
    
    return Deal(
      transactionId: json['transactionId'] ?? json['_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      sellerPhone: json['sellerPhone'] ?? '',
      buyerPhone: json['buyerPhone'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      transactionFee: (fees['transactionFee'] ?? json['transactionFee'] ?? 0).toDouble(),
      releaseFee: (fees['releaseFee'] ?? json['releaseFee'] ?? 0).toDouble(),
      mpesaReceipt: json['mpesaReceipt'],
      disputeReason: json['disputeReason'],
      proofs: json['proofs'] != null
          ? (json['proofs'] as List)
              .map((p) => (p as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
              .toList()
          : [],
      statusHistory: json['statusHistory'] != null
          ? (json['statusHistory'] as List)
              .map((h) => (h as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
              .toList()
          : [],
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
