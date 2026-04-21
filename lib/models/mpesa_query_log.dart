class MpesaQueryLog {
  final String id;
  final String? conversationId;
  final String? originatorConversationId;
  final String? receipt;
  final String? status;
  final String? resultDesc;
  final Map<String, dynamic>? rawResponse;
  final DateTime createdAt;

  MpesaQueryLog({
    required this.id,
    this.conversationId,
    this.originatorConversationId,
    this.receipt,
    this.status,
    this.resultDesc,
    this.rawResponse,
    required this.createdAt,
  });

  factory MpesaQueryLog.fromJson(Map<String, dynamic> json) {
    return MpesaQueryLog(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'],
      originatorConversationId: json['originatorConversationId'],
      receipt: json['receipt'],
      status: json['status'],
      resultDesc: json['resultDesc'],
      rawResponse: json['rawResponse'] is Map ? json['rawResponse'] : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
