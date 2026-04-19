class AuditLog {
  final String id;
  final String action;
  final String performedBy;
  final dynamic details;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.details,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    String parsedDetails = json['description'] ?? json['details']?.toString() ?? '';
    if (json['newValue'] != null) {
      parsedDetails += '\nNew: ${json['newValue']}';
    }
    if (json['oldValue'] != null) {
      parsedDetails += '\nOld: ${json['oldValue']}';
    }

    return AuditLog(
      id: json['_id'] ?? json['id'] ?? '',
      action: json['action'] ?? '',
      performedBy: json['adminEmail'] ?? json['performedBy'] ?? json['adminId'] ?? '',
      details: parsedDetails.trim(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
